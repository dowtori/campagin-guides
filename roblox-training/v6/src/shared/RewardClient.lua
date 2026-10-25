-- Each player sees and collides with only their earned, visible sculpture.
-- Celebration belongs to CampusClient's existing header, not another overlay.
local Client={}
function Client.start(gui)
 local config=require(script.Parent:WaitForChild('ThumbData'))
 local Policy=require(script.Parent:WaitForChild('RewardPolicy'))
 local model=workspace:WaitForChild('TrainingMap'):FindFirstChild('PierThumbsUp',true)
 local player=game:GetService('Players').LocalPlayer
 local origin=Vector3.new(unpack(config.origin));local parts={};local stage=-1;local desired=0
 for _,p in ipairs(model:GetChildren())do
  if p:IsA('BasePart') then table.insert(parts,{part=p,offset=p.Position-origin,rotation=p.CFrame.Rotation,size=p.Size,color=p.Color,level=p:WaitForChild('ThumbStage').Value}) end
 end
 local function pose(target)
  local item=config.stages[target+1]
  for _,v in ipairs(parts)do
   local p=v.part;local k=v.level==0 and 1 or item.scale;local anchor=Vector3.new(0,.486,0)
   local visible=table.find(item.groups,v.level)~=nil
   p.Size=v.size*k;p.CFrame=CFrame.new(origin+anchor+(v.offset-anchor)*k)*v.rotation
   p.Transparency=visible and 0 or 1;p.CanCollide=visible;p.CanQuery=visible;p.CanTouch=false
   p.Color=v.level>0 and Color3.fromRGB(unpack(item.color)) or v.color
   p.Material=Enum.Material.SmoothPlastic
  end
  stage=target
 end
 local function clearForGrowth()
  local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
  if not root then return true end
  local d=root.Position-origin
  -- Encloses every possible hand, plus avatar clearance. This is a growth guard,
  -- not an invisible wall: the player can freely walk away before the pose changes.
  return math.abs(d.X)>18 or math.abs(d.Z)>12 or d.Y>30 or d.Y< -5
 end
 local function applyPending()
  if desired~=stage and clearForGrowth() then pose(desired)end
 end
 pose(0)
 game:GetService('RunService').Heartbeat:Connect(applyPending)
 return {sync=function(s)
  local r=Policy.summary(s);desired=r.stage;applyPending();return r
 end}
end
return Client
