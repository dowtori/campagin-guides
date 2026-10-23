/**
 * IG Lead Saver — Google Apps Script 백엔드  (v1.5)
 *
 * 설치 방법
 *  1) 저장할 구글시트를 연다
 *  2) 확장 프로그램 > Apps Script
 *  3) 이 파일 내용을 통째로 붙여넣고 저장
 *  4) 배포 > 새 배포 > 유형: 웹 앱
 *       - 실행 계정: 나
 *       - 액세스 권한: 모든 사용자   ← 반드시 이렇게
 *  5) 발급된 /exec URL을 확장 프로그램 옵션에 붙여넣기
 *
 * 이미 배포한 스크립트를 고쳤을 때는 "새 배포"가 아니라
 * 배포 관리 > 편집(연필) > 버전: 새 버전 으로 올려야 URL이 유지된다.
 *
 * ── v1.2 변경점 ──────────────────────────────────────────────────────────
 *  · '저장자' 열 추가 (누가 넣었는지 → 업무 배분용)
 *  · 캠페인마다 탭을 나눠 쓰는 구조를 지원 (listSheets / createSheet)
 *  · _이력색인 탭을 자동 유지 → 과거 캠페인까지 아우르는 중복 판정
 *  · 기존 탭은 헤더를 읽어 맞춰 쓰므로, 예전에 만든 탭도 그대로 동작한다
 */

var INDEX_SHEET = '_이력색인';
var STATUS_OPTIONS = ['연락전', 'DM 발송', '회신 옴', '협업 진행', '보류', '부적합'];

// 캠페인 탭의 열 정의. 순서를 바꾸면 새로 만드는 탭의 헤더도 같이 바뀐다.
var COLUMNS = [
  { key: 'savedAtLocal', header: '저장일시',   width: 130 },
  { key: 'savedBy',      header: '저장자',     width: 90 },
  { key: 'username',     header: '사용자명',   width: 150 },
  { key: 'fullName',     header: '프로필명',   width: 150 },
  { key: 'profileUrl',   header: '프로필 링크', width: 250 },
  { key: 'followers',    header: '팔로워',     width: 90 },
  { key: 'following',    header: '팔로잉',     width: 90 },
  { key: 'posts',        header: '게시물',     width: 80 },
  { key: 'category',     header: '카테고리',   width: 120 },
  { key: 'email',        header: '이메일',     width: 180 },
  { key: 'phone',        header: '연락처',     width: 120 },
  { key: 'externalUrl',  header: '외부 링크',  width: 190 },
  { key: 'biography',    header: '소개',       width: 300 },
  { key: 'flags',        header: '속성',       width: 110 },
  { key: 'source',       header: '유입경로',   width: 130 },
  { key: 'status',       header: '상태',       width: 90 },
  { key: 'tag',          header: '비고',       width: 140 },
  { key: 'memo',         header: '정산여부',   width: 110 },
  { key: 'profilePic',   header: '프로필 사진', width: 180 }
];

// 색인 탭은 가볍게 유지한다. 조회는 첫 열만 읽으면 되므로 빠르다.
var INDEX_COLUMNS = [
  { key: 'username',  header: '사용자명',   width: 160 },
  { key: 'firstAt',   header: '최초 저장일', width: 130 },
  { key: 'savedBy',   header: '저장자',     width: 90 },
  { key: 'campaign',  header: '캠페인',     width: 200 },
  { key: 'origin',    header: '출처',       width: 110 }
];

// ── 라우팅 ────────────────────────────────────────────────────────────────

