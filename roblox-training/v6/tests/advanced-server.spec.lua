local H=require('./ServerHarness')
local data=require('./CaseData');local D=require('./AdvancedData');local R=require('./RewardPolicy')
local rs=H.game:GetService('ReplicatedStorage')
local remote=H.Instance.new('RemoteEvent');remote.Name='AdvancedEvent';remote.OnServerEvent=H.Mock.event();remote.Parent=rs
local packets={};function remote:FireClient(_,p)table.insert(packets,p)end
local now=0;function H.workspace:GetServerTimeNow()return now end
H.Vector3.zero=H.Vector3.new(0,0,0)
local run={Heartbeat=H.Mock.event()};local original=H.game.GetService
H.game.GetService=function(self,name)if name=='RunService'then return run end;return original(self,name)end
require('./CampusServer')
local checks=0;local function check(v,m)checks+=1;assert(v,m)end
H.send({kind='hello'});local s=H.last().state
remote.OnServerEvent:Fire(H.player,{kind='enter',id='scout'});check(H.last().kind=='notice' and not s.advanced,'basic gate in server')
for _,q in ipairs(data.phases)do s.completed[q.id]=true end
remote.OnServerEvent:Fire(H.player,{kind='enter',id='scout'})
check(H.root.Position.X==D.room.arrival[1] and H.root.Position.Z==D.room.arrival[3],'native teleport arrival')
check(packets[#packets].run.status=='brief','client receives world reading state')
local token=s.advanced.run.token;remote.OnServerEvent:Fire(H.player,{kind='start',token=token})
now=30;run.Heartbeat:Fire(.2);check(s.advanced.run.status=='timeout','server heartbeat timeout')
remote.OnServerEvent:Fire(H.player,{kind='retry',token=token});check(s.advanced.run.status=='brief','native retry')
remote.OnServerEvent:Fire(H.player,{kind='start',token=s.advanced.run.token})
H.send({kind='chapter',chapter='profile',revision=s.revision})
check(not s.advanced.run and H.last().kind=='open','chapter cancels timed game')
check(packets[#packets].run==nil,'client clears room on travel')
remote.OnServerEvent:Fire(H.player,{kind='enter',id='fee'});remote.OnServerEvent:Fire(H.player,{kind='start',token=s.advanced.run.token})
now=100000;run.Heartbeat:Fire(.2);check(s.advanced.run.status=='active','untimed server NPC')
H.send({kind='rest'});check(not s.advanced.run and H.root.Position.X==-17 and H.root.Position.Z==-321,'reward visit clears run')
local awards=0
local function solve(id)
 remote.OnServerEvent:Fire(H.player,{kind='enter',id=id})
 local run=s.advanced.run;local token=run.token
 remote.OnServerEvent:Fire(H.player,{kind='start',token=token})
 local c=require('./AdvancedEngine').challenge(D,id);local slot
 for i,j in ipairs(run.order)do if c.rounds[run.round].options[j].correct then slot=i end end
 remote.OnServerEvent:Fire(H.player,{kind='answer',token=token,slot=slot})
 return token,slot
end
solve('scout');solve('fee');local oldToken,oldSlot=solve('conditions')
check(R.summary(s).king and not s.advanced.run,'final challenge closes run and earns king')
check(H.root.Position.X==0 and H.root.Position.Z==-326 and H.last().kind=='kingReward','final clear returns to unobstructed pier and requests view once')
for _,packet in ipairs(H.clients)do if packet.kind=='kingReward' then awards+=1 end end
solve('conditions');local count=0;for _,packet in ipairs(H.clients)do if packet.kind=='kingReward' then count+=1 end end
check(count==awards,'replay does not re-award or teleport')
local rev=s.revision
H.send({kind='restart',scope='all',revision=rev-1});check(R.summary(s).king,'stale reset rejected')
H.send({kind='restart',scope='send',revision=rev})
check(not s.completed.send and s.completed.profile and s.advanced.completed.conditions,'server partial reset preserves other records')
check(H.last().kind=='reset' and H.last().open and s.phase==5,'server returns reset chapter')
local prior=s.revision;H.send({kind='restart',scope='forged',revision=prior});check(s.revision==prior,'forged scope rejected')
H.send({kind='restart',scope='all',revision=s.revision})
check(R.summary(s).stage==0 and s.phase==1 and s.revision>prior,'full reset monotonic and empty')
remote.OnServerEvent:Fire(H.player,{kind='answer',token=oldToken,slot=oldSlot})
check(R.summary(s).stage==0 and not s.advanced.run,'old answer cannot restore completed reward')
H.players.PlayerRemoving:Fire(H.player);run.Heartbeat:Fire(.2)
print('PASS: '..checks..' actual server integration checks; gating, native travel, heartbeat, chapter exit and pier visit')
