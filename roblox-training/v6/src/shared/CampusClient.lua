-- SIRIAI v6.2: one visible action, deliberate phone access, resumable work.
local Client={}
function Client.start(gui)
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local data=require(script.Parent:WaitForChild('CaseData'))
local Raster=require(script.Parent:WaitForChild('RasterRenderer'))
local remote=RS:WaitForChild('CampusEvent')
local player=Players.LocalPlayer
local status=gui:FindFirstChild('Status');if status then status:Destroy()end
local C={paper=Color3.fromRGB(250,249,247),ink=Color3.fromRGB(29,27,34),pink=Color3.fromRGB(223,25,64),gray=Color3.fromRGB(99,94,106),line=Color3.fromRGB(230,227,232),soft=Color3.fromRGB(239,236,240),white=Color3.new(1,1,1),green=Color3.fromRGB(60,105,80)}
local state={phase=1,revision=0,record={},complete=false}
local pending=false;local drafts={};local mode=nil;local order=0
local function make(class,parent,props)
 local o=Instance.new(class);for k,v in pairs(props or {})do o[k]=v end;o.Parent=parent;return o
end
local function round(o,r)make('UICorner',o,{CornerRadius=UDim.new(0,r or 12)})end
local function txt(parent,value,size,color,height)
 return make('TextLabel',parent,{Text=value,TextSize=size or 18,TextColor3=color or C.ink,Font=Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,BackgroundTransparency=1,Size=UDim2.new(1,0,0,height or 0),AutomaticSize=height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y})
end
local function btn(parent,value,fn)
 local o=make('TextButton',parent,{Text=value,TextSize=17,TextColor3=C.ink,Font=Enum.Font.GothamBold,TextWrapped=true,BackgroundColor3=C.soft,BorderSizePixel=0,Size=UDim2.new(1,0,0,48),AutoButtonColor=true})
 round(o,10);if fn then o.Activated:Connect(fn)end;return o
end
local hud=make('Frame',gui,{Name='ObjectiveHUD',Position=UDim2.new(.035,0,0,74),Size=UDim2.new(1,-126,0,92),BackgroundColor3=C.ink,BackgroundTransparency=.06,BorderSizePixel=0});round(hud,14)
make('UISizeConstraint',hud,{MaxSize=Vector2.new(360,92)})
local phaseText=txt(hud,'첫 캠페인 받기',20,C.white,28);phaseText.Position=UDim2.fromOffset(14,12);phaseText.Size=UDim2.new(1,-28,0,28);phaseText.Font=Enum.Font.GothamBold
local objective=make('TextButton',hud,{Text='준비 테라스로 이동 →',TextSize=14,TextColor3=C.white,Font=Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,BorderSizePixel=0});objective.Position=UDim2.fromOffset(14,47);objective.Size=UDim2.new(1,-28,0,38)
local phoneButton=btn(gui,'폰  [P]');phoneButton.Name='PhoneButton';phoneButton.Size=UDim2.fromOffset(90,44);phoneButton.AnchorPoint=Vector2.new(1,0);phoneButton.Position=UDim2.new(.965,0,0,74)
local helpButton=btn(gui,'?');helpButton.Size=UDim2.fromOffset(44,44);helpButton.AnchorPoint=Vector2.new(1,0);helpButton.Position=UDim2.new(.965,0,0,126)
local toast=txt(gui,'',17,C.white,64);toast.AnchorPoint=Vector2.new(.5,1);toast.Position=UDim2.new(.5,0,1,UIS.TouchEnabled and -220 or -138);toast.Size=UDim2.new(.9,0,0,64);toast.BackgroundColor3=C.ink;toast.BackgroundTransparency=.04;toast.Visible=false;round(toast)
make('UIPadding',toast,{PaddingTop=UDim.new(0,12),PaddingLeft=UDim.new(0,16),PaddingRight=UDim.new(0,16)})
make('UISizeConstraint',toast,{MaxSize=Vector2.new(560,96)})
local serial=0
local function notice(value)
 serial+=1;local n=serial;toast.Text=value;toast.Visible=true
 task.delay(4,function()if serial==n then toast.Visible=false end end)
