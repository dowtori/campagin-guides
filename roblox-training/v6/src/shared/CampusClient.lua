-- SIRIAI v6.7: one visible action, deliberate phone access, resumable work.
local Client={}
function Client.start(gui)
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local data=require(script.Parent:WaitForChild('CaseData'))
local Raster=require(script.Parent:WaitForChild('RasterRenderer'))
local remote=RS:WaitForChild('CampusEvent')
local Reward=require(script.Parent:WaitForChild('RewardPolicy'))
local rewardView,advancedView
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
local panelLimit=make('UISizeConstraint',panel,{MaxSize=Vector2.new(510,660)})
local tag=txt(panel,'SIRIAI',12,C.gray,18);tag.Position=UDim2.fromOffset(22,20);tag.Size=UDim2.new(1,-80,0,18)
local title=txt(panel,'',26,C.ink,64);title.Position=UDim2.fromOffset(22,47);title.Size=UDim2.new(1,-44,0,64);title.Font=Enum.Font.GothamBold
local body=make('ScrollingFrame',panel,{Name='WorkBody',Position=UDim2.fromOffset(22,124),Size=UDim2.new(1,-44,1,-214),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y})
make('UIListLayout',body,{Padding=UDim.new(0,18),SortOrder=Enum.SortOrder.LayoutOrder})
make('UIPadding',body,{PaddingRight=UDim.new(0,4),PaddingBottom=UDim.new(0,14)})
local primary=btn(panel,'계속');primary.Name='PrimaryAction';primary.Position=UDim2.new(0,22,1,-70);primary.Size=UDim2.new(1,-44,0,50);primary.BackgroundColor3=C.pink;primary.TextColor3=C.white
local secondary=btn(panel,'이미 완료했습니다');secondary.Name='SecondaryAction';secondary.Position=UDim2.new(0,22,1,-126);secondary.Size=UDim2.new(1,-44,0,46);secondary.Visible=false
local doPrimary,doSecondary=nil,nil
secondary.Activated:Connect(function()if secondary.Visible and secondary.Active and not pending and doSecondary then doSecondary()end end)
local function alternate(caption,fn)
 secondary.Text=caption;secondary.Visible=true;secondary.Active=true;doSecondary=fn
 body.Size=UDim2.new(1,-44,1,-270)
end
local promptList={}
local world=workspace:FindFirstChild('TrainingMap')
if world then for _,o in ipairs(world:GetDescendants())do if o:IsA('ProximityPrompt')then table.insert(promptList,o)end end end
local function prompts()
 local q=data.phases[state.phase]
 for _,o in ipairs(promptList)do
  if o:IsA('ProximityPrompt')then
   local id=o.Parent:FindFirstChild('ActionID');id=id and id.Value
   if id then o.Enabled=not panel.Visible and not state.complete and id==q.target end
  end
 end
end
local function visibility(show)
 panel.Visible=show;hud.Visible=not show;phoneButton.Visible=not show;helpButton.Visible=not show;prompts()
end
local function closePanel()visibility(false);mode=nil end
if world and world:FindFirstChild('PierThumbsUp',true) then rewardView=require(script.Parent:WaitForChild('RewardClient')).start(gui,notice)end
if world and world:FindFirstChild('AdvancedRoom',true) then advancedView=require(script.Parent:WaitForChild('AdvancedClient')).start(gui,closePanel,notice,function()closePanel();remote:FireServer({kind='rest'})end)end
local close=btn(panel,'×',closePanel);close.Name='ClosePanel';close.Position=UDim2.new(1,-54,0,12);close.Size=UDim2.fromOffset(42,42)
local function action(caption,fn,enabled)
 primary.Text=caption;primary.Active=enabled~=false;primary.BackgroundColor3=enabled==false and C.line or C.pink;primary.TextColor3=enabled==false and C.gray or C.white;doPrimary=fn
