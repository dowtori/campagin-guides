local E=require('./AdvancedEngine')
local D=require('./AdvancedData')
local R=require('./RewardPolicy')
local Session=require('./AdvancedSession')
local n=0
local function check(v,label)n+=1;assert(v,label)end
local function fresh()
 local s={completed={},record={sent=1,total=2300}}
 for _,id in ipairs({'brief','profile','connect','discover','send','reply','settle'})do s.completed[id]=true end
 return s
end
local function slot(s,correct)
 local run=s.advanced.run;local c=E.challenge(D,run.id)
 for i,j in ipairs(run.order)do if (c.rounds[run.round].options[j].correct==true)==correct then return i end end
end
check(not E.enter({completed={}},'scout',D,0),'locked before basic')
local s=fresh()
check(R.summary(s).score==70 and not R.summary(s).king,'basic reward')
check(E.enter(s,'scout',D,1),'enter')
local t=s.advanced.run.token
check(not s.advanced.run.deadline,'reading untimed')
check(not E.tick(s,999999),'reading never expires')
check(not E.answer(s,t,1,D,1),'no answering before start')
check(E.start(s,t,D,100),'start')
check(s.advanced.run.deadline==130,'exact 30 seconds')
check(not E.start(s,t,D,110),'cannot extend deadline')
check(not E.answer(s,t+1,1,D,101),'stale token')
for _,value in ipairs({0,4,1.5,'1',math.huge,0/0})do check(not E.answer(s,t,value,D,102),'invalid slot')end
check(E.answer(s,t,slot(s,false),D,129.99),'wrong choice')
check(s.advanced.run.status=='failed' and R.summary(s).bonus==0,'no wrong reward')
check(E.enter(s,'scout',D,2),'retry')
check(s.advanced.run.round==2 and s.advanced.run.token~=t and not s.advanced.run.deadline,'new attempt')
check(E.start(s,s.advanced.run.token,D,200),'restart')
check(E.answer(s,s.advanced.run.token,slot(s,true),D,230),'deadline answer')
check(s.advanced.run.status=='timeout' and R.summary(s).bonus==0,'at deadline is timeout')
check(E.enter(s,'scout',D,0),'third attempt')
check(E.start(s,s.advanced.run.token,D,300),'third start')
check(E.answer(s,s.advanced.run.token,slot(s,true),D,329.999),'before deadline passes')
check(R.summary(s).bonusPoints==100,'first award')
for _,id in ipairs({'scout','fee','conditions'})do
 check(E.enter(s,id,D,1),'next entry')
 check(E.start(s,s.advanced.run.token,D,400),'next start')
 if id~='scout' then check(not s.advanced.run.deadline and not E.tick(s,1000000),'NPC untimed')end
 check(E.answer(s,s.advanced.run.token,slot(s,true),D,id=='scout' and 401 or 1000000),'next answer')
end
check(R.summary(s).score==370 and R.summary(s).stage==10 and R.summary(s).king,'king unlocked')
check(s.record.total==2300,'game points separate from compensation')
check(not E.answer(s,s.advanced.run.token,1,D,400),'duplicate award ignored')
s.complete=false;check(R.summary(s).unlocked,'chapter replay keeps unlocked')
E.leave(s);check(not s.advanced.run and R.summary(s).king,'leave preserves reward')
local states={a=fresh(),b=fresh()};local positions={a={X=0,Y=4,Z=0},b={X=0,Y=4,Z=0}}
local clock=0;local sent={};local notices={}
local session=Session.new(E,D,R,{
 state=function(p)return states[p]end,position=function(p)return positions[p]end,
 travel=function(p,v)positions[p]={X=v[1],Y=v[2],Z=v[3]}end,
 clock=function()return clock end,rotation=function()return 0 end,
 send=function(p,packet)sent[p]=packet end,sync=function()end,notice=function(p,t)notices[p]=t end
})
session.handle('a',{kind='enter',id='scout'});check(positions.a.X==60,'server destination')
session.handle('b',{kind='enter',id='fee'});check(states.a.advanced.run.id=='scout','players isolated')
session.handle('a',{kind='start',token=states.a.advanced.run.token})
session.handle('b',{kind='start',token=states.b.advanced.run.token})
clock=30;session.tick()
check(states.a.advanced.run.status=='timeout','heartbeat timeout')
check(states.b.advanced.run.status=='active','NPC not timed out')
session.handle('a',{kind='retry',token=states.a.advanced.run.token});local old=states.a.advanced.run.token
session.handle('a',{kind='start',token=old})
positions.a={X=0,Y=4,Z=0};session.tick();check(not states.a.advanced.run,'walking away cancels')
session.handle('a',{kind='answer',token=old,slot=1});check(R.summary(states.a).bonus==0,'remote answer outside rejected')
session.handle('a',{kind='enter',id='scout'})
positions.a=nil;session.tick();check(not states.a.advanced.run,'death removes attempt')
session.leave('b');check(not states.b.advanced.run,'chapter travel cancels')
print('PASS: '..n..' advanced checks; server deadline, untimed NPCs, easy retry, stale attempts, isolation and unique king reward')
