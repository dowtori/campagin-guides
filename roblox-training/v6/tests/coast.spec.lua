local Coast=require('./Coast')
local d=require('./CoastData')
local n=0
local function expect(v,m)n+=1;assert(v,m)end
for _,p in ipairs({{0,100},{-34,42},{-50,-55},{46,-44}})do expect(Coast.height(d,p[1],p[2])>=0 and Coast.height(d,p[1],p[2])<.5,'all job areas remain dry and flat')end
for x=-1000,1000,80 do for z=-1080,740,80 do expect(Coast.rescue(d,x,-5,z)==nil,'swimming and normal exploration do not kill or return a player')end end
for x=-720,720,60 do for z=-940,700,60 do for y=-40,172,12 do
 local mat,solid,liquid=Coast.voxel(d,x,y,z)
 expect(solid>=0 and solid<=1 and liquid>=0 and liquid<=1,'valid native occupancy')
 expect(solid<1-1/256 or liquid==0,'no liquid in full solid cells')
end end end
expect(Coast.height(d,300,110)>50,'connected ridge has actual height')
expect(Coast.height(d,-480,-604)>130,'offshore peaks are actual terrain')
expect(d.seaLevel-Coast.height(d,0,-550)>25,'deep offshore water')
expect(Coast.rescue(d,0,-39,-500)~=nil,'fall below seabed returns alive')
expect(Coast.rescue(d,0,0,800)~=nil,'outside the world returns alive')
print('PASS: '..n..' coast, ridge, native water channel and nonlethal rescue checks')
