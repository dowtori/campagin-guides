/* IG Lead Saver — content script
 * 인스타그램 DOM에 저장 버튼을 주입하고, 프로필 정보를 수집해 background로 넘긴다.
 */
(() => {
  'use strict';

  // ── 상수 ──────────────────────────────────────────────────────────────────
  // /explore/ 같은 예약 경로는 사용자명이 아니다.
  const RESERVED = new Set([
    '', 'p', 'reel', 'reels', 'stories', 'explore', 'direct', 'accounts',
    'about', 'developer', 'legal', 'privacy', 'terms', 'challenge', 'emails',
    'session', 'your_activity', 'ajax', 'api', 'graphql', 'web', 'a', 'lite',
    'settings', 'archive', 'create', 'saved', 'tv', 'igtv', 'locations',
    'nametag', 'topics', 'push'
  ]);

  const FALLBACK_APP_ID = '936619743392459';

  // 저장된 사용자명 캐시 (버튼 상태 표시용). background와 동기화.
  let savedSet = new Set();   // 이 캠페인 탭에 저장된 계정
  let knownSet = new Set();   // 과거 캠페인 포함 전체 접촉 이력
  // 저장 진행 중인 사용자명 (중복 클릭 방지)
  const inFlight = new Set();

  // ── 유틸 ──────────────────────────────────────────────────────────────────
  const debounce = (fn, ms) => {
    let t;
    return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); };
  };

  /** 쿠키 한 개 읽기 (content script는 instagram.com 오리진이라 그대로 보인다) */
  function cookie(name) {
    const m = document.cookie.match(new RegExp(`(^|;\\s*)${name}=([^;]*)`));
    return m ? decodeURIComponent(m[2]) : '';
  }

  /**
   * 인스타 웹 클라이언트가 내부 API에 붙이는 헤더 묶음.
   * app id만 보내면 일부 계정에서 400이 떨어진다.
   */
  function apiHeaders(appId) {
    const h = {
      'x-ig-app-id': appId,
      'x-asbd-id': '129477',
      'x-requested-with': 'XMLHttpRequest'
    };
    const csrf = cookie('csrftoken');
    if (csrf) h['x-csrftoken'] = csrf;
    // www-claim은 페이지가 sessionStorage에 넣어둔다. 콘텐츠 스크립트는 같은 오리진이라 읽힌다.
    try {
      const claim = sessionStorage.getItem('www-claim-v2') || sessionStorage.getItem('www-claim');
      if (claim) h['x-ig-www-claim'] = claim;
    } catch (_) { /* noop */ }
    return h;
  }

  // 1.5: page responses/cache first; one bounded queue for all extension API reads.
  let cooldownUntil = 0, lastLimitStatus = 0, authProblem = false;
  const inCooldown = () => Date.now() < cooldownUntil;
  const cooldownLeftSec = () => Math.max(1, Math.ceil((cooldownUntil - Date.now()) / 1000));
  function clearCooldown() { cooldownUntil = 0; renderDockMeta(); rearmStalledTiles(); }
  function paintKnownTiles() {
    document.querySelectorAll('a[data-igls-tile]').forEach(a => a._iglsPaint?.());
  }
  function readVisibleProfile(username) {
    // Only read the displayed profile, never infer a post author's count from the brand header.
    if (IGLSCore.key(usernameFromPath(location.pathname)) !== IGLSCore.key(username)) return null;
    const header = document.querySelector('main header, header section');
    if (!header) return null;
    const result = { username };
    for (const a of header.querySelectorAll('a[href]')) {
      const count = IGLSCore.parseStat({href: a.getAttribute('href') || '', text: a.textContent,
        title: a.querySelector('[title]')?.getAttribute('title') || a.getAttribute('title') || '',
        aria: a.getAttribute('aria-label') || ''});
      if (count) { result[count.field] = count.value; if (count.field === 'followers') result.followersApprox = count.approximate; }
    }
    return result;
  }
  const profileClient = IGLSCore.createClient({
    fetch: (...args) => fetch(...args), storage: chrome.storage.local,
    headers: () => apiHeaders(FALLBACK_APP_ID), readDOM: readVisibleProfile,
    onData: () => queueMicrotask(paintKnownTiles),
    onState: st => { cooldownUntil = st.until; lastLimitStatus = st.status; authProblem = st.status === 401 && st.until > Date.now(); renderDockMeta(); }
  });
  const passivePackets = [];
  let passiveReady = false;
  window.addEventListener('message', ev => {
    if (ev.source !== window || ev.origin !== location.origin || ev.data?.source !== 'igls-passive-v15') return;
    if (!passiveReady) { if (passivePackets.length < 20) passivePackets.push(ev.data); return; }
    profileClient.accept(ev.data); paintKnownTiles();
  });
  async function igApiGet(url) { return profileClient.request(url); }

  /** href나 pathname에서 사용자명 추출. 프로필 링크가 아니면 null */
  function usernameFromPath(pathname) {
    if (!pathname) return null;
    const parts = pathname.split('?')[0].split('#')[0].split('/').filter(Boolean);
    if (parts.length === 0) return null;
    const first = parts[0].toLowerCase();
    if (RESERVED.has(first)) return null;
    // /username/ 또는 /username/reels/ 같은 하위 탭까지 허용
    if (!/^[A-Za-z0-9._]{1,30}$/.test(parts[0])) return null;
    return parts[0];
  }

  /** 지금 보고 있는 화면이 프로필 페이지면 사용자명 반환 */
  function currentProfileUsername() {
    // 게시물 모달이 열려 있으면 그 게시물 작성자가 우선
    const dialog = document.querySelector('div[role="dialog"] article');
    if (dialog) {
      const u = usernameFromArticle(dialog);
      if (u) return u;
    }
    return usernameFromPath(location.pathname);
  }

  /** article(피드 게시물/모달) 안의 헤더에서 작성자 사용자명 추출 */
  function usernameFromArticle(article) {
    if (!article) return null;
    const header = article.querySelector('header') || article;
    const anchors = header.querySelectorAll('a[href^="/"]');
    for (const a of anchors) {
      const u = usernameFromPath(new URL(a.href, location.origin).pathname);
      if (u) return u;
    }
    return null;
  }

  // ── 프로필 정보 수집 ───────────────────────────────────────────────────────
  /**
   * 인스타 웹 내부 API로 프로필 상세를 가져온다.
   * content script는 instagram.com 오리진에서 돌기 때문에 세션 쿠키가 그대로 실린다.
   */
  // 세션 내 프로필 캐시. 호버로 미리 본 계정을 저장할 때 재요청하지 않는다.

  const clean = (s) => (s || '').replace(/\s+/g, ' ').trim();

  /** Visible page and shared cache first; supported fallback is in profile-core.js. */
  async function fetchProfile(username, opts = {}) {
    const p = await profileClient.get(username, { pk: profileClient.owner(opts.shortcode)?.pk });
    return { ...minimalProfile(username), ...p };
  }

  /** API가 막혔을 때 최소한의 정보라도 저장하기 위한 폴백 */
  function minimalProfile(username) {
    return {
      username,
      fullName: '',
      profileUrl: `https://www.instagram.com/${username}/`,
      followers: '', following: '', posts: '',
      isVerified: false, isPrivate: false, isBusiness: false,
      category: '', biography: '', externalUrl: '', email: '', phone: '',
      profilePic: ''
    };
  }

  // ── 저장 실행 ─────────────────────────────────────────────────────────────
  /**
   * @param {string} username
   * @param {string} source 어디서 저장했는지 (유입경로 컬럼)
   * @param {HTMLElement=} btn 상태를 표시할 버튼
   */
  async function saveUsername(username, source, btn, opts = {}) {
    if (!username) return { ok: false, error: '사용자명이 없습니다.' };
    if (inFlight.has(username)) return { ok: false, error: '이미 처리 중입니다.' };
    inFlight.add(username);
    setBtnState(btn, 'loading');

    try {
      let profile;
      try {
        profile = await fetchProfile(username, opts);
      } catch (e) {
        // 모든 조회 경로가 막혀도 링크와 계정명은 남긴다.
        console.warn(`[IG Lead Saver] 프로필 조회 실패(${e.message}) — 최소 정보로 저장`);
        profile = { ...minimalProfile(username), ...(profileClient.peek(username) || {}) };
      }

      // 전송 항목은 시트에 실제로 기록되는 값으로만 한정한다.
      // (저장 시각은 Apps Script가 서버에서 직접 찍으므로 보내지 않는다.
      //  페이지 URL도 보내지 않는다 — 열람 이력이 전송될 이유가 없다.)
      const payload = { ...profile, source: source + (profile.followersApprox ? ' · 팔로워 반올림값' : profile.followers === '' || profile.followers == null ? ' · 팔로워 미확인' : '') };

      const res = await chrome.runtime.sendMessage({ type: 'SAVE_LEAD', payload });

      if (res?.ok) {
        if (!res.sheetName || res.sheetName === config.sheetName) { savedSet.add(username.toLowerCase()); setBtnState(btn, 'saved'); }
        else setBtnState(btn, stateFor(username));

        if (res.status === 'duplicate') {
          toast(`이미 있음 · @${username}`, 'info');
        } else if (res.prior) {
          // 시트가 "과거에 접촉한 적 있다"고 알려준 경우.
          // 여기서 표시하지 않으면 중복 발송을 아무도 눈치채지 못한다.
          knownSet.add(username.toLowerCase());
          const when = res.prior.firstAt ? `${res.prior.firstAt.slice(0, 10)} · ` : '';
          const where = res.prior.campaign || '이전 캠페인';
          toast(`⚠ 이미 접촉한 계정입니다 — ${when}${where}`, 'warn');
          console.warn(`[IG Lead Saver] 중복 접촉: @${username} (${when}${where})`);
        } else {
          const f = profile.followers === '' || profile.followers == null ? ' · 팔로워 미확인' : ` · 팔로워 ${profile.followersApprox ? '약 ' : ''}${fmt(profile.followers)}`;
          toast(`저장 완료 · @${username}${f}`, 'ok');
        }
        refreshAllButtons();
        return { ok: true, status: res.status, username };
      }

      setBtnState(btn, 'idle');
      const err = res?.error || '저장 실패 — 옵션에서 시트 URL을 확인하세요';
      toast(err, 'err');
      return { ok: false, error: err };
    } catch (e) {
      setBtnState(btn, 'idle');
      toast(`오류: ${e.message}`, 'err');
      return { ok: false, error: e.message };
    } finally {
      inFlight.delete(username);
    }
  }

  const fmt = (n) => (typeof n === 'number' ? n.toLocaleString('ko-KR') : n);

  // ── 토스트 ────────────────────────────────────────────────────────────────
  let toastTimer;
  function toast(msg, kind = 'ok') {
    let el = document.getElementById('igls-toast');
    if (!el) {
      el = document.createElement('div');
      el.id = 'igls-toast';
      document.body.appendChild(el);
    }
    el.textContent = msg;
    el.className = `igls-toast igls-toast--${kind} igls-toast--show`;
    clearTimeout(toastTimer);
    // 중복 접촉 경고는 놓치면 안 되므로 오래 띄운다
    toastTimer = setTimeout(() => el.classList.remove('igls-toast--show'), kind === 'warn' ? 7000 : 2600);
  }

  // ── 버튼 만들기 ───────────────────────────────────────────────────────────
  /** 계정 하나의 버튼 상태를 결정한다 */
  function stateFor(username) {
    const u = (username || '').toLowerCase();
    if (savedSet.has(u)) return 'saved';   // 이 캠페인에 이미 있음
    if (knownSet.has(u)) return 'known';   // 예전에 접촉한 적 있음
    return 'idle';
  }

  function setBtnState(btn, state) {
    if (!btn) return;
    btn.dataset.state = state;
    const label = btn.querySelector('.igls-btn__label');
    const icon = btn.querySelector('.igls-btn__icon');
    if (state === 'loading') {
      if (icon) icon.textContent = '⋯';
      if (label) label.textContent = '저장 중';
    } else if (state === 'saved') {
      if (icon) icon.textContent = '✓';
      if (label) label.textContent = '저장됨';
    } else if (state === 'known') {
      if (icon) icon.textContent = '!';
      if (label) label.textContent = '기존 접촉';
    } else {
      if (icon) icon.textContent = '+';
      if (label) label.textContent = btn.dataset.idleLabel || '시트에 저장';
    }
  }

  function makeButton({ username, source, variant, idleLabel }) {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = `igls-btn igls-btn--${variant}`;
    btn.dataset.iglsUser = username;
    btn.dataset.idleLabel = idleLabel || '시트에 저장';
    btn.title = `@${username} 를 구글시트에 저장`;
    btn.innerHTML = `<span class="igls-btn__icon">+</span><span class="igls-btn__label"></span>`;
    setBtnState(btn, stateFor(username));

    // username이 비어 있으면(그리드 미해석 타일) 호출부가 직접 핸들러를 단다.
    if (username) {
      btn.addEventListener('click', (ev) => {
        ev.preventDefault();
        ev.stopPropagation();
        // 이미 저장된 항목도 다시 누르면 재전송 (시트에서 중복 처리)
        saveUsername(username, source, btn);
      }, true);
    }

    return btn;
  }

  /** 저장 상태가 바뀌었을 때 화면의 모든 버튼 라벨 갱신 */
  function refreshAllButtons() {
    document.querySelectorAll('.igls-btn').forEach((b) => {
      const u = (b.dataset.iglsUser || '').toLowerCase();
      if (b.dataset.state === 'loading') return;
      setBtnState(b, stateFor(u));
    });
  }

  // ── 플로팅 패널 위치 · 최소화 상태 ────────────────────────────────────────
  // 기본 위치(우하단)는 인스타 DM 위젯과 겹친다. 사용자가 옮긴 위치와
  // 접힘 상태를 저장해 페이지를 이동해도 유지한다.
  let panelPos = null;      // { x, y } — 뷰포트 좌상단 기준. null이면 기본 위치
  let panelMinimized = false;

  async function loadPanelState() {
    const st = await chrome.storage.local.get(['panelPos', 'panelMinimized']);
    panelPos = st.panelPos || null;
    panelMinimized = !!st.panelMinimized;
  }

  const savePanelPos = debounce(() => {
    chrome.storage.local.set({ panelPos });
  }, 300);

  /** 패널이 화면 밖으로 나가지 않도록 가둔다 (창 크기가 줄어든 경우 대비) */
  function clampPanel(el, x, y) {
    const w = el.offsetWidth || 200;
    const h = el.offsetHeight || 100;
    const m = 8;
    return {
      x: Math.min(Math.max(m, x), Math.max(m, window.innerWidth - w - m)),
      y: Math.min(Math.max(m, y), Math.max(m, window.innerHeight - h - m))
    };
  }

  function applyPanelPos(el) {
    if (!panelPos) {
      // 기본 위치는 CSS(우하단)에 맡긴다
      el.style.left = el.style.top = '';
      el.style.right = ''; el.style.bottom = '';
      return;
    }
    const p = clampPanel(el, panelPos.x, panelPos.y);
    el.style.left = `${p.x}px`;
    el.style.top = `${p.y}px`;
    el.style.right = 'auto';
    el.style.bottom = 'auto';
  }

  /** 헤더를 잡고 끌어서 옮긴다 */
  function makeDraggable(el, handle) {
    let startX, startY, originX, originY, dragging = false, moved = false;

    handle.addEventListener('pointerdown', (ev) => {
      if (ev.button !== 0) return;
      const r = el.getBoundingClientRect();
      startX = ev.clientX; startY = ev.clientY;
      originX = r.left; originY = r.top;
      dragging = true; moved = false;
      handle.setPointerCapture(ev.pointerId);
      el.classList.add('igls-panel--dragging');
      ev.preventDefault();
    });

    handle.addEventListener('pointermove', (ev) => {
      if (!dragging) return;
      const dx = ev.clientX - startX;
      const dy = ev.clientY - startY;
      if (!moved && Math.hypot(dx, dy) < 3) return;   // 미세한 흔들림은 무시
      moved = true;
      const p = clampPanel(el, originX + dx, originY + dy);
      el.style.left = `${p.x}px`;
      el.style.top = `${p.y}px`;
      el.style.right = 'auto';
      el.style.bottom = 'auto';
    });

    const end = (ev) => {
      if (!dragging) return;
      dragging = false;
      el.classList.remove('igls-panel--dragging');
      try { handle.releasePointerCapture(ev.pointerId); } catch (_) { /* noop */ }
      if (moved) {
        const r = el.getBoundingClientRect();
        panelPos = { x: r.left, y: r.top };
        savePanelPos();
      }
    };
    handle.addEventListener('pointerup', end);
    handle.addEventListener('pointercancel', end);
  }

  function setPanelMinimized(el, min, persist) {
    panelMinimized = min;
    el.classList.toggle('igls-panel--min', min);
    const t = el.querySelector('.igls-panel__toggle');
    if (t) {
      t.textContent = min ? '＋' : '−';
      t.title = min ? '펼치기' : '접기';
      t.setAttribute('aria-label', min ? '펼치기' : '접기');
    }
    if (persist) chrome.storage.local.set({ panelMinimized: min });
    updateHandleText();
    // 접거나 펴면 크기가 바뀌므로 화면 밖으로 나가지 않게 다시 가둔다
    requestAnimationFrame(() => applyPanelPos(el));
  }

  window.addEventListener('resize', debounce(() => {
    if (panel && panelPos) applyPanelPos(panel);
  }, 150));

  // ── 저장 대상 판별 ────────────────────────────────────────────────────────
  /**
   * 지금 화면에서 저장할 계정. 세 경우를 모두 본다.
   *   1) 게시물 모달이 열려 있으면 그 작성자
   *   2) 프로필 페이지면 그 프로필 (릴스 탭 /username/reels/ 포함)
   *   3) 릴스 피드(/reels/{코드}/)면 지금 보고 있는 릴스의 작성자
   */
  function currentTargetUsername() {
    const u = currentProfileUsername();
    if (u) return u;
    return visibleReelAuthor();
  }

  /** 릴스 피드에서 화면 중앙에 있는 릴스의 작성자 링크를 찾는다 */
  function visibleReelAuthor() {
    if (!/^\/reels?\//.test(location.pathname)) return null;

    const mid = window.innerHeight / 2;
    let best = null, bestDist = Infinity;

    document.querySelectorAll('a[href^="/"]').forEach((a) => {
      const name = usernameFromPath(new URL(a.href, location.origin).pathname);
      if (!name) return;
      const r = a.getBoundingClientRect();
      if (!r.height || r.bottom < 0 || r.top > window.innerHeight) return;
      const d = Math.abs((r.top + r.bottom) / 2 - mid);
      if (d < bestDist) { bestDist = d; best = name; }
    });
    return best;
  }

  // ── 주입 지점 1: 플로팅 독 (저장 버튼 + 저장자·캠페인 표시) ─────────────────
  // 인스타 어느 화면에서든 떠 있다. 재접속했을 때 "내가 누구로, 어느 캠페인에
  // 담고 있는지"를 기억하지 않아도 되게 하는 것이 목적.
  let panel;
  let dockTarget = null;

  function ensureProfilePanel() {
    const username = currentTargetUsername();

    if (!panel) {
      buildDock();
    }
    if (dockTarget !== username) {
      dockTarget = username;
      renderDockTarget();
    } else {
      const b = panel.querySelector('.igls-btn--primary');
      if (b && username && b.dataset.state !== 'loading') setBtnState(b, stateFor(username));
    }
  }

  function buildDock() {
    panel = document.createElement('div');
    panel.className = 'igls-panel';

    const handle = document.createElement('div');
    handle.className = 'igls-panel__handle';

    const who = document.createElement('span');
    who.className = 'igls-panel__who';

    const toggle = document.createElement('button');
    toggle.type = 'button';
    toggle.className = 'igls-panel__toggle';
    toggle.addEventListener('pointerdown', (ev) => ev.stopPropagation()); // 드래그와 분리
    toggle.addEventListener('click', (ev) => {
      ev.preventDefault();
      ev.stopPropagation();
      setPanelMinimized(panel, !panelMinimized, true);
    });

    handle.append(who, toggle);

    const body = document.createElement('div');
    body.className = 'igls-panel__body';

    const target = document.createElement('div');
    target.className = 'igls-dock__target';

    const meta = document.createElement('div');
    meta.className = 'igls-dock__meta';

    const byChip = document.createElement('button');
    byChip.type = 'button';
    byChip.className = 'igls-dock__chip';
    byChip.dataset.field = 'savedBy';
    byChip.addEventListener('click', (ev) => { ev.stopPropagation(); openDockEditor('savedBy'); });

    const campChip = document.createElement('button');
    campChip.type = 'button';
    campChip.className = 'igls-dock__chip';
    campChip.dataset.field = 'sheetName';
    campChip.addEventListener('click', (ev) => { ev.stopPropagation(); openDockEditor('sheetName'); });

    meta.append(byChip, campChip);

    const editor = document.createElement('div');
    editor.className = 'igls-dock__editor';
    editor.hidden = true;

    body.append(target, meta, editor);
    panel.append(handle, body);
    document.body.appendChild(panel);

    makeDraggable(panel, handle);
    applyPanelPos(panel);
    setPanelMinimized(panel, panelMinimized, false);
    renderDockMeta();
    // 처음 만들 때도 대상 영역을 한 번 그려야 한다.
    // (대상이 null 이면 ensureProfilePanel 의 비교가 통과해버려 안내 문구가 안 나온다)
    renderDockTarget();
  }

  /**
   * 헤더 문구. 접었을 때는 저장 대상 대신 저장자·캠페인을 보여준다 —
   * 접힌 상태에서도 "누구로, 어느 캠페인에" 담는지가 보여야 하기 때문.
   */
  function updateHandleText() {
    const who = panel?.querySelector('.igls-panel__who');
    if (!who) return;
    if (panelMinimized) {
      who.textContent = `${config.savedBy || '이름 미설정'} · ${config.sheetName}`;
    } else {
      who.textContent = dockTarget ? `@${dockTarget}` : 'IG Lead Saver';
    }
  }

  /** 저장자·캠페인 칩 갱신 */
  function renderDockMeta() {
    if (!panel) return;
    updateHandleText();
    const by = panel.querySelector('.igls-dock__chip[data-field="savedBy"]');
    const camp = panel.querySelector('.igls-dock__chip[data-field="sheetName"]');
    if (by) {
      by.textContent = config.savedBy ? `👤 ${config.savedBy}` : '👤 이름 설정';
      by.classList.toggle('igls-dock__chip--unset', !config.savedBy);
      by.title = '저장자 이름 변경';
    }
    if (camp) {
      camp.textContent = `📁 ${config.sheetName}`;
      camp.title = '진행 중인 캠페인(시트 탭) 변경';
    }

    // 상태 안내 — 이게 없으면 팀원이 "확장이 고장났다"고 오해한다.
    // 조회 제한(기다리면 풀림)과 세션 만료(재로그인 필요)는 대응이 달라 분리한다.
    let warn = panel.querySelector('.igls-dock__limit');
    const msg = authProblem
      ? '인스타 로그인 또는 계정 확인이 필요합니다 (HTTP 401). 확인 후 아래 버튼을 눌러주세요.'
      : inCooldown()
        ? `추가 조회 ${cooldownLeftSec()}초 대기 (HTTP ${lastLimitStatus}). 계정명을 확인한 대상은 링크를 저장할 수 있습니다.`
        : '';

    if (msg) {
      if (!warn) {
        warn = document.createElement('div');
        warn.className = 'igls-dock__limit';
        panel.querySelector('.igls-panel__body')?.appendChild(warn);
      }
      warn.textContent = msg;
      if (authProblem) {
        const retry = document.createElement('button'); retry.textContent = '로그인 후 재확인'; retry.type = 'button';
        retry.addEventListener('click', async () => { await profileClient.resume(); authProblem = false; clearCooldown(); });
        warn.appendChild(retry);
      }
      warn.classList.toggle('igls-dock__limit--auth', authProblem);
      // 접혀 있으면 안내가 안 보이므로 펴준다 (한 번만)
      if (panelMinimized && !warn.dataset.expanded) {
        warn.dataset.expanded = '1';
        setPanelMinimized(panel, false, false);
      }
    } else if (warn) {
      warn.remove();
    }
  }

  // 쿨다운이 풀리면 안내를 스스로 걷어낸다
  setInterval(() => {
    if (cooldownUntil && !inCooldown()) clearCooldown();
    else if (inCooldown()) renderDockMeta();
  }, 20000);

  /** 저장 대상(프로필/릴스 작성자)에 맞춰 헤더와 버튼을 갱신 */
  function renderDockTarget() {
    if (!panel) return;
    const who = panel.querySelector('.igls-panel__who');
    const target = panel.querySelector('.igls-dock__target');
    if (!who || !target) return;

    target.textContent = '';
    updateHandleText();

    if (!dockTarget) {
      const hint = document.createElement('div');
      hint.className = 'igls-panel__hint';
      hint.textContent = '프로필·게시물·릴스에서 저장할 수 있습니다';
      target.appendChild(hint);
      return;
    }

    const btn = makeButton({
      username: dockTarget,
      source: dockSource(),
      variant: 'primary',
      idleLabel: '시트에 저장'
    });
    const hint = document.createElement('div');
    hint.className = 'igls-panel__hint';
    hint.textContent = '드래그로 이동 · Alt + S';
    target.append(btn, hint);
  }

  function dockSource() {
    const p = location.pathname;
    if (/^\/reels?\//.test(p)) return '릴스 피드';
    const parts = p.split('/').filter(Boolean);
    const tab = (parts[1] || '').toLowerCase();
    if (tab === 'reels') return `릴스 탭 (@${parts[0]})`;
    if (tab === 'tagged') return `태그됨 (@${parts[0]})`;
    return '프로필 페이지';
  }

  /** 칩을 누르면 그 자리에서 값을 바꾸는 인라인 편집기 */
  async function openDockEditor(field) {
    const editor = panel?.querySelector('.igls-dock__editor');
    if (!editor) return;

    if (!editor.hidden && editor.dataset.field === field) {
      editor.hidden = true;
      return;
    }
    editor.dataset.field = field;
    editor.hidden = false;
    editor.textContent = '';

    if (field === 'savedBy') {
      const input = document.createElement('input');
      input.type = 'text';
      input.className = 'igls-dock__input';
      input.placeholder = '이름 (예: 김민수)';
      input.value = config.savedBy;
      input.maxLength = 20;

      const save = document.createElement('button');
      save.type = 'button';
      save.className = 'igls-dock__ok';
      save.textContent = '확인';

      const commit = async () => {
        const v = input.value.trim();
        await chrome.runtime.sendMessage({ type: 'SET_CONFIG', savedBy: v });
        config.savedBy = v;
        renderDockMeta();
        editor.hidden = true;
        toast(v ? `저장자: ${v}` : '저장자 이름을 비웠습니다', 'info');
      };
      save.addEventListener('click', commit);
      input.addEventListener('keydown', (e) => { if (e.key === 'Enter') commit(); });

      editor.append(input, save);
      input.focus();
      input.select();
      return;
    }

    // 캠페인(시트 탭) — 시트에서 탭 목록을 받아 고르거나 새로 만든다
    const loading = document.createElement('div');
    loading.className = 'igls-dock__note';
    loading.textContent = '시트 탭 불러오는 중…';
    editor.appendChild(loading);

    const res = await chrome.runtime.sendMessage({ type: 'LIST_SHEETS' });
    editor.textContent = '';

    if (!res?.ok) {
      const err = document.createElement('div');
      err.className = 'igls-dock__note igls-dock__note--err';
      err.textContent = res?.error || '탭 목록을 불러오지 못했습니다';
      editor.appendChild(err);
      return;
    }

    const select = document.createElement('select');
    select.className = 'igls-dock__input';
    (res.sheets || []).forEach((s) => {
      const o = document.createElement('option');
      o.value = s.name;
      o.textContent = `${s.name} (${s.rowCount})`;
      if (s.name === config.sheetName) o.selected = true;
      select.appendChild(o);
    });
    const newOpt = document.createElement('option');
    newOpt.value = '__new__';
    newOpt.textContent = '+ 새 캠페인 만들기…';
    select.appendChild(newOpt);

    const nameInput = document.createElement('input');
    nameInput.type = 'text';
    nameInput.className = 'igls-dock__input';
    nameInput.placeholder = '새 캠페인 이름';
    nameInput.hidden = true;

    select.addEventListener('change', () => {
      nameInput.hidden = select.value !== '__new__';
      if (!nameInput.hidden) nameInput.focus();
    });

    const ok = document.createElement('button');
    ok.type = 'button';
    ok.className = 'igls-dock__ok';
    ok.textContent = '적용';

    ok.addEventListener('click', async () => {
      ok.disabled = true;
      try {
        if (select.value === '__new__') {
          const name = nameInput.value.trim();
          if (!name) { toast('캠페인 이름을 입력하세요', 'err'); ok.disabled = false; return; }
          const r = await chrome.runtime.sendMessage({ type: 'CREATE_SHEET', name });
          if (!r?.ok) { toast(r?.error || '탭 생성 실패', 'err'); ok.disabled = false; return; }
          config.sheetName = r.created;
          toast(`캠페인 생성: ${r.created}`, 'ok');
        } else {
          await chrome.runtime.sendMessage({ type: 'SET_CONFIG', sheetName: select.value });
          config.sheetName = select.value;
          toast(`캠페인 전환: ${select.value}`, 'info');
        }
        renderDockMeta();
        refreshAllButtons();
        editor.hidden = true;
      } finally {
        ok.disabled = false;
      }
    });

    editor.append(select, nameInput, ok);
  }

  // ── 주입 지점 2: 피드/모달 게시물 헤더 ────────────────────────────────────
  function injectArticleButtons() {
    document.querySelectorAll('article').forEach((article) => {
      if (article.dataset.iglsDone === '1') {
        // SPA 재사용으로 작성자가 바뀌었을 수 있으니 사용자명 검증
        const cur = usernameFromArticle(article);
        const btn = article.querySelector(':scope .igls-btn');
        if (btn && cur && btn.dataset.iglsUser !== cur) {
          btn.remove();
          article.dataset.iglsDone = '0';
        } else {
          return;
        }
      }

      const username = usernameFromArticle(article);
      if (!username) return;

      const header = article.querySelector('header');
      if (!header) return;

      const btn = makeButton({
        username,
        source: '피드 게시물',
        variant: 'inline',
        idleLabel: '저장'
      });
      btn.classList.add('igls-btn--article');
      header.appendChild(btn);
      article.dataset.iglsDone = '1';
    });
  }

  // ── 그리드 썸네일 → 작성자 해석 ───────────────────────────────────────────
  // 태그됨/탐색 탭의 썸네일에는 작성자 정보가 DOM에 없다.
  // shortcode는 미디어 ID를 base64로 인코딩한 값이므로 역산이 가능하다(네트워크 불필요).
  const SC_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  function shortcodeToMediaId(shortcode) {
    try {
      let id = 0n;
      for (const ch of shortcode) {
        const idx = SC_ALPHABET.indexOf(ch);
        if (idx < 0) return null;
        id = id * 64n + BigInt(idx);
      }
      return id.toString();
    } catch (_) {
      return null;
    }
  }

  /**
   * 게시물 링크 해석. 인스타는 두 가지 형식을 섞어 쓴다.
   *   /p/{코드}/                   → 작성자 정보 없음
   *   /{계정명}/reel/{코드}/        → 작성자가 URL에 들어 있음 (태그됨 탭이 이 형식)
   * 후자면 조회 없이 작성자를 바로 알 수 있다.
   */
  function parsePostLink(href) {
    try {
      const p = new URL(href, location.origin).pathname;

      let m = p.match(/^\/(?:p|reel|reels|tv)\/([A-Za-z0-9_-]+)\/?/);
      if (m) return { shortcode: m[1], username: null };

      m = p.match(/^\/([A-Za-z0-9._]{1,30})\/(?:p|reel|reels|tv)\/([A-Za-z0-9_-]+)\/?/);
      if (m && !RESERVED.has(m[1].toLowerCase())) {
        return { shortcode: m[2], username: m[1] };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // shortcode → { username, followers } 캐시. 같은 타일을 여러 번 조회하지 않는다.
  const ownerCache = new Map();
  const ownerPending = new Map();

  async function loadOwnerCache() {
    const { ownerCache: stored = {} } = await chrome.storage.local.get('ownerCache');
    Object.entries(stored).forEach(([k, v]) => ownerCache.set(k, v));
  }

  const persistOwnerCache = debounce(async () => {
    // 최근 500건만 유지
    const entries = [...ownerCache.entries()].slice(-500);
    await chrome.storage.local.set({ ownerCache: Object.fromEntries(entries) });
  }, 1500);

  // 실패한 shortcode를 기억한다. 이게 없으면 스크롤로 타일이 재활용될 때마다
  // 같은 게시물을 무한히 다시 조회해서 차단을 스스로 연장한다.
  const ownerFail = new Map();   // shortcode -> 실패 시각
  const FAIL_TTL_MS = 10 * 60e3;

  /**
   * 미디어 작성자 조회. 프로필 그리드처럼 작성자가 자명한 경우는 호출 전에 걸러진다.
   * @param {{force?: boolean}} opts 사용자가 버튼을 직접 눌렀을 때는 쿨다운·실패캐시를 무시한다
   */
  async function resolveOwner(shortcode, opts = {}) {
    const observed = profileClient.owner(shortcode);
    if (observed) return observed;
    if (ownerCache.has(shortcode)) return ownerCache.get(shortcode);
    if (ownerPending.has(shortcode)) return ownerPending.get(shortcode);

    {
      const failedAt = ownerFail.get(shortcode);
      if (failedAt && Date.now() - failedAt < FAIL_TTL_MS) throw new Error('cached_fail');
      if (inCooldown()) throw new Error('cooldown');
    }

    const task = (async () => {
      const mediaId = shortcodeToMediaId(shortcode);
      if (!mediaId) throw new Error('shortcode_decode_failed');

      const json = await igApiGet(`https://www.instagram.com/api/v1/media/${mediaId}/info/`);
      const item = json?.items?.[0];
      const user = item?.user;
      if (!user?.username) throw new Error('media_api_no_owner');

      const info = {
        username: user.username,
        pk: user.pk ? String(user.pk) : (user.id ? String(user.id) : ''),
        fullName: user.full_name || '',
        isVerified: !!user.is_verified,
        followers: typeof user.follower_count === 'number' ? user.follower_count : null
      };
      ownerCache.set(shortcode, info);
      ownerFail.delete(shortcode);
      persistOwnerCache();
      return info;
    })()
      .catch((e) => {
        // 인스타가 막아서 실패한 건 '이 게시물이 해석 불가'라는 뜻이 아니다.
        // 이걸 실패 캐시에 넣으면 쿨다운(1분)이 풀린 뒤에도 10분간
        // '작성자 조회 실패'가 남아 팀원이 보고한 증상이 그대로 재현된다.
        if (e.kind !== 'limit' && e.kind !== 'auth') ownerFail.set(shortcode, Date.now());
        throw e;
      })
      .finally(() => ownerPending.delete(shortcode));

    ownerPending.set(shortcode, task);
    return task;
  }

  /** 지금 화면의 그리드가 "그 프로필 본인의 게시물"이면 조회 없이 작성자를 안다 */
  function gridOwnerShortcut() {
    const parts = location.pathname.split('/').filter(Boolean);
    const u = usernameFromPath(location.pathname);
    if (!u) return null;
    const tab = (parts[1] || '').toLowerCase();
    // /username/ 과 /username/reels/ 는 본인 게시물, /username/tagged/ 는 타인 게시물
    if (tab === '' || tab === 'reels') return u;
    return null;
  }

  // ── 팔로워 수 자동 표시 ───────────────────────────────────────────────────
  // Visible tiles only. profile-core serializes and paces network reads; cached data paints immediately.
  const BRIEF_CONCURRENCY = 1;
  const BRIEF_GAP_MS = 0; // the shared request queue owns network pacing
  const BRIEF_TTL_MS = 24 * 60 * 60 * 1000;

  const briefCache = new Map();   // username -> { followers, isVerified, fullName, at }
  const briefQueue = [];
  let briefActive = 0;
  let lastBriefAt = 0;

  async function loadBriefCache() {
    const { briefCache: stored = {} } = await chrome.storage.local.get('briefCache');
    const now = Date.now();
    Object.entries(stored).forEach(([k, v]) => {
      if (v && now - (v.at || 0) < BRIEF_TTL_MS) briefCache.set(k, v);
    });
  }

  const persistBriefCache = debounce(() => {
    const entries = [...briefCache.entries()].slice(-800);
    chrome.storage.local.set({ briefCache: Object.fromEntries(entries) });
  }, 1500);

  // 쿨다운 때문에 조회를 못 한 타일. 풀리면 여기 있는 것부터 다시 채운다.
  // IntersectionObserver 는 이미 unobserve 된 상태라 이 목록이 없으면 복구 경로가 없다.
  const stalledTiles = new Set();

  function rearmStalledTiles() {
    if (!stalledTiles.size) return;
    let n = 0;
    for (const el of [...stalledTiles]) {
      stalledTiles.delete(el);
      if (!el.isConnected || !el._iglsBrief) continue;
      el._iglsBrief();
      n++;
    }
    if (n) console.log(`[IG Lead Saver] 조회 제한 해제 — 대기 중이던 썸네일 ${n}개를 다시 조회합니다.`);
  }

  function pumpBrief() {
    if (inCooldown()) {
      // 버리기 전에 어떤 타일이었는지 기억해둔다
      briefQueue.forEach((j) => { j.__queued = false; if (j.__tile) stalledTiles.add(j.__tile); });
      briefQueue.length = 0;
      return;
    }
    if (briefActive >= BRIEF_CONCURRENCY || !briefQueue.length) return;
    const job = briefQueue.shift();
    job.__queued = false;
    if (job.__tile && (!job.__tile.isConnected || job.__tile.getBoundingClientRect().bottom < 0 || job.__tile.getBoundingClientRect().top > innerHeight + 120)) { pumpBrief(); return; }
    briefActive++;
    const wait = Math.max(0, BRIEF_GAP_MS - (Date.now() - lastBriefAt));
    setTimeout(async () => {
      lastBriefAt = Date.now();
      try { await job(); } catch (_) { /* 개별 실패는 무시 */ }
      briefActive--;
      pumpBrief();
    }, wait);
  }

  function enqueueBrief(job) {
    if (job.__queued) return;
    job.__queued = true;
    briefQueue.push(job);
    pumpBrief();
  }

  /** 캐시 우선 프로필 요약 조회 */
  async function getBrief(username, shortcode) {
    const live = profileClient.peek(username);
    if (typeof live?.followers === 'number') return live;
    const hit = briefCache.get(username.toLowerCase());
    if (hit && Date.now() - (hit.at || 0) < BRIEF_TTL_MS) return hit;

    const p = await fetchProfile(username, { shortcode });
    const brief = {
      followers: p.followers === '' ? null : p.followers,
      isVerified: !!p.isVerified,
      fullName: p.fullName || '',
      at: Date.now()
    };
    briefCache.set(username.toLowerCase(), brief);
    persistBriefCache();
    return brief;
  }

  // 화면에 들어온 타일만 조회 대상으로 삼는다
  const tileObserver = new IntersectionObserver((entries) => {
    entries.forEach((e) => {
      if (!e.isIntersecting) return;
      tileObserver.unobserve(e.target);
      e.target._iglsBrief?.();
    });
  }, { rootMargin: '120px' });

  /**
   * 팔로워 규모 구간. 좋고/나쁨이 아니라 크기 순서라 순차 램프를 쓴다.
   * 1: ~1천  2: 1천~1만  3: 1만~5만  4: 5만~100만  5: 100만~
   */
  function followerTier(n) {
    if (typeof n !== 'number') return 0;
    if (n < 1000) return 1;
    if (n < 10000) return 2;
    if (n < 50000) return 3;
    if (n < 1000000) return 4;
    return 5;
  }

  const FOLLOWER_ICON =
    '<svg viewBox="0 0 16 16" width="14" height="14" fill="currentColor" aria-hidden="true">' +
    '<path d="M8 8a3 3 0 1 0 0-6 3 3 0 0 0 0 6Zm0 1.4c-2.76 0-5 1.4-5 3.1V14h10v-1.5c0-1.7-2.24-3.1-5-3.1Z"/></svg>';

  // 100만 이상에만 붙는다. 색만으로는 최하위(어두운 칩)와 헷갈리므로
  // 모양이라는 다른 채널을 하나 더 준다.
  const STAR_ICON =
    '<svg viewBox="0 0 16 16" width="14" height="14" fill="currentColor" aria-hidden="true">' +
    '<path d="M8 1.5l1.94 3.93 4.34.63-3.14 3.06.74 4.32L8 11.42l-3.88 2.02.74-4.32L1.72 6.06l4.34-.63z"/></svg>';

  // ── 주입 지점 3: 그리드 썸네일 (태그됨 · 탐색 · 프로필) ────────────────────
  function injectGridButtons() {
    const shortcut = gridOwnerShortcut();
    let found = 0;

    document.querySelectorAll('a[href*="/p/"], a[href*="/reel/"]').forEach((a) => {
      const link = parsePostLink(a.href);
      if (!link) return;
      const { shortcode } = link;
      // 작성자를 아는 경로: URL에 박혀 있거나(태그됨 탭), 본인 프로필 그리드거나.
      const knownOwner = link.username || shortcut || profileClient.owner(shortcode)?.username || ownerCache.get(shortcode)?.username;

      // 썸네일 타일만 대상. 본문 링크나 작은 텍스트 링크는 제외.
      const rect = a.getBoundingClientRect();
      if (rect.width < 90 || rect.height < 90) return;
      // 릴스 타일은 img 대신 video/canvas로 그려지는 경우가 있다.
      if (!a.querySelector('img, video, canvas')) return;
      // 게시물 모달 안의 링크는 제외 (헤더 버튼이 이미 담당)
      if (a.closest('div[role="dialog"] article')) return;

      found++;

      // 인스타는 스크롤 시 타일 DOM을 재활용한다.
      // shortcode를 키로 두어 다른 게시물로 바뀌면 오버레이를 새로 만든다.
      if (a.dataset.iglsTile === shortcode) return;
      a.querySelector(':scope > .igls-tile')?.remove();
      a.querySelector(':scope > .igls-followers')?.remove();
      a.dataset.iglsTile = shortcode;

      if (getComputedStyle(a).position === 'static') a.style.position = 'relative';

      const overlay = document.createElement('div');
      overlay.className = 'igls-tile';

      const info = document.createElement('div');
      info.className = 'igls-tile__info';
      info.textContent = knownOwner ? `@${knownOwner}` : '작성자 확인 중…';
      if (knownOwner) info.classList.add('igls-tile__info--ready');

      const btn = makeButton({
        username: '',
        source: gridSourceLabel(),
        variant: 'mini',
        idleLabel: '저장'
      });
      btn.classList.add('igls-btn--tile');
      if (knownOwner) {
        btn.dataset.iglsUser = knownOwner;
        btn.title = `@${knownOwner} 를 구글시트에 저장`;
        setBtnState(btn, stateFor(knownOwner));
      }

      // 팔로워 배지 — 좌상단. 인스타는 우상단(릴스·캐러셀 표시)을 쓰고
      // 우리 저장 버튼은 하단을 쓰므로 좌상단만 비어 있다.
      const badge = document.createElement('div');
      badge.className = 'igls-followers';
      badge.innerHTML =
        `${FOLLOWER_ICON}<span class="igls-followers__n"></span>` +
        `<span class="igls-followers__star">${STAR_ICON}</span>`;

      overlay.append(info, btn);
      a.append(badge, overlay);

      // 작성자 확정 — URL에 있으면 요청 없이 즉시, 없으면 shortcode로 조회.
      let owner = knownOwner;
      let hoverTimer;

      // 미디어 조회 응답에 팔로워 수가 함께 오는 경우가 있다. 그걸 재사용하면
      // 프로필 조회를 한 번 더 하지 않아도 되어 요청이 절반으로 준다.
      let ownerFollowers = profileClient.owner(shortcode)?.followers ?? null;

      const ensureOwner = async (force) => {
        const observed = profileClient.owner(shortcode);
        if (!owner && observed) { owner = observed.username; ownerFollowers = observed.followers ?? null; }
        if (owner) { btn.dataset.iglsUser = owner; setBtnState(btn, stateFor(owner)); return owner; }
        if (info.dataset.busy === '1') {
          // Share the active owner request instead of turning a concurrent save into "open instead".
          try { return (await resolveOwner(shortcode)).username; } catch (_) { return null; }
        }
        info.dataset.busy = '1';
        try {
          const r = await resolveOwner(shortcode, { force });
          owner = r.username;
          if (typeof r.followers === 'number') ownerFollowers = r.followers;
          btn.dataset.iglsUser = owner;
          btn.title = `@${owner} 를 구글시트에 저장`;
          info.textContent = `@${owner}`;
          info.classList.remove('igls-tile__info--err');
          info.classList.add('igls-tile__info--ready');
          setBtnState(btn, stateFor(owner));
        } catch (e) {
          // 조회 제한이면 "실패"가 아니라 "잠시 후"라고 알려줘야 오해가 없다
          const limited = e.message === 'cooldown' || e.kind === 'limit' || inCooldown();
          if (authProblem) {
            info.textContent = '인스타 로그인 확인 필요';
          } else if (limited) {
            info.textContent = `잠시 후 재시도 · ${cooldownLeftSec()}초`;
            stalledTiles.add(a);   // 풀리면 다시 조회한다
          } else {
            info.textContent = '작성자 조회 실패';
          }
          info.classList.add('igls-tile__info--err');
        } finally {
          info.dataset.busy = '0';
        }
        return owner;
      };

      const paintBadge = (n) => {
        if (n == null) return;
        badge.className = 'igls-followers';
        badge.querySelector('.igls-followers__n').textContent = (profileClient.peek(owner)?.followersApprox ? '≈' : '') + compact(n);
        badge.classList.add('igls-followers--on', `igls-followers--t${followerTier(n)}`);
        badge.title = `팔로워 ${profileClient.peek(owner)?.followersApprox ? '약 ' : ''}${n.toLocaleString('ko-KR')}명`;
      };

      // History paints synchronously from local data even while another tile awaits followers.
      a._iglsPaint = () => {
        if (a.dataset.iglsTile !== shortcode) return;
        const observed = profileClient.owner(shortcode);
        if (!owner && observed) owner = observed.username;
        if (!owner) return;
        const hit = profileClient.peek(owner);
        btn.dataset.iglsUser = owner;
        if (btn.dataset.state !== 'loading') setBtnState(btn, stateFor(owner));
        info.textContent = `@${owner}` + (typeof hit?.followers === 'number' ? ` · 팔로워 ${hit.followersApprox ? '약 ' : ''}${compact(hit.followers)}` : '');
        info.classList.add('igls-tile__info--ready');
        if (typeof hit?.followers === 'number') paintBadge(hit.followers);
      };
      a._iglsPaint();

      // 팔로워 수를 배지에 채우고, 호버 시 보이는 줄에는 계정명까지 붙인다.
      const showBrief = async () => {
        const u = await ensureOwner();
        if (!u || info.dataset.brief === '1') return;

        // 작성자 조회에서 이미 팔로워 수를 받았으면 프로필 조회를 생략한다
        if (ownerFollowers != null) {
          info.dataset.brief = '1';
          info.textContent = `@${u} · 팔로워 ${compact(ownerFollowers)}`;
          paintBadge(ownerFollowers);
          return;
        }
        // Cached/visible page data can still paint while network reads are paused.
        if (inCooldown()) { stalledTiles.add(a); return; }

        info.dataset.brief = '1';
        try {
          const b = await getBrief(u, shortcode);
          const v = b.isVerified ? ' ✔' : '';
          const f = b.followers == null ? '' : ` · 팔로워 ${compact(b.followers)}`;
          info.textContent = `@${u}${v}${f}`;
          paintBadge(b.followers);
        } catch (_) {
          info.dataset.brief = '0'; // 실패하면 다음 기회에 재시도
          if (inCooldown()) stalledTiles.add(a);
        }
      };

      if (settings.gridAutoResolve) {
        // 화면에 들어오면 자동으로 (큐를 거쳐) 조회
        // 쿨다운으로 버려질 때 어떤 타일이었는지 되찾을 수 있도록 참조를 붙인다
        showBrief.__tile = a;
        a._iglsBrief = () => { a._iglsPaint(); if (typeof profileClient.peek(owner)?.followers !== 'number') enqueueBrief(showBrief); };
        tileObserver.observe(a);
      } else {
        // 자동 표시를 끈 사용자는 기존처럼 호버할 때만
        a.addEventListener('mouseenter', () => { hoverTimer = setTimeout(showBrief, 450); });
        a.addEventListener('mouseleave', () => clearTimeout(hoverTimer));
      }

      // 인스타 미디어 API는 일부 게시물에 대해 계속 5xx를 준다.
      // 그런 게시물은 재시도해도 소용없으므로, 버튼을 '열어서 저장'으로 바꿔
      // 게시물 모달로 보낸다. 모달 헤더에는 작성자가 항상 있으니 거기서 저장된다.
      let openInstead = false;

      btn.addEventListener('click', async (ev) => {
        if (openInstead) return;   // preventDefault 하지 않는다 → 타일 링크가 그대로 열린다

        ev.preventDefault();
        ev.stopPropagation();
        setBtnState(btn, 'loading');

        const u = await ensureOwner(true);
        if (u) { saveUsername(u, gridSourceLabel(), btn, { shortcode }); return; }

        if (inCooldown()) {
          setBtnState(btn, 'idle');
          toast(`조회가 몰려 ${cooldownLeftSec()}초만 쉬는 중입니다. 잠시 후 다시 눌러주세요.`, 'err');
          return;
        }

        // 이 게시물은 API로 작성자를 알 수 없다. 막다른 길 대신 다음 클릭에 열어준다.
        openInstead = true;
        btn.dataset.idleLabel = '열어서 저장';
        setBtnState(btn, 'idle');
        btn.title = '이 게시물은 목록에서 작성자를 읽을 수 없습니다. 눌러서 게시물을 연 뒤 저장하세요.';
        toast('작성자를 읽을 수 없는 게시물입니다. 한 번 더 누르면 게시물이 열립니다.', 'info');
      }, true);
    });

    // 진단용: 타일이 0개면 감지 조건이 현재 레이아웃과 안 맞는다는 신호
    if (found !== lastTileCount) {
      lastTileCount = found;
      console.log(`[IG Lead Saver] 그리드 썸네일 ${found}개 감지 (${gridSourceLabel()})`);
    }
  }

  let lastTileCount = -1;

  function gridSourceLabel() {
    const parts = location.pathname.split('/').filter(Boolean);
    const tab = (parts[1] || '').toLowerCase();
    if (tab === 'tagged') return `태그됨 (@${parts[0]})`;
    if (tab === 'reels') return `릴스 탭 (@${parts[0]})`;
    if (location.pathname.startsWith('/explore')) return '탐색';
    if (/^\/reels?\//.test(location.pathname)) return '릴스 피드';
    if (usernameFromPath(location.pathname)) return `프로필 그리드 (@${parts[0]})`;
    return '그리드';
  }

  /** 12300 → 1.2만 */
  function compact(n) {
    if (typeof n !== 'number') return '';
    if (n >= 100000000) return `${(n / 100000000).toFixed(1).replace(/\.0$/, '')}억`;
    if (n >= 10000) return `${(n / 10000).toFixed(1).replace(/\.0$/, '')}만`;
    if (n >= 1000) return `${(n / 1000).toFixed(1).replace(/\.0$/, '')}천`;
    return n.toLocaleString('ko-KR');
  }

  // ── 주입 지점 4: 다이얼로그 내 사용자 목록 (팔로워/팔로잉/추천) ───────────
  function injectDialogRowButtons() {
    const dialogs = document.querySelectorAll('div[role="dialog"]');
    dialogs.forEach((dialog) => {
      // 게시물 모달은 위 article 처리로 커버되므로 제외
      if (dialog.querySelector('article')) return;

      dialog.querySelectorAll('a[href^="/"]').forEach((a) => {
        const username = usernameFromPath(new URL(a.href, location.origin).pathname);
        if (!username) return;

        // 사용자 행의 최상위 컨테이너를 찾는다 (링크의 몇 단계 상위)
        let row = a;
        for (let i = 0; i < 6 && row.parentElement; i++) {
          row = row.parentElement;
          if (row.getBoundingClientRect().height >= 44) break;
        }
        if (!row || row.dataset.iglsRow === '1') return;
        if (row.querySelector('.igls-btn')) return;

        const btn = makeButton({
          username,
          source: '목록/다이얼로그',
          variant: 'mini',
          idleLabel: '저장'
        });
        btn.classList.add('igls-btn--row');
        row.style.position = row.style.position || 'relative';
        row.appendChild(btn);
        row.dataset.iglsRow = '1';
      });
    });
  }

  // ── 스캔 루프 ─────────────────────────────────────────────────────────────
  let visibleSignature = '';
  const scan = debounce(async () => {
    try {
      const u = usernameFromPath(location.pathname);
      const visible = u && readVisibleProfile(u);
      const sig = location.pathname + JSON.stringify(visible);
      if (sig !== visibleSignature) { visibleSignature = sig; if (visible) profileClient.record(visible, 'visible-page'); }
      ensureProfilePanel();
      if (settings.enableFeedButtons) injectArticleButtons();
      if (settings.enableGridButtons) injectGridButtons();
      if (settings.enableListButtons) injectDialogRowButtons();
    } catch (e) {
      console.warn('[IG Lead Saver] scan error', e);
    }
  }, 200);

  // ── 설정 & 초기화 ─────────────────────────────────────────────────────────
  let settings = {
    enableListButtons: true,
    enableFeedButtons: true,
    enableGridButtons: true,
    gridAutoResolve: true
  };
  // 문자열 설정은 별도로 둔다 (settings 는 boolean 전용 로직을 탄다)
  let config = { savedBy: '', sheetName: '인플루언서' };

  async function loadState() {
    const st = await chrome.storage.local.get(['savedUsernames', 'knownUsernames', 'savedScopeV15', 'knownScopeV15']);
    savedSet = new Set((st.savedUsernames || []).map((s) => s.toLowerCase()));
    knownSet = new Set((st.knownUsernames || []).map((s) => s.toLowerCase()));

    const cfg = await chrome.storage.sync.get([...Object.keys(settings), 'savedBy', 'sheetName', 'webAppUrl']);
    Object.keys(settings).forEach((k) => {
      if (cfg[k] !== undefined) settings[k] = cfg[k] !== false;
    });
    config.savedBy = cfg.savedBy || '';
    config.sheetName = cfg.sheetName || '인플루언서';
    if (st.savedScopeV15 !== (cfg.webAppUrl || '') + '|' + config.sheetName) savedSet.clear();
    if (st.knownScopeV15 !== (cfg.webAppUrl || '')) knownSet.clear();

    await Promise.all([loadOwnerCache(), loadBriefCache(), loadPanelState(), profileClient.load()]);
    const net = profileClient.netState(); cooldownUntil = net.until; lastLimitStatus = net.status; authProblem = net.status === 401 && net.until > Date.now();
    passiveReady = true; passivePackets.splice(0).forEach(p => profileClient.accept(p));
    window.postMessage({ source: 'igls-request-passive-v15' }, location.origin);

    // 이력 목록이 오래됐으면 조용히 새로 받아온다.
    // 수동 버튼에만 의존하면 팀원 A가 저장한 계정을 B가 모른 채 또 저장한다.
    chrome.runtime.sendMessage({ type: 'REFRESH_KNOWN' }).then(r => { if (!r?.ok) console.warn('[IG Lead Saver] 이력 동기화 실패:', r?.error); }).catch(() => {});
  }

  chrome.storage.onChanged.addListener((changes, area) => {
    if (area === 'local') {
      if (changes.savedUsernames) {
        savedSet = new Set((changes.savedUsernames.newValue || []).map((s) => s.toLowerCase()));
      }
      if (changes.knownUsernames) {
        knownSet = new Set((changes.knownUsernames.newValue || []).map((s) => s.toLowerCase()));
      }
      if (changes.savedUsernames || changes.knownUsernames) { refreshAllButtons(); paintKnownTiles(); }
    }
    if (area === 'sync') {
      Object.keys(settings).forEach((k) => {
        if (changes[k]) settings[k] = changes[k].newValue !== false;
      });
      if (changes.savedBy) config.savedBy = changes.savedBy.newValue || '';
      if (changes.sheetName) { config.sheetName = changes.sheetName.newValue || '인플루언서'; savedSet.clear(); refreshAllButtons(); paintKnownTiles(); }
      if (changes.webAppUrl) { savedSet.clear(); knownSet.clear(); refreshAllButtons(); paintKnownTiles(); }
      if (changes.savedBy || changes.sheetName) renderDockMeta();
      scan();
    }
  });

  // 팝업/단축키에서 오는 요청 처리
  chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
    if (msg?.type === 'SAVE_CURRENT') {
      const u = currentTargetUsername();
      if (!u) {
        toast('저장할 계정을 찾지 못했습니다', 'err');
        sendResponse({ ok: false, error: '현재 화면에서 계정을 찾지 못했습니다.' });
        return true;
      }
      const btn = panel?.querySelector('.igls-btn--primary');
      saveUsername(u, msg.source || '단축키', btn).then(sendResponse);
      return true;
    }
    if (msg?.type === 'SAVE_LINK') {
      let u = null;
      try { u = usernameFromPath(new URL(msg.url).pathname); } catch (_) { /* noop */ }
      if (!u) {
        toast('프로필 링크가 아닙니다', 'err');
        sendResponse({ ok: false, error: '프로필 링크가 아닙니다.' });
        return true;
      }
      saveUsername(u, msg.source || '우클릭(링크)').then(sendResponse);
      return true;
    }
    if (msg?.type === 'GET_DIAGNOSTICS') { sendResponse({ version: '1.5.0', ...profileClient.metrics, savedCount: savedSet.size, knownCount: knownSet.size, cooldownUntil, lastLimitStatus }); return true; }
    if (msg?.type === 'GET_CURRENT_PROFILE') {
      sendResponse({ username: currentTargetUsername(), campaign: config.sheetName, savedBy: config.savedBy });
      return true;
    }
    return false;
  });

  (async function init() {
    await loadState();
    scan();

    const mo = new MutationObserver(scan);
    mo.observe(document.body, { childList: true, subtree: true });

    // SPA 라우팅 감지 (history API 후킹 없이 pathname 폴링)
    let lastPath = location.pathname;
    setInterval(() => {
      if (location.pathname !== lastPath) {
        lastPath = location.pathname;
        scan();
      }
    }, 500);

    console.log('[IG Lead Saver] 활성화됨');
  })();
})();
