-- Late replication is handled for every image panel, including panels that arrive after startup.
local shared=game:GetService('ReplicatedStorage'):WaitForChild('TrainingShared')
local Raster=require(shared:WaitForChild('RasterRenderer'))
local map=workspace:WaitForChild('TrainingMap')
local seen={}
local function render(node)
    if not node:IsA('SurfaceGui') or node.Name~='RasterArt' or seen[node] then return end
    seen[node]=true
    task.spawn(function()
        local parent=node.Parent;if not parent then return end
        local key=parent:WaitForChild('RasterKey',15)
        if key and node.Parent then Raster.upgrade(node,key.Value) end
    end)
end
map.DescendantAdded:Connect(render)
for _,node in ipairs(map:GetDescendants())do render(node)end
