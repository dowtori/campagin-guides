const test=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const {harness}=require('./helpers/background-harness.cjs');
const legacy={savedUsernames:['@Alice'],knownUsernames:['@Alice','@Prior'],knownSyncedAt:1234,recent:[{username:'Alice',campaign:'A'}],ownerCache:{POST123:{username:'Alice'}},briefCache:{alice:{followers:100,at:1234}},panelPos:{x:50,y:90},panelMinimized:true};
async function upgrade(h,response={ok:true,current:['alice'],known:['alice','prior']}) {const done=h.installed({reason:'update',previousVersion:'1.4.0'});await h.waitRequests(1);h.requests[0].resolve(response);await done;}
test('store update preserves every existing sync setting and local preference',async()=>{
 const h=harness({local:legacy,sync:{defaultStatus:'보류',defaultTag:'keep',gridAutoResolve:false,enableFeedButtons:false}}),before=structuredClone(h.sync);
 await upgrade(h);assert.deepEqual(h.sync,before);assert.equal(h.writes.filter(w=>w.area==='sync').length,0);
 for(const key of ['recent','ownerCache','briefCache','panelPos','panelMinimized'])assert.deepEqual(h.local[key],legacy[key]);
 assert.deepEqual(h.local.iglsLegacyHistoryV14.savedUsernames,legacy.savedUsernames);assert.deepEqual(h.local.iglsLegacyHistoryV14.knownUsernames,legacy.knownUsernames);assert.equal(h.local.iglsSchemaVersion,15);
});
test('upgrade snapshot is idempotent and context menus do not duplicate',async()=>{
 const h=harness({local:legacy});await upgrade(h);const backup=structuredClone(h.local.iglsLegacyHistoryV14);
 await h.installed({reason:'update',previousVersion:'1.4.0'});assert.deepEqual(h.local.iglsLegacyHistoryV14,backup);assert.equal(h.menus.length,2);assert.equal(new Set(h.menus.map(m=>m.id)).size,2);assert.equal(h.requests.length,1);
});
test('failed first sync retains legacy backup and never labels it as verified current history',async()=>{
 const h=harness({local:legacy});await upgrade(h,{ok:false,error:'offline'});
 assert.deepEqual(h.local.iglsLegacyHistoryV14.knownUsernames,legacy.knownUsernames);assert.deepEqual(h.local.savedUsernames,[]);assert.equal(h.local.historyStatusV15.ready,false);assert.equal(h.sync.sheetName,'A');
});
test('unscoped legacy names are replaced only by the confirmed campaign response',async()=>{
 const h=harness({local:legacy,sync:{sheetName:'B'}});const done=h.installed({reason:'update',previousVersion:'1.4.0'});await h.waitRequests(1);
 assert.deepEqual(h.local.savedUsernames,[]);h.requests[0].resolve({ok:true,current:['bob'],known:['bob','prior']});await done;assert.deepEqual(h.local.savedUsernames,['bob']);assert.equal(h.local.savedScopeV15,h.sync.webAppUrl+'|B');assert.deepEqual(h.local.iglsLegacyHistoryV14.savedUsernames,['@Alice']);
});
test('old 1.4 SAVE_LEAD messages still work during transition and back up history first',async()=>{
 const h=harness({local:legacy});const done=h.send({type:'SAVE_LEAD',payload:{username:'newone',followers:100}});await h.waitRequests(1);
 assert.equal(h.requests[0].body.action,'append');assert.equal(h.requests[0].body.lead.savedBy,'tester');h.requests[0].resolve({ok:true,status:'added'});assert.equal((await done).ok,true);assert.deepEqual(h.local.iglsLegacyHistoryV14.savedUsernames,['@Alice']);assert.equal(h.local.recent[1].username,'Alice');
});
test('fresh install initializes only local schema and does not replace sync settings',async()=>{
 const h=harness({sync:{webAppUrl:''}}),before=structuredClone(h.sync);await h.installed({reason:'install'});assert.deepEqual(h.sync,before);assert.equal(h.local.iglsSchemaVersion,15);assert.equal(h.local.iglsLegacyHistoryV14,undefined);assert.equal(h.requests.length,0);
});
test('store package keeps the same permissions and raises the supplied baseline version',()=>{
 const root=path.join(__dirname,'..'),before=JSON.parse(fs.readFileSync(path.join(root,'releases/baseline-1.4.0.json'))),after=JSON.parse(fs.readFileSync(path.join(root,'manifest.json')));
 for(const k of ['permissions','host_permissions','optional_permissions','optional_host_permissions'])assert.deepEqual(after[k],before[k]);
 assert.deepEqual([...new Set(after.content_scripts.flatMap(s=>s.matches))].sort(),[...new Set(before.content_scripts.flatMap(s=>s.matches))].sort());
 const parts=v=>v.split('.').map(Number);assert.ok(parts(after.version)[1]>parts(before.version)[1]);assert.equal(after.name,before.name);
});