end
primary.Activated:Connect(function()if primary.Active and not pending and doPrimary then doPrimary()end end)
body.ChildAdded:Connect(function(o)if o:IsA('GuiObject')then order+=1;o.LayoutOrder=order end end)
local function clear(heading,step)
 panel.AnchorPoint=Vector2.new(1,.5);panel.Position=UDim2.new(.97,0,.52,0);panel.Size=UDim2.new(.94,0,.84,0);panelLimit.MaxSize=Vector2.new(510,660)
 tag.Position=UDim2.fromOffset(22,20);title.Position=UDim2.fromOffset(22,47);title.Size=UDim2.new(1,-44,0,64)
 body.Position=UDim2.fromOffset(22,124)
 for _,o in ipairs(body:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
 order=0;body.CanvasPosition=Vector2.zero;title.Text=heading;tag.Text=step or 'SIRIAI';toast.Visible=false
 secondary.Visible=false;doSecondary=nil;body.Size=UDim2.new(1,-44,1,-214)
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
-- One offered action at a time; taps fill the example, never ask for a sequence.
local function profilePreview(filled)
 local f=make('Frame',body,{Name='ProfilePreview',Size=UDim2.new(1,0,0,340),BackgroundColor3=C.white,BorderSizePixel=0});round(f,12)
 local logo=make('Frame',f,{Name='LogoSlot',Position=UDim2.fromOffset(14,14),Size=UDim2.fromOffset(58,58),BackgroundColor3=C.soft,BorderSizePixel=0});round(logo,29)
 if filled>=1 then Raster.draw(logo,'logo')else local t=txt(logo,'로고',14,C.gray,58);t.TextXAlignment=Enum.TextXAlignment.Center;t.TextYAlignment=Enum.TextYAlignment.Center end
 local handle=txt(f,'siriai_partner',18,C.ink,24);handle.Position=UDim2.fromOffset(86,14);handle.Size=UDim2.new(1,-100,0,24);handle.Font=Enum.Font.GothamBold
 local bio=txt(f,filled>=3 and data.bio or '프로필 소개',15,C.gray,44);bio.Name='BioSlot';bio.Position=UDim2.fromOffset(86,42);bio.Size=UDim2.new(1,-100,0,44)
 local link=txt(f,filled>=3 and '✓ 제공된 프로필 링크' or '프로필 링크',14,filled>=3 and C.green or C.gray,22);link.Name='LinkSlot';link.Position=UDim2.fromOffset(14,91);link.Size=UDim2.new(1,-28,0,22)
 local grid=make('Frame',f,{Name='PostSlots',Position=UDim2.fromOffset(14,122),Size=UDim2.new(1,-28,0,204),BackgroundTransparency=1})
 for i=1,6 do
  local col=(i-1)%3;local row=math.floor((i-1)/3)
  local slot=make('Frame',grid,{Name='Post'..i,Position=UDim2.new(col/3,0,row/2,0),Size=UDim2.new(1/3,-4,.5,-4),BackgroundColor3=C.soft,BorderSizePixel=0})
  if filled>=2 then local im=Raster.draw(slot,'brand'..i);make('UIAspectRatioConstraint',im,{AspectRatio=.8,AspectType=Enum.AspectType.FitWithinMaxSize});im.AnchorPoint=Vector2.new(.5,.5);im.Position=UDim2.fromScale(.5,.5)end
 end
end
local function connectionPreview(filled)
 local f=make('Frame',body,{Name='ConnectionPreview',Size=UDim2.new(1,0,0,274),BackgroundColor3=C.white,BorderSizePixel=0});round(f,12)
 local app=txt(f,filled>=1 and '✓ IG Lead Saver 설치됨' or 'IG Lead Saver',18,filled>=1 and C.green or C.gray,28);app.Name='ExtensionSlot';app.Position=UDim2.fromOffset(16,14);app.Size=UDim2.new(1,-32,0,28);app.Font=Enum.Font.GothamBold
 local function field(name,label,value,y,ready)
  local t=txt(f,label,12,C.gray,18);t.Position=UDim2.fromOffset(16,y);t.Size=UDim2.new(1,-32,0,18)
  local v=txt(f,value,16,ready and C.ink or C.gray,32);v.Name=name;v.Position=UDim2.fromOffset(16,y+20);v.Size=UDim2.new(1,-32,0,32);v.BackgroundColor3=C.soft;v.TextYAlignment=Enum.TextYAlignment.Center;round(v,6)
  make('UIPadding',v,{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)})
 end
 field('AddressSlot','웹앱 URL',filled>=2 and '✓ 받은 주소 입력됨' or '받은 주소가 들어갈 자리',50,filled>=2)
 field('SaverSlot','저장자 이름',filled>=2 and '✓ 본인 이름' or '이름이 들어갈 자리',110,filled>=2)
 field('CampaignSlot','진행 중인 캠페인',filled>=3 and data.campaign or '안내받은 캠페인',170,filled>=3)
 local result=txt(f,filled>=3 and '✓ 연결·저장 완료  ·  연락전  ·  기존 목록 확인' or '',13,filled>=3 and C.green or C.gray,36);result.Name='ConnectionResult';result.Position=UDim2.fromOffset(16,232);result.Size=UDim2.new(1,-32,0,36)
