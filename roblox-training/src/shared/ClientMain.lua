local Client={}
function Client.start()
-- Native responsive Roblox UI. Mouse, touch and ProximityPrompt inputs are supported.
local Players = game:GetService('Players')
local Prompts = game:GetService('ProximityPromptService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')
local Visual = require(script.Parent:WaitForChild('VisualTutorials'))
local Raster = require(script.Parent:WaitForChild('RasterRenderer'))
local RunService = game:GetService('RunService')
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild('TrainingEvent')
local oldGui=player:WaitForChild('PlayerGui'):FindFirstChild('SiriaiTraining')
if oldGui then oldGui:Destroy() end
local gui = Instance.new('ScreenGui')
gui.Name, gui.ResetOnSpawn, gui.ZIndexBehavior = 'SiriaiTraining', false, Enum.ZIndexBehavior.Sibling
gui.DisplayOrder=20
gui.Parent = player:WaitForChild('PlayerGui')
local C = {paper=Color3.fromRGB(251,250,247), ink=Color3.fromRGB(28,27,25), muted=Color3.fromRGB(111,109,104), line=Color3.fromRGB(229,227,221), soft=Color3.fromRGB(239,237,231), pink=Color3.fromRGB(255,35,75), green=Color3.fromRGB(39,128,103)}
local stages, snapshot = {}, {progress=1,completed=0,flags={},total=6,finished=false}
local token, question, pending, welcomed = '', nil, false, false
local order, choiceButtons, footerAction, secondaryAction = {}, {}, nil, nil
local nextHighlight, waypoint, celebrated
local relaxing=false

local function make(class, parent, props)
    local object = Instance.new(class)
    for k,v in pairs(props or {}) do object[k] = v end
    object.Parent = parent
    return object
end
local function round(object, radius) make('UICorner',object,{CornerRadius=UDim.new(0,radius or 14)}) end
local function padding(object, amount)
    make('UIPadding',object,{PaddingTop=UDim.new(0,amount),PaddingBottom=UDim.new(0,amount),PaddingLeft=UDim.new(0,amount),PaddingRight=UDim.new(0,amount)})
end
local function text(parent, value, size, color, bold)
    return make('TextLabel',parent,{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text=value,TextSize=size or 17,TextColor3=color or C.ink,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,RichText=false})
end
local function button(parent, caption, props)
    local values = {Text=caption,TextSize=16,Font=Enum.Font.GothamBold,TextColor3=C.ink,BackgroundColor3=C.soft,BorderSizePixel=0,AutoButtonColor=true,TextWrapped=true,Size=UDim2.new(1,0,0,52)}
    for k,v in pairs(props or {}) do values[k]=v end
    local object = make('TextButton',parent,values)
    round(object,12)
    return object
end

local hud = make('Frame',gui,{AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(.5,0,0,58),Size=UDim2.new(.94,0,0,92),BackgroundColor3=C.paper,BorderSizePixel=0})
round(hud,18)
make('UISizeConstraint',hud,{MaxSize=Vector2.new(840,92)})
Raster.draw(hud,'logo',UDim2.fromOffset(14,14),UDim2.fromOffset(24,24))
local hudBrand = text(hud,'SIRIAI v4  /  TRAINING CAMPUS',12,C.muted,true)
hudBrand.Position,hudBrand.Size,hudBrand.AutomaticSize=UDim2.fromOffset(47,12),UDim2.new(1,-150,0,17),Enum.AutomaticSize.None
local hudTitle = text(hud,'캠퍼스에 오신 걸 환영해요',17,C.ink,true)
hudTitle.Position,hudTitle.Size,hudTitle.AutomaticSize=UDim2.fromOffset(18,33),UDim2.new(1,-156,0,24),Enum.AutomaticSize.None
hudTitle.TextWrapped,hudTitle.TextTruncate=false,Enum.TextTruncate.AtEnd
local hudProgress = text(hud,'스탬프 0 / 6',12,C.muted)
hudProgress.Position=UDim2.fromOffset(18,63)
local hudBar = make('Frame',hud,{Position=UDim2.new(0,18,1,-7),Size=UDim2.new(1,-36,0,3),BackgroundColor3=C.line,BorderSizePixel=0})
local hudFill = make('Frame',hudBar,{Size=UDim2.fromScale(0,1),BackgroundColor3=C.pink,BorderSizePixel=0})
round(hudBar,3) round(hudFill,3)
local mapButton = button(hud,'미션지도',{Position=UDim2.new(1,-128,0,26),Size=UDim2.fromOffset(72,38),TextSize=13})
local helpButton = button(hud,'?',{Position=UDim2.new(1,-48,0,26),Size=UDim2.fromOffset(32,38),TextSize=18})
local hint = make('TextLabel',gui,{AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-16),Size=UDim2.new(.85,0,0,36),BackgroundColor3=C.ink,BackgroundTransparency=.12,BorderSizePixel=0,Text='단말기에서 E / 터치 · 그림과 모의 화면으로 직접 연습',TextColor3=Color3.new(1,1,1),Font=Enum.Font.Gotham,TextSize=12,TextWrapped=true})
round(hint,12) make('UISizeConstraint',hint,{MaxSize=Vector2.new(570,48)})

