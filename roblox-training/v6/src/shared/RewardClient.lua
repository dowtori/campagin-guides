-- Every player sees the evolution they earned; other players cannot overwrite it.
local Client={}
function Client.start(gui,notice)
 local config=require(script.Parent:WaitForChild('ThumbData'))
 local Policy=require(script.Parent:WaitForChild('RewardPolicy'))
 local model=workspace:WaitForChild('TrainingMap'):FindFirstChild('PierThumbsUp',true)
 local origin=Vector3.new(unpack(config.origin));local parts={};local stage=-1;local serial=0
 for _,p in ipairs(model:GetChildren())do
  if p:IsA('BasePart') then table.insert(parts,{part=p,offset=p.Position-origin,rotation=p.CFrame.Rotation,size=p.Size,color=p.Color,level=p:WaitForChild('ThumbStage').Value}) end
 end
 local function pose(target,scale,bob)
  for _,v in ipairs(parts)do
   local p=v.part;p.Size=v.size*scale;p.CFrame=CFrame.new(origin+v.offset*scale+Vector3.new(0,bob or 0,0))*v.rotation
   p.Transparency=v.level<=target and not (v.level==8 and target==10) and 0 or 1
   p.Color=target>=7 and v.level==0 and not p.Name:find('pedestal') and Color3.fromRGB(255,206,83) or v.color
   p.Material=(v.level==6 or (target==10 and v.level==10 and p.Name:find('jewel'))) and Enum.Material.Neon or Enum.Material.SmoothPlastic
  end
 end
 -- A small non-blocking 3D preview of the actual sculpture accompanies each growth.
 local preview=Instance.new('ViewportFrame');preview.Name='ThumbEvolution';preview.Size=UDim2.fromOffset(160,190);preview.Position=UDim2.new(0,18,1,-340);preview.BackgroundTransparency=1;preview.Visible=false;preview.Active=false;preview.Ambient=Color3.fromRGB(220,211,190);preview.LightColor=Color3.fromRGB(255,244,218);preview.Parent=gui
 local camera=Instance.new('Camera');camera.Parent=preview;preview.CurrentCamera=camera
 local function showPreview(token)
  local old=preview:FindFirstChild('RewardModel');if old then old:Destroy()end
  local copy=model:Clone();copy.Name='RewardModel';copy.Parent=preview
  local scale=config.stages[stage+1].scale
  camera.CFrame=CFrame.lookAt(origin+Vector3.new(11,7,20)*scale,origin+Vector3.new(0,3,0)*scale);camera.FieldOfView=34
  local work=gui:FindFirstChild('WorkPanel')
  preview.Visible=not(work and work.Visible and work.AbsolutePosition.X<190)
  task.delay(5,function()if serial==token then preview.Visible=false end end)
 end
 local function sync(s)
  local r=Policy.summary(s);if r.stage==stage then return r end
  local previous=stage;stage=r.stage;serial+=1;local token=serial
  local oldScale=config.stages[math.max(0,previous)+1].scale;local targetScale=config.stages[stage+1].scale
  if previous<0 or stage<previous then pose(stage,targetScale);return r end
  local start=os.clock();local connection
  connection=game:GetService('RunService').RenderStepped:Connect(function()
   if serial~=token then connection:Disconnect();return end
   local t=math.min(1,(os.clock()-start)/.65);local ease=1-(1-t)^3
   pose(stage,oldScale+(targetScale-oldScale)*ease,math.sin(t*math.pi)*.7)
   if t>=1 then connection:Disconnect();showPreview(token)end
  end)
  -- Let the normal chapter transition finish before placing a short reward line.
  task.delay(.75,function()if serial==token then notice(config.stages[stage+1].title..'!  ·  게임 점수 '..r.score..'점')end end)
  return r
 end
 return {sync=sync}
end
return Client
