local Engine=require('./CaseEngine')
local data=require('./CaseData')
local H=require('./ServerHarness')
require('./CampusServer')
local n=0
local function expect(v,m)n+=1;assert(v,m)end
local payloads={
 brief={reviewed=true},profile={assembled=true,understood=true,completion='already_done'},connect={assembled=true,understood=true,completion='guide_done'},
 discover={sourceBrand='oddtype_official',sourceTab='tagged',collected={{handle='beauty_sample',postId='tag01'}}},send={handle=data.lead.handle,fee=data.lead.fee,sent=true,status='DM 발송'},
 reply={reaction='none',applicationRead=true},settle={reviewed=true,selectionRead=true}
}
local s=Engine.new()
for _,invalid in ipairs({'missing','',3,{id='send'}})do
 expect(not Engine.choose(s,invalid,data),'unknown/non-string chapter rejected')
 expect(s.phase==1 and s.revision==0,'invalid chapter leaves progress intact')
end
expect(Engine.choose(s,'settle',data),'last chapter can be selected first')
expect(s.phase==7 and not s.completed.brief and s.record.sent==nil,'selection never fabricates prior work')
expect(not Engine.apply(s,'settle',{},data),'jump still requires chapter action')
expect(Engine.apply(s,'settle',payloads.settle,data),'later chapter uses its supplied example')
expect(s.phase==1 and not s.complete and s.completed.settle,'only the finished chapter gets a check; return to unfinished work')
expect(s.record.total==2300 and s.record.sent==nil and s.record.applied==nil,'example calculation does not invent sent/application records')
for _,id in ipairs({'connect','reply','profile','send','discover','brief'})do
 expect(Engine.choose(s,id,data),'choose '..id)
 expect(Engine.apply(s,id,payloads[id],data),'complete '..id)
end
expect(s.complete,'all seven finished in any order completes the course')
for _,q in ipairs(data.phases)do expect(s.completed[q.id],'every completion recorded')end
local total=s.record.total
expect(Engine.choose(s,'settle',data),'completed chapter can be replayed')
expect(Engine.apply(s,'settle',payloads.settle,data),'replay completes')
expect(s.complete and s.record.total==total,'replay neither duplicates payment nor loses completion')
local current=Engine.new();Engine.apply(current,'brief',payloads.brief,data)
local revision=current.revision;local ok,changed=Engine.choose(current,'profile',data)
expect(ok and changed==false and current.revision==revision,'choosing current chapter preserves draft revision')
local function request(id,revision)
 H.send({kind='chapter',chapter=id,revision=revision or H.last().state.revision,position={10000,-999,10000}})
end
H.send({kind='hello'})
request('send',900);expect(H.last().kind=='state' and H.last().state.phase==1,'stale chapter request cannot change state')
request('unknown');expect(H.last().kind=='notice' and H.last().state.phase==1,'invalid chapter rejected by actual server')
for _,q in ipairs(data.phases)do
 request(q.id)
 expect(H.last().kind=='open' and H.last().profile==q.target,'selected chapter opens at correct target')
 expect(H.root.Position.X==H.targets[q.target].Position.X and H.root.Position.Z==H.targets[q.target].Position.Z+7,'coordinates come from server arrival pads')
 expect(next(H.last().state.completed)==nil,'teleporting alone completes nothing')
end
local revision=H.last().state.revision
request('settle');expect(H.last().resetDraft==false and H.last().state.revision==revision,'reselecting same unfinished chapter resumes')
H.send({kind='apply',revision=revision-1,action='settle',payload=payloads.settle})
expect(H.last().state.record.total==nil,'old work packet cannot complete newly selected chapter')
H.send({kind='apply',revision=revision,action='settle',payload=payloads.settle})
expect(H.last().kind=='done' and not H.last().state.complete and H.last().state.phase==1,'finishing last chapter returns to missing chapter')
print('PASS: '..n..' chapter checks; arbitrary order, replay, true completion, safe travel, stale requests')