function doPost(e) {
  var body;
  try { body = JSON.parse(e.postData.contents); } catch (err) { return json({ ok: false, error: 'JSON 형식 오류' }); }
  var sheetName = body.sheetName || '인플루언서';
  // Reads no longer wait behind a 25-second write lock or mutate sheet headers.
  try {
    if (body.action === 'list') return json(handleReadList(sheetName));
    if (body.action === 'ping') return json(handleReadPing(sheetName));
    if (body.action === 'listSheets') return json(handleReadSheets());
  } catch (err) { return json({ ok: false, error: String(err) }); }
  var lock = LockService.getScriptLock();
  try { lock.waitLock(25000); } catch (err) { return json({ ok: false, error: '다른 저장 요청 처리 중입니다. 잠시 후 다시 시도해주세요.' }); }
  try {
    switch (body.action) {
      case 'append': return json(handleAppend(sheetName, body.lead || {}));
      case 'createSheet': return json(handleCreateSheet(body.newSheetName));
      case 'importHistory': return json(handleImportHistory(body.rows || [], body.origin));
      default: return json({ ok: false, error: '알 수 없는 action: ' + body.action });
    }
  } catch (err) { return json({ ok: false, error: String(err) }); }
  finally { try { SpreadsheetApp.flush(); } finally { lock.releaseLock(); } }
}

function handleReadList(sheetName) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName(sheetName), index = ss.getSheetByName(INDEX_SHEET);
  var current = sheet ? readUsernameColumn(sheet) : [];
  var known = [];
  if (index && index.getLastRow() > 1) {
    known = index.getRange(2, 1, index.getLastRow() - 1, 1).getValues()
      .map(function (r) { return String(r[0] || '').replace(/^@/, '').trim(); }).filter(String);
  }
  return { ok: true, version: '1.5', current: current, known: known, usernames: current };
}
function handleReadPing(sheetName) {
  var ss = SpreadsheetApp.getActiveSpreadsheet(), sheet = ss.getSheetByName(sheetName), index = ss.getSheetByName(INDEX_SHEET);
  return { ok: true, version: '1.5', spreadsheetName: ss.getName(), sheetName: sheetName,
    rowCount: sheet ? Math.max(0, sheet.getLastRow() - 1) : 0, indexCount: index ? Math.max(0, index.getLastRow() - 1) : 0 };
}
function handleReadSheets() {
  var ss = SpreadsheetApp.getActiveSpreadsheet(), index = ss.getSheetByName(INDEX_SHEET);
  return { ok: true, sheets: ss.getSheets().filter(function (s) { return s.getName().charAt(0) !== '_'; })
    .map(function (s) { return { name: s.getName(), rowCount: Math.max(0, s.getLastRow() - 1) }; }),
    indexCount: index ? Math.max(0, index.getLastRow() - 1) : 0 };
}

function doGet() {
  return json({ ok: true, message: 'IG Lead Saver 웹앱이 동작 중입니다.', version: '1.5' });
}

// ── 핸들러 ────────────────────────────────────────────────────────────────

function handlePing(sheetName) {
  var sheet = getOrCreateSheet(sheetName);
  var index = getOrCreateIndex();
  return {
    ok: true,
    version: '1.5',
    spreadsheetName: SpreadsheetApp.getActiveSpreadsheet().getName(),
    sheetName: sheet.getName(),
    rowCount: Math.max(0, sheet.getLastRow() - 1),
    indexCount: Math.max(0, index.getLastRow() - 1)
  };
}

