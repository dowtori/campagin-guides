-- A single guided campaign. Actions are checked against the actual work record.
local Engine={}
function Engine.new()return {phase=1,revision=0,complete=false,record={}}end
local function same(v,a)return type(v)=='string' and v==a end
function Engine.apply(state,action,p,data)
    if state.complete then return false,'이미 완료한 캠페인입니다.'end
    p=type(p)=='table' and p or {}
    local phase=data.phases[state.phase].id
    if action~=phase then return false,'지금 화면의 작업부터 마무리해주세요.'end
    local ok=false
    if phase=='brief'then ok=p.reviewed==true
    elseif phase=='profile'then ok=p.photo=='siriai' and same(p.bio,data.bio) and same(p.link,data.link) and p.posts==true
    elseif phase=='connect'then ok=same(p.url,data.webAppUrl) and type(p.name)=='string' and #p.name>0 and #p.name<80 and same(p.tab,data.campaign) and p.tested==true and p.loaded==true and p.status=='연락전'
    elseif phase=='discover'then ok=p.handle==data.lead.handle and p.reviewed==true and p.historyChecked==true
    elseif phase=='send'then ok=p.handle==data.lead.handle and p.fee==data.lead.fee and p.sent==true and p.status=='DM 발송'
    elseif phase=='reply'then ok=p.fee==data.lead.requestedFee and p.replied==true and p.shared==true
    elseif phase=='handoff'then ok=p.asked==true and p.replied==true and p.selectionRead==true
    elseif phase=='settle'then ok=state.record.sent==1 and state.record.selected==1 and p.reviewed==true end
    if not ok then return false,'화면의 작업 안내와 기록을 확인해주세요.'end
    if phase=='discover'then state.record.handle=p.handle;state.record.status='연락전'
    elseif phase=='send'then state.record.sent=1;state.record.status='DM 발송'
    elseif phase=='reply'then state.record.requestedFee=p.fee;state.record.note='희망 고료 15만 원 / 조정 요청'
    elseif phase=='handoff'then state.record.selected=1;state.record.selection='브랜드 최종 선정'
    elseif phase=='settle'then state.record.total=2300 end
    state.revision+=1
    if state.phase==#data.phases then state.complete=true else state.phase+=1 end
    return true
end
return Engine
