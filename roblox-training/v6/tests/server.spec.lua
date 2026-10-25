local H=require('./ServerHarness')
require('./CampusServer')
local data=require('./CaseData')
local n=0
local function expect(v,m)n+=1;assert(v,m)end
H.send({kind='hello'});expect(H.last().state.phase==1,'hello')
H.send({kind='interact',target='Mailbox'});expect(H.last().kind=='notice','wrong destination does not start a later phase')
H.targets.Manager.Interact.Triggered:Fire(H.player);expect(H.last().kind=='open','native prompt')
H.send({kind='apply',revision=90,action='brief',payload={reviewed=true}});expect(H.last().state.phase==1,'stale request')
H.root.Position=H.Vector3.new(1000,4,0)
H.send({kind='apply',revision=0,action='brief',payload={reviewed=true}});expect(H.last().state.phase==1,'work requires proximity')
H.send({kind='travel',revision=0,target='Mailbox',position={999,999,999}})
expect(H.last().kind=='arrived' and H.last().state.phase==1,'travel preserves work')
expect(H.root.Position.Z==H.targets.Manager.Position.Z+7,'server-selected clear arrival')
H.send({kind='resume',revision=0});expect(H.last().kind=='open' and H.last().profile=='Manager','resume current work')
H.send({kind='travel',revision=90});expect(H.last().kind=='state','stale travel rejected')
local payloads={{reviewed=true},{photo='siriai',bio=data.bio,link=data.link,posts=true},{url=data.webAppUrl,name='파트너',tab=data.campaign,status='연락전',tested=true,loaded=true},{handle='beauty_sample',reviewed=true,historyChecked=true},{handle='beauty_sample',fee=100000,sent=true,status='DM 발송'},{replied=true,applicationRead=true},{reviewed=true,selectionRead=true}}
local visits={};local previous=nil
for i,q in ipairs(data.phases)do
 if q.target~=previous then table.insert(visits,q.target);previous=q.target end
 H.root.Position=H.targets[q.target].Position
 H.send({kind='interact',target=q.target});expect(H.last().kind=='open','current work opens')
 H.send({kind='apply',revision=i-1,action=q.id,payload=payloads[i]});expect(H.last().kind=='done','action completes')
 local continues=i<#data.phases and q.target==data.phases[i+1].target
 expect(H.last().continueHere==continues,'same-location continuation is explicit')
end
expect(table.concat(visits,',')=='Manager,beauty_sample,Mailbox','only three forward visits, never return to first location')
local tool=H.player.Backpack:FindFirstChild('리크루터 폰');expect(tool and tool.ManualActivationOnly,'deliberate tool activation')
local before=#H.clients;tool.Activated:Fire();expect(#H.clients==before,'click cannot open phone')
tool.Equipped:Fire();expect(H.last().kind=='phone','equip opens phone')
expect(H.last().state.complete and H.last().state.record.total==2300,'basic course completes')
H.send({kind='apply',revision=#data.phases,action='settle',payload={reviewed=true,selectionRead=true}});expect(H.last().kind=='state','no duplicate settlement')
H.send({kind='restart'});expect(H.root.Position.X==-34 and H.root.Position.Z==100 and H.last().state.phase==1,'replay returns to beginning, not across the island')
print('PASS: '..n..' native server checks; current destinations, three visits, continuous work, restart')
