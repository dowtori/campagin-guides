const $ = (id) => document.getElementById(id);
let activeTabId = null;

async function init() {
  const { webAppUrl } = await chrome.storage.sync.get('webAppUrl');
  renderRecent();

  if (!webAppUrl) {
    $('status').textContent = '구글시트가 아직 연결되지 않았습니다. 설정에서 웹앱 URL을 등록하세요.';
    $('status').className = 'pstatus pstatus--err';
    return;
  }

  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  activeTabId = tab?.id ?? null;

  if (!tab || !/^https:\/\/www\.instagram\.com\//.test(tab.url || '')) {
    $('status').textContent = '인스타그램 탭에서 열어주세요.';
    return;
  }

  let res;
  try {
    res = await chrome.tabs.sendMessage(tab.id, { type: 'GET_CURRENT_PROFILE' });
  } catch (_) {
    $('status').textContent = '페이지를 새로고침한 뒤 다시 시도해주세요.';
    return;
  }

  if (res && res.version !== chrome.runtime.getManifest().version) {
    $('status').textContent = '업데이트를 적용하려면 인스타그램 탭을 새로고침해주세요.';
    return;
  }

  if (res?.username) {
    $('status').textContent = '저장 준비 완료';
    $('who').textContent = `@${res.username}`;
    $('target').hidden = false;
    $('saveBtn').disabled = false;
  } else {
    $('status').textContent = '현재 화면에서 프로필을 찾지 못했습니다. 프로필 페이지나 게시물에서 열어주세요.';
  }
}

$('saveBtn').addEventListener('click', async () => {
  if (!activeTabId) return;
  $('saveBtn').disabled = true;
  $('saveBtn').textContent = '저장 중…';
  try {
    const res = await chrome.tabs.sendMessage(activeTabId, { type: 'SAVE_CURRENT', source: '확장 팝업' });
    if (res?.ok) {
      $('saveBtn').textContent = res.status === 'duplicate' ? '이미 있음 ✓' : '저장 완료 ✓';
      setTimeout(renderRecent, 300);
    } else {
      $('saveBtn').textContent = '저장 실패';
      $('saveBtn').disabled = false;
      $('status').textContent = res?.error || '알 수 없는 오류';
      $('status').className = 'pstatus pstatus--err';
    }
  } catch (e) {
    $('saveBtn').textContent = '실패';
    $('status').textContent = e.message;
    $('status').className = 'pstatus pstatus--err';
  }
});

$('openOptions').addEventListener('click', () => chrome.runtime.openOptionsPage());

async function renderRecent() {
  const { recent = [] } = await chrome.storage.local.get('recent');
  const box = $('recent');
  if (!recent.length) return;
  box.innerHTML = '';
  recent.slice(0, 5).forEach((r) => {
    const row = document.createElement('div');
    row.className = 'rec';
    const a = document.createElement('a');
    a.href = r.profileUrl;
    a.target = '_blank';
    a.rel = 'noopener';
    a.textContent = `@${r.username}`;
    const meta = document.createElement('span');
    meta.className = 'meta';
    meta.textContent = typeof r.followers === 'number' ? r.followers.toLocaleString('ko-KR') : '';
    row.append(a, meta);
    box.appendChild(row);
  });
}

init();
