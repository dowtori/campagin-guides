local RS=game:GetService('ReplicatedStorage')
local Raster=require(RS:WaitForChild('CampusShared'):WaitForChild('RasterRenderer'))
local map=workspace:WaitForChild('TrainingMap')
for _,p in ipairs(map:GetDescendants())do
 local key=p:FindFirstChild('RasterKey')
 if key then local surface=p:FindFirstChild('RasterArt');if surface then Raster.upgrade(surface,key.Value)end end
end

workspace.DescendantAdded:Connect(function(p)
 if p:IsA('StringValue') and p.Name=='RasterKey' then
  task.defer(function()local surface=p.Parent and p.Parent:FindFirstChild('RasterArt');if surface then Raster.upgrade(surface,p.Value)end end)
 end
end)
