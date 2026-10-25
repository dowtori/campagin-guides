-- WindShake drives one root per complete CC0 clump; rigid faces follow together.
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('CampusShared')
local Wind=require(Shared:WaitForChild('ThirdParty'):WaitForChild('WindShake'))
local Run=game:GetService('RunService')
local Lighting=game:GetService('Lighting')
local root=workspace:WaitForChild('TrainingMap'):WaitForChild('Architecture')
local folder=root:WaitForChild('MeadowReeds')
Wind:Init();Wind.RenderDistance=85;Wind.MaxRefreshRate=1/30
Wind:SetDefaultSettings({WindDirection=Vector3.new(1,0,.35),WindSpeed=9,WindPower=.5})
local clumps={}
for _,model in ipairs(folder:GetChildren())do
 local anchor=model:FindFirstChild('Grass wind root')
 if anchor then
  local entry={anchor=anchor,parts={},offsets={},last=anchor.CFrame}
  for _,p in ipairs(model:GetChildren())do
   if p:IsA('BasePart') and p~=anchor then
    table.insert(entry.parts,p);table.insert(entry.offsets,anchor.CFrame:ToObjectSpace(p.CFrame))
   end
  end
  Wind:AddObjectShake(anchor);table.insert(clumps,entry)
 end
end
local parts,frames={},{}
Run.Heartbeat:Connect(function()
 table.clear(parts);table.clear(frames)
 for _,c in ipairs(clumps)do
  local frame=c.anchor.CFrame
  if frame~=c.last then
   c.last=frame
   for i,p in ipairs(c.parts)do table.insert(parts,p);table.insert(frames,frame*c.offsets[i])end
  end
 end
 if #parts>0 then workspace:BulkMoveTo(parts,frames,Enum.BulkMoveMode.FireCFrameChanged)end
end)
-- The visible disc uses the same direction as native shadows and water reflection.
-- Camera-relative placement prevents parallax from separating it from the real sun.
local sun=root:WaitForChild('Setting sun')
Run:BindToRenderStep('SiriaiSun',Enum.RenderPriority.Camera.Value+1,function()
 local camera=workspace.CurrentCamera
 if camera then sun.CFrame=CFrame.new(camera.CFrame.Position+Lighting:GetSunDirection()*1250)end
end)
