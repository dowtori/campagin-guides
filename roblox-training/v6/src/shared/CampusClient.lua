local Client={}
function Client.start(gui)
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local UIS=game:GetService('UserInputService')
local data=require(script.Parent:WaitForChild('CaseData'))
local Raster=require(script.Parent:WaitForChild('RasterRenderer'))
local remote=RS:WaitForChild('CampusEvent')
local player=Players.LocalPlayer
local status=gui:FindFirstChild('Status');if status then status:Destroy()end
local C={paper=Color3.fromRGB(250,249,247),ink=Color3.fromRGB(29,27,34),pink=Color3.fromRGB(255,35,75),gray=Color3.fromRGB(106,102,112),line=Color3.fromRGB(230,227,232),soft=Color3.fromRGB(240,237,241),white=Color3.new(1,1,1)}
local state={phase=1,revision=0,record={},complete=false};local pending=false;local drafts={}
local function make(class,parent,props)local o=Instance.new(class);for k,v in pairs(props or {})do o[k]=v end;o.Parent=parent;return o end
local function round(o,r)make('UICorner',o,{CornerRadius=UDim.new(0,r or 12)})end
local function txt(parent,value,size,color,height)
 local o=make('TextLabel',parent,{Text=value,TextSize=size or 16,TextColor3=color or C.ink,Font=Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,BackgroundTransparency=1,Size=UDim2.new(1,0,0,height or 0),AutomaticSize=height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y})
 return o
end
local function btn(parent,value,fn)
 local o=make('TextButton',parent,{Text=value,TextSize=15,TextColor3=C.ink,Font=Enum.Font.GothamBold,TextWrapped=true,BackgroundColor3=C.soft,BorderSizePixel=0,Size=UDim2.new(1,0,0,48),AutoButtonColor=true});round(o,10)
 if fn then o.Activated:Connect(fn)end;return o
end
local hud=make('Frame',gui,{Position=UDim2.new(.035,0,0,74),Size=UDim2.new(1,-170,0,112),BackgroundColor3=C.ink,BackgroundTransparency=.08,BorderSizePixel=0});round(hud,14)
make('UISizeConstraint',hud,{MaxSize=Vector2.new(380,112)})
local phaseText=txt(hud,'첫 캠페인을 받아보세요',16,C.white,42);phaseText.Position=UDim2.fromOffset(16,13);phaseText.Size=UDim2.new(1,-32,0,42);phaseText.Font=Enum.Font.GothamBold
local objective=txt(hud,'분홍 표식의 매니저에게 다가가 E / 터치',12,C.white,52);objective.Position=UDim2.fromOffset(16,57);objective.Size=UDim2.new(1,-32,0,50)
local phoneButton=btn(gui,'폰 / 진행 기록',nil);phoneButton.Size=UDim2.fromOffset(132,38);phoneButton.AnchorPoint=Vector2.new(1,0);phoneButton.Position=UDim2.new(.965,0,0,74)
local helpButton=btn(gui,'?',nil);helpButton.Size=UDim2.fromOffset(38,36);helpButton.AnchorPoint=Vector2.new(1,0);helpButton.Position=UDim2.new(.965,0,0,120)
local toast=txt(gui,'인플루언서 모집을 로블록스에서!',16,C.white,80);toast.AnchorPoint=Vector2.new(.5,1);toast.Position=UDim2.new(.5,0,1,UIS.TouchEnabled and -230 or -155);toast.Size=UDim2.new(.9,0,0,80);toast.BackgroundColor3=C.ink;toast.BackgroundTransparency=.05;toast.Visible=false;round(toast)
make('UIPadding',toast,{PaddingTop=UDim.new(0,12),PaddingLeft=UDim.new(0,16),PaddingRight=UDim.new(0,16)})
make('UISizeConstraint',toast,{MaxSize=Vector2.new(640,110)})
local serial=0
local function notice(value)serial+=1;local n=serial;toast.Text=value;toast.Visible=true;task.delay(5,function()if serial==n then toast.Visible=false end end)end
local panel=make('Frame',gui,{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(.97,0,.5,0),Size=UDim2.new(.94,0,.76,0),BackgroundColor3=C.paper,BorderSizePixel=0,Visible=false});round(panel,18)
make('UISizeConstraint',panel,{MaxSize=Vector2.new(510,620)})
local tag=txt(panel,'SIRIAI / 캠페인 연습',12,C.pink,18);tag.Position=UDim2.fromOffset(18,15)
local title=txt(panel,'',20,C.ink,47);title.Position=UDim2.fromOffset(18,38);title.Size=UDim2.new(1,-68,0,47);title.Font=Enum.Font.GothamBold
local close=btn(panel,'×',function()panel.Visible=false end);close.Position=UDim2.new(1,-49,0,12);close.Size=UDim2.fromOffset(34,34)
local body=make('ScrollingFrame',panel,{Position=UDim2.fromOffset(18,96),Size=UDim2.new(1,-36,1,-168),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y})
make('UIListLayout',body,{Padding=UDim.new(0,13),SortOrder=Enum.SortOrder.LayoutOrder})
make('UIPadding',body,{PaddingRight=UDim.new(0,6),PaddingBottom=UDim.new(0,20)})
local primary=btn(panel,'계속',nil);primary.Position=UDim2.new(0,18,1,-59);primary.Size=UDim2.new(1,-36,0,44);primary.BackgroundColor3=C.pink;primary.TextColor3=C.white
local doPrimary=nil
primary.Activated:Connect(function()if primary.Active and not pending and doPrimary then doPrimary()end end)
local order=0
body.ChildAdded:Connect(function(o)if o:IsA('GuiObject')then order+=1;o.LayoutOrder=order end end)
local function action(caption,fn,active)primary.Text=caption;primary.Active=active~=false;primary.BackgroundColor3=active==false and C.line or C.pink;primary.TextColor3=active==false and C.gray or C.white;doPrimary=fn end
local function clear(heading)
 for _,o in ipairs(body:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
 order=0;body.CanvasPosition=Vector2.zero;title.Text=heading;panel.Visible=true;pending=false;action('화면의 작업을 진행하세요',nil,false)
end
local function card(label,value)
 local f=make('Frame',body,{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.soft,BorderSizePixel=0});round(f,10)
 make('UIPadding',f,{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14),PaddingTop=UDim.new(0,12),PaddingBottom=UDim.new(0,12)})
 local t=txt(f,label..'\n'..value,15);return f,t
