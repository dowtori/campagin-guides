local R={}
function R.summary(s)
 local basic=0;for _,done in pairs(s.completed or {})do if done then basic+=1 end end
 basic=math.min(7,basic)
 local bonus=0;local a=s.advanced or {}
 for _,id in ipairs({'scout','fee','conditions'})do if a.completed and a.completed[id]then bonus+=1 end end
 return {basic=basic,bonus=bonus,stage=basic+bonus,score=basic*10+bonus*100,bonusPoints=bonus*100,unlocked=basic==7,king=basic==7 and bonus==3}
end
return R