function handleAppend(sheetName, lead) {
  if (!lead.username) return { ok: false, error: '사용자명이 없습니다.' };

  var sheet = getOrCreateSheet(sheetName);
  var uname = String(lead.username).replace(/^@/, '').trim();

  // 1) 이 캠페인 탭에 이미 있나?
  var existingRow = findUsernameRow(sheet, uname);
  if (existingRow > 0) {
    return { ok: true, status: 'duplicate', row: existingRow, sheetName: sheetName };
  }

  // 2) 과거 이력이 있나? (다른 캠페인이거나 예전 캠페인)
  var prior = lookupIndex(uname);

  var flags = [];
  if (lead.isVerified) flags.push('인증');
  if (lead.isPrivate) flags.push('비공개');
  if (lead.isBusiness) flags.push('비즈니스');

  var record = {
    savedAtLocal: nowStr(),
    savedBy: lead.savedBy || '',
    username: '@' + uname,
    fullName: lead.fullName || '',
    profileUrl: lead.profileUrl || ('https://www.instagram.com/' + uname + '/'),
    followers: numOrBlank(lead.followers),
    following: numOrBlank(lead.following),
    posts: numOrBlank(lead.posts),
    category: lead.category || '',
    email: lead.email || '',
    phone: lead.phone || '',
    externalUrl: lead.externalUrl || '',
    biography: lead.biography || '',
    flags: flags.join(', '),
    source: lead.source || '',
    status: lead.status || '연락전',
    // 과거 접촉 이력이 있으면 비고에 남긴다.
    // 화면 경고는 놓칠 수 있으므로 시트에도 흔적이 있어야 나중에 걸러낼 수 있다.
    tag: [lead.tag || '', prior ? '[기존접촉: ' + (prior.campaign || '이전 캠페인') + ']' : '']
      .filter(String).join(' '),
    memo: '',
    profilePic: lead.profilePic || ''
  };

  // 기존 탭은 자기 헤더 순서에 맞춰 쓴다 (예전에 만든 탭도 깨지지 않게)
  var header = readHeader(sheet);
  var row = header.map(function (h) {
    var col = findColumnByHeader(h);
    return col ? valueOrBlank(record[col.key]) : '';
  });
  sheet.appendRow(row);

  var newRow = sheet.getLastRow();
  formatRow(sheet, newRow, header);

  // 3) 색인에 등록 (이미 있으면 건드리지 않는다 — '최초' 기록을 보존)
  if (!prior) {
    appendIndex({
      username: uname,
      firstAt: nowStr(),
      savedBy: record.savedBy,
      campaign: sheetName,
      origin: '확장'
    });
  }

  return {
    ok: true,
    status: 'added',
    row: newRow,
    sheetName: sheetName,
    prior: prior || null   // 과거 이력이 있으면 캠페인·날짜를 돌려준다
  };
}

function handleList(sheetName) {
  var sheet = getOrCreateSheet(sheetName);
  var current = readUsernameColumn(sheet);
  return {
    ok: true,
    current: current,             // 이 캠페인 탭에 저장된 계정
    known: readIndexUsernames(),  // 과거 포함 전체 이력
    // v1.1.0 이하 확장은 usernames 를 읽는다. 스토어 승인 전까지 팀원이
    // 구버전을 쓰더라도 중복 표시가 멈추지 않도록 같이 내려준다.
    usernames: current
  };
}

function handleListSheets() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var out = [];
  ss.getSheets().forEach(function (s) {
    var name = s.getName();
    if (name === INDEX_SHEET) return;
    if (name.charAt(0) === '_') return;   // _ 로 시작하는 탭은 시스템용으로 간주
    out.push({ name: name, rowCount: Math.max(0, s.getLastRow() - 1) });
  });
  return { ok: true, sheets: out, indexCount: Math.max(0, getOrCreateIndex().getLastRow() - 1) };
}

function handleCreateSheet(name) {
  name = String(name || '').trim();
  if (!name) return { ok: false, error: '탭 이름이 비어 있습니다.' };
  if (name.charAt(0) === '_') return { ok: false, error: '_ 로 시작하는 이름은 쓸 수 없습니다.' };

  var ss = SpreadsheetApp.getActiveSpreadsheet();
  if (ss.getSheetByName(name)) {
    return { ok: false, error: '"' + name + '" 탭이 이미 있습니다.', exists: true };
  }
  getOrCreateSheet(name);
  return { ok: true, created: name, sheets: handleListSheets().sheets };
}

/**
 * 과거 캠페인 계정을 색인에 일괄 등록한다.
 * rows: [{ username, campaign }]
 */
