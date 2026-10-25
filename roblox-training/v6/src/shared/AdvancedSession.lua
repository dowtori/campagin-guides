-- Server-owned sessions; the adapter supplies Roblox I/O.
local Session={}
function Session.new(Engine,data,Reward,env)
 local S={};local active={}
 local function inside(player)
  local p=env.position(player);if not p then return false end
  local c,h=data.room.center,data.room.halfSize
  return math.abs(p.X-c[1])<h[1] and math.abs(p.Y-c[2])<h[2] and math.abs(p.Z-c[3])<h[3]
 end
 local function emit(player)
  local s=env.state(player);env.send(player,{run=s.advanced and s.advanced.run,reward=Reward.summary(s),cleared=s.advanced and s.advanced.completed or {}});env.sync(player)
 end
 function S.leave(player)
  if active[player] then Engine.leave(env.state(player));active[player]=nil;emit(player) end
 end
 function S.handle(player,p)
  if type(p)~='table' or type(p.kind)~='string' then return end
  local s=env.state(player)
  if not Reward.summary(s).unlocked then env.notice(player,'기본 챕터를 모두 마치면 열려요.');return end
  if p.kind=='leave' then S.leave(player);return end
  if p.kind=='enter' then
   if not Engine.challenge(data,p.id) or not env.position(player) then return end
   if not inside(player) then env.travel(player,data.room.arrival,data.room.lookAt) end
   if Engine.enter(s,p.id,data,env.rotation()) then active[player]=true;emit(player) end
   return
  end
  if not active[player] or not inside(player) then S.leave(player);return end
  local run=s.advanced and s.advanced.run
  if not run or p.token~=run.token then return end
  local changed=false;local wasKing=Reward.summary(s).king
  if p.kind=='start' then changed=Engine.start(s,p.token,data,env.clock())
  elseif p.kind=='answer' then changed=Engine.answer(s,p.token,p.slot,data,env.clock())
  elseif p.kind=='retry' and run.status~='active' then changed=Engine.enter(s,run.id,data,env.rotation()) end
  if changed then
   if not wasKing and Reward.summary(s).king and env.kingReward then
    Engine.leave(s);active[player]=nil;env.kingReward(player)
   end
   emit(player)
   if not wasKing and Reward.summary(s).king and env.showKing then env.showKing(player)end
  end
 end
 function S.tick()
  for player in pairs(active) do
   if not inside(player) then S.leave(player)
   elseif Engine.tick(env.state(player),env.clock()) then emit(player) end
  end
 end
 function S.reset(player)active[player]=nil;emit(player)end
 function S.remove(player)active[player]=nil end
 return S
end
return Session
