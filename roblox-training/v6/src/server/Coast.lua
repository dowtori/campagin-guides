-- Pure sampling/voxel logic shared by terrain construction and regression tests.
local Coast={}
local function clamp(v,lo,hi)return math.max(lo,math.min(hi,v))end
function Coast.height(data,x,z)
    local gx=clamp((x-data.x0)/data.step,0,data.nx-1)
    local gz=clamp((z-data.z0)/data.step,0,data.nz-1)
    local ix,iz=math.floor(gx),math.floor(gz)
    local ax,az=gx-ix,gz-iz
    local function h(dx,dz)
        return data.heights[math.min(ix+dx,data.nx-1)*data.nz+math.min(iz+dz,data.nz-1)+1]
    end
    local a=h(0,0)*(1-ax)+h(1,0)*ax
    local b=h(0,1)*(1-ax)+h(1,1)*ax
    return a*(1-az)+b*az
end
function Coast.voxelAtHeight(data,h,y)
    local solid=clamp((h-y)/data.voxelSize,0,1)
    local liquid=clamp((data.seaLevel-y)/data.voxelSize,0,1)
    if solid>1-1/256 then liquid=0 end -- Full solid voxels cannot contain water.
    local material=solid<=0 and 'Air' or (h<-.15 and 'Sand' or (h>44 and 'Rock' or 'Grass'))
    return material,solid,liquid
end
function Coast.voxel(data,x,y,z)
    return Coast.voxelAtHeight(data,Coast.height(data,x,z),y)
end
function Coast.rescue(data,x,y,z)
    local r=data.rescue
    if y>=r.minY and math.abs(x)<=r.maxX and z>=r.minZ and z<=r.maxZ then return nil end
    return z<-200 and r.shore or r.arrival
end
return Coast
