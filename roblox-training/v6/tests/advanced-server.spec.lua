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
H.players.PlayerRemoving:Fire(H.player);run.Heartbeat:Fire(.2)
print('PASS: '..checks..' actual server integration checks; gating, native travel, heartbeat, chapter exit and pier visit')
