-- Execute the entire exported ClientMain, not just its individual visual widgets.
local Mock=require('./NativeUiMock')
local Curriculum=require('./Curriculum')
local Engine=require('./TrainingEngine')
local H={Mock=Mock,packets={}}
H.Vector2={new=function(x,y)return {X=x,Y=y}end,zero={X=0,Y=0}}
H.Vector3={new=function(x,y,z)return {X=x,Y=y,Z=z}end}
H.Enum=Mock.Enum;H.Instance=Mock.Instance;H.Color3=Mock.Color3;H.UDim=Mock.UDim;H.UDim2=Mock.UDim2
local event=Mock.event
H.task={wait=function()end,delay=function()end,spawn=function(f,...)f(...)end}
H.workspace=Mock.Instance.new('Workspace')
local map=Mock.Instance.new('Model');map.Name='TrainingMap';map.Parent=H.workspace
local stations=Mock.Instance.new('Folder');stations.Name='Stations';stations.Parent=map
for _,s in ipairs(Curriculum.stages)do
    local booth=Mock.Instance.new('Model');booth.Name=string.format('Station%02d',s.id);booth.Parent=stations
    local terminal=Mock.Instance.new('Part');terminal.Name='Terminal';terminal.Parent=booth
end
H.player=Mock.Instance.new('Player')
H.playerGui=Mock.Instance.new('PlayerGui');H.playerGui.Name='PlayerGui';H.playerGui.Parent=H.player
H.character=Mock.Instance.new('Model');H.player.Character=H.character
H.root=Mock.Instance.new('Part');H.root.Name='HumanoidRootPart';H.root.Position={X=0,Y=4,Z=60};H.root.Parent=H.character
H.remote=Mock.Instance.new('RemoteEvent');H.remote.Name='TrainingEvent';H.remote.OnClientEvent=event()
local public={}
for _,s in ipairs(Curriculum.stages)do table.insert(public,{id=s.id,title=s.title,color=s.color,subtitle=s.subtitle,position=s.position})end
function H.remote:FireServer(packet)
    table.insert(H.packets,packet)
    if packet.kind=='hello' and not H.noWelcome then self.OnClientEvent:Fire({kind='welcome',stages=public,snapshot=Engine.snapshot(Engine.new(),Curriculum)})end
end
local replicated=Mock.Instance.new('ReplicatedStorage');H.remote.Parent=replicated
H.prompts={Enabled=true}
H.input={InputBegan=event(),GetFocusedTextBox=function()return nil end}
H.run={Heartbeat=event()}
H.game={GetService=function(_,name)return ({Players={LocalPlayer=H.player},ReplicatedStorage=replicated,ProximityPromptService=H.prompts,UserInputService=H.input,RunService=H.run,TweenService={Create=function(_,target,_,props)return {Play=function()for k,v in pairs(props)do target[k]=v end end}end},AssetService={CreateEditableImage=function()error('Unavailable: test embedded image fallback')end}})[name]end}
H.TweenInfo={new=function()return {}end}
H.warn=function(message)H.warning=message end
function H.all()return H.playerGui:GetDescendants()end
function H.find(text)
    for _,n in ipairs(H.all())do if n:IsA('TextButton') and n.Text and (n.Name==text or n.Text==text or n.Text:find(text,1,true))then return n end end
    error('Button missing '..text)
end
function H.gui()return assert(H.playerGui:FindFirstChild('SiriaiTraining'))end
return H