end
local render
local function setupLesson(q,d)
 local profile=q.id=='profile';d.filled=d.filled or 0
 local section=profile and '계정 세팅' or '확장프로그램 설치·연결'
 local function complete(source)submit({assembled=true,understood=true,completion=source})end
 if d.view=='handoff' then
  clear('안내서로 설정하기',q.title)
  card('받은 안내서',section)
  txt(body,'설정을 마치면 돌아와 계속해주세요.',18)
  alternate('선택으로 돌아가기',function()d.view='choice';render()end)
  action('설정했습니다 · 계속',function()complete('guide_done')end)
 elseif d.view=='choice' then
  clear(profile and '실제 계정도 준비됐나요?' or '실제 연결도 마쳤나요?',q.title)
  txt(body,'아직이라면 받은 안내서에서 설정해요.',18)
  alternate('이미 완료했습니다',function()complete('already_done')end)
  action('지금 하기',function()d.view='handoff';render()end)
 else
  clear(profile and '모집 계정을 채워봐요' or '연결 화면을 채워봐요','설정 예시  ·  '..d.filled..' / 3')
  if profile then profilePreview(d.filled)else connectionPreview(d.filled)end
  local steps=profile and {
   {button='로고 넣기',hint='프로필 사진은 시리아이 로고.'},
   {button='게시물 6장 채우기',hint='게시물은 제공된 이미지 6장.'},
   {button='소개·링크 채우기',hint='소개와 링크는 받은 자료 그대로.'}
  } or {
   {button='확장프로그램 준비하기',hint='IG Lead Saver 설치 → 옵션 열기'},
   {button='주소·이름 채우기',hint='웹앱 주소와 저장자 이름 입력'},
   {button='캠페인 연결·저장',hint='연결 테스트 → 캠페인 선택·저장 → 기존 목록 불러오기'}
  }
  if d.filled<3 then
   local nextStep=steps[d.filled+1];txt(body,nextStep.hint,17)
   action(nextStep.button,function()d.filled+=1;render()end)
  else
   txt(body,'설정 방법을 이해했나요?',18)
   btn(body,'다시 채워보기',function()d.filled=0;d.understood=false;render()end)
   action('이해했어요',function()d.understood=true;d.view='choice';render()end)
  end
 end
end
render=function(profileId)
 mode='work';pending=false
 local q=data.phases[state.phase]
 local d=drafts[q.id] or {step=1};drafts[q.id]=d
 local function screen(heading,step,total)clear(heading,q.title..(total and ('  ·  '..step..' / '..total) or ''))end
 if q.id=='brief'then
  screen('인플루언서 모집을\n로블록스에서!')
  txt(body,'크리에이터를 찾고, 협업 DM을 보내요.',18)
  card('오늘 찾을 크리에이터','뷰티 릴스\n팔로워 5천~3만')
  action('첫 캠페인 맡기',function()submit({reviewed=true})end)
 elseif q.id=='profile' or q.id=='connect'then
  setupLesson(q,d)
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
  txt(body,'브랜드 최종 선정: @beauty_sample',17,C.green)
  card('유효 DM 1건 + 최종 선정 1명','300원 + 2,000원')
  card('세전 보수 예시','2,300원',C.pink)
  detail('월 1회, 계약서의 정산 기준과 지급일에 따라 지급해요.','지급 일정 보기')
  action('정산 확인 완료',function()submit({reviewed=true,selectionRead=true})end)
 end
