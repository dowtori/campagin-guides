-- Native terrain water. The authored fallback surface remains if terrain creation fails.
local terrain = workspace.Terrain
local map = workspace:WaitForChild('TrainingMap')
local architecture = map:WaitForChild('Architecture')
local fallback = architecture:FindFirstChild('Lake water preview')
terrain.WaterColor = Color3.fromRGB(143,121,168)
terrain.WaterWaveSize = 0.13
terrain.WaterWaveSpeed = 6
terrain.WaterTransparency = 0.3
terrain.WaterReflectance = 0.5
workspace.GlobalWind = Vector3.new(5,0,2)
local ok, reason = pcall(function()
    terrain:FillBlock(CFrame.new(0,-3,-1450), Vector3.new(3000,4,2300), Enum.Material.Water)
end)
if ok and fallback then fallback.Transparency = 1 end
if not ok then warn('[SIRIAI] Lake fallback retained: '..tostring(reason)) end
