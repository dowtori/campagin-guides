-- Native Terrain water, a continuous seabed, and nonlethal return from map bounds.
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local data=require(script.Parent:WaitForChild('CoastData'))
local Coast=require(script.Parent:WaitForChild('Coast'))
local terrain=workspace.Terrain
local map=workspace:WaitForChild('TrainingMap')
local previews=map:WaitForChild('Architecture'):WaitForChild('CoastPreview')
local oceanPreviews=map:WaitForChild('Architecture'):WaitForChild('OceanPreview')
workspace:SetAttribute('SiriaiWorldVersion','6.11')
workspace:SetAttribute('SiriaiOceanReady',false)
workspace:SetAttribute('SiriaiTerrainReady',false)
workspace:SetAttribute('SiriaiTerrainChunks',0)
workspace:SetAttribute('SiriaiOceanStatus','해안과 바다를 준비하고 있어요')
workspace.FallenPartsDestroyHeight=-4096
workspace.GlobalWind=Vector3.new(4,0,1.5)
terrain.WaterColor=Color3.fromHex(data.waterColor)
terrain.WaterWaveSize=data.waveSize
terrain.WaterWaveSpeed=data.waveSpeed
terrain.WaterTransparency=data.waterTransparency
terrain.WaterReflectance=data.waterReflectance
for material,color in pairs(data.materialColors)do terrain:SetMaterialColor(Enum.Material[material],Color3.fromHex(color))end

-- This rescue never changes Health or training progress, and runs before terrain work.
local clock=0
RunService.Heartbeat:Connect(function(dt)
    clock+=dt;if clock<.15 then return end;clock=0
    for _,player in ipairs(Players:GetPlayers())do
        local character=player.Character
        local root=character and character:FindFirstChild('HumanoidRootPart')
        local humanoid=character and character:FindFirstChildOfClass('Humanoid')
        if root and humanoid and humanoid.Health>0 then
            local p=root.Position;local destination=Coast.rescue(data,p.X,p.Y,p.Z)
            if destination then
                root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
                character:PivotTo(CFrame.new(destination[1],destination[2],destination[3]))
            end
        end
    end
end)

local ok,reason=xpcall(function()
    local ocean=data.ocean
    -- Keep each native terrain edit well below the engine voxel region limit.
    local left=ocean.center[1]-ocean.size[1]/2
    local back=ocean.center[3]-ocean.size[3]/2
    for x=0,ocean.size[1]-1,600 do for z=0,ocean.size[3]-1,560 do
        local sx,sz=math.min(600,ocean.size[1]-x),math.min(560,ocean.size[3]-z)
        local cx,cz=left+x+sx/2,back+z+sz/2
        terrain:FillBlock(CFrame.new(cx,ocean.center[2],cz),Vector3.new(sx,ocean.size[2],sz),Enum.Material.Water)
        terrain:FillBlock(CFrame.new(cx,-44,cz),Vector3.new(sx,8,sz),Enum.Material.Sand)
        task.wait()
    end end
    -- Native water is ready now. A later mountain error must not leave glass
    -- covering the engine's waves/reflections for the entire play session.
    for _,p in ipairs(oceanPreviews:GetChildren())do if p:IsA('BasePart')then p.Transparency=1;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false end end
    workspace:SetAttribute('SiriaiOceanReady',true)
    workspace:SetAttribute('SiriaiOceanStatus','Water ready; building coastline')
    local completed=0
    local r=data.voxelSize
    local nx=(data.nx-1)*data.step/r;local nz=(data.nz-1)*data.step/r
    local chunk=data.chunkCells
    local channelsSupported=true
    for sx=0,nx-1,chunk do
        for sz=0,nz-1,chunk do
            local dx,dz=math.min(chunk,nx-sx),math.min(chunk,nz-sz)
            -- Only write as high as each chunk needs, including the interpolation boundary.
            local top=data.seaLevel+8
            for x=0,dx,2 do for z=0,dz,2 do
                top=math.max(top,Coast.height(data,data.x0+(sx+x)*r,data.z0+(sz+z)*r)+8)
            end end
            local upper=math.min(data.maxY,math.ceil(top/r)*r)
            local ny=(upper-data.minY)/r
            -- Height is constant along a column. Sample once, not once per Y voxel.
            local heights={}
            for x=1,dx do
                heights[x]={}
                for z=1,dz do heights[x][z]=Coast.height(data,data.x0+(sx+x-.5)*r,data.z0+(sz+z-.5)*r) end
            end
            local materials,solids,liquids={},{},{}
            for x=1,dx do
                materials[x]={};solids[x]={};liquids[x]={}
                for y=1,ny do
                    materials[x][y]={};solids[x][y]={};liquids[x][y]={}
                    for z=1,dz do
                        local name,solid,liquid=Coast.voxelAtHeight(data,heights[x][z],data.minY+(y-1)*r)
                        materials[x][y][z]=Enum.Material[name];solids[x][y][z]=solid;liquids[x][y][z]=liquid
                    end
                end
            end
            local low=Vector3.new(data.x0+sx*r,data.minY,data.z0+sz*r)
            local high=low+Vector3.new(dx*r,ny*r,dz*r)
            local region=Region3.new(low,high):ExpandToGrid(r)
            local written=false
            if channelsSupported then
                written=pcall(function()terrain:WriteVoxelChannels(region,r,{SolidMaterial=materials,SolidOccupancy=solids,LiquidOccupancy=liquids})end)
                if not written then channelsSupported=false end
            end
            if not written then
                -- Compatibility for older Studio versions: actual water voxels, no glass fallback.
                for x=1,dx do for y=1,ny do for z=1,dz do
                    if solids[x][y][z]<=0 then
                        materials[x][y][z]=liquids[x][y][z]>0 and Enum.Material.Water or Enum.Material.Air
                        solids[x][y][z]=liquids[x][y][z]
                    end
                end end end
                terrain:WriteVoxels(region,r,materials,solids)
            end
            completed+=1;workspace:SetAttribute('SiriaiTerrainChunks',completed)
            task.wait()
        end
    end
    for _,p in ipairs(previews:GetChildren())do if p:IsA('BasePart')then p.Transparency=1;p.CanCollide=false;p.CanQuery=false end end
    workspace:SetAttribute('SiriaiTerrainReady',true)
    workspace:SetAttribute('SiriaiOceanStatus','얕은 물가와 수영 가능한 바다')
end,debug.traceback)
if not ok then
    workspace:SetAttribute('SiriaiOceanStatus','Terrain build failed; saved land and rescue retained')
    workspace:SetAttribute('SiriaiTerrainError',tostring(reason))
    warn('[SIRIAI Coast] '..tostring(reason))
end