end
local marker,highlight=nil,nil
local function update()
 if rewardView then rewardView.sync(state)end
 if advancedView then advancedView.sync(Reward.summary(state))end
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
 if not Reward.summary(state).unlocked then return end
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
-- Original native illustrations: a profile, sheet, creator, envelope, reply and receipt.
-- Menu composition references Conveyor Sushi Restaurant's large picture tiles.
local function chapterArt(parent,id)
 local function box(x,y,w,h,color,r)
  local f=make('Frame',parent,{Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),BackgroundColor3=color,BorderSizePixel=0})
  round(f,r or 6);return f
 end
 local function label(p,value,size)
  local t=txt(p,value,size or 18,C.ink);t.Size=UDim2.fromScale(1,1);t.AutomaticSize=Enum.AutomaticSize.None;t.TextXAlignment=Enum.TextXAlignment.Center;t.TextYAlignment=Enum.TextYAlignment.Center;t.Font=Enum.Font.GothamBold;return t
 end
 local function line(p,x,y,w,color)
  make('Frame',p,{Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,.06),BackgroundColor3=color or C.line,BorderSizePixel=0})
 end
 if id=='brief' then
  local f=box(.12,.02,.76,.96,C.white)
  local logo=make('Frame',f,{Position=UDim2.fromScale(.07,.13),Size=UDim2.fromScale(.22,.36),BackgroundTransparency=1});Raster.draw(logo,'logo');make('UIAspectRatioConstraint',logo,{AspectRatio=1,AspectType=Enum.AspectType.FitWithinMaxSize})
  local t=label(f,'BEAUTY',22);t.Position=UDim2.fromScale(.28,.1);t.Size=UDim2.fromScale(.66,.32)
  line(f,.08,.61,.83);line(f,.08,.78,.56,C.pink)
 elseif id=='profile' then
  local f=box(.16,.01,.68,.98,C.white)
  local im=Raster.draw(f,'logo',UDim2.fromScale(.09,.09),UDim2.fromScale(.28,.30));make('UIAspectRatioConstraint',im,{AspectRatio=1})
  line(f,.46,.15,.40,C.ink);line(f,.46,.29,.31)
  for i=1,3 do local post=Raster.draw(f,'brand'..i,UDim2.fromScale(.08+(i-1)*.29,.49),UDim2.fromScale(.26,.43));make('UIAspectRatioConstraint',post,{AspectRatio=.8,AspectType=Enum.AspectType.FitWithinMaxSize})end
 elseif id=='connect' then
  local f=box(.08,.08,.84,.84,C.white);line(f,.08,.12,.5,C.green)
  for y=1,3 do for x=1,3 do make('Frame',f,{Position=UDim2.fromScale(.08+(x-1)*.29,.31+(y-1)*.19),Size=UDim2.fromScale(.26,.14),BackgroundColor3=y==1 and Color3.fromRGB(191,219,206) or C.soft,BorderSizePixel=0})end end
 elseif id=='discover' then
  local f=box(.19,.01,.62,.98,C.white)
  Raster.draw(f,'creator1',UDim2.fromScale(.08,.06),UDim2.fromScale(.84,.71))
  local t=label(f,'1.8만',14);t.Position=UDim2.fromScale(0,.79);t.Size=UDim2.fromScale(1,.17)
 elseif id=='send' then
  local f=box(.10,.20,.80,.62,C.white);f.ClipsDescendants=true
  for _,edge in ipairs({{.25,20},{.75,-20}})do make('Frame',f,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(edge[1],.30),Size=UDim2.new(.58,0,0,3),Rotation=edge[2],BackgroundColor3=Color3.fromRGB(214,175,131),BorderSizePixel=0})end
  local seal=make('Frame',f,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.52),Size=UDim2.fromOffset(18,18),BackgroundColor3=C.pink,BorderSizePixel=0});round(seal,9)
 elseif id=='reply' then
  local incoming=box(.03,.05,.70,.45,C.white);label(incoming,'···',28)
  local outgoing=box(.27,.52,.70,.44,C.pink);label(outgoing,'✓',22).TextColor3=C.white
 else
  local f=box(.14,.01,.72,.98,C.white)
  local t=label(f,'300 + 2,000',14);t.Position=UDim2.fromScale(.02,.07);t.Size=UDim2.fromScale(.96,.26)
  line(f,.12,.43,.76)
  local v=label(f,'2,300',24);v.Position=UDim2.fromScale(0,.52);v.Size=UDim2.fromScale(1,.37);v.TextColor3=C.pink
 end
