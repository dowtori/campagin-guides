local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Tween=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local Shared=RS:WaitForChild('CampusShared')
local data=require(Shared:WaitForChild('CaseData'))
local Engine=require(Shared:WaitForChild('CaseEngine'))
local remote=RS:WaitForChild('CampusEvent')
local objects=workspace:WaitForChild('TrainingMap'):WaitForChild('Architecture'):WaitForChild('QuestObjects')
-- Complete classic rigs with native joints. The anchored root holds each quest NPC
-- in place; the visible body is an articulated Roblox humanoid, not a loose part pile.
for _,model in ipairs(objects:GetChildren())do
    local humanoid=model:IsA('Model') and model:FindFirstChildOfClass('Humanoid')
    local torso=humanoid and model:FindFirstChild('Torso')
    if torso then
        local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Size=Vector3.new(2,2,1);root.CFrame=torso.CFrame;root.Transparency=1;root.Anchored=true;root.CanCollide=false;root.Parent=model;model.PrimaryPart=root
        humanoid.AutoRotate=false
        local function joint(a,b,name)
            local m=Instance.new('Motor6D');m.Name=name;m.Part0=a;m.Part1=b;m.C0=a.CFrame:ToObjectSpace(b.CFrame);m.Parent=a;b.Anchored=false;b.Massless=true
        end
        joint(root,torso,'RootJoint')
        for _,name in ipairs({'Head','Left Arm','Right Arm','Left Leg','Right Leg'})do local p=model:FindFirstChild(name);if p then joint(torso,p,({Head='Neck',['Left Arm']='Left Shoulder',['Right Arm']='Right Shoulder',['Left Leg']='Left Hip',['Right Leg']='Right Hip'})[name])end end
        for _,p in ipairs(model:GetChildren())do
            if p:IsA('BasePart') and p~=root and p~=torso and not table.find({'Head','Left Arm','Right Arm','Left Leg','Right Leg'},p.Name)then
                local parent=model:FindFirstChild(p.Name=='Right Shoe' and 'Right Leg' or p.Name=='Left Shoe' and 'Left Leg' or p.Name=='Uniform symbol' and 'Torso' or 'Head')
                if parent then local weld=Instance.new('WeldConstraint');weld.Part0=parent;weld.Part1=p;weld.Parent=p;p.Anchored=false;p.Massless=true;p.CanCollide=false end
            end
        end
    end
end
local states={};local targets={}
for _,p in ipairs(objects:GetDescendants())do
    if p:IsA('BasePart') and p:FindFirstChild('ActionID')then targets[p.ActionID.Value]=p end
end
local function state(player)if not states[player]then states[player]=Engine.new()end return states[player]end
local function send(player,kind,extra)
    local packet=extra or {};packet.kind=kind;packet.state=state(player);remote:FireClient(player,packet)
end
local function near(player,target)
    local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
    return root and target and (root.Position-target.Position).Magnitude<=38
end
local function interact(player,id)
    local s=state(player);if s.complete then send(player,'finished');return end
    local phase=data.phases[s.phase]
    local allowed=id==phase.target or (phase.id=='discover' and (id=='tiny_sample' or id=='trip_sample'))
    if not allowed then send(player,'notice',{text='먼저 '..data.phases[s.phase].title..' · 분홍 표식을 따라가세요.'});return end
    if near(player,targets[id])then send(player,'open',{profile=id})end
end
for id,target in pairs(targets)do
    target:WaitForChild('Interact').Triggered:Connect(function(player)interact(player,id)end)