end
local panel=make('Frame',gui,{Name='WorkPanel',AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(.97,0,.52,0),Size=UDim2.new(.94,0,.84,0),BackgroundColor3=C.paper,BorderSizePixel=0,Visible=false});round(panel,18)
make('UISizeConstraint',panel,{MaxSize=Vector2.new(510,660)})
local tag=txt(panel,'SIRIAI',12,C.gray,18);tag.Position=UDim2.fromOffset(22,20);tag.Size=UDim2.new(1,-80,0,18)
local title=txt(panel,'',26,C.ink,64);title.Position=UDim2.fromOffset(22,47);title.Size=UDim2.new(1,-44,0,64);title.Font=Enum.Font.GothamBold
local body=make('ScrollingFrame',panel,{Name='WorkBody',Position=UDim2.fromOffset(22,124),Size=UDim2.new(1,-44,1,-214),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y})
make('UIListLayout',body,{Padding=UDim.new(0,18),SortOrder=Enum.SortOrder.LayoutOrder})
make('UIPadding',body,{PaddingRight=UDim.new(0,4),PaddingBottom=UDim.new(0,14)})
local primary=btn(panel,'계속');primary.Name='PrimaryAction';primary.Position=UDim2.new(0,22,1,-70);primary.Size=UDim2.new(1,-44,0,50);primary.BackgroundColor3=C.pink;primary.TextColor3=C.white
local doPrimary=nil
local promptList={}
local world=workspace:FindFirstChild('TrainingMap')
if world then for _,o in ipairs(world:GetDescendants())do if o:IsA('ProximityPrompt')then table.insert(promptList,o)end end end
local function prompts()
 local q=data.phases[state.phase]
 for _,o in ipairs(promptList)do
  if o:IsA('ProximityPrompt')then
   local id=o.Parent:FindFirstChild('ActionID');id=id and id.Value
   o.Enabled=not panel.Visible and not state.complete and id==q.target
  end
 end
end
local function visibility(show)
 panel.Visible=show;hud.Visible=not show;phoneButton.Visible=not show;helpButton.Visible=not show;prompts()
end
local function closePanel()visibility(false);mode=nil end
local close=btn(panel,'×',closePanel);close.Name='ClosePanel';close.Position=UDim2.new(1,-54,0,12);close.Size=UDim2.fromOffset(42,42)
local function action(caption,fn,enabled)
 primary.Text=caption;primary.Active=enabled~=false;primary.BackgroundColor3=enabled==false and C.line or C.pink;primary.TextColor3=enabled==false and C.gray or C.white;doPrimary=fn