local shade = make('TextButton',gui,{Size=UDim2.fromScale(1,1),Text='',BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.34,BorderSizePixel=0,Visible=false,AutoButtonColor=false,Modal=true})
local panel = make('Frame',shade,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(.92,0,.88,0),BackgroundColor3=C.paper,BorderSizePixel=0})
round(panel,20) make('UISizeConstraint',panel,{MaxSize=Vector2.new(920,750)})
local headerTag = text(panel,'SIRIAI CAMPUS',12,C.pink,true)
headerTag.Position,headerTag.Size,headerTag.AutomaticSize=UDim2.fromOffset(22,18),UDim2.new(1,-90,0,18),Enum.AutomaticSize.None
local headerTitle = text(panel,'트레이닝 캠퍼스',21,C.ink,true)
headerTitle.Position,headerTitle.Size,headerTitle.AutomaticSize=UDim2.fromOffset(22,42),UDim2.new(1,-90,0,48),Enum.AutomaticSize.None
local closeButton = button(panel,'×',{Position=UDim2.new(1,-58,0,18),Size=UDim2.fromOffset(36,36),TextSize=25})
local body = make('ScrollingFrame',panel,{Position=UDim2.fromOffset(22,100),Size=UDim2.new(1,-44,1,-202),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,ScrollBarImageColor3=C.muted,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y})
make('UIListLayout',body,{Padding=UDim.new(0,14),SortOrder=Enum.SortOrder.LayoutOrder})
make('UIPadding',body,{PaddingRight=UDim.new(0,8),PaddingBottom=UDim.new(0,24)})
local footer = make('Frame',panel,{Position=UDim2.new(0,22,1,-86),Size=UDim2.new(1,-44,0,64),BackgroundTransparency=1})
local secondary = button(footer,'닫기',{Size=UDim2.new(.3,-5,0,54),Position=UDim2.fromOffset(0,4),TextSize=14})
local primary = button(footer,'시작하기',{Size=UDim2.new(.7,-5,0,54),Position=UDim2.new(.3,5,0,4),BackgroundColor3=C.pink,TextColor3=Color3.new(1,1,1),TextSize=16})
local toast = make('TextLabel',gui,{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,112),Size=UDim2.new(.9,0,0,65),BackgroundColor3=C.ink,BorderSizePixel=0,TextColor3=Color3.new(1,1,1),TextSize=15,Font=Enum.Font.Gotham,TextWrapped=true,Visible=false,ZIndex=5})
round(toast,12) padding(toast,12) make('UISizeConstraint',toast,{MaxSize=Vector2.new(700,80)})
local relaxButton = button(gui,'노을 산책  ↗',{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(.97,0,0,158),Size=UDim2.fromOffset(144,36),TextSize=12,BackgroundColor3=Color3.fromRGB(241,222,187),BackgroundTransparency=.12})
local function setRelaxing(value)
    relaxing=value
    hud.Visible=not value
    hint.Visible=not value
    relaxButton.Text=value and '교육으로 돌아가기  ↩' or '노을 산책  ↗'
    if waypoint then waypoint.Enabled=not value end
    if nextHighlight then nextHighlight.Enabled=not value end
