const vm=require('node:vm'),fs=require('node:fs'),path=require('node:path');
const tick=()=>new Promise(r=>setImmediate(r));
function harness(seed={}) {
 const local=structuredClone(seed.local||{});
 const sync={webAppUrl:'https://script.google.com/macros/s/test/exec',sheetName:'A',savedBy:'tester',...structuredClone(seed.sync||{})};
 const changes=[],listeners={},requests=[],writes=[],menus=[];
 const area=(obj,name)=>({
  get:async keys=>typeof keys==='string'?{[keys]:structuredClone(obj[keys])}:Array.isArray(keys)?Object.fromEntries(keys.map(k=>[k,structuredClone(obj[k])])):{...keys,...structuredClone(obj)},
  set:async patch=>{writes.push({area:name,patch:structuredClone(patch)});const c={};for(const[k,v]of Object.entries(patch)){c[k]={oldValue:structuredClone(obj[k]),newValue:structuredClone(v)};obj[k]=structuredClone(v);}changes.forEach(f=>f(c,name));}
 });
 const chrome={storage:{local:area(local,'local'),sync:area(sync,'sync'),onChanged:{addListener:f=>changes.push(f)}},runtime:{onMessage:{addListener:f=>listeners.message=f},onInstalled:{addListener:f=>listeners.installed=f}},commands:{onCommand:{addListener:()=>{}}},contextMenus:{removeAll:f=>{menus.length=0;f()},create:o=>menus.push(o),onClicked:{addListener:()=>{}}}};
 const ctx=vm.createContext({chrome,fetch:(url,options)=>new Promise((resolve,reject)=>requests.push({url,body:JSON.parse(options.body),reject,resolve:data=>resolve({ok:true,text:async()=>JSON.stringify(data)})})),AbortController,structuredClone,setTimeout,clearTimeout,Date});
 vm.runInContext(fs.readFileSync(path.join(__dirname,'../../src/background.js'),'utf8'),ctx);
 const send=msg=>new Promise(resolve=>listeners.message(msg,{},resolve));
 const waitRequests=async n=>{for(let i=0;i<20&&requests.length<n;i++)await tick();if(requests.length<n)throw Error('expected request not started');};
 return{local,sync,requests,writes,menus,send,tick,waitRequests,installed:details=>listeners.installed(details)};
}
module.exports={harness,tick};
