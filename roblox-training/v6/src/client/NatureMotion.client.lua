local Shared=game:GetService('ReplicatedStorage'):WaitForChild('CampusShared')
local Wind=require(Shared:WaitForChild('ThirdParty'):WaitForChild('WindShake'))
local Run=game:GetService('RunService')
local root=workspace:WaitForChild('TrainingMap'):WaitForChild('Architecture')
local folder=root:WaitForChild('MeadowReeds')
Wind:Init();Wind.RenderDistance=90;Wind.MaxRefreshRate=1/30
Wind:SetDefaultSettings({WindDirection=Vector3.new(1,0,.35),WindSpeed=6,WindPower=.15})
for _,p in ipairs(folder:GetDescendants())do
 if p:IsA('BasePart') and (p.Name=='Reed leaf' or p.Name=='Reed leaf back' or p.Name=='Reed plume')then p.PivotOffset=CFrame.new(0,-p.Size.Y*.47,0);Wind:AddObjectShake(p)end
end
local clouds={}
for i,model in ipairs(root:WaitForChild('DriftingClouds'):GetChildren())do table.insert(clouds,{model=model,base=model:GetPivot(),phase=i})end
local elapsed,refresh=0,0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;refresh+=dt;if refresh<1/20 then return end;refresh=0
 for _,c in ipairs(clouds)do c.model:PivotTo(c.base*CFrame.new(math.sin(elapsed*.013+c.phase)*18,math.sin(elapsed*.01+c.phase)*1.2,math.cos(elapsed*.012+c.phase)*8))end
end)
