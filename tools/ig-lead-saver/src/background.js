/* Apps Script transport and endpoint/campaign-scoped local history. */
const DEFAULTS={webAppUrl:'',sheetName:'인플루언서',savedBy:'',defaultStatus:'연락전',defaultTag:'',enableFeedButtons:true,enableListButtons:true,enableGridButtons:true,gridAutoResolve:true};
const KNOWN_TTL_MS=15*60e3;
const normal=u=>String(u||'').replace(/^@/,'').trim().toLowerCase();
const unique=a=>[...new Set((a||[]).map(normal).filter(Boolean))];
const scope=s=>s.webAppUrl+'|'+s.sheetName;
async function getSettings(){return {...DEFAULTS,...await chrome.storage.sync.get(DEFAULTS)};}
async function callSheet(action,body,cfg){
 const s=cfg||await getSettings();if(!s.webAppUrl)return{ok:false,error:'설정에서 구글시트 웹앱 URL을 등록해주세요.'};
 if(!/^https:\/\/script\.google\.com\/macros\/s\/[\w-]+\/exec$/.test(s.webAppUrl))return{ok:false,error:'웹앱 URL 형식을 확인해주세요.'};
 const ctl=new AbortController(),timer=setTimeout(()=>ctl.abort(),25000);
 try{
  const r=await fetch(s.webAppUrl,{method:'POST',headers:{'Content-Type':'text/plain;charset=utf-8'},body:JSON.stringify({action,...body}),redirect:'follow',signal:ctl.signal});
  const t=await r.text();if(!r.ok)return{ok:false,error:`시트 응답 오류 ${r.status}`};
  try{return JSON.parse(t);}catch{return{ok:false,error:/<html|accounts\.google\.com/i.test(t)?'웹앱이 로그인 화면을 반환했습니다. 기존 웹앱 배포 권한을 확인해주세요.':'시트 응답을 읽지 못했습니다.'};}
 }catch(e){return{ok:false,error:e.name==='AbortError'?'시트 응답이 지연되고 있습니다. 시트에서 저장 여부를 확인한 후 다시 시도해주세요.':`시트 네트워크 오류: ${e.message}`};}
 finally{clearTimeout(timer);}
}
let localChain=Promise.resolve();
function serialLocal(fn){const p=localChain.catch(()=>{}).then(fn);localChain=p;return p;}
function historyFor(h,s){return h?.endpoint===s.webAppUrl?h:{endpoint:s.webAppUrl,known:[],knownAt:0,campaigns:{},recentWrites:[]};}
async function mirror(h,s){
 const latest=await getSettings();if(scope(latest)!==scope(s))return;
 const c=h.campaigns[s.sheetName];
 await chrome.storage.local.set({savedUsernames:c?.names||[],knownUsernames:h.known||[],savedScopeV15:scope(s),knownScopeV15:s.webAppUrl,
  knownSyncedAt:h.knownAt||0,historyStatusV15:{at:h.knownAt||0,ready:!!c?.at}});
}
async function selectCached(s){return serialLocal(async()=>{const st=await chrome.storage.local.get('iglsHistoryV15');const h=historyFor(st.iglsHistoryV15,s);await mirror(h,s);return h;});}
const refreshing=new Map();
async function refreshKnownIfStale(force){
 const s=await getSettings();if(!s.webAppUrl)return{ok:false,error:'연결 주소가 없습니다.'};
 const h=await selectCached(s),c=h.campaigns[s.sheetName];
 if(!force&&c&&Date.now()-c.at<KNOWN_TTL_MS&&Date.now()-h.knownAt<KNOWN_TTL_MS)return{ok:true,skipped:true,current:c.names,known:h.known};
 const k=scope(s);if(refreshing.has(k))return refreshing.get(k);
 const started=Date.now();
 const task=(async()=>{
  const r=await callSheet('list',{sheetName:s.sheetName},s);
  if(!r.ok||!Array.isArray(r.current)||!Array.isArray(r.known))return r.ok?{ok:false,error:'이력 응답 형식이 올바르지 않습니다. 기존 캐시를 유지합니다.'}:r;
  await serialLocal(async()=>{
   const latest=await getSettings();if(latest.webAppUrl!==s.webAppUrl)return;
   const st=await chrome.storage.local.get('iglsHistoryV15');const next=historyFor(st.iglsHistoryV15,s);
   const recent=(next.recentWrites||[]).filter(w=>w.at>=started);
   next.known=unique([...r.known,...recent.map(w=>w.username)]);next.knownAt=Date.now();
   next.campaigns[s.sheetName]={names:unique([...r.current,...recent.filter(w=>w.sheet===s.sheetName).map(w=>w.username)]),at:Date.now()};
   const campaigns=Object.entries(next.campaigns).sort((a,b)=>b[1].at-a[1].at).slice(0,12);next.campaigns=Object.fromEntries(campaigns);
   await chrome.storage.local.set({iglsHistoryV15:next});await mirror(next,s);
  });return r;
 })();refreshing.set(k,task);task.finally(()=>refreshing.delete(k)).catch(()=>{});return task;
}
async function markSaved(username,s,entry){return serialLocal(async()=>{
 const st=await chrome.storage.local.get(['iglsHistoryV15','recent']);const latest=await getSettings();
 if(latest.webAppUrl===s.webAppUrl){
  const h=historyFor(st.iglsHistoryV15,s),c=h.campaigns[s.sheetName]||{names:[],at:0};
  c.names=unique([...c.names,username]);h.campaigns[s.sheetName]=c;h.known=unique([...h.known,username]);
  h.recentWrites=[...(h.recentWrites||[]),{username:normal(username),sheet:s.sheetName,at:Date.now()}].slice(-200);
  await chrome.storage.local.set({iglsHistoryV15:h});await mirror(h,s);
 }
 await chrome.storage.local.set({recent:[entry,...(st.recent||[])].slice(0,30)});
});}
chrome.storage.onChanged.addListener((changes,area)=>{
 if(area==='sync'&&(changes.sheetName||changes.webAppUrl))getSettings().then(s=>selectCached(s)).then(()=>refreshKnownIfStale(false)).catch(()=>{});
});
chrome.runtime.onMessage.addListener((msg,_sender,sendResponse)=>{
 (async()=>{try{switch(msg?.type){
  case'SAVE_LEAD':{
   const s=await getSettings(),payload={...msg.payload,savedBy:s.savedBy,status:s.defaultStatus,tag:s.defaultTag};
   const r=await callSheet('append',{sheetName:s.sheetName,lead:payload},s);
   if(r.ok)await markSaved(payload.username,s,{username:payload.username,fullName:payload.fullName,followers:payload.followers,profileUrl:payload.profileUrl,at:Date.now(),status:r.status,campaign:s.sheetName,savedBy:s.savedBy});
   sendResponse({...r,sheetName:s.sheetName});break;
  }
  case'PING_SHEET':{const s=await getSettings();sendResponse(await callSheet('ping',{sheetName:s.sheetName},s));break;}
  case'SYNC_SAVED':sendResponse(await refreshKnownIfStale(true));break;
  case'REFRESH_KNOWN':sendResponse(await refreshKnownIfStale(false));break;
  case'LIST_SHEETS':sendResponse(await callSheet('listSheets',{}));break;
  case'CREATE_SHEET':{const r=await callSheet('createSheet',{newSheetName:msg.name});if(r.ok)await chrome.storage.sync.set({sheetName:r.created});sendResponse(r);break;}
  case'SET_CONFIG':{
   const patch={};if(typeof msg.savedBy==='string')patch.savedBy=msg.savedBy.trim();if(typeof msg.sheetName==='string'&&msg.sheetName.trim())patch.sheetName=msg.sheetName.trim();
   await chrome.storage.sync.set(patch);await selectCached(await getSettings());sendResponse({ok:true,...patch});
   refreshKnownIfStale(false).catch(()=>{});break;
  }
  default:sendResponse({ok:false,error:`알 수 없는 요청: ${msg?.type}`});
 }}catch(e){sendResponse({ok:false,error:e.message});}})();return true;
});
chrome.commands.onCommand.addListener(async command=>{
 if(command!=='save-current-profile')return;const[tab]=await chrome.tabs.query({active:true,currentWindow:true});
 if(tab?.id&&/^https:\/\/www\.instagram\.com\//.test(tab.url||''))chrome.tabs.sendMessage(tab.id,{type:'SAVE_CURRENT',source:'단축키'}).catch(()=>{});
});
chrome.runtime.onInstalled.addListener(()=>{
 chrome.contextMenus.removeAll(()=>{
  chrome.contextMenus.create({id:'igls-save-link',title:'이 프로필을 시트에 저장',contexts:['link'],documentUrlPatterns:['https://www.instagram.com/*'],targetUrlPatterns:['https://www.instagram.com/*']});
  chrome.contextMenus.create({id:'igls-save-page',title:'현재 프로필을 시트에 저장',contexts:['page'],documentUrlPatterns:['https://www.instagram.com/*']});
 });
});
chrome.contextMenus.onClicked.addListener((info,tab)=>{
 if(!tab?.id)return;
 if(info.menuItemId==='igls-save-page')chrome.tabs.sendMessage(tab.id,{type:'SAVE_CURRENT',source:'우클릭'}).catch(()=>{});
 if(info.menuItemId==='igls-save-link'&&info.linkUrl)chrome.tabs.sendMessage(tab.id,{type:'SAVE_LINK',url:info.linkUrl,source:'우클릭(링크)'}).catch(()=>{});
});