end
local function phone(player)
    if player.Backpack:FindFirstChild('리크루터 폰') or (player.Character and player.Character:FindFirstChild('리크루터 폰'))then return end
    local tool=Instance.new('Tool');tool.Name='리크루터 폰';tool.CanBeDropped=false;tool.RequiresHandle=true;tool.ManualActivationOnly=true;tool.ToolTip='장착하거나 P 키로 이어하기 · 목표 위치 이동'
    local handle=Instance.new('Part');handle.Name='Handle';handle.Size=Vector3.new(.72,1.15,.16);handle.Color=Color3.fromRGB(30,28,35);handle.Material=Enum.Material.SmoothPlastic;handle.CanCollide=false;handle.Massless=true;handle.Parent=tool
    local gui=Instance.new('SurfaceGui');gui.Name='RasterArt';gui.Face=Enum.NormalId.Front;gui.Parent=handle
    local key=Instance.new('StringValue');key.Name='RasterKey';key.Value='logoWhite';key.Parent=handle
    -- Equipped is deliberate. Ordinary world/UI clicks must never open this menu.
    tool.Equipped:Connect(function()send(player,'phone')end);tool.Parent=player.Backpack
end
local function envelope(player)
    local a=targets.Mailbox.Position;local b=targets.beauty_sample.Position
    local p=Instance.new('Part');p.Name='Sent DM envelope';p.Size=Vector3.new(1.5,1,.25);p.Color=Color3.fromRGB(255,35,75);p.Material=Enum.Material.Neon;p.CanCollide=false;p.Anchored=true;p.Position=a+Vector3.new(0,5,0);p.Parent=workspace
    local middle=(a+b)*.5+Vector3.new(0,22,0)
    local first=Tween:Create(p,TweenInfo.new(.65,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=middle})
    first.Completed:Connect(function()Tween:Create(p,TweenInfo.new(.65,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=b+Vector3.new(0,4,0),Transparency=1}):Play()end)
    first:Play();Debris:AddItem(p,2)
end
remote.OnServerEvent:Connect(function(player,packet)
    if type(packet)~='table'then return end
    local s=state(player)
    if packet.kind=='hello'then send(player,'state');if s.phase>1 then phone(player)end
    elseif packet.kind=='interact'then if type(packet.target)=='string'then interact(player,packet.target)end
    elseif packet.kind=='resume' or packet.kind=='travel'then
        if packet.revision~=s.revision then send(player,'state');return end
        if s.complete then send(player,'finished');return end
        local phase=data.phases[s.phase];local target=targets[phase.target]
        local character=player.Character;local root=character and character:FindFirstChild('HumanoidRootPart')
        if not root or not target then return end
        -- Every target has a clear arrival pad in front of it. Clients cannot choose
        -- coordinates or skip a phase; moving never advances the campaign record.
        local destination=target.Position+Vector3.new(0,0,7)
        character:PivotTo(CFrame.lookAt(destination,target.Position))
        root.AssemblyLinearVelocity=Vector3.new(0,0,0)
        root.AssemblyAngularVelocity=Vector3.new(0,0,0)
        if packet.kind=='resume' then send(player,'open',{profile=phase.target})
        else send(player,'arrived',{text=phase.place..'에 도착했어요.'})end
    elseif packet.kind=='apply'then
        if packet.revision~=s.revision or s.complete then send(player,'state');return end
        local phase=data.phases[s.phase]
        if not near(player,targets[phase.target])then send(player,'notice',{text='작업 대상 가까이에서 진행해주세요.'});return end
        local ok,reason=Engine.apply(s,packet.action,packet.payload,data)
        if ok then
            if phase.id=='brief'then phone(player)end
            if phase.id=='send'then envelope(player)end
            send(player,'done',{text=phase.done})
        else send(player,'notice',{text=reason})end
    elseif packet.kind=='home'then
        local character=player.Character
        if character then character:PivotTo(CFrame.new(0,5,100));send(player,'state')end
    elseif packet.kind=='rest'then
        local character=player.Character
        if character then character:PivotTo(CFrame.new(0,5,-326));send(player,'state')end
    elseif packet.kind=='restart' and s.complete then states[player]=Engine.new();send(player,'state')end
end)
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()task.wait(1);if state(player).phase>1 then phone(player)end;send(player,'state')end)
end)
Players.PlayerRemoving:Connect(function(player)states[player]=nil end)
print('[SIRIAI v6.1] Recruiter Island ready: NPC quests, phone tool, one campaign')
