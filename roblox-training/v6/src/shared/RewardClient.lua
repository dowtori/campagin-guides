-- Each player sees and collides with only their earned, visible sculpture.
-- Celebration belongs to CampusClient's existing header, not another overlay.
local Client={}
function Client.start(gui,onChallenge,canInteract)
 local config=require(script.Parent:WaitForChild('ThumbData'))
 local Policy=require(script.Parent:WaitForChild('RewardPolicy'))
 local model=workspace:WaitForChild('TrainingMap'):FindFirstChild('PierThumbsUp',true)
 local player=game:GetService('Players').LocalPlayer
 local origin=Vector3.new(unpack(config.origin));local parts={};local stage=-1;local desired=0
 for _,p in ipairs(model:GetChildren())do
  if p:IsA('BasePart') then table.insert(parts,{part=p,offset=p.Position-origin,rotation=p.CFrame.Rotation,size=p.Size,color=p.Color,level=p:WaitForChild('ThumbStage').Value}) end
 end
 local eligible=false;local detectors={};local prompt
 local function allowed()return eligible and (not canInteract or canInteract())end
 local function challenge()if allowed() and onChallenge then onChallenge()end end
 for _,v in ipairs(parts)do
  local detector=Instance.new('ClickDetector');detector.Name='ThumbChallengeClick';detector.MaxActivationDistance=0;detector.Parent=v.part
  detector.MouseClick:Connect(challenge);table.insert(detectors,{detector=detector,part=v.part})
  if v.level==0 then
   prompt=Instance.new('ProximityPrompt');prompt.Name='ThumbChallengePrompt';prompt.ActionText='도전하기';prompt.ObjectText='따봉 챌린지';prompt.KeyboardKeyCode=Enum.KeyCode.E
   prompt.HoldDuration=0;prompt.MaxActivationDistance=20;prompt.RequiresLineOfSight=false;prompt.Enabled=false;prompt.Parent=v.part;prompt.Triggered:Connect(challenge)
  end
 end
 local function interaction()
  local enabled=allowed()
  if prompt then prompt.Enabled=enabled end
  for _,v in ipairs(detectors)do v.detector.MaxActivationDistance=enabled and v.part.Transparency==0 and 26 or 0 end
 end
 local function pose(target)
  local item=config.stages[target+1]
  local targetOrigin=item.origin and Vector3.new(unpack(item.origin)) or origin
  for _,v in ipairs(parts)do
   local p=v.part;local k=v.level==0 and 1 or item.scale;local anchor=Vector3.new(0,.486,0)
   local visible=table.find(item.groups,v.level)~=nil
   local position=targetOrigin+anchor+(v.offset-anchor)*k
   local size=v.size*k
   if v.level==0 then
    position=origin+v.offset
    if item.pedestal then position=Vector3.new(unpack(item.pedestal.position));size=Vector3.new(unpack(item.pedestal.size))end
   end
   p.Size=size;p.CFrame=CFrame.new(position)*v.rotation
   p.Transparency=visible and 0 or 1;p.CanCollide=visible;p.CanQuery=visible;p.CanTouch=false
   p.Color=v.level>0 and Color3.fromRGB(unpack(item.color)) or v.color
   p.Material=Enum.Material.SmoothPlastic
  end
  stage=target
 end
 local function clearForGrowth()
  local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
  if not root then return true end
  local function occupied(index)
   local bounds=config.stages[index+1].bounds;local p=root.Position
   return p.X>=bounds.min[1]-3 and p.X<=bounds.max[1]+3
    and p.Y>=bounds.min[2]-4 and p.Y<=bounds.max[2]+4
    and p.Z>=bounds.min[3]-3 and p.Z<=bounds.max[3]+3
  end
  -- Never grow around an avatar or remove a sculpture while they stand on it.
  return not occupied(desired) and (stage<0 or not occupied(stage))
 end
 local function applyPending()
  if desired~=stage and clearForGrowth() then pose(desired)end
  interaction()
 end
 pose(0)
 game:GetService('RunService').Heartbeat:Connect(applyPending)
 return {sync=function(s)
  local r=Policy.summary(s);desired=r.stage;eligible=r.unlocked and not r.king;applyPending();return r
 end}
end
return Client
