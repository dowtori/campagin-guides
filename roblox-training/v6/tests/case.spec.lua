local Engine=require('./CaseEngine')
local data=require('./CaseData')
local n=0
local function expect(v,m)n+=1;assert(v,m)end
local payloads={
 {reviewed=true},
 {assembled=true,understood=true,completion='already_done'},
 {assembled=true,understood=true,completion='guide_done'},
 {handle=data.lead.handle,reviewed=true,historyChecked=true},
 {handle=data.lead.handle,fee=100000,sent=true,status='DM 발송'},
 {replied=true,applicationRead=true},
 {reviewed=true,selectionRead=true}
}
local s=Engine.new()
expect(not Engine.apply(s,'settle',payloads[#payloads],data),'cannot finish before doing work')
for i,q in ipairs(data.phases)do
 expect(s.phase==i,'campaign sequence')
 expect(q.id~='handoff','special conditions are not a mandatory phase')
 expect(not Engine.apply(s,q.id,{},data),'empty actions cannot advance')
 for key in pairs(payloads[i])do
  local invalid=table.clone(payloads[i]);invalid[key]=nil
  expect(not Engine.apply(s,q.id,invalid,data),'required record: '..q.id..'/'..key)
 end
 expect(Engine.apply(s,q.id,payloads[i],data),'valid action advances')
 expect(s.revision==i,'one revision per completed action')
 if i<#data.phases then expect(s.phase==i+1 and not s.complete,'next task')end
 if q.id=='reply'then expect(s.record.selected==nil,'application is not brand selection')end
 expect(s.record.requestedFee==nil and s.record.note==nil,'core task never forces fee negotiation')
end
expect(s.complete and s.record.total==2300,'basic case finishes without any appendix interaction')
expect(s.record.selected==1 and s.record.sent==1 and s.record.applied,'final notice and basic work recorded')
expect(not Engine.apply(s,'settle',{reviewed=true,selectionRead=true},data),'no duplicate payout')
expect(s.record.setup.profile.completion=='already_done' and s.record.setup.connect.completion=='guide_done','two explicit setup routes recorded')
expect(s.record.setup.profile.selfReported and s.record.setup.connect.selfReported,'outside setup is self-reported, not claimed as verified')
local setup=Engine.new();setup.phase=2
expect(not Engine.apply(setup,'profile',{assembled=true,understood=true,completion='opened_guide'},data),'opening a guide does not complete setup')
expect(#data.appendix==10,'optional edge-case reference topics')
print('PASS: '..n..' campaign checks; ordinary response, separate final notice, no forced exception practice')
