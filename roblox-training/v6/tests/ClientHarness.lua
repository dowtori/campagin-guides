local Mock=require('./NativeUiMock')
local data=require('./CaseData')
local Engine=require('./CaseEngine')
local H={Mock=Mock,packets={},state=Engine.new()}
local event=Mock.event
local V={};V.__index=function(self,k)if k=='Magnitude'then return math.sqrt(self.X*self.X+self.Y*self.Y+self.Z*self.Z)end return V[k]end
V.__sub=function(a,b)return H.Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
H.Vector3={new=function(x,y,z)return setmetatable({X=x,Y=y,Z=z},V)end}
H.Vector2={new=function(x,y)return {X=x,Y=y}end}
H.Vector2.zero=H.Vector2.new(0,0)
H.Enum=Mock.Enum;H.Instance=Mock.Instance;H.Color3=Mock.Color3;H.UDim=Mock.UDim;H.UDim2=Mock.UDim2
H.task={wait=function()end,delay=function()end}
H.workspace=Mock.Instance.new('Workspace')
local map=Mock.Instance.new('Model');map.Name='TrainingMap';map.Parent=H.workspace
for _,name in ipairs({'Manager','DiscoveryDesk','Mailbox'})do
 local p=Mock.Instance.new('Part');p.Name='Target_'..name;p.Position=H.Vector3.new(0,4,0);p.Parent=map
end
H.player=Mock.Instance.new('Player');H.player.DisplayName='테스트 파트너';local char=Mock.Instance.new('Model');H.player.Character=char
local root=Mock.Instance.new('Part');root.Name='HumanoidRootPart';root.Position=H.Vector3.new(0,4,0);root.Parent=char
H.gui=Mock.Instance.new('ScreenGui')
H.remote=Mock.Instance.new('RemoteEvent');H.remote.Name='CampusEvent';H.remote.OnClientEvent=event()
function H.remote:FireServer(packet)
 table.insert(H.packets,packet)
 if packet.kind=='hello'then self.OnClientEvent:Fire({kind='state',state=H.state})
 elseif packet.kind=='resume'then self.OnClientEvent:Fire({kind='open',state=H.state,profile=data.phases[H.state.phase].target})
 elseif packet.kind=='travel'then self.OnClientEvent:Fire({kind='arrived',state=H.state,text='도착'})
 elseif packet.kind=='chapter'then
  assert(packet.revision==H.state.revision,'valid chapter revision')
  local ok,changed=Engine.choose(H.state,packet.chapter,data);assert(ok)
  self.OnClientEvent:Fire({kind='open',state=H.state,profile=data.phases[H.state.phase].target,resetDraft=changed and H.state.completed[packet.chapter]==true})
 elseif packet.kind=='apply'then
  assert(packet.revision==H.state.revision,'valid client revision')
  local q=data.phases[H.state.phase]
  local ok,reason=Engine.apply(H.state,packet.action,packet.payload,data)
  assert(ok,(reason or '')..': '..q.id)
  self.OnClientEvent:Fire({kind='done',state=H.state,text=q.done,continueHere=not H.state.complete and q.target==data.phases[H.state.phase].target})
 end
end
local replicated=Mock.Instance.new('ReplicatedStorage');H.remote.Parent=replicated
H.run={Heartbeat=event()};H.input={InputBegan=event(),TouchEnabled=false}
H.game={GetService=function(_,name)return ({Players={LocalPlayer=H.player},ReplicatedStorage=replicated,RunService=H.run,UserInputService=H.input,AssetService={CreateEditableImage=function()error('test fallback')end}})[name]end}
function H.find(value)
 for _,o in ipairs(H.gui:GetDescendants())do if o.ClassName=='TextButton' and o.Text and o.Text:find(value,1,true)then return o end end
 error('Missing native button: '..value)
end
function H.click(value)local b=H.find(value);assert(b.Active~=false,'button disabled: '..value);b.Activated:Fire()end
function H.open(profile)H.remote.OnClientEvent:Fire({kind='open',state=H.state,profile=profile})end
return H
