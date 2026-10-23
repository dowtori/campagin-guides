/* Passive observer. Makes NO requests; only selects public fields from normal page responses. */
(()=>{
 'use strict';if(window.__iglsPassive15)return;window.__iglsPassive15=true;
 const users=new Map(),media=new Map();let timer;
 function collect(data){
  const packet=IGLSCore.extract(data);
  for(const u of packet.users)users.set(u.username,IGLSCore.merge(users.get(u.username),u));
  for(const m of packet.media)media.set(m.shortcode,m);
  while(users.size>1500)users.delete(users.keys().next().value);
  while(media.size>1500)media.delete(media.keys().next().value);
  clearTimeout(timer);timer=setTimeout(send,80);
 }
 function send(){const uu=[...users.values()],mm=[...media.values()];
  for(let i=0;i<Math.max(uu.length,mm.length);i+=250)window.postMessage({source:'igls-passive-v15',users:uu.slice(i,i+250),media:mm.slice(i,i+250)},location.origin);
 }
 function matches(url){try{const u=new URL(url,location.href);return u.origin===location.origin&&(/^\/api\/v1\/(feed|media|users|web\/search)\//.test(u.pathname)||/^\/graphql\/query\/?$/.test(u.pathname));}catch{return false;}}
 const nativeFetch=window.fetch;
 window.fetch=function(...args){
  const result=Reflect.apply(nativeFetch,this,args),url=typeof args[0]==='string'?args[0]:args[0]?.url;
  if(matches(url))result.then(r=>{
   if(!r.ok||Number(r.headers.get('content-length')||0)>4e6)return;
   r.clone().text().then(text=>{if(text.length>4e6)return;try{collect(JSON.parse(text.replace(/^for \(;;\);\s*/,'')));}catch{}}).catch(()=>{});
  }).catch(()=>{});return result;
 };
 const nativeOpen=XMLHttpRequest.prototype.open;
 XMLHttpRequest.prototype.open=function(method,url,...rest){
  if(matches(url))this.addEventListener('load',()=>{try{
   if(this.status<200||this.status>=300)return;
   if(this.responseType==='json')collect(this.response);
   else if((!this.responseType||this.responseType==='text')&&this.responseText.length<4e6)collect(JSON.parse(this.responseText.replace(/^for \(;;\);\s*/,'')));
  }catch{}},{once:true});return Reflect.apply(nativeOpen,this,[method,url,...rest]);
 };
 const seen=new WeakSet();let scans=0;
 function initialData(){
  for(const s of document.querySelectorAll('script[type="application/json"]')){
   if(seen.has(s)||s.textContent.length>4e6)continue;seen.add(s);try{collect(JSON.parse(s.textContent));}catch{}
  }
  if(++scans>30)observer.disconnect();
 }
 const observer=new MutationObserver(()=>{clearTimeout(initialData.timer);initialData.timer=setTimeout(initialData,200);});
 observer.observe(document,{childList:true,subtree:true});document.addEventListener('DOMContentLoaded',initialData,{once:true});
 window.addEventListener('message',e=>{if(e.source===window&&e.origin===location.origin&&e.data?.source==='igls-request-passive-v15')send();});
})();