end
local function input(label,value)
 txt(body,label,13,C.gray)
 local o=make('TextBox',body,{Text=value or '',PlaceholderText=label,ClearTextOnFocus=false,TextSize=15,Font=Enum.Font.Gotham,TextColor3=C.ink,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=C.white,BorderSizePixel=0,Size=UDim2.new(1,0,0,43)})
 round(o,9);make('UIPadding',o,{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)});return o
end
local function submit(payload)
 if pending then return end;pending=true;action('기록 중…',nil,false)
 remote:FireServer({kind='apply',revision=state.revision,action=data.phases[state.phase].id,payload=payload})
 local revision=state.revision;task.delay(8,function()if pending and state.revision==revision then pending=false;notice('응답을 기다리고 있어요. 창을 닫고 작업 대상에서 다시 열어주세요.')end end)
end
local function context(q)
 txt(body,q.context,16)
 card('지금 할 일',q.goal)
 local help=btn(body,'캠페인 가이드 확인',nil)
 local ref=txt(body,q.reference,14,C.gray);ref.Visible=false
 help.Activated:Connect(function()ref.Visible=not ref.Visible end)
end
local function images(keys,height,ratio)
 local f=make('Frame',body,{Size=UDim2.new(1,0,0,height),BackgroundTransparency=1})
 for i,key in ipairs(keys)do local im=Raster.draw(f,key,UDim2.new((i-1)/#keys,2,0,0),UDim2.new(1/#keys,-4,1,0));make('UIAspectRatioConstraint',im,{AspectRatio=ratio or 1,AspectType=Enum.AspectType.FitWithinMaxSize})end
 return f
end
local render
render=function(profileId)
 local q=data.phases[state.phase];clear(q.id=='brief' and data.title or q.title);if q.id~='brief'then context(q)end
 if q.id=='brief'then
    txt(body,data.welcome,16)
    card(data.campaign,data.criteria..'\n기본 제안 고료: '..data.feeRule)
    action('가이드 받고 리크루터 폰 챙기기',function()submit({reviewed=true})end)
 elseif q.id=='profile'then
    local f=make('Frame',body,{Size=UDim2.new(1,0,0,70),BackgroundColor3=C.white,BorderSizePixel=0});round(f,10)
    local portrait=nil;local label=txt(f,'siriai_partner\n프로필 준비 중',15);label.Position=UDim2.new(.24,0,0,14);label.Size=UDim2.new(.7,0,0,54)
    local applied=drafts.profile or {photo=false,bio=false,link=false};drafts.profile=applied
    if applied.photo then portrait=Raster.draw(f,'logo',UDim2.fromOffset(10,10),UDim2.fromOffset(50,50))end
    local bio=txt(body,applied.link and data.bio..'\n'..data.link or applied.bio and data.bio or '소개와 링크를 적용해주세요.',15,C.gray)
    local function ready()action('프로필 저장',function()submit({photo='siriai',bio=data.bio,link=data.link,posts=true})end,applied.photo and applied.bio and applied.link)end
    btn(body,'제공된 시리아이 로고 적용',function()if not portrait then portrait=Raster.draw(f,'logo',UDim2.fromOffset(10,10),UDim2.fromOffset(50,50))end;applied.photo=true;ready()end)
    btn(body,'제공된 소개 문구 붙여넣기',function()applied.bio=true;bio.Text=data.bio;ready()end)
    btn(body,'프로필 링크 적용',function()applied.link=true;bio.Text=data.bio..'\n'..data.link;ready()end)
    ready()
    txt(body,'제공된 프로필 게시물 6장',13,C.gray)
    images({'brand1','brand2','brand3'},125,.8);images({'brand4','brand5','brand6'},125,.8)
 elseif q.id=='connect'then
    local cache=drafts.connect or {};drafts.connect=cache
    local phase=cache.phase or 1;local name=cache.name or '';local step
    local function draw()
        clear(q.title);txt(body,'IG Lead Saver · 확장 프로그램 옵션',16)
        if phase==1 then
            txt(body,'웹 스토어에서 설치한 후 chrome://extensions → 세부정보 → 확장 프로그램 옵션을 엽니다.',14,C.gray)
            card('전달받은 웹앱 URL',data.webAppUrl)
            local url=input('Apps Script 웹앱 URL',cache.url or '');url.TextSize=11
            url:GetPropertyChangedSignal('Text'):Connect(function()cache.url=url.Text end)
            btn(body,'전달받은 URL 붙여넣기',function()url.Text=data.webAppUrl end)
            local n=input('저장자 이름',name)
            n:GetPropertyChangedSignal('Text'):Connect(function()cache.name=n.Text end)
            btn(body,'연습용 이름 입력',function()n.Text='연습 파트너'end)
            action('연결 테스트',function()
                if url.Text~=data.webAppUrl or #n.Text<1 then notice('전달받은 URL과 저장자 이름을 먼저 넣어주세요.');return end
                name=n.Text;phase=2;cache.name=name;cache.phase=phase;draw()
            end)
        elseif phase==2 then
            card('연결 테스트 완료','저장자: '..name)
            txt(body,'진행 중인 캠페인(시트 탭)',14,C.gray)
            btn(body,data.campaign..' 선택',function()phase=3;cache.phase=phase;draw()end)
        elseif phase==3 then
            card('선택한 캠페인',data.campaign..'\n기본 상태: 연락전')
            txt(body,'아직 DM을 보내기 전이므로 연락전 상태로 저장합니다.',15)
            action('설정 저장',function()phase=4;cache.phase=phase;draw()end)
        else
            card('설정이 저장됐어요','인스타그램을 새로고침한 뒤, 기존 저장목록을 불러오면 중복을 확인할 수 있어요.')
            action('새로고침 · 시트 저장목록 불러오기',function()submit({url=data.webAppUrl,name=name,tab=data.campaign,status='연락전',tested=true,loaded=true})end)
        end
    end
    draw()
 elseif q.id=='discover'then
    local p=data.profiles[1];for _,item in ipairs(data.profiles)do if item.id==profileId then p=item end end
    card('@'..p.handle,tostring(p.followers)..' 팔로워 / '..p.genre..'\n'..p.recent)
    images({'creator'..p.posts[1],'creator'..p.posts[2],'creator'..p.posts[3]},126)
    txt(body,'이번 기준: '..data.criteria,15,C.pink)
    local checked=false
    btn(body,'! 기존 접촉 이력 확인',function()if not checked then checked=true;card('접촉 이력',p.history)end
        if p.fits then action('IG Lead Saver로 시트에 저장',function()submit({handle=p.handle,reviewed=true,historyChecked=true})end)end
    end)
    if not p.fits then
        card('이번 캠페인과 맞지 않아요',p.followers<5000 and '팔로워가 5천 명보다 적어요. 다른 크리에이터도 만나보세요.' or '최근 콘텐츠가 여행 사진 중심이에요. 뷰티 릴스 크리에이터를 찾아보세요.')
        action('다른 크리에이터 찾아보기',function()panel.Visible=false end)
    end
 elseif q.id=='send'then
    local step=drafts.sendStep or 1
    local function draw()
        clear(q.title)
        if step==1 then
            card('캠페인 진행 시트','@beauty_sample   18,000 팔로워\n상태: 연락전')
            txt(body,'방금 모은 대상입니다. 이 행에서 프로필을 열어 DM을 보낼 수 있어요.',15)
            action('대상 프로필에서 DM 열기',function()step=2;drafts.sendStep=step;draw()end)
        elseif step==2 then
            card('이번 캠페인 문구 구간',data.feeRule)
            local filled=false;local draft=txt(body,'@beauty_sample / 팔로워 1.8만\nDM 문구를 불러와주세요.',16)
            btn(body,'1만~3만 구간 DM 양식 불러오기',function()
                filled=true;draft.Text='안녕하세요, 시리아이입니다 :)\n뷰티 릴스 캠페인 협업을 제안드립니다.\n제안 고료 10만 원\n관심 있으시면 지원 부탁드립니다.'
                action('이 문구로 DM 보내기',function()step=3;drafts.sendStep=step;draw()end)
            end)
        else
            card('DM 발송 완료','@beauty_sample에게 제안을 보냈어요. 시트에도 발송 상태를 남깁니다.')
            btn(body,'시트 상태: DM 발송으로 변경',function()action('변경한 시트 저장',function()submit({handle=data.lead.handle,fee=data.lead.fee,sent=true,status='DM 발송'})end)end)
        end
    end
    draw()
 elseif q.id=='reply'then
    local replied,note,shared=false,false,false
    card('@beauty_sample','좋은 제안 감사합니다! 고료를 15만 원으로 조정할 수 있을까요?')
    local draft=txt(body,'희망 금액을 전달하고 확인 후 안내합니다.',15)
    local function ready()action('응대와 기록 마무리',function()submit({fee=150000,replied=true,shared=true})end,replied and note and shared)end
    btn(body,'확인 후 안내하겠다는 답장 보내기',function()replied=true;draft.Text='희망 고료 15만 원을 함께 전달드리겠습니다. 확인 후 안내드릴게요 :)';ready()end)
    btn(body,'비고에 희망 고료 15만 원 기록',function()if not note then card('시트 비고','희망 고료 15만 원 / 조정 요청')end;note=true;ready()end)
    btn(body,'단톡에 계정과 희망 금액 공유',function()if not replied or not note then notice('먼저 답장과 비고 기록을 마무리해주세요.');return end;shared=true;card('공유한 내용','@beauty_sample / 희망 고료 15만 원 / 조정 요청');ready()end)
 elseif q.id=='handoff'then
    local step=drafts.handoffStep or 1
    local function draw()
        clear(q.title)
        if step==1 then
            card('@beauty_sample의 추가 문의','얼굴 전체 노출이 꼭 필요한가요?')
            txt(body,'안내받지 않은 제작 조건입니다. 계정과 질문을 담당자에게 전달하세요.',15)
            action('담당자에게 조건 확인 요청',function()step=2;drafts.handoffStep=step;draw()end)
        elseif step==2 then
            card('담당자의 확인된 답변','이번 연습 캠페인은 얼굴 전체 노출이 필요합니다.')
            txt(body,'확인된 내용으로 회신합니다. 조건을 임의로 바꿔 약속하지 않아요.',15)
            action('확인한 내용으로 크리에이터에게 회신',function()step=3;drafts.handoffStep=step;draw()end)
        else
            card('이후 도착한 캠페인 안내','브랜드 최종 선정: @beauty_sample\n진행 상세는 담당자가 별도로 안내합니다.')
            txt(body,'지원만 완료한 상태와 최종 선정은 구분합니다. 이번에는 최종 선정 안내까지 도착했어요.',15)
            action('최종 선정 안내 확인',function()submit({asked=true,replied=true,selectionRead=true})end)
        end
    end
    draw()
 elseif q.id=='settle'then
    card('이번 캠페인의 기록','@beauty_sample / 유효 DM 발송 1건 / 최종 선정 1명')
    card('세전 보수 예시','1건 × 300원 + 1명 × 2,000원\n합계 2,300원')
    txt(body,'월 1회, 계약서의 정산 기준과 지급일에 따라 지급합니다.',15)
    action('첫 캠페인 마치기',function()submit({reviewed=true})end)
 end
end
local marker,highlight=nil,nil
local function targetPart()
 local phase=data.phases[state.phase];local world=workspace:FindFirstChild('TrainingMap')
 return world and world:FindFirstChild('Target_'..phase.target,true)
end
local function update()
 phaseText.Text=state.complete and '첫 캠페인 완료!' or data.phases[state.phase].title
 objective.Text=state.complete and '갈대 바다에서 쉬어가세요. 폰에서 기록을 볼 수 있어요.' or data.phases[state.phase].goal
 if marker then marker:Destroy()end;if highlight then highlight:Destroy()end
 if not state.complete then
    local p=targetPart()
    if p then
        marker=make('BillboardGui',gui,{Adornee=p,Size=UDim2.fromOffset(180,42),StudsOffsetWorldSpace=Vector3.new(0,5,0),AlwaysOnTop=true,MaxDistance=650})
        local t=txt(marker,'!  여기에서 이어하기',15,C.white,40);t.BackgroundColor3=C.pink;t.TextXAlignment=Enum.TextXAlignment.Center;t.TextYAlignment=Enum.TextYAlignment.Center;round(t,10)
        highlight=make('Highlight',p,{Adornee=p,FillColor=C.pink,FillTransparency=.83,OutlineColor=C.pink,OutlineTransparency=.15})
    end
 end
end
local function phone()
 clear('리크루터 폰')
 if state.complete then
    card('첫 캠페인 완료','모은 인원 1명 / 유효 DM 1건 / 최종 선정 1명\n세전 보수 예시 2,300원')
    btn(body,'노을 바다로 가기',function()panel.Visible=false;remote:FireServer({kind='rest'})end)
    action('처음부터 다시 해보기',function()panel.Visible=false;remote:FireServer({kind='restart'})end)
 else
    card('현재 목표',data.phases[state.phase].goal)
    local r=state.record
    txt(body,'수집: '..(r.handle and '1명' or '0명')..' / 발송: '..tostring(r.sent or 0)..'건 / 최종 선정: '..tostring(r.selected or 0)..'명',15)
    action('표식을 따라 작업 계속하기',function()panel.Visible=false end)
 end
end
phoneButton.Activated:Connect(phone)
helpButton.Activated:Connect(function()
 clear('조작 안내')
 txt(body,'이동: WASD / 모바일 조이스틱\n상호작용: 가까이에서 E / 화면 터치\n폰: 도구창에서 리크루터 폰 장착 후 클릭\n현재 목표: 분홍 표식을 따라가세요.',16)
 txt(body,'이곳의 캠페인과 계정은 연습 사례입니다. 실제 업무 자료는 별도로 받은 시리아이 안내서를 사용합니다.',13,C.gray)
 btn(body,'물가에서 잠시 쉬기',function()panel.Visible=false;remote:FireServer({kind='rest'})end)
 action('입구로 돌아가기',function()panel.Visible=false;remote:FireServer({kind='home'})end)
end)
local nearButton=btn(gui,'E / 작업 시작',nil);nearButton.Visible=false;nearButton.AnchorPoint=Vector2.new(.5,1);nearButton.Position=UDim2.new(.5,0,1,UIS.TouchEnabled and -160 or -92);nearButton.Size=UDim2.new(.8,0,0,45);nearButton.BackgroundColor3=C.pink;nearButton.TextColor3=C.white
make('UISizeConstraint',nearButton,{MaxSize=Vector2.new(380,45)})
nearButton.Activated:Connect(function()remote:FireServer({kind='interact',target=data.phases[state.phase].target})end)
local tick=0
Run.Heartbeat:Connect(function(dt)
 tick+=dt;if tick<.2 then return end;tick=0
 local p=targetPart();local r=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 nearButton.Visible=not panel.Visible and not state.complete and p and r and (p.Position-r.Position).Magnitude<18 or false
end)
UIS.InputBegan:Connect(function(input,processed)
 if not processed and input.KeyCode==Enum.KeyCode.E and nearButton.Visible then remote:FireServer({kind='interact',target=data.phases[state.phase].target})end
end)
remote.OnClientEvent:Connect(function(packet)
 if packet.state then if packet.state.revision<state.revision then drafts={}end;state=packet.state;update()end
 if packet.kind=='open'then render(packet.profile)
 elseif packet.kind=='done'then pending=false;panel.Visible=false;notice('✓ '..packet.text)
 elseif packet.kind=='phone' or packet.kind=='finished'then phone()
 elseif packet.kind=='notice'then pending=false;notice(packet.text)end
end)
for attempt=1,4 do remote:FireServer({kind='hello'});task.wait(1)end
end
return Client
