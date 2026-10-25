local Mock=require('./NativeUiMock')
local data=require('./CaseData')
local route=require('./RouteData')
local H={Mock=Mock,clients={},players={}}
local event=Mock.event
local V={};V.__index=function(self,k)if k=='Magnitude'then return math.sqrt(self.X*self.X+self.Y*self.Y+self.Z*self.Z)end return V[k]end
V.__sub=function(a,b)return H.Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
V.__add=function(a,b)return H.Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
V.__mul=function(a,b)return H.Vector3.new(a.X*b,a.Y*b,a.Z*b)end
H.Vector3={new=function(x,y,z)return setmetatable({X=x,Y=y,Z=z},V)end}
H.Instance=Mock.Instance;H.Color3=Mock.Color3;H.UDim2=Mock.UDim2;H.Enum=Mock.Enum
H.CFrame={new=function(x,y,z)return {Position=H.Vector3.new(x,y,z)}end,lookAt=function(pos,target)return {Position=pos,Target=target}end};H.TweenInfo={new=function()return {}end}
H.task={wait=function()end}
H.workspace=Mock.Instance.new('Workspace');local map=Mock.Instance.new('Model');map.Name='TrainingMap';map.Parent=H.workspace
local architecture=Mock.Instance.new('Folder');architecture.Name='Architecture';architecture.Parent=map
H.objects=Mock.Instance.new('Folder');H.objects.Name='QuestObjects';H.objects.Parent=architecture
H.targets={}
for _,name in ipairs({'Manager','beauty_sample','Mailbox'})do
 local p=Mock.Instance.new('Part');p.Name='Target_'..name;p.Position=H.Vector3.new(unpack(route.targets[name].position));p.Parent=H.objects
 local id=Mock.Instance.new('StringValue');id.Name='ActionID';id.Value=name;id.Parent=p
 local prompt=Mock.Instance.new('ProximityPrompt');prompt.Name='Interact';prompt.Triggered=event();prompt.Parent=p
 H.targets[name]=p
end
-- Extend only the native type predicate needed for actual source execution.
local oldNew=Mock.Instance.new
function H.Instance.new(class)
 local p=oldNew(class)
 if class=='Part'then p.props.Position=H.Vector3.new(0,0,0)end
 return p
end
local mt=getmetatable(H.targets.Manager);local oldIndex=mt.__index
mt.__index=function(self,k)
 if k=='IsA'then return function(o,name)return o.props.ClassName==name or (name=='BasePart' and o.props.ClassName=='Part')end end
 local value=oldIndex(self,k);if value~=nil then return value end
 for _,child in ipairs(self.children)do if child.Name==k then return child end end
end
H.player=H.Instance.new('Player');H.player.Backpack=H.Instance.new('Backpack');H.player.Backpack.Parent=H.player
H.player.Character=H.Instance.new('Model');local root=H.Instance.new('Part');root.Name='HumanoidRootPart';root.Position=H.Vector3.new(0,4,0);root.Parent=H.player.Character;H.root=root;root.Position=H.targets.Manager.Position
function H.player.Character:PivotTo(frame)H.root.Position=frame.Position;H.lastPivot=frame end
H.player.CharacterAdded=event();H.players.PlayerAdded=event();H.players.PlayerRemoving=event()
H.remote=H.Instance.new('RemoteEvent');H.remote.Name='CampusEvent';H.remote.OnServerEvent=event()
function H.remote:FireClient(_,packet)table.insert(H.clients,packet)end
local rs=H.Instance.new('ReplicatedStorage');H.remote.Parent=rs
local shared=H.Instance.new('Folder');shared.Name='CampusShared';shared.Parent=rs
H.game={GetService=function(_,name)return ({Players=H.players,ReplicatedStorage=rs,TweenService={Create=function()return {Completed=event(),Play=function()end}end},Debris={AddItem=function()end}})[name]end}
function H.send(p)H.remote.OnServerEvent:Fire(H.player,p)end
function H.last()return H.clients[#H.clients]end
return H
