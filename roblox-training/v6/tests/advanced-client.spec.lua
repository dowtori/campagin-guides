local H=require('./ClientHarness')
local E=require('./AdvancedEngine');local D=require('./AdvancedData');local R=require('./RewardPolicy');local Session=require('./AdvancedSession')
local map=H.workspace:FindFirstChild('TrainingMap')
local room=H.Instance.new('Model');room.Name='AdvancedRoom';room.Parent=map
for _,name in ipairs({'ConditionBoard','ChallengeConsole','ChoiceBoard1','ChoiceBoard2','ChoiceBoard3'})do
 local p=H.Instance.new('Part');p.Name=name;p.Parent=room
end
for i=1,3 do
 local npc=H.Instance.new('Model');npc.Name='AnswerNPC'..i;npc.Parent=map
 for _,name in ipairs({'Torso','Head','Left Arm','Right Arm','Left Leg','Right Leg','Eye','HumanoidRootPart'})do
  local p=H.Instance.new('Part');p.Name=name;p.Parent=npc
 end
end
local pg=H.Instance.new('PlayerGui');pg.Name='PlayerGui';pg.Parent=H.player
local rs=H.game:GetService('ReplicatedStorage')
local remote=H.Instance.new('RemoteEvent');remote.Name='AdvancedEvent';remote.OnClientEvent=H.Mock.event();remote.Parent=rs
local now=0;function H.workspace:GetServerTimeNow()return now end
local state={completed={},record={}}
for _,id in ipairs({'brief','profile','connect','discover','send','reply','settle'})do state.completed[id]=true end
local session=Session.new(E,D,R,{state=function()return state end,clock=function()return now end,
 position=function()return {X=60,Y=4,Z=-80}end,rotation=function()return 1 end,travel=function()error('already inside')end,
 send=function(_,packet)remote.OnClientEvent:Fire(packet)end,sync=function()end,notice=function()end})
function remote:FireServer(p)session.handle('me',p)end
local closed=0;local client=require('./AdvancedClient').start(H.gui,function()closed+=1 end,function()end)
local checks=0
local function check(v,m)checks+=1;assert(v,m)end
local function find(value)
 for _,o in ipairs(pg:GetDescendants())do if o.ClassName=='TextButton' and o.Text:find(value,1,true)then return o end end
end
local function click(value)local b=find(value);assert(b,'missing '..value);b.Activated:Fire()end
local function npcState(visible)
 for i=1,3 do
  local npc=map:FindFirstChild('AnswerNPC'..i)
  check(npc:FindFirstChild('Torso').CanCollide==visible and npc:FindFirstChild('Torso').Transparency==(visible and 0 or 1),'NPC solid only while visible')
  check(npc:FindFirstChild('Eye').CanCollide==false,'face details never add collision')
 end
end
npcState(false)
client.enter();npcState(false)
check(state.advanced.run.status=='brief' and closed>0,'entry closes work panel')
local surfaces=0;for _,o in ipairs(pg:GetChildren())do if o.ClassName=='SurfaceGui'then surfaces+=1;check(o.Adornee and o.AlwaysOnTop==false,'physical board')end end
check(surfaces==5,'five world surfaces')
check(not find('이 크리에이터 선택'),'candidates hidden before start')
now=99999;H.run.Heartbeat:Fire(.2);session.tick();check(state.advanced.run.status=='brief','reading time unlimited')
click('시작');check(state.advanced.run.deadline==now+30,'explicit start')
check(find('이 크리에이터 선택')~=nil,'candidate buttons available')
check(#H.gui:GetChildren()==0,'no ScreenGui popup')
now+=30;session.tick();check(state.advanced.run.status=='timeout','timeout shown')
click('다시 도전');check(state.advanced.run.status=='brief','wall retry returns to reading')
click('고료 조정 문의');click('NPC 답변 보기');npcState(true)
check(state.advanced.run.deadline==nil and find('이 답변 선택')~=nil,'NPC choices untimed')
now+=999999;H.run.Heartbeat:Fire(.2);session.tick();check(state.advanced.run.status=='active','no NPC timeout')
local run=state.advanced.run;local c=E.challenge(D,run.id);local correct
for i,j in ipairs(run.order)do if c.rounds[run.round].options[j].correct then correct=i end end
local chosen=pg:FindFirstChild('Challenge_ChoiceBoard'..correct)
for _,o in ipairs(chosen:GetDescendants())do if o.ClassName=='TextButton' then o.Activated:Fire();break end end
check(state.advanced.run.status=='passed' and R.summary(state).bonus==1,'world button grants one clear')
for _,o in ipairs(pg:GetDescendants())do if o.Text then check(not o.Text:find('%+%d+점'),'world results do not advertise game points')end end
click('다시 도전');check(state.advanced.run.status=='brief','success replay available')
session.leave('me');npcState(false);check(find('도전하기')~=nil,'room returns to idle after leaving')
print('PASS: '..checks..' actual advanced-client callback checks; world surfaces, timers, NPC choices and retry')