end
primary.Activated:Connect(function()if primary.Active and not pending and doPrimary then doPrimary()end end)
body.ChildAdded:Connect(function(o)if o:IsA('GuiObject')then order+=1;o.LayoutOrder=order end end)
local function clear(heading,step)
 for _,o in ipairs(body:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
 order=0;body.CanvasPosition=Vector2.zero;title.Text=heading;tag.Text=step or 'SIRIAI';toast.Visible=false
 visibility(true);action('계속',nil,false)
end
local function card(label,value,color)
 local f=make('Frame',body,{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.soft,BorderSizePixel=0});round(f)
 make('UIPadding',f,{PaddingLeft=UDim.new(0,16),PaddingRight=UDim.new(0,16),PaddingTop=UDim.new(0,14),PaddingBottom=UDim.new(0,14)})
 make('UIListLayout',f,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
 local small=txt(f,label,13,C.gray);small.LayoutOrder=1
 local main=txt(f,value,20,color or C.ink);main.Font=Enum.Font.GothamBold;main.LayoutOrder=2
 return f,main
end
local function input(label,value)
 txt(body,label,14,C.gray)
 local o=make('TextBox',body,{Text=value or '',PlaceholderText=label,ClearTextOnFocus=false,TextSize=17,Font=Enum.Font.Gotham,TextColor3=C.ink,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=C.white,BorderSizePixel=0,Size=UDim2.new(1,0,0,48)})
 round(o,9);make('UIPadding',o,{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)});return o
end
local function detail(value,label)
 local b=btn(body,label or '자세히 보기');b.TextSize=14;b.Size=UDim2.new(1,0,0,44);b.BackgroundTransparency=1;b.TextColor3=C.gray
 local t=txt(body,value,16,C.gray);t.Visible=false
 b.Activated:Connect(function()t.Visible=not t.Visible;b.Text=t.Visible and '접기' or (label or '자세히 보기')end)
end
local function images(keys,height,ratio)
 local f=make('Frame',body,{Size=UDim2.new(1,0,0,height),BackgroundTransparency=1})
 for i,key in ipairs(keys)do local im=Raster.draw(f,key,UDim2.new((i-1)/#keys,2,0,0),UDim2.new(1/#keys,-4,1,0));make('UIAspectRatioConstraint',im,{AspectRatio=ratio or 1,AspectType=Enum.AspectType.FitWithinMaxSize})end
 return f
end
local function submit(payload)
 if pending then return end;pending=true;action('저장 중…',nil,false)
 remote:FireServer({kind='apply',revision=state.revision,action=data.phases[state.phase].id,payload=payload})
 local revision=state.revision;task.delay(8,function()if pending and state.revision==revision then pending=false;notice('잠시 후 폰에서 이어하기를 눌러주세요.')end end)
end
local render
render=function(profileId)
 mode='work';pending=false
 local q=data.phases[state.phase]
 local d=drafts[q.id] or {step=1};drafts[q.id]=d
 local function screen(heading,step,total)clear(heading,q.title..(total and ('  ·  '..step..' / '..total) or ''))end
 if q.id=='brief'then
  screen('인플루언서 모집을\n로블록스에서!')
  txt(body,'브랜드에 어울리는 크리에이터를 찾고, 협업 DM을 보내는 일이에요.',18)
  card('오늘 찾을 크리에이터','뷰티 릴스\n팔로워 5천~3만')
  action('첫 캠페인 맡기',function()submit({reviewed=true})end)
 elseif q.id=='profile'then
  screen('이렇게 준비해요')
  local f=make('Frame',body,{Size=UDim2.new(1,0,0,82),BackgroundTransparency=1})
  Raster.draw(f,'logo',UDim2.fromOffset(0,4),UDim2.fromOffset(68,68))
  local t=txt(f,'siriai_partner',20);t.Font=Enum.Font.GothamBold;t.Position=UDim2.fromOffset(84,5);t.Size=UDim2.new(1,-84,0,28)
  t=txt(f,data.bio,15,C.gray);t.Position=UDim2.fromOffset(84,36);t.Size=UDim2.new(1,-84,0,44)
  images({'brand1','brand2','brand3'},94,.8);images({'brand4','brand5','brand6'},94,.8)
  txt(body,'받은 로고·게시물·소개를 그대로 적용해요.',17)
  detail('프로필 링크: '..data.link..'\n부계정도 사용할 수 있어요.','프로필 링크 확인')
  action('이 프로필 적용',function()submit({photo='siriai',bio=data.bio,link=data.link,posts=true})end)
 elseif q.id=='connect'then
  if d.step==1 then
   screen('시트에 연결해요',1,2)
   local url=input('Apps Script 웹앱 URL',d.url or '');url.TextSize=14
   url:GetPropertyChangedSignal('Text'):Connect(function()d.url=url.Text end)
   btn(body,'받은 주소 붙여넣기',function()url.Text=data.webAppUrl end)
   local name=input('저장자 이름',d.name or player.DisplayName or '');d.name=name.Text
   name:GetPropertyChangedSignal('Text'):Connect(function()d.name=name.Text end)
   detail('Chrome 웹 스토어에서 IG Lead Saver 설치 → 확장 프로그램의 세부정보 → 확장 프로그램 옵션.\n내 이름으로 수집한 인원을 구분해요.','옵션 화면 여는 법')
   action('연결 확인',function()
    if url.Text~=data.webAppUrl or not name.Text:find('%S')then notice('받은 주소와 저장자 이름을 넣어주세요.');return end
    d.step=2;render()
   end)
  else
   screen('이 캠페인에 저장해요',2,2)
   card('연결 완료',data.campaign,C.green)
   card('처음 저장할 상태','연락전')
   txt(body,'저장 후 기존 목록을 불러와 중복을 확인해요.',18)
   action('설정 저장 · 목록 불러오기',function()submit({url=data.webAppUrl,name=d.name,tab=data.campaign,status='연락전',tested=true,loaded=true})end)
  end
 elseif q.id=='discover'then
  local p=data.profiles[1];for _,item in ipairs(data.profiles)do if item.id==profileId then p=item end end
  d.profile=p.id;screen('@'..p.handle)
  images({'creator'..p.posts[1],'creator'..p.posts[2],'creator'..p.posts[3]},138)
  card(p.genre,tostring(p.followers)..' 팔로워')
  txt(body,p.recent,18)
  if not p.fits then
   txt(body,p.followers<5000 and '이번 기준은 팔로워 5천 명 이상이에요.' or '이번에는 뷰티 릴스 계정을 찾아요.',18,C.gray)
   action('다른 계정 살펴보기',closePanel)
  elseif d.checked then
   txt(body,'✓ 기존 접촉 없음',17,C.green)
   action('시트에 저장',function()submit({handle=p.handle,reviewed=true,historyChecked=true})end)
  else
   action('기존 접촉 이력 확인',function()d.checked=true;render(p.id)end)
  end
 elseif q.id=='send'then
  if d.step==1 then
   screen('제안을 보낼 대상이에요',1,3)
   card('진행 시트','@beauty_sample\n팔로워 1.8만 · 연락전')
   txt(body,'팔로워 구간에 맞춰 전달받은 문구를 사용해요.',18)
   action('1만~3만 구간 문구 열기',function()d.step=2;render()end)
  elseif d.step==2 then
   screen('기본 고료가 담겨 있어요',2,3)
   card('@beauty_sample에게','안녕하세요, 시리아이입니다 :)\n뷰티 릴스 캠페인 협업을 제안드립니다.\n제안 고료 10만 원\n관심 있으시면 지원 부탁드립니다.')
   action('DM 보내기',function()d.step=3;render()end)
  else
   screen('시트에도 남겨요',3,3)
   card('DM을 보냈어요','@beauty_sample',C.green)
   card('변경할 상태','연락전 → DM 발송')
   action('DM 발송으로 저장',function()submit({handle=data.lead.handle,fee=data.lead.fee,sent=true,status='DM 발송'})end)
  end
 elseif q.id=='reply'then
  screen('지원 완료 소식이 왔어요')
  card('@beauty_sample','안내해주신 캠페인에 지원했어요!')
  txt(body,'감사합니다. 선정되면 안내드릴게요 :)',18)
  action('이렇게 답장하기',function()submit({replied=true,applicationRead=true})end)
 elseif q.id=='settle'then
  screen('이번 모집을 마무리해요')
  txt(body,'이후 도착한 브랜드 안내: @beauty_sample 최종 선정',17,C.green)
  card('유효 DM 1건 + 최종 선정 1명','300원 + 2,000원')
  card('세전 보수 예시','2,300원',C.pink)
  detail('유효 발송 1건당 300원, 최종 선정 1명당 2,000원입니다. 월 1회, 계약서의 정산 기준과 지급일에 따라 지급해요.','정산 기준 보기')
  action('첫 캠페인 마치기',function()submit({reviewed=true,selectionRead=true})end)
 end
end
local marker,highlight=nil,nil
local function update()
 local q=data.phases[state.phase]
 phaseText.Text=state.complete and '첫 캠페인 완료!' or q.title
 objective.Text=state.complete and '바다로 이동 →' or q.place..' · 바로 이동 →'
 if marker then marker:Destroy()end;if highlight then highlight:Destroy()end
 if not state.complete then
  local world=workspace:FindFirstChild('TrainingMap');local p=world and world:FindFirstChild('Target_'..q.target,true)
  if p then
   marker=make('BillboardGui',gui,{Adornee=p,Size=UDim2.fromOffset(160,40),StudsOffsetWorldSpace=Vector3.new(0,5,0),AlwaysOnTop=true,MaxDistance=650})
   local t=txt(marker,'!  '..q.place,16,C.white,40);t.BackgroundColor3=C.pink;t.TextXAlignment=Enum.TextXAlignment.Center;t.TextYAlignment=Enum.TextYAlignment.Center;round(t,10)
   highlight=make('Highlight',p,{Adornee=p,FillColor=C.pink,FillTransparency=.9,OutlineColor=C.pink,OutlineTransparency=.15})
  end
 end
 prompts()
end
local function navigation(kind)
 closePanel();remote:FireServer({kind=kind,revision=state.revision})
end
objective.Activated:Connect(function()navigation(state.complete and 'rest' or 'travel')end)
local appendix
appendix=function(item)
 if not state.complete then return end
 mode='appendix'
 if item then
  clear(item.title,'부록 / 필요할 때만')
  card('이런 문의가 오면',item.question)
  card('답장 예시',item.reply)
  txt(body,item.note,18)
  action('부록 목록으로',function()appendix()end)
 else
  clear('필요할 때 보는 부록','기본 과정 완료')
  for _,topic in ipairs(data.appendix)do
   local item=topic;btn(body,item.title,function()appendix(item)end)
  end
  action('닫고 쉬기',closePanel)
 end
end
local function phone()
 -- Neither a tool equip nor a late packet can interrupt an active work screen.
 if panel.Visible or pending then return end
 mode='phone';clear('리크루터 폰','SIRIAI / 빠른 이동')
 if state.complete then
  card('첫 캠페인 완료','유효 DM 1건 · 최종 선정 1명')
  btn(body,'필요할 때 보는 부록',function()appendix()end)
  btn(body,'처음부터 다시',function()drafts={};navigation('restart')end)
  action('노을 바다로 가기',function()navigation('rest')end)
 else
  local q=data.phases[state.phase];card('현재 할 일',q.title)
  txt(body,q.place,18,C.gray)
  btn(body,'목표 위치로 이동',function()navigation('travel')end)
  action('이어서 하기',function()navigation('resume')end)
 end
end
phoneButton.Activated:Connect(phone)
helpButton.Activated:Connect(function()
 if panel.Visible then return end
 mode='help';clear('조작 안내')
 card('대화 · 작업','가까이에서 E / 화면 터치')
 card('이어하기 · 빠른 이동','폰 버튼 / P 키')
 detail('폰은 장착할 때 한 번 열려요. 들고 있는 동안 좌클릭은 폰을 열지 않아요.\n모든 창은 ×로 닫을 수 있고, 진행 중인 작업은 폰에서 이어갈 수 있어요.')
 action('돌아가기',closePanel)
end)
UIS.InputBegan:Connect(function(input,processed)
 if processed then return end
 if input.KeyCode==Enum.KeyCode.P then
  if panel.Visible and mode=='phone'then closePanel()else phone()end
 end
end)
remote.OnClientEvent:Connect(function(packet)
 if packet.state then
  if packet.state.revision<state.revision then drafts={}end
  state=packet.state;update()
 end
 if packet.kind=='open'then
  if mode=='work' and panel.Visible then return end
  render(packet.profile)
 elseif packet.kind=='done'then
  pending=false;closePanel()
  if packet.continueHere then render(data.phases[state.phase].target)
  elseif state.complete then phone()
  else notice('✓ '..packet.text)end
 elseif packet.kind=='phone' or packet.kind=='finished'then phone()
 elseif packet.kind=='arrived'then closePanel();notice(packet.text)
 elseif packet.kind=='notice'then pending=false;notice(packet.text)end
end)
for attempt=1,4 do remote:FireServer({kind='hello'});task.wait(1)end
end
return Client