end
local function phone(refresh)
 -- Neither a tool equip nor a late packet can interrupt an active work screen.
 if (panel.Visible and not (refresh==true and mode=='phone')) or pending then return end
 local completed=state.completed or {};local count=0
 for _,q in ipairs(data.phases)do if completed[q.id]then count+=1 end end
 mode='phone';clear('챕터 선택','리크루터 폰  ·  '..count..' / '..#data.phases..' 완료')
 panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.52);panel.Size=UDim2.fromScale(.94,.88);panelLimit.MaxSize=Vector2.new(980,gui.AbsoluteSize.X<700 and 720 or (state.complete and 680 or 620))
 tag.Position=UDim2.fromOffset(22,16);title.Position=UDim2.fromOffset(22,40);title.Size=UDim2.new(1,-80,0,38)
 body.Position=UDim2.fromOffset(22,94);body.Size=UDim2.new(1,-44,1,-184)
 local narrow=gui.AbsoluteSize.X<700;local short=gui.AbsoluteSize.Y<500
 local topHeight=short and 140 or 214;local bottomHeight=short and 140 or 178
 local grid=make('Frame',body,{Name='ChapterMenu',Size=UDim2.new(1,0,0,narrow and 676 or topHeight+12+bottomHeight),BackgroundTransparency=1})
 local captions={'캠페인 받기','프로필 세팅','확장프로그램','크리에이터 찾기','DM 발송','회신 응대','정산 확인'}
 local colors={Color3.fromRGB(238,222,189),Color3.fromRGB(231,222,237),Color3.fromRGB(213,230,220),Color3.fromRGB(222,230,234),Color3.fromRGB(240,224,206),Color3.fromRGB(235,217,225),Color3.fromRGB(224,229,213)}
 for i,q in ipairs(data.phases)do
  local chapter=q;local current=not state.complete and state.phase==i
  local tile=make('TextButton',grid,{Name='Chapter_'..q.id,Text='',AutoButtonColor=true,BackgroundColor3=colors[i],BorderSizePixel=0,ClipsDescendants=true})
  round(tile,12)
  if narrow then
   if i==1 then tile.Position=UDim2.fromOffset(0,0);tile.Size=UDim2.new(1,0,0,160)
   else local j=i-2;tile.Position=UDim2.new((j%2)*.5,(j%2)*6,0,172+math.floor(j/2)*172);tile.Size=UDim2.new(.5,-6,0,160)end
  elseif i==1 then tile.Position=UDim2.fromOffset(0,0);tile.Size=UDim2.new(.5,-6,0,topHeight)
  elseif i<=3 then tile.Position=UDim2.new(.5+(i-2)*.25,6+(i-2)*3,0,0);tile.Size=UDim2.new(.25,-9,0,topHeight)
  else local j=i-4;tile.Position=UDim2.new(j*.25,j*3,0,topHeight+12);tile.Size=UDim2.new(.25,-9,0,bottomHeight)end
  local num=txt(tile,string.format('%02d',i),12,C.gray,18);num.Position=UDim2.fromOffset(12,10);num.Size=UDim2.fromOffset(30,18)
  if current or completed[q.id] then
   local badge=txt(tile,current and '진행 중' or '✓ 완료',12,current and C.pink or C.green,18);badge.Position=UDim2.new(1,-76,0,10);badge.Size=UDim2.fromOffset(64,18);badge.TextXAlignment=Enum.TextXAlignment.Right;badge.Font=Enum.Font.GothamBold
  end
  if current then make('UIStroke',tile,{Color=C.pink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})end
  local art=make('Frame',tile,{Name='ChapterArt',Position=UDim2.fromOffset(12,34),Size=UDim2.new(1,-24,1,-80),BackgroundTransparency=1});chapterArt(art,q.id)
  local name=txt(tile,captions[i],narrow and 16 or 18,C.ink,36);name.Position=UDim2.new(0,8,1,-40);name.Size=UDim2.new(1,-16,0,36);name.Font=Enum.Font.GothamBold;name.TextXAlignment=Enum.TextXAlignment.Center;name.TextYAlignment=Enum.TextYAlignment.Center
  tile.Activated:Connect(function()
   if pending then return end
   pending=true;closePanel();remote:FireServer({kind='chapter',revision=state.revision,chapter=chapter.id})
  end)
 end
 local earned=Reward.summary(state)
 if earned.unlocked then
  if advancedView then btn(body,earned.king and '왕따봉 해금! · 심화 다시 도전' or '심화 도전 · 왕따봉 해금  '..earned.bonus..'/3',advancedView.enter)end
 end
 if earned.basic>0 then
  btn(body,'따봉 보러 가기  ·  '..earned.score..'점',function()navigation('rest')end)
 end
 if state.complete then
  btn(body,'필요할 때 보는 부록',function()appendix()end)
  action('노을 바다로 가기',function()navigation('rest')end)
 else action('이어서 하기',function()navigation('resume')end)end
end
phoneButton.Activated:Connect(phone)
gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()if mode=='phone' and panel.Visible then phone(true)end end)
helpButton.Activated:Connect(function()
 if panel.Visible then return end
 mode='help';clear('조작 안내')
 card('대화 · 작업','가까이에서 E / 화면 터치')
 card('이어하기 · 빠른 이동','폰 버튼 / P 키')

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
  if packet.resetDraft then drafts[data.phases[state.phase].id]=nil end
  render(packet.profile)
 elseif packet.kind=='done'then
  pending=false;closePanel()
  if packet.continueHere then render(data.phases[state.phase].target)
  elseif state.complete then phone()
  else notice('✓ '..packet.text)end
 elseif packet.kind=='phone' or packet.kind=='finished'then phone()
 elseif packet.kind=='arrived'then closePanel();notice(packet.text)
 elseif packet.kind=='notice'then pending=false;notice(packet.text)
 elseif packet.kind=='state'then pending=false end
end)
for attempt=1,4 do remote:FireServer({kind='hello'});task.wait(1)end
end
return Client
