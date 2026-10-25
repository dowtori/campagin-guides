-- Only nearby reed clusters move. Each sway starts at the original ground pivot.
local RunService = game:GetService('RunService')
local folder = workspace:WaitForChild('TrainingMap'):WaitForChild('Architecture'):WaitForChild('MeadowReeds')
local reeds, active = {}, {}
for _, model in ipairs(folder:GetChildren()) do
    if model:IsA('Model') then
        local base = model:GetPivot()
        local ground = CFrame.new(base.Position.X,0.2,base.Position.Z)
        table.insert(reeds,{model=model,base=base,ground=ground,offset=ground:ToObjectSpace(base),phase=base.Position.X*.07+base.Position.Z*.05})
    end
end
local elapsed, selectionClock, drawClock = 0,2,0
RunService.Heartbeat:Connect(function(dt)
    elapsed += dt
    selectionClock += dt
    drawClock += dt
    if selectionClock > 1.5 then
        selectionClock = 0
        for _, reed in ipairs(active) do reed.model:PivotTo(reed.base) end
        active = {}
        local camera = workspace.CurrentCamera
        if camera then
            local candidates = {}
            for _, reed in ipairs(reeds) do
                local delta = reed.base.Position-camera.CFrame.Position
                local distance = delta:Dot(delta)
                if distance < 10000 then table.insert(candidates,{reed=reed,distance=distance}) end
            end
            table.sort(candidates,function(a,b)return a.distance<b.distance end)
            for i=1,math.min(40,#candidates) do table.insert(active,candidates[i].reed) end
        end
    end
    if drawClock < 0.083 then return end
    drawClock = 0
    for _, reed in ipairs(active) do
        local sway=math.sin(elapsed*.85+reed.phase)*.035
        reed.model:PivotTo(reed.ground*CFrame.Angles(sway*.3,0,sway)*reed.offset)
    end
end)
