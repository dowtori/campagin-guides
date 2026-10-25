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
local base=model:GetChildren()[1];local initial=base.Size.X
for i,id in ipairs({'brief','profile','connect','discover','send','reply','settle'})do
 state.completed[id]=true;reward.sync(state);H.now+=1;H.run.RenderStepped:Fire()
 for _,fn in ipairs(H.delayed)do fn()end;H.delayed={}
 check(base.Size.X>initial,'each phase grows');initial=base.Size.X
 check(notifications[#notifications]:find(config.stages[i+1].title,1,true),'correct title')
end
local count=#notifications;reward.sync(state);check(#notifications==count,'same phase no duplicate')
state.advanced={completed={}}
for i,id in ipairs({'scout','fee','conditions'})do
 state.advanced.completed[id]=true;reward.sync(state);H.now+=1;H.run.RenderStepped:Fire()
 for _,fn in ipairs(H.delayed)do fn()end;H.delayed={}
end
for _,p in ipairs(model:GetChildren())do
 local level=p:FindFirstChild('ThumbStage').Value
 check(p.Transparency==(level==8 and 1 or 0),'king accessories')
 check(type(p.Material)=='string','valid enum material')
end
check(notifications[#notifications]:find('왕따봉',1,true),'king notification')
check(H.gui:FindFirstChild('ThumbEvolution'):FindFirstChild('RewardModel')~=nil,'actual 3D clone preview')
print('PASS: '..n..' exported reward-client checks; all growth stages, accessories, names, materials and 3D reward preview')
