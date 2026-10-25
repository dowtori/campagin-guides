local H={}
local function event()
 local e={listeners={}}
 function e:Connect(fn)table.insert(self.listeners,fn);return {Disconnect=function()end}end
 function e:Fire(...)for _,fn in ipairs(self.listeners)do fn(...)end end
 return e
end
H.Vector3={};local V={}
V.__index=V;function V.__add(a,b)return H.Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
function H.Vector3.new(x,y,z)return setmetatable({X=x,Y=y,Z=z},V)end
H.Vector3.zero=H.Vector3.new(0,0,0)
H.CFrame={new=function(x,y,z)return {Position=H.Vector3.new(x,y,z)}end}
H.Region3={new=function(low,high)return {low=low,high=high,ExpandToGrid=function(self,r)return self end}end}
H.Color3={fromHex=function(v)return v end}
H.Enum={Material=setmetatable({},{__index=function(_,k)return k end})}
H.task={wait=function()end};H.warn=function(m)H.warning=m end
H.run={Heartbeat=event()}
H.root={Position=H.Vector3.new(0,0,60)};H.humanoid={Health=100}
H.character={FindFirstChild=function(_,n)return n=='HumanoidRootPart' and H.root end,FindFirstChildOfClass=function()return H.humanoid end,PivotTo=function(_,cf)H.root.Position=cf.Position;H.returns+=1 end}
H.players={GetPlayers=function()return {{Character=H.character}}end}
H.terrain={}
function H.terrain:SetMaterialColor()end
function H.terrain:FillBlock(cf,size,material)
 if H.failAll then error('simulated terrain API failure')end
 table.insert(H.fills,{position=cf.Position,size=size,material=material})
end
function H.terrain:WriteVoxelChannels(region,resolution,channels)
 if not H.channels then error('simulated older Studio')end
 assert(resolution==4 and channels.SolidMaterial and channels.SolidOccupancy and channels.LiquidOccupancy)
 local dx=(region.high.X-region.low.X)/4;local dz=(region.high.Z-region.low.Z)/4
 assert(#channels.SolidMaterial==dx and #channels.LiquidOccupancy[1][1]==dz,'API dimensions match region')
 H.chunks+=1
end
function H.terrain:WriteVoxels(region,resolution,materials,occupancies)
 assert(resolution==4)
 for _,ys in ipairs(materials)do for _,zs in ipairs(ys)do for _,m in ipairs(zs)do if m=='Water'then H.waterVoxels+=1 end end end end
 H.chunks+=1
end
H.preview={GetChildren=function()return H.previewParts end}
H.oceanPreview={GetChildren=function()return H.oceanParts end}
H.map={WaitForChild=function()return {WaitForChild=function(_,name)return name=='OceanPreview' and H.oceanPreview or H.preview end}end}
H.workspace={Terrain=H.terrain,WaitForChild=function()return H.map end,SetAttribute=function(_,key,value)H.attributes[key]=value end}
H.game={GetService=function(_,name)return name=='Players' and H.players or H.run end}
function H.reset(channels,failAll)
 H.channels=channels;H.failAll=failAll;H.attributes={};H.fills={};H.chunks=0;H.waterVoxels=0;H.returns=0;H.warning=nil
 H.run.Heartbeat.listeners={};H.humanoid.Health=100;H.root.Position=H.Vector3.new(0,0,60)
 H.oceanParts={{Transparency=.22,CanCollide=false,CanTouch=false,CanQuery=false,IsA=function()return true end}}
 H.previewParts={{Transparency=0,CanCollide=true,IsA=function()return true end}}
end
return H