end
local nearbyId=nil
local nearbyButton=button(gui,'부스 안에서 미션을 시작해요',{AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,UserInputService.TouchEnabled and -150 or -62),Size=UDim2.new(.86,0,0,52),TextSize=15,BackgroundColor3=C.pink,TextColor3=Color3.new(1,1,1),Visible=false})
make('UISizeConstraint',nearbyButton,{MaxSize=Vector2.new(560,58)})
nearbyButton.Activated:Connect(function()if nearbyId then remote:FireServer({kind='open',stage=nearbyId})end end)
local proximityClock=0
RunService.Heartbeat:Connect(function(dt)
    proximityClock+=dt;if proximityClock<.2 then return end;proximityClock=0
    nearbyId=nil
    local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
    if root and not shade.Visible and not relaxing then
        for _,stage in ipairs(stages) do
            local p=stage.position
            if p and math.abs(root.Position.X-p[1])<=24 and math.abs(root.Position.Z-p[3])<=23 and math.abs(root.Position.Y-4)<18 then nearbyId=stage.id break end
        end
    end
    nearbyButton.Visible=nearbyId~=nil
    if nearbyId then nearbyButton.Text=string.format('%02d %s  ·  미션 시작 [E]',nearbyId,stages[nearbyId].title) end
end)
local bodyOrder=0
body.ChildAdded:Connect(function(child)
    if child:IsA('GuiObject') then bodyOrder+=1 child.LayoutOrder=bodyOrder end
end)
local toastSerial=0
local function notify(value)
    toastSerial+=1
    local serial=toastSerial
    toast.Text,toast.Visible=value,true
    task.delay(4,function() if toastSerial==serial then toast.Visible=false end end)
end
local function clearBody()
    for _, object in ipairs(body:GetChildren()) do
        if object:IsA('GuiObject') then object:Destroy() end
    end
    body.CanvasPosition=Vector2.zero
    order,choiceButtons,pending={}, {}, false
    bodyOrder=0
end
local function show(tag,title)
    nearbyButton.Visible=false
    setRelaxing(false)
    clearBody()
    headerTag.Text,headerTitle.Text=tag,title
    shade.Visible=true
    relaxButton.Visible=false
    Prompts.Enabled=false
end
local function close(send)
    shade.Visible=false
    relaxButton.Visible=true
    Prompts.Enabled=true
    pending=false
    if send then remote:FireServer({kind='close'}) end
end
local function setPrimary(caption,action,enabled)
    primary.Text=caption
    footerAction=action
    primary.Active=enabled~=false
    primary.BackgroundColor3=enabled==false and C.line or C.pink
    primary.TextColor3=enabled==false and C.muted or Color3.new(1,1,1)
    primary.AutoButtonColor=enabled~=false
end
local function setSecondary(caption,action)
    secondary.Text,secondaryAction=caption,action
end
primary.Activated:Connect(function() if primary.Active and footerAction then footerAction() end end)
secondary.Activated:Connect(function() if secondaryAction then secondaryAction() end end)
closeButton.Activated:Connect(function() close(true) end)

local function card(value,dark)
    local frame=make('Frame',body,{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=dark and C.ink or C.soft,BorderSizePixel=0})
    round(frame,14) padding(frame,18)
    text(frame,value,16,dark and Color3.new(1,1,1) or C.ink)
    return frame
end
local function sendAnswer(answer)
    if pending then return end
    pending=true
    setPrimary('확인 중…',nil,false)
    remote:FireServer({kind='answer',token=token,answer=answer})
    local requestedToken=token
    task.delay(9,function()
        if pending and token==requestedToken then
            close(true)
            notify('응답이 늦어지고 있어요. 단말기에서 다시 열어주세요. 완료한 단계는 유지돼요.')
        end
    end)
end

