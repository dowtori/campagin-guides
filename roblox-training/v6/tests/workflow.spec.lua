-- All revised optional scenarios must work through the real server engine.
local D=require('./AdvancedData');local E=require('./AdvancedEngine');local R=require('./RewardPolicy');local Case=require('./CaseData')
local n=0;local function check(v,m)n+=1;assert(v,m)end
local function fresh()
 local s={completed={},record={total=2300}}
 for _,q in ipairs(Case.phases)do s.completed[q.id]=true end
 return s
end
check(#Case.phases==7,'new exceptions must not add mandatory stages')
for _,c in ipairs(D.challenges)do
 for ri,round in ipairs(c.rounds)do
  check(#round.options==3,'three world choices')
  local count=0;for _,o in ipairs(round.options)do if o.correct then count+=1 end end
  check(count==1,'one unambiguous accepted answer per scenario')
  for oi,option in ipairs(round.options)do
   local s=fresh()
   for attempt=1,ri do check(E.enter(s,c.id,D,0),'retry chooses next variant')end
   local run=s.advanced.run;check(run.round==ri,'requested variant is reachable')
   check(E.start(s,run.token,D,100),'explicit start')
   check((c.id=='scout' and run.deadline==130) or (c.id~='scout' and run.deadline==nil),'only scout timed')
   local slot;for i,j in ipairs(run.order)do if j==oi then slot=i end end
   check(E.answer(s,run.token,slot,D,c.id=='scout' and 101 or 100000),'answer can be submitted')
   check(run.status==(option.correct and 'passed' or 'failed'),'answer feedback matches outcome')
   check(R.summary(s).bonusPoints==(option.correct and 100 or 0),'no bonus for wrong replies')
   check(s.record.total==2300,'learning rewards never change partner compensation')
   check(E.enter(s,c.id,D,0),'immediate retry remains available')
  end
 end
end
print('PASS: '..n..' revised scenario outcomes, all variants, retries, timing and compensation checks')
