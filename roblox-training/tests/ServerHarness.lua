-- Small service adapter for executing the real TrainingServer in Luau CLI.
local H={now=20,packets={},guid=0}
local V={}
V.__index=function(v,k)if k=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end return V[k]end
V.__sub=function(a,b)return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z},V)end
H.Vector3={new=function(x,y,z)return setmetatable({X=x,Y=y,Z=z},V)end}
H.Vector3.zero=H.Vector3.new(0,0,0)
H.CFrame={lookAt=function(position,focus)return {Position=position,Focus=focus}end}
H.os={clock=function()return H.now end}
H.task={wait=function()end}
local function event()
    local e={}
    function e:Connect(f)self.callback=f end
    function e:Emit(...)if self.callback then self.callback(...)end end
    return e
end
local function node(name,cls)
    local t={children={},values={Name=name,ClassName=cls}}
    local methods={}
    function methods:FindFirstChild(n)for _,c in ipairs(self.children)do if c.Name==n then return c end end end
    function methods:WaitForChild(n)return assert(self:FindFirstChild(n),n)end
    function methods:IsA(c)return self.ClassName==c end
    function methods:IsDescendantOf(parent)local p=self.Parent while p do if p==parent then return true end p=p.Parent end return false end
    function methods:FindFirstChildOfClass(c)for _,n in ipairs(self.children)do if n:IsA(c)then return n end end end
    function methods:SetAttribute(k,v)self.values[k]=v end
    function methods:Destroy()self.values.Destroyed=true end
    return setmetatable(t,{__index=function(self,k)return methods[k] or self.values[k]end,__newindex=function(self,k,v)self.values[k]=v if k=='Parent' and v then table.insert(v.children,self)end end})
end
H.Instance={new=function(cls)return node('',cls)end}
H.workspace=node('Workspace','Workspace')
local map=node('TrainingMap','Model');map.Parent=H.workspace
H.stations=node('Stations','Folder');H.stations.Parent=map
local curriculum=require('./Curriculum')
for _,s in ipairs(curriculum.stages)do
    local station=node(string.format('Station%02d',s.id),'Model');station.Parent=H.stations
    local terminal=node('Terminal','Part');terminal.Parent=station;terminal.Position=H.Vector3.new(s.position[1],4.5,s.position[3]+5.8)
    local prompt=node('StartMission','ProximityPrompt');prompt.Parent=terminal
end
H.remote=node('TrainingEvent','RemoteEvent');H.remote.OnServerEvent=event()
function H.remote:FireClient(player,packet)table.insert(H.packets,packet)end
local replicated=node('ReplicatedStorage','ReplicatedStorage');H.remote.Parent=replicated
H.players={PlayerAdded=event(),PlayerRemoving=event(),GetPlayers=function()return {}end}
H.prompts={PromptTriggered=event()}
H.game={GetService=function(_,name)
    return ({Players=H.players,ReplicatedStorage=replicated,ProximityPromptService=H.prompts,HttpService={GenerateGUID=function()H.guid+=1 return 'nonce'..H.guid end}})[name]
end}
H.player=node('Learner','Player');H.player.Parent=node('Players','Players');H.player.CharacterAdded=event()
H.character=node('Character','Model');H.player.Character=H.character
H.root=node('HumanoidRootPart','Part');H.root.Parent=H.character;H.root.Position=H.Vector3.new(0,4,42)
H.humanoid=node('Humanoid','Humanoid');H.humanoid.Parent=H.character
function H.character:PivotTo(cframe)self.LastPivot=cframe H.root.Position=cframe.Position end
function H.send(packet)H.now+=1 H.remote.OnServerEvent:Emit(H.player,packet)end
function H.prompt(id)
    local s=H.stations:FindFirstChild(string.format('Station%02d',id))
    H.prompts.PromptTriggered:Emit(s:FindFirstChild('Terminal'):FindFirstChild('StartMission'),H.player)
end
function H.last(kind)for i=#H.packets,1,-1 do if H.packets[i].kind==kind then return H.packets[i]end end end
return H