local renderQuestion,showCompletion,showMap
local function refreshOrder()
    for _, row in ipairs(choiceButtons) do
        local rank=table.find(order,row.id)
        row.button.Text=(rank and (tostring(rank)..'  ✓  ') or '＋  ')..row.caption
        row.button.BackgroundColor3=rank and Color3.fromRGB(255,226,233) or C.soft
    end
    setPrimary(string.format('순서 확인  %d / %d',#order,#question.options),function() sendAnswer(table.clone(order)) end,#order==#question.options)
end
renderQuestion=function(payload,newToken)
    question,token=payload,newToken
    show(string.format('MISSION %02d  ·  %d / %d%s',payload.stage,payload.step,payload.steps,payload.review and '  ·  복습' or ''),payload.stageTitle)
    text(body,payload.title,23,C.ink,true)
    if Visual.render({body=body,text=text,button=button,primary=setPrimary,secondary=setSecondary,finish=sendAnswer,hint=notify,replay=function()renderQuestion(payload,newToken)end},payload) then return end
    if payload.step==1 then text(body,payload.stageIntro,15,C.muted) end
    card(payload.context,false)
    if payload.mode=='sequence' then text(body,'먼저 할 일부터 하나씩 눌러 순서를 완성해요.',14,C.muted) end
    -- Choice order is randomized per render; correctness never depends on button position.
    local choices=table.clone(payload.options)
    for i=#choices,2,-1 do local j=math.random(i) choices[i],choices[j]=choices[j],choices[i] end
    for i,choice in ipairs(choices) do
        local selected=choice
        local caption=(payload.mode=='sequence' and '＋  ' or (string.char(64+i)..'  ·  '))..choice.text
        local b=button(body,caption,{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextXAlignment=Enum.TextXAlignment.Left,TextSize=16,Font=Enum.Font.Gotham})
        padding(b,18)
        make('UISizeConstraint',b,{MinSize=Vector2.new(0,62)})
        table.insert(choiceButtons,{id=choice.id,caption=choice.text,button=b})
        b.Activated:Connect(function()
            if pending then return end
            if payload.mode=='sequence' then
                if not table.find(order,selected.id) then table.insert(order,selected.id) refreshOrder() end
            else sendAnswer(selected.id) end
        end)
    end
    if payload.mode=='sequence' then
        setSecondary('선택 초기화',function() if not pending then order={} refreshOrder() end end)
        refreshOrder()
    else
        setSecondary('잠깐 닫기',function() close(true) end)
        setPrimary('위에서 답을 골라주세요',nil,false)
    end
end

local function confetti()
    if celebrated then return end
    celebrated=true
    local colors={C.pink,Color3.fromRGB(241,189,82),Color3.fromRGB(139,114,232),Color3.fromRGB(57,155,129)}
    for i=1,50 do
        local piece=make('Frame',gui,{Position=UDim2.fromScale(math.random(),-.05),Size=UDim2.fromOffset(math.random(6,11),math.random(10,18)),BackgroundColor3=colors[math.random(#colors)],BorderSizePixel=0,Rotation=math.random(0,180),ZIndex=8})
        TweenService:Create(piece,TweenInfo.new(2.6+math.random(),Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.fromScale(math.random(),1.1),Rotation=math.random(300,650),BackgroundTransparency=.35}):Play()
        task.delay(4.1,function() piece:Destroy() end)
    end
end

showCompletion=function(result)
    local finished=result.snapshot.finished
    local stage=stages[result.stage]
    show(finished and 'TRAINING COMPLETE' or 'STAMP COLLECTED',finished and '소현님, 교육 수료를 축하해요!' or (stage.title..' 완료'))
    text(body,finished and '찾고, 보내고, 협업으로 연결할 준비를 마쳤어요.' or '미션 스탬프를 모았어요. 다음 공간에서도 직접 연습해봐요.',22,C.ink,true)
    local stampRow=make('Frame',body,{Size=UDim2.new(1,0,0,58),BackgroundTransparency=1})
    for id=1,6 do
        local done=result.snapshot.flags[id]
        local stamp=button(stampRow,(done and '✓ ' or '')..string.format('%02d',id),{Position=UDim2.fromScale((id-1)/6,0),Size=UDim2.new(1/6,-6,0,50),BackgroundColor3=done and C.pink or C.line,TextColor3=done and Color3.new(1,1,1) or C.muted,TextSize=16,AutoButtonColor=false})
        stamp.Active=false
    end
    if finished then
        card('기억할 세 가지\n\n· 캠페인에 맞는 인원을 수집하고 발송 후 상태 표시\n· 고료 조정 요청은 희망 금액 기록·공유\n· 지원과 최종 선정은 다르며, 어려운 문의는 단톡으로',true)
        text(body,'유효 발송 300원 + 최종 선정 2,000원',20,C.pink,true)
        text(body,'실제 업무는 별도로 받은 안내서와 캠페인 가이드로 시작해주세요. 게임 속 가상 사례와 점수는 실제 발송·보수가 아니에요.',15,C.muted)
        if not result.review then confetti() end
        setPrimary('수료 데크로 이동',function() remote:FireServer({kind='jump',stage=7}) end)
    else
        card('완료한 미션은 미션지도에서 언제든 다시 방문해 복습할 수 있어요.',false)
        setPrimary('다음 미션으로 이동',function() remote:FireServer({kind='jump',stage=result.snapshot.progress}) end)
    end
    setSecondary('캠퍼스 둘러보기',function() close(true) end)
end

local function renderResult(packet)
    pending=false
    token=packet.token
    show(packet.correct and 'NICE WORK' or 'LET’S TRY AGAIN',packet.correct and '좋아요, 이렇게 진행하면 돼요.' or '설명을 보고 다시 골라볼까요?')
    text(body,question and question.title or '미션 확인',21,C.ink,true)
    Visual.feedback({body=body},question,packet.correct)
    card(packet.explanation,packet.correct)
    text(body,packet.correct and '이해했다면 다음 단계로 넘어가요.' or '실수해도 괜찮아요. 횟수 제한 없이 다시 연습할 수 있어요.',15,C.muted)
    setSecondary('잠깐 닫기',function() close(true) end)
    setPrimary(packet.correct and '다음으로' or '다시 선택하기',function()
        if packet.stageComplete then showCompletion(packet)
        elseif packet.question then renderQuestion(packet.question,packet.token)
        else close(true) end
    end)
end

local function updateHud(value)
    snapshot=value
    hudTitle.Text=value.finished and '교육 수료 · 캠퍼스를 둘러보세요' or ((stages[value.progress] and stages[value.progress].title) or '첫 미션을 시작해요')
    hudProgress.Text=string.format('스탬프 %d / %d  ·  틀려도 다시 도전할 수 있어요',value.completed,value.total)
    TweenService:Create(hudFill,TweenInfo.new(.3),{Size=UDim2.fromScale(value.completed/value.total,1)}):Play()
    if nextHighlight then nextHighlight:Destroy() nextHighlight=nil end
    if waypoint then waypoint:Destroy() waypoint=nil end
    if not value.finished then
        local model=workspace:WaitForChild('TrainingMap'):WaitForChild('Stations'):FindFirstChild(string.format('Station%02d',value.progress))
        local terminal=model and model:FindFirstChild('Terminal')
        if terminal then
            nextHighlight=make('Highlight',terminal,{Adornee=terminal,FillColor=C.pink,FillTransparency=.6,OutlineColor=Color3.new(1,1,1),OutlineTransparency=.1,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop})
            waypoint=make('BillboardGui',gui,{Adornee=terminal,Size=UDim2.fromOffset(176,36),StudsOffsetWorldSpace=Vector3.new(0,8,0),AlwaysOnTop=true,MaxDistance=450})
            local marker=button(waypoint,string.format('다음 미션  %02d  ↓',value.progress),{Size=UDim2.fromScale(1,1),BackgroundColor3=C.pink,TextColor3=Color3.new(1,1,1),TextSize=14,AutoButtonColor=false})
            marker.Active=false
        end
    end
    if relaxing then setRelaxing(true) end
end

showMap=function()
    remote:FireServer({kind='close'})
    show('CAMPUS MAP','6개의 공간, 한 번의 업무 연습')
    text(body,'열린 공간으로 바로 이동할 수 있어요. 완료한 미션도 다시 열어 복습할 수 있습니다.',15,C.muted)
    for _,stage in ipairs(stages) do
        local current=stage
        local unlocked=stage.id<=snapshot.progress or snapshot.finished
        local status=snapshot.flags[stage.id] and '완료 ✓' or (unlocked and '진행 가능 →' or '아직 잠김')
        local b=button(body,string.format('%02d   %s   /   %s\n%s',stage.id,stage.title,status,stage.subtitle),{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextXAlignment=Enum.TextXAlignment.Left,TextSize=15,BackgroundColor3=unlocked and C.soft or C.line,TextColor3=unlocked and C.ink or C.muted})
        padding(b,16)
        b.Activated:Connect(function()
            if unlocked then remote:FireServer({kind='jump',stage=current.id}) else notify('앞의 미션부터 완료해주세요 :)') end
        end)
    end
    setSecondary('로비로 이동',function() remote:FireServer({kind='jump',stage=0}) end)
    setPrimary(snapshot.finished and '수료 데크로 이동' or '현재 미션으로 이동',function() remote:FireServer({kind='jump',stage=snapshot.finished and 7 or snapshot.progress}) end)
end

local function showHelp()
    remote:FireServer({kind='close'})
    show('HOW TO PLAY','천천히, 직접 해보면서 배워요.')
    card('이동: PC는 WASD · 모바일은 화면 조이스틱\n점프: 스페이스 · 모바일 점프 버튼\n미션: 단말기 가까이에서 E · 모바일은 표시된 버튼 터치\n빠른 이동: 오른쪽 위 ‘미션지도’',false)
    text(body,'갈대밭을 걷거나, 분홍 표식에서 미션을 시작해요.',22,C.ink,true)
    text(body,'미션은 순서대로 열려요. 틀린 답에는 설명이 나오고 다시 선택할 수 있습니다. 캐릭터가 다시 생성되어도 이번 접속 중 완료한 단계는 유지돼요.',16,C.muted)
    card('이곳은 모의 교육 공간이에요. 실제 확장프로그램 설치는 PC 크롬에서, 실제 발송과 정산은 별도로 받은 업무 안내에 따라 진행해주세요. 재접속하면 새 연습으로 시작합니다.',true)
    local restart=button(body,'처음부터 새로 연습하기',{TextSize=14})
    restart.Activated:Connect(function() remote:FireServer({kind='restart'}) end)
    setSecondary('닫기',function() close(true) end)
    setPrimary('미션지도 보기',showMap)
end

local function showWelcome()
    show('WELCOME TO SIRIAI','소현님, 반가워요 :)')
    text(body,'인플루언서 모집을\n플레이하면서 배워봐요.',30,C.ink,true)
    card('프로필 준비 → 확장프로그램 연결 → 인원 선별 → DM 발송 → 문의 응대 → 정산\n\n그림 카드를 고르고, 화면을 직접 눌러 18개 활동을 완료하면 교육 수료!',false)
    text(body,'분홍색 표식의 단말기 가까이 가서 E를 누르세요. 모바일에서는 표시된 버튼을 터치하면 됩니다. 미션지도에서 빠르게 이동할 수도 있어요.',16,C.muted)
    text(body,'‘노을 산책’을 누르면 진행 내용을 유지한 채 물가에서 쉬어갈 수 있어요.\n실제 계정·시트와 연결되지 않는 교육용 시뮬레이션입니다.',14,C.muted)
    setSecondary('둘러보기',function() close(true) end)
    setPrimary('첫 미션으로 이동',function() remote:FireServer({kind='jump',stage=1}) end)
end

relaxButton.Activated:Connect(function()
    remote:FireServer({kind=relaxing and 'return' or 'relax'})
end)
mapButton.Activated:Connect(showMap)
helpButton.Activated:Connect(showHelp)
UserInputService.InputBegan:Connect(function(input,processed)
    if not processed and input.KeyCode==Enum.KeyCode.E and nearbyId and not shade.Visible and not UserInputService:GetFocusedTextBox() then remote:FireServer({kind='open',stage=nearbyId}) end
    if not processed and input.KeyCode==Enum.KeyCode.M and not UserInputService:GetFocusedTextBox() then showMap() end
end)
remote.OnClientEvent:Connect(function(packet)
    local ok,err=xpcall(function()
    if packet.kind=='welcome' then
        stages=packet.stages
        updateHud(packet.snapshot)
        if not welcomed then welcomed=true showWelcome() end
    elseif packet.kind=='state' then
        updateHud(packet.snapshot)
    elseif packet.kind=='question' then
        nearbyButton.Visible=false
        renderQuestion(packet.question,packet.token)
    elseif packet.kind=='result' then
        if shade.Visible then renderResult(packet) end
    elseif packet.kind=='relax' then
        close(false)
        setRelaxing(true)
    elseif packet.kind=='close' then
        setRelaxing(false)
        close(false)
        if packet.text then notify(packet.text) end
    elseif packet.kind=='notice' then
        notify(packet.text)
    end
    end,debug.traceback)
    if not ok then close(false) notify('화면을 여는 중 오류가 발생했어요. 부스의 미션 시작을 다시 눌러주세요.') warn('[SIRIAI UI] '..tostring(err)) end
end)
task.spawn(function()
for attempt=1,12 do
    remote:FireServer({kind='hello'})
    task.wait(3)
    if welcomed then break end
end
if not welcomed then notify('서버 연결을 기다리고 있어요. 단말기에서 E를 누르거나 미션지도를 열어주세요.') end
end)

end
return Client
