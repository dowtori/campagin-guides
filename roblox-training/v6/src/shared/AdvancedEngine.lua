-- Server-owned attempts and deadlines. Reading conditions has no time limit.
local E={}
local function progress(s)
 if not s.advanced then s.advanced={completed={},attempts={},serial=0}end
 return s.advanced
end
local function challenge(data,id)for _,c in ipairs(data.challenges)do if c.id==id then return c end end end
function E.enter(s,id,data,rotation)
 local count=0;for _,v in pairs(s.completed or {})do if v then count+=1 end end
 if count<7 then return false,'기본 7개 챕터를 마치면 열려요.'end
 local c=challenge(data,id);if not c then return false,'미니게임을 찾을 수 없어요.'end
 local a=progress(s);a.serial+=1;a.attempts[id]=(a.attempts[id] or 0)+1
 local round=(a.attempts[id]-1)%#c.rounds+1;local order={}
 for i=1,3 do order[i]=(i-1+(rotation or 0))%3+1 end
 a.run={id=id,token=a.serial,status='brief',round=round,order=order};return true
end
function E.start(s,token,data,now)
 local a=progress(s);local run=a.run
 if not run or run.token~=token or run.status~='brief'then return false end
 local c=challenge(data,run.id);run.status='active';run.deadline=c.timed and now+c.seconds or nil;return true
end
function E.tick(s,now)
 local run=progress(s).run
 if run and run.status=='active' and run.deadline and now>=run.deadline then
  run.status='timeout';run.feedback='시간이 끝났어요. 다시 도전해봐요.';return true
 end
 return false
end
function E.answer(s,token,slot,data,now)
 local a=progress(s);local run=a.run
 if not run or run.token~=token or run.status~='active'then return false end
 if E.tick(s,now)then return true end
 if type(slot)~='number' or slot%1~=0 or slot<1 or slot>3 then return false end
 local c=challenge(data,run.id);local option=c.rounds[run.round].options[run.order[slot]]
 run.choice=slot;run.feedback=option.feedback;run.status=option.correct and 'passed' or 'failed'
 run.firstClear=option.correct and not a.completed[run.id] or false
 if option.correct then a.completed[run.id]=true end
 return true
end
function E.leave(s)
 local a=progress(s);a.serial+=1;a.run=nil
end
function E.challenge(data,id)return challenge(data,id)end
return E
