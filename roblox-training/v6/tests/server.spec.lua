local H=require('./ServerHarness')
require('./CampusServer')
local data=require('./CaseData')
local n=0
local function expect(v,m)n+=1;assert(v,m)end
H.send({kind='hello'});expect(H.last().state.phase==1,'server hello')
H.send({kind='interact',target='Mailbox'});expect(H.last().kind=='notice','wrong job target directs learner to current task')
H.targets.Manager.Interact.Triggered:Fire(H.player);expect(H.last().kind=='open','native proximity opens mission')
H.send({kind='apply',revision=90,action='brief',payload={reviewed=true}});expect(H.last().state.phase==1,'stale nonce does not progress')
H.root.Position=H.Vector3.new(1000,4,0)
H.send({kind='apply',revision=0,action='brief',payload={reviewed=true}});expect(H.last().state.phase==1,'remote action must be near work target')
H.root.Position=H.Vector3.new(0,4,0)
local payloads={{reviewed=true},{photo='siriai',bio=data.bio,link=data.link,posts=true},{url=data.webAppUrl,name='파트너',tab=data.campaign,status='연락전',tested=true,loaded=true},{handle='beauty_sample',reviewed=true,historyChecked=true},{handle='beauty_sample',fee=100000,sent=true,status='DM 발송'},{fee=150000,replied=true,shared=true},{asked=true,replied=true,selectionRead=true},{reviewed=true}}
for i,q in ipairs(data.phases)do
 H.send({kind='interact',target=q.target});expect(H.last().kind=='open','current job target opens: '..q.id)
 H.send({kind='apply',revision=i-1,action=q.id,payload=payloads[i]});expect(H.last().kind=='done','actual server action done: '..q.id)
end
expect(H.player.Backpack:FindFirstChild('리크루터 폰')~=nil,'native tool granted after accepting quest')
expect(H.last().state.complete and H.last().state.record.total==2300,'server reaches one completed campaign')
H.send({kind='apply',revision=8,action='settle',payload={reviewed=true}});expect(H.last().kind=='state','no duplicate settlement')
print('PASS: '..n..' actual server remote/proximity checks; target, distance, stale revision, phone grant and full campaign')