function handleImportHistory(rows, origin) {
  if (!rows.length) return { ok: false, error: '가져올 행이 없습니다.' };

  var index = getOrCreateIndex();
  var have = {};
  readIndexUsernames().forEach(function (u) { have[u.toLowerCase()] = true; });

  var stamp = nowStr();
  var batch = [];
  var skipped = 0;

  rows.forEach(function (r) {
    var u = String(r.username || '').replace(/^@/, '').trim();
    if (!u) return;
    if (have[u.toLowerCase()]) { skipped++; return; }
    have[u.toLowerCase()] = true;
    batch.push([u, stamp, '', String(r.campaign || ''), origin || '과거캠페인']);
  });

  if (batch.length) {
    index.getRange(index.getLastRow() + 1, 1, batch.length, INDEX_COLUMNS.length).setValues(batch);
  }
  return { ok: true, added: batch.length, skipped: skipped, total: Math.max(0, index.getLastRow() - 1) };
}

// ── 시트 헬퍼 ─────────────────────────────────────────────────────────────

function getOrCreateSheet(name) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName(name);

  if (sheet) {
    ensureSavedByColumn(sheet);
    return sheet;
  }

  sheet = ss.insertSheet(name);
  writeHeader(sheet, COLUMNS);

  // 상태 열 드롭다운
  var statusCol = headerIndex(sheet, '상태');
  if (statusCol > 0) {
    var rule = SpreadsheetApp.newDataValidation()
      .requireValueInList(STATUS_OPTIONS, true)
      .setAllowInvalid(true)
      .build();
    sheet.getRange(2, statusCol, sheet.getMaxRows() - 1, 1).setDataValidation(rule);
  }
  return sheet;
}

function getOrCreateIndex() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName(INDEX_SHEET);
  if (sheet) {
    ensureIndexHeader(sheet);
    return sheet;
  }

  sheet = ss.insertSheet(INDEX_SHEET);
  writeHeader(sheet, INDEX_COLUMNS);
  // 색인은 평소 볼 일이 없으니 맨 뒤로 보낸다
  ss.setActiveSheet(sheet);
  ss.moveActiveSheet(ss.getNumSheets());
  return sheet;
}

function writeHeader(sheet, cols) {
  var headers = cols.map(function (c) { return c.header; });
  sheet.getRange(1, 1, 1, headers.length)
    .setValues([headers])
    .setFontWeight('bold')
    .setBackground('#f1f3f4')
    .setVerticalAlignment('middle');
  sheet.setFrozenRows(1);
  sheet.setRowHeight(1, 32);
  cols.forEach(function (c, i) { sheet.setColumnWidth(i + 1, c.width); });
}

/**
 * 색인 탭을 사람이 먼저 만들어 데이터부터 붙여넣은 경우를 구제한다.
 * 색인은 2행부터 읽으므로, 헤더 없이 1행부터 데이터가 있으면 첫 줄이 통째로 무시된다.
 * 1행이 헤더가 아니면 위에 한 줄을 밀어 넣고 헤더를 쓴다.
 */
function ensureIndexHeader(sheet) {
  var first = String(sheet.getRange(1, 1).getValue() || '').trim();
  if (first === INDEX_COLUMNS[0].header) return;   // 이미 정상

  if (sheet.getLastRow() > 0) sheet.insertRowBefore(1);
  writeHeader(sheet, INDEX_COLUMNS);
}

/** 예전 버전으로 만든 탭에 '저장자' 열이 없으면 끝에 덧붙인다 */
function ensureSavedByColumn(sheet) {
  if (sheet.getLastRow() === 0) { writeHeader(sheet, COLUMNS); return; }
  if (headerIndex(sheet, '저장자') > 0) return;

  var col = sheet.getLastColumn() + 1;
  sheet.getRange(1, col)
    .setValue('저장자')
    .setFontWeight('bold')
    .setBackground('#f1f3f4');
  sheet.setColumnWidth(col, 90);
}

function readHeader(sheet) {
  var lastCol = sheet.getLastColumn();
  if (lastCol < 1) return [];
  return sheet.getRange(1, 1, 1, lastCol).getValues()[0].map(function (v) {
    return String(v || '').trim();
  });
}

