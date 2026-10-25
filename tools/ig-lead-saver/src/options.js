const DEFAULTS = {
  webAppUrl: '',
  sheetName: '인플루언서',
  savedBy: '',
  defaultStatus: '연락전',
  defaultTag: '',
  enableFeedButtons: true,
  enableListButtons: true,
  enableGridButtons: true,
  gridAutoResolve: true
};

const TOGGLES = ['enableFeedButtons', 'enableListButtons', 'enableGridButtons', 'gridAutoResolve'];

const $ = (id) => document.getElementById(id);

function setResult(el, msg, kind) {
  el.textContent = msg;
  el.className = `result result--${kind}`;
}

async function load() {
  const cfg = await chrome.storage.sync.get(DEFAULTS);
  $('webAppUrl').value = cfg.webAppUrl || '';
  $('savedBy').value = cfg.savedBy || '';
  $('defaultStatus').value = cfg.defaultStatus || DEFAULTS.defaultStatus;
  $('defaultTag').value = cfg.defaultTag || '';
  TOGGLES.forEach((k) => { $(k).checked = cfg[k] !== false; });
  syncSubToggle();
  // 저장된 탭 이름을 우선 넣어두고, 시트에서 목록을 받아오면 갱신한다
  setSheetOptions([cfg.sheetName || DEFAULTS.sheetName], cfg.sheetName || DEFAULTS.sheetName);
  renderRecent();
  if (cfg.webAppUrl) reloadSheets(true);
}

/** 셀렉트에 탭 목록을 채운다 */
function setSheetOptions(names, selected) {
  const sel = $('sheetName');
  sel.textContent = '';
  const list = names.length ? names : [DEFAULTS.sheetName];
  list.forEach((n) => {
    const o = document.createElement('option');
    o.value = typeof n === 'string' ? n : n.name;
    o.textContent = typeof n === 'string' ? n : `${n.name} (${n.rowCount}건)`;
    if (o.value === selected) o.selected = true;
    sel.appendChild(o);
  });
  // 저장된 탭이 시트에서 사라진 경우에도 선택지를 잃지 않도록
  if (selected && ![...sel.options].some((o) => o.value === selected)) {
    const o = document.createElement('option');
    o.value = selected;
    o.textContent = `${selected} (아직 없음 — 저장 시 생성)`;
    o.selected = true;
    sel.appendChild(o);
  }
}

/** 시트에서 탭 목록을 받아온다 */
async function reloadSheets(quiet) {
  const btn = $('reloadSheets');
  const current = $('sheetName').value;
  btn.disabled = true;
  if (!quiet) setResult($('testResult'), '탭 목록 불러오는 중…', 'ok');

  const res = await chrome.runtime.sendMessage({ type: 'LIST_SHEETS' });
  btn.disabled = false;

  if (!res?.ok) {
    if (!quiet) setResult($('testResult'), res?.error || '탭 목록을 불러오지 못했습니다', 'err');
    return;
  }
  setSheetOptions(res.sheets || [], current);
  if (!quiet) {
    setResult($('testResult'), `탭 ${(res.sheets || []).length}개 · 이력 색인 ${res.indexCount || 0}건`, 'ok');
  }
}

/** 새 캠페인 탭 생성 */
async function createSheet() {
  const name = $('newSheetName').value.trim();
  if (!name) { setResult($('testResult'), '새 캠페인 이름을 입력하세요', 'err'); return; }

  const btn = $('createSheet');
  btn.disabled = true;
  const res = await chrome.runtime.sendMessage({ type: 'CREATE_SHEET', name });
  btn.disabled = false;

  if (!res?.ok) { setResult($('testResult'), res?.error || '탭 생성 실패', 'err'); return; }
  $('newSheetName').value = '';
  setSheetOptions(res.sheets || [], res.created);
  setResult($('testResult'), `"${res.created}" 탭을 만들고 선택했습니다`, 'ok');
}

