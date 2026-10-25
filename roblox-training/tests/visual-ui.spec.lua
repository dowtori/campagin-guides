local Mock=require('./NativeUiMock')
local Visual=require('./VisualTutorials')
local Curriculum=require('./Curriculum')
local Engine=require('./TrainingEngine')
local count=0
local function flatten(root,out)
    out=out or {};for _,o in ipairs(root:GetChildren())do table.insert(out,o);flatten(o,out)end;return out
end
local function find(root,match)
    for _,o in ipairs(flatten(root))do if o.ClassName=='TextButton' and (o.Name==match or o.Text==match)then return o end end
    for _,o in ipairs(flatten(root))do if o.ClassName=='TextButton' and o.Text and string.find(o.Text,match,1,true)then return o end end
    error('Missing button: '..match)
end
local function click(root,match)find(root,match).Activated:Fire()end
for _,width in ipairs({820,300})do
 Mock.width=width
 for _,stage in ipairs(Curriculum.stages)do for _,q in ipairs(stage.questions)do
    local ctx={body=Mock.Instance.new('Frame'),answer=nil,notices=0}
    ctx.text=function(p,s)local o=Mock.Instance.new('TextLabel');o.Text=s;o.Parent=p;return o end
    ctx.button=function(p,s,props)local o=Mock.Instance.new('TextButton');o.Text=s;for k,v in pairs(props or {})do o[k]=v end;o.Parent=p;return o end
    ctx.primary=function(_,fn,enabled)ctx.action=fn;ctx.enabled=enabled~=false end
    ctx.secondary=function()end;ctx.finish=function(v)ctx.answer=v end;ctx.hint=function()ctx.notices+=1 end;ctx.replay=function()end
    assert(Visual.render(ctx,q),'visual renderer missing')
    assert(ctx.answer==nil,'must not auto-complete')
    local id=q.id;local root=ctx.body
    if id=='profile' or id=='fit' or id=='template' or id=='valid' or id=='incentive'then click(root,'VisualChoice_a')
    elseif id=='bio'then click(root,q.options[1].text)
    elseif id=='role'then for _,key in ipairs(q.answer)do click(root,'VisualChoice_'..key)end
    elseif id=='options'then click(root,'확장 프로그램 옵션')
    elseif id=='setup-order'then
        click(root,'연결 테스트');assert(ctx.notices==1 and ctx.answer==nil,'skip connection steps must not pass')
        click(root,'웹앱 URL');click(root,'이름 예시');click(root,'연결 테스트');click(root,'캠페인 목록 새로고침');click(root,'설정 저장');click(root,'시트에서 저장목록');click(root,'인스타그램 새로고침')
    elseif id=='defaults'then click(root,'기본 상태 선택');click(root,'연락전')
    elseif id=='history'then click(root,'기존 접촉');click(root,'이번 캠페인의 중복 제외')
    elseif id=='send-order'then click(root,'@beauty_sample');click(root,'DM 발송 (연습)');click(root,'DM 발송')
    elseif id=='fee'then click(root,q.visual.drafts[1].text);click(root,'15만 원');click(root,'단톡에 계정과 희망 금액 공유')
    elseif id=='math'then
        local buttons={};for _,o in ipairs(flatten(root))do if o.ClassName=='TextButton' then table.insert(buttons,o)end end
        local base,bonus
        for _,o in ipairs(buttons)do if o.Text=='300원' and not base then base=o elseif o.Text=='2000원' then bonus=o end end
        assert(base and bonus,'rate controls');base.Activated:Fire();bonus.Activated:Fire()
    elseif id=='settlement'then click(root,'월말 실적 집계')
    else click(root,q.visual.drafts[1].text) end
    if ctx.answer==nil then assert(ctx.enabled and ctx.action,'action not enabled: '..id);ctx.action()end
    assert(Engine.isCorrect(q,ctx.answer),'native UI emitted incorrect payload: '..id)
    Visual.feedback(ctx,q,true);Visual.feedback(ctx,q,false)
    ctx.body:Destroy();count+=1
 end end
end
print('PASS: '..count..' native visual UI interaction paths (desktop + mobile adapter); 18 activities submit correct server payloads')
