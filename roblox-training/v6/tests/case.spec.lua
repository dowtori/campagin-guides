local Engine=require('./CaseEngine')
local data=require('./CaseData')
local n=0
local function expect(v,m)n+=1;assert(v,m)end
local payloads={
 {reviewed=true},
 {photo='siriai',bio=data.bio,link=data.link,posts=true},
 {url=data.webAppUrl,name='파트너',tab=data.campaign,status='연락전',tested=true,loaded=true},
 {handle=data.lead.handle,reviewed=true,historyChecked=true},
 {handle=data.lead.handle,fee=100000,sent=true,status='DM 발송'},
 {fee=150000,replied=true,shared=true},
 {asked=true,replied=true,selectionRead=true},
 {reviewed=true}
}
local s=Engine.new()
expect(not Engine.apply(s,'settle',payloads[8],data),'cannot finish before doing work')
for i,q in ipairs(data.phases)do
 expect(s.phase==i,'campaign context sequence')
 expect(not Engine.apply(s,q.id,{},data),'empty actions cannot advance')
 local p=payloads[i]
 for key in pairs(p)do
  local invalid=table.clone(p);invalid[key]=nil
  expect(not Engine.apply(s,q.id,invalid,data),'every required work record is checked: '..q.id..'/'..key)
 end
 local phase=s.phase;expect(Engine.apply(s,q.id,p,data),'valid action advances')
 expect(s.revision==i,'one revision for one completed action')
 if i<8 then expect(s.phase==phase+1 and not s.complete,'next task available')end
end
expect(s.complete and s.record.total==2300,'correct one-case payout example')
expect(s.record.requestedFee==150000 and s.record.selected==1 and s.record.sent==1,'requested fee differs from selection and sent count')
expect(not Engine.apply(s,'settle',{reviewed=true},data),'completion cannot be duplicated')
local t=Engine.new()
for i=1,3 do expect(Engine.apply(t,data.phases[i].id,payloads[i],data),'prepare lead search')end
expect(not Engine.apply(t,'discover',{handle='tiny_sample',reviewed=true,historyChecked=true},data),'out-of-scope person cannot be collected')
expect(not Engine.apply(t,'discover',{handle='trip_sample',reviewed=true,historyChecked=true},data),'wrong content category rejected')
print('PASS: '..n..' actual campaign state checks; malformed/partial/out-of-order work, rate/identity checks, record and completion idempotence')