async function save() {
  const url = $('webAppUrl').value.trim();
  if (url && !/^https:\/\/script\.google\.com\/macros\/s\/[\w-]+\/exec/.test(url)) {
    setResult($('saveResult'), '웹앱 URL 형식이 올바르지 않습니다 (…/exec 로 끝나야 합니다)', 'err');
    return;
  }
  const payload = {
    webAppUrl: url,
    sheetName: $('sheetName').value.trim() || DEFAULTS.sheetName,
    savedBy: $('savedBy').value.trim(),
    defaultStatus: $('defaultStatus').value,
    defaultTag: $('defaultTag').value.trim()
  };
  TOGGLES.forEach((k) => { payload[k] = $(k).checked; });
  await chrome.storage.sync.set(payload);
  setResult($('saveResult'), '저장되었습니다', 'ok');
  setTimeout(() => setResult($('saveResult'), '', 'ok'), 2500);
}

async function test() {
  const btn = $('test');
  btn.disabled = true;
  setResult($('testResult'), '확인 중…', 'ok');
  await save();
  const res = await chrome.runtime.sendMessage({ type: 'PING_SHEET' });
  btn.disabled = false;
  if (res?.ok) {
    setResult(
      $('testResult'),
      `연결됨 · ${res.spreadsheetName} / ${res.sheetName} (${res.rowCount}행)`,
      'ok'
    );
  } else {
    setResult($('testResult'), res?.error || '연결 실패', 'err');
  }
}

async function sync() {
  const btn = $('sync');
  btn.disabled = true;
  setResult($('testResult'), '불러오는 중…', 'ok');
  const res = await chrome.runtime.sendMessage({ type: 'SYNC_SAVED' });
  btn.disabled = false;
  if (res?.ok) {
    const cur = (res.current || []).length;
    const known = (res.known || []).length;
    setResult(
      $('testResult'),
      `이 캠페인 ${cur}명 · 전체 이력 ${known}명 동기화 — 이력에 있는 계정은 '기존 접촉'으로 표시됩니다`,
      'ok'
    );
  } else {
    setResult($('testResult'), res?.error || '동기화 실패', 'err');
  }
}

async function renderRecent() {
  const { recent = [] } = await chrome.storage.local.get('recent');
  const box = $('recent');
  if (!recent.length) {
    box.innerHTML = '<p class="empty">아직 저장한 프로필이 없습니다.</p>';
    return;
  }
  box.innerHTML = '';
  recent.slice(0, 12).forEach((r) => {
    const row = document.createElement('div');
    row.className = 'rec';

    const a = document.createElement('a');
    a.href = r.profileUrl;
    a.target = '_blank';
    a.rel = 'noopener';
    a.textContent = `@${r.username}`;
    row.appendChild(a);

    if (r.fullName) {
      const n = document.createElement('span');
      n.className = 'dup';
      n.textContent = r.fullName;
      row.appendChild(n);
    }
    if (r.status === 'duplicate') {
      const d = document.createElement('span');
      d.className = 'dup';
      d.textContent = '· 중복';
      row.appendChild(d);
    }

    const meta = document.createElement('span');
    meta.className = 'meta';
    const f = typeof r.followers === 'number' ? `팔로워 ${r.followers.toLocaleString('ko-KR')} · ` : '';
    meta.textContent = f + new Date(r.at).toLocaleString('ko-KR', { month: 'numeric', day: 'numeric', hour: '2-digit', minute: '2-digit' });
    row.appendChild(meta);

    box.appendChild(row);
  });
}

/** 그리드 버튼을 끄면 하위 옵션(미리 표시)도 의미가 없으므로 함께 비활성화 */
function syncSubToggle() {
  const on = $('enableGridButtons').checked;
  $('gridAutoResolve').disabled = !on;
  $('gridAutoResolve').closest('.check').style.opacity = on ? '1' : '.45';
}

$('enableGridButtons').addEventListener('change', syncSubToggle);
$('reloadSheets').addEventListener('click', () => reloadSheets(false));
$('createSheet').addEventListener('click', createSheet);
$('newSheetName').addEventListener('keydown', (e) => { if (e.key === 'Enter') createSheet(); });
$('save').addEventListener('click', save);
$('test').addEventListener('click', test);
$('sync').addEventListener('click', sync);
load();
