-- A single guided campaign. Actions are checked against the actual work record.
local Engine={}
function Engine.new()return {phase=1,revision=0,complete=false,record={}}end
function Engine.apply(state,action,p,data)
    if state.complete then return false,'이미 완료한 캠페인입니다.'end
    p=type(p)=='table' and p or {}
    local phase=data.phases[state.phase].id
    if action~=phase then return false,'지금 화면의 작업부터 마무리해주세요.'end
    local ok=false
    if phase=='brief'then ok=p.reviewed==true
    elseif phase=='profile' or phase=='connect'then ok=p.assembled==true and p.understood==true and (p.completion=='already_done' or p.completion=='guide_done')
    elseif phase=='discover'then ok=p.handle==data.lead.handle and p.reviewed==true and p.historyChecked==true
    elseif phase=='send'then ok=p.handle==data.lead.handle and p.fee==data.lead.fee and p.sent==true and p.status=='DM 발송'
    elseif phase=='reply'then ok=p.replied==true and p.applicationRead==true
    elseif phase=='settle'then ok=state.record.sent==1 and state.record.applied==true and p.reviewed==true and p.selectionRead==true end
    if not ok then return false,'화면의 작업 안내와 기록을 확인해주세요.'end
    if phase=='profile' or phase=='connect'then
        state.record.setup=state.record.setup or {};state.record.setup[phase]={completion=p.completion,selfReported=true}
    elseif phase=='discover'then state.record.handle=p.handle;state.record.status='연락전'
    elseif phase=='send'then state.record.sent=1;state.record.status='DM 발송'
    elseif phase=='reply'then state.record.applied=true
    elseif phase=='settle'then
        state.record.selected=data.result.selected;state.record.selection=data.result.selection
        state.record.total=state.record.sent*300+state.record.selected*2000 end
    state.revision+=1
    if state.phase==#data.phases then state.complete=true else state.phase+=1 end
    return true
end
return Engine
