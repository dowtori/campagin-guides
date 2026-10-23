const test=require('node:test'),assert=require('node:assert/strict'),vm=require('node:vm'),fs=require('node:fs'),path=require('node:path');
async function popup(profile) {
 const elements={};const el=id=>elements[id]||(elements[id]={textContent:'',className:'',disabled:id==='saveBtn',hidden:id==='target',addEventListener(){}});
 const chrome={storage:{sync:{get:async()=>({webAppUrl:'https://script.google.com/macros/s/test/exec'})},local:{get:async()=>({recent:[]})}},tabs:{query:async()=>[{id:1,url:'https://www.instagram.com/alice/'}],sendMessage:async()=>profile},runtime:{getManifest:()=>({version:'1.5.0'}),openOptionsPage(){}}};
 vm.runInNewContext(fs.readFileSync(path.join(__dirname,'../src/popup.js'),'utf8'),{document:{getElementById:el},chrome,setTimeout});
 for(let i=0;i<5;i++)await new Promise(r=>setImmediate(r));return elements;
}
test('popup requests refresh for a pre-update content script instead of enabling save',async()=>{const p=await popup({username:'alice',campaign:'A'});assert.equal(p.saveBtn.disabled,true);assert.match(p.status.textContent,/업데이트.*새로고침/);});
test('popup enables saving for a matching current content script version',async()=>{const p=await popup({version:'1.5.0',username:'alice',campaign:'A'});assert.equal(p.saveBtn.disabled,false);assert.equal(p.who.textContent,'@alice');});
