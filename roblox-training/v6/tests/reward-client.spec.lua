local H=require('./ClientHarness')
local config=require('./ThumbData')
local fixture=require('./ThumbFixture')
H.now=0;H.delayed={};H.task.delay=function(_,fn)table.insert(H.delayed,fn)end
H.run.RenderStepped=H.Mock.event()
local V=getmetatable(H.Vector3.new(0,0,0))
V.__add=function(a,b)return H.Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
V.__mul=function(a,b)return H.Vector3.new(a.X*b,a.Y*b,a.Z*b)end
local CF={};CF.__index=CF;CF.__mul=function(a,b)return a end
H.CFrame={new=function(v)return setmetatable({Position=v,Rotation={}},CF)end,lookAt=function(v,t)return {Position=v,Target=t}end}
local map=H.workspace:FindFirstChild('TrainingMap')
local model=H.Instance.new('Model');model.Name='PierThumbsUp';model.Parent=map
local mt=getmetatable(model);local old=mt.__index
local function clone(o)
 local c=H.Instance.new(o.ClassName);for k,v in pairs(o.props)do if k~='Parent' then c[k]=v end end
 for _,child in ipairs(o:GetChildren())do local copy=clone(child);copy.Parent=c end
 return c
end
mt.__index=function(self,key)
 if key=='IsA' then return function(o,name)return o.ClassName==name or name=='BasePart' and o.ClassName=='Part' end end
 if key=='Clone' then return clone end
 return old(self,key)
end
for _,v in ipairs(fixture)do
 local p=H.Instance.new('Part');p.Name=v.name;p.Position=H.Vector3.new(unpack(v.position));p.Size=H.Vector3.new(unpack(v.size));p.Color=v.color;p.CFrame=H.CFrame.new(p.Position);p.Parent=model
 local tag=H.Instance.new('IntValue');tag.Name='ThumbStage';tag.Value=v.level;tag.Parent=p
end
local notifications={}
local reward=require('./RewardClient').start(H.gui,function(t)table.insert(notifications,t)end)
local state={completed={}};local n=0
local function check(v,m)n+=1;assert(v,m)end
reward.sync(state)
local base=model:GetChildren()[1];local plinth=base.Size.X;local lastHeight=0
local function checkPose(index)
 local item=config.stages[index+1];local visible=0;local top=-math.huge;local bottom=math.huge
 for _,p in ipairs(model:GetChildren())do
  local level=p:FindFirstChild('ThumbStage').Value
  local active=table.find(item.groups,level)~=nil
  check(p.Transparency==(active and 0 or 1),'exactly current silhouette visible')
  check(p.CanCollide==active and p.CanQuery==active and p.CanTouch==false,'only visible physical silhouette collides and can be queried')
  if level>0 and p.Transparency==0 then
   visible+=1;check(level==index+1,'no old-stage overlap')
  end
 end
 check(base.Size.X==(item.pedestal and item.pedestal.size[1] or plinth),'normal plinth unchanged; king has offshore seabed support')
 local target=item.origin or config.origin
 for _,p in ipairs(model:GetChildren())do
  local level=p:FindFirstChild('ThumbStage').Value
  if table.find(item.groups,level) then
   if level==0 and item.pedestal then
    check(p.CFrame.Position.X==item.pedestal.position[1] and p.CFrame.Position.Z==item.pedestal.position[3],'king plinth at offshore position')
   elseif level>0 then
    check(p.CFrame.Position.Z< (index==10 and -385 or -317),'hand is at correct stage location')
   end
  end
 end
 check(visible>0 and visible<=28,'compact native silhouette exists')
 local height=(item.thumbHeight-.54)*.9*item.scale
 check(height>lastHeight,'actual hand height grows');lastHeight=height
end
checkPose(0)
for i,id in ipairs({'brief','profile','connect','discover','send','reply','settle'})do
 state.completed[id]=true;reward.sync(state);H.now+=1;H.run.RenderStepped:Fire()
 for _,fn in ipairs(H.delayed)do fn()end;H.delayed={}
 checkPose(i)
 check(#notifications==0,'growth does not add detached toasts')
end
local count=#notifications;reward.sync(state);check(#notifications==count,'same phase no duplicate')
state.advanced={completed={}}
for i,id in ipairs({'scout','fee','conditions'})do
 state.advanced.completed[id]=true;reward.sync(state);H.now+=1;H.run.RenderStepped:Fire()
 for _,fn in ipairs(H.delayed)do fn()end;H.delayed={}
 checkPose(7+i)
end
for _,p in ipairs(model:GetChildren())do
 local level=p:FindFirstChild('ThumbStage').Value
 check(p.Transparency==(table.find(config.stages[11].groups,level) and 0 or 1),'king only shows one unadorned hand and its fixed pedestal')
 check(type(p.Material)=='string','valid enum material')
end
check(#notifications==0,'no separate king toast')
for _,value in ipairs(notifications)do check(not value:find('점'),'reward notice excludes game points')end
check(H.gui:FindFirstChild('ThumbEvolution')==nil,'detached 3D thumbnail removed')
local root=H.player.Character:FindFirstChild('HumanoidRootPart')
root.Position=H.Vector3.new(unpack(config.origin))
reward.sync({completed={}});H.run.Heartbeat:Fire(.1)
for _,p in ipairs(model:GetChildren())do
 local level=p:FindFirstChild('ThumbStage').Value
 check(p.CanCollide==(level==0 or level==11),'pose stays solid while avatar occupies growth area')
end
root.Position=H.Vector3.new(0,4,0);H.run.Heartbeat:Fire(.1)
for _,p in ipairs(model:GetChildren())do
 local level=p:FindFirstChild('ThumbStage').Value
 check(p.CanCollide==(level==0 or level==1),'pending pose applied after leaving; old pose cannot block')
end
local independent={completed={brief=true}}
reward.sync(independent);H.run.Heartbeat:Fire(.1)
for _,p in ipairs(model:GetChildren())do
 local level=p:FindFirstChild('ThumbStage').Value
 check(p.CanCollide==(level==0 or level==2),'visible stage remains solid on another progression')
end
-- Remote king footprint must also defer growth, not only the old pier footprint.
root.Position=H.Vector3.new(-165,5,-470)
reward.sync(state);H.run.Heartbeat:Fire(.1)
check(base.CFrame.Position.Z==config.origin[3],'king waits while local avatar occupies offshore target')
root.Position=H.Vector3.new(0,4,-326);H.run.Heartbeat:Fire(.1)
check(base.CFrame.Position.Z==-470,'king appears when offshore target clear; pier viewer remains free')
root.Position=H.Vector3.new(-165,220,-470)
reward.sync(independent);H.run.Heartbeat:Fire(.1)
check(base.CFrame.Position.Z==-470,'do not remove king under avatar standing near top')
root.Position=H.Vector3.new(0,4,-326);H.run.Heartbeat:Fire(.1)
check(base.CFrame.Position.Z==config.origin[3],'restores normal pier pedestal after leaving king')
print('PASS: '..n..' exported reward-client checks; all growth stages, silhouettes, fixed pedestal, materials, visible collision, hidden-stage clearance and safe pending growth')