function headerIndex(sheet, headerName) {
  var h = readHeader(sheet);
  for (var i = 0; i < h.length; i++) if (h[i] === headerName) return i + 1;
  return -1;
}

// 예전 헤더명 → 현재 key.
// 이미 만들어진 탭은 헤더가 옛 이름이라, 이게 없으면 해당 열에 값이 안 들어간다.
var HEADER_ALIASES = {
  '태그': 'tag',
  '메모': 'memo'
};

function findColumnByHeader(headerName) {
  for (var i = 0; i < COLUMNS.length; i++) {
    if (COLUMNS[i].header === headerName) return COLUMNS[i];
  }
  var aliasKey = HEADER_ALIASES[headerName];
  if (aliasKey) {
    for (var j = 0; j < COLUMNS.length; j++) {
      if (COLUMNS[j].key === aliasKey) return COLUMNS[j];
    }
  }
  return null;
}

function formatRow(sheet, row, header) {
  ['팔로워', '팔로잉', '게시물'].forEach(function (h) {
    var c = header.indexOf(h) + 1;
    if (c > 0) sheet.getRange(row, c).setNumberFormat('#,##0');
  });
  var bio = header.indexOf('소개') + 1;
  if (bio > 0) sheet.getRange(row, bio).setWrapStrategy(SpreadsheetApp.WrapStrategy.CLIP);
  sheet.setRowHeight(row, 24);
}

function readUsernameColumn(sheet) {
  var col = headerIndex(sheet, '사용자명');
  var last = sheet.getLastRow();
  if (col < 1 || last < 2) return [];
  return sheet.getRange(2, col, last - 1, 1).getValues()
    .map(function (r) { return String(r[0] || '').replace(/^@/, '').trim(); })
    .filter(function (v) { return v; });
}

function findUsernameRow(sheet, username) {
  var col = headerIndex(sheet, '사용자명');
  var last = sheet.getLastRow();
  if (col < 1 || last < 2) return -1;

  var target = String(username).toLowerCase();
  var values = sheet.getRange(2, col, last - 1, 1).getValues();
  for (var i = 0; i < values.length; i++) {
    var v = String(values[i][0] || '').replace(/^@/, '').trim().toLowerCase();
    if (v && v === target) return i + 2;
  }
  return -1;
}

// ── 색인 ──────────────────────────────────────────────────────────────────

function readIndexUsernames() {
  var index = getOrCreateIndex();
  var last = index.getLastRow();
  if (last < 2) return [];
  return index.getRange(2, 1, last - 1, 1).getValues()
    .map(function (r) { return String(r[0] || '').replace(/^@/, '').trim(); })
    .filter(function (v) { return v; });
}

/** 과거 이력 조회. 있으면 { campaign, firstAt, origin } 반환 */
function lookupIndex(username) {
  var index = getOrCreateIndex();
  var last = index.getLastRow();
  if (last < 2) return null;

  var target = String(username).toLowerCase();
  var values = index.getRange(2, 1, last - 1, INDEX_COLUMNS.length).getValues();
  for (var i = 0; i < values.length; i++) {
    var v = String(values[i][0] || '').replace(/^@/, '').trim().toLowerCase();
    if (v && v === target) {
      return { campaign: String(values[i][3] || ''), firstAt: String(values[i][1] || ''), origin: String(values[i][4] || '') };
    }
  }
  return null;
}

function appendIndex(rec) {
  var index = getOrCreateIndex();
  index.appendRow([rec.username, rec.firstAt, rec.savedBy, rec.campaign, rec.origin]);
}

// ── 잡동사니 ──────────────────────────────────────────────────────────────

function nowStr() {
  return Utilities.formatDate(new Date(), Session.getScriptTimeZone(), 'yyyy-MM-dd HH:mm');
}

function valueOrBlank(v) {
  return (v === undefined || v === null) ? '' : v;
}

function numOrBlank(v) {
  return (v === '' || v === null || v === undefined) ? '' : Number(v);
}

function json(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
