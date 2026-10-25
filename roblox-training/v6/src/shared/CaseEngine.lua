-- Guided campaign with freely selectable chapters; only finished actions earn a checkmark.
local Engine={}
local function collectionValid(p,data)
 if p.sourceBrand~=data.collection.brandHandle or p.sourceTab~='tagged' or type(p.collected)~='table' or #p.collected<1 then return false end
 local seen={}
 for _,row in ipairs(p.collected)do
  if type(row)~='table' or type(row.handle)~='string' or seen[row.handle] then return false end
  local found=false
  for _,post in ipairs(data.collection.posts)do if post.id==row.postId and post.author==row.handle then found=true end end
  if not found then return false end
  seen[row.handle]=true
 end
 return true
end
function Engine.new()return {phase=1,revision=0,complete=false,record={},completed={}}end
function Engine.choose(state,id,data)
    if type(id)~='string' then return false,'챕터를 선택해주세요.' end
    local index=nil
    for i,q in ipairs(data.phases)do if q.id==id then index=i;break end end
    if not index then return false,'챕터를 찾을 수 없어요.' end
    if state.phase==index and not state.complete then return true,false end
    -- Later chapters supply their scenario inputs, never fabricated completion.
    state.exampleRecord=index>=6 and {sent=1,applied=index>=7} or nil
    state.phase=index;state.complete=false;state.revision+=1
    return true,true
end
function Engine.apply(state,action,p,data)
    if state.complete then return false,'이미 완료한 캠페인입니다.'end
    p=type(p)=='table' and p or {}
    local phase=data.phases[state.phase].id
    if action~=phase then return false,'지금 화면의 작업부터 마무리해주세요.'end
    local ok=false
    if phase=='brief'then ok=p.reviewed==true
    elseif phase=='profile' or phase=='connect'then ok=p.assembled==true and p.understood==true and (p.completion=='already_done' or p.completion=='guide_done')
    elseif phase=='discover'then ok=collectionValid(p,data)
    elseif phase=='send'then ok=p.handle==(state.record.handle or data.lead.handle) and p.fee==data.lead.fee and p.sent==true and p.status=='DM 발송'
    elseif phase=='reply'then ok=p.applicationRead==true and (p.reaction=='like' or p.reaction=='none')
    elseif phase=='settle'then
        local example=state.exampleRecord or {}
        ok=(state.record.sent==1 or example.sent==1) and (state.record.applied==true or example.applied==true) and p.reviewed==true and p.selectionRead==true end
    if not ok then return false,'화면의 작업 안내와 기록을 확인해주세요.'end
    if phase=='profile' or phase=='connect'then
        state.record.setup=state.record.setup or {};state.record.setup[phase]={completion=p.completion,selfReported=true}
    elseif phase=='discover'then state.record.collected={}
        for _,row in ipairs(p.collected)do table.insert(state.record.collected,{handle=row.handle,postId=row.postId,sourceBrand=p.sourceBrand,sourceTab='tagged'})end
        state.record.handle=p.collected[1].handle;state.record.status='연락전'
    elseif phase=='send'then state.record.sent=1;state.record.status='DM 발송'
    elseif phase=='reply'then state.record.applied=true;state.record.reaction=p.reaction
    elseif phase=='settle'then
        state.record.selected=data.result.selected;state.record.selection=data.result.selection
        state.record.total=(state.record.sent or state.exampleRecord.sent)*300+state.record.selected*2000 end
    state.completed[phase]=true
    state.revision+=1
    -- Continue forward, then return to the first unfinished chapter. Replaying never
    -- duplicates settlement and jumping never checks off a chapter that was skipped.
    local nextPhase=nil
    for offset=1,#data.phases do
        local i=(state.phase+offset-1)%#data.phases+1
        if not state.completed[data.phases[i].id] then nextPhase=i;break end
    end
    if nextPhase then state.phase=nextPhase else state.complete=true end
    return true
end
return Engine
