-- SIRIAI v6.14: measured dialogs, explicit actions and consistent type roles.
local Client={}
function Client.start(gui)
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local data=require(script.Parent:WaitForChild('CaseData'))
local Discovery=require(script.Parent:WaitForChild('DiscoveryLesson'))
local Sheet=require(script.Parent:WaitForChild('SheetLesson'))
local DialogLayout=require(script.Parent:WaitForChild('DialogLayout'))
local T={title=30,body=22,note=18,label=16,action=20}
local Raster=require(script.Parent:WaitForChild('RasterRenderer'))
local remote=RS:WaitForChild('CampusEvent')
local Reward=require(script.Parent:WaitForChild('RewardPolicy'))
local rewardView,advancedView
local player=Players.LocalPlayer
local status=gui:FindFirstChild('Status');if status then status:Destroy()end
local C={paper=Color3.fromRGB(250,249,247),ink=Color3.fromRGB(29,27,34),pink=Color3.fromRGB(223,25,64),gray=Color3.fromRGB(99,94,106),line=Color3.fromRGB(230,227,232),soft=Color3.fromRGB(239,236,240),white=Color3.new(1,1,1),green=Color3.fromRGB(60,105,80)}
local state={phase=1,revision=0,record={},complete=false}
local pending=false;local drafts={};local mode=nil;local order=0
local completionSerial=0;local completedSnapshot={};local restoreAcknowledgement
local function cancelAcknowledgement()
 completionSerial+=1
 if restoreAcknowledgement then restoreAcknowledgement();restoreAcknowledgement=nil end
end
local function make(class,parent,props)
 local o=Instance.new(class);for k,v in pairs(props or {})do o[k]=v end;o.Parent=parent;return o
end
local function round(o,r)make('UICorner',o,{CornerRadius=UDim.new(0,r or 12)})end
local function txt(parent,value,size,color,height)
 return make('TextLabel',parent,{Text=value,TextSize=size or T.body,TextColor3=color or C.ink,Font=Enum.Font.Gotham,LineHeight=1.2,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,BackgroundTransparency=1,Size=UDim2.new(1,0,0,height or 0),AutomaticSize=height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y})
end
local function btn(parent,value,fn)
 local o=make('TextButton',parent,{Text=value,TextSize=T.action,TextColor3=C.ink,Font=Enum.Font.GothamBold,TextWrapped=true,BackgroundColor3=C.soft,BorderSizePixel=0,Size=UDim2.new(1,0,0,52),AutoButtonColor=true})
 round(o,10);if fn then o.Activated:Connect(fn)end;return o
end
local hud=make('Frame',gui,{Name='ObjectiveHUD',Position=UDim2.new(.035,0,0,74),Size=UDim2.new(1,-126,0,160),BackgroundColor3=C.ink,BackgroundTransparency=.04,BorderSizePixel=0});round(hud,14)
make('UISizeConstraint',hud,{MaxSize=Vector2.new(360,224)})
local phaseText=txt(hud,'첫 캠페인 받기',24,C.white,60);phaseText.Name='ObjectiveTitle';phaseText.Position=UDim2.fromOffset(20,16);phaseText.Size=UDim2.new(1,-40,0,60);phaseText.Font=Enum.Font.GothamBold
local objective=make('TextButton',hud,{Name='ObjectiveAction',Text='준비 테라스로 이동 →',TextSize=20,TextColor3=C.white,Font=Enum.Font.GothamBold,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=C.pink,BorderSizePixel=0});round(objective,8);objective.Position=UDim2.fromOffset(20,92);objective.Size=UDim2.new(1,-40,0,48)
make('UIPadding',objective,{PaddingLeft=UDim.new(0,16),PaddingRight=UDim.new(0,16)})
local function fitHud()
 local width=math.min(360,gui.AbsoluteSize.X-126)-40
 local pixels=0;for _,code in utf8.codes(phaseText.Text)do pixels+=phaseText.TextSize*(code>=0x2E80 and 1 or code==32 and .36 or .62)end
 local height=math.max(30,math.ceil(pixels/math.max(100,width*.96))*29)
 phaseText.Size=UDim2.new(1,-40,0,height)
 objective.Position=UDim2.fromOffset(20,16+height+14)
 hud.Size=UDim2.new(1,-126,0,height+94)
end
phaseText:GetPropertyChangedSignal('Text'):Connect(fitHud)
fitHud()
local phoneButton=btn(gui,'폰  [P]');phoneButton.Name='PhoneButton';phoneButton.Size=UDim2.fromOffset(90,44);phoneButton.AnchorPoint=Vector2.new(1,0);phoneButton.Position=UDim2.new(.965,0,0,74)
local helpButton=btn(gui,'?');helpButton.Size=UDim2.fromOffset(44,44);helpButton.AnchorPoint=Vector2.new(1,0);helpButton.Position=UDim2.new(.965,0,0,126)
local toast=txt(gui,'',T.note,C.white,64);toast.AnchorPoint=Vector2.new(.5,1);toast.Position=UDim2.new(.5,0,1,UIS.TouchEnabled and -220 or -138);toast.Size=UDim2.new(.9,0,0,64);toast.AutomaticSize=Enum.AutomaticSize.Y;toast.Size=UDim2.new(.9,0,0,0);toast.BackgroundColor3=C.ink;toast.BackgroundTransparency=.04;toast.Visible=false;round(toast)
make('UIPadding',toast,{PaddingTop=UDim.new(0,12),PaddingBottom=UDim.new(0,12),PaddingLeft=UDim.new(0,16),PaddingRight=UDim.new(0,16)})
make('UISizeConstraint',toast,{MaxSize=Vector2.new(560,160),MinSize=Vector2.new(0,48)})
local serial=0
local function notice(value)
 serial+=1;local n=serial;toast.Text=value;toast.Visible=true
 task.delay(4,function()if serial==n then toast.Visible=false end end)
end
local panel=make('Frame',gui,{Name='WorkPanel',AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-16,.5,0),Size=UDim2.fromOffset(560,320),BackgroundColor3=C.paper,BorderSizePixel=0,Visible=false});round(panel,18)
local panelLimit=make('UISizeConstraint',panel,{MaxSize=Vector2.new(560,780)})
local tag=txt(panel,'SIRIAI',T.label,C.gray,24);tag.Name='DialogContext';tag.Position=UDim2.fromOffset(24,24);tag.Size=UDim2.new(1,-100,0,24)
local title=txt(panel,'',T.title);title.Name='DialogTitle';title.Position=UDim2.fromOffset(24,56);title.Size=UDim2.new(1,-48,0,0);title.Font=Enum.Font.GothamBold
local body=make('ScrollingFrame',panel,{Name='WorkBody',Position=UDim2.fromOffset(24,112),Size=UDim2.new(1,-48,0,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=C.gray,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ClipsDescendants=true})
local bodyLayout=make('UIListLayout',body,{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder})
make('UIPadding',body,{PaddingRight=UDim.new(0,6),PaddingBottom=UDim.new(0,4)})
local primary=btn(panel,'계속');primary.Name='PrimaryAction';primary.Size=UDim2.new(1,-48,0,52);primary.BackgroundColor3=C.pink;primary.TextColor3=C.white
local secondary=btn(panel,'이미 완료했습니다');secondary.Name='SecondaryAction';secondary.Size=UDim2.new(1,-48,0,52);secondary.Visible=false
local measureCards
local layoutDirty=true;local dialogWidth=560;local centeredDialog=false
local function requestLayout()layoutDirty=true end
local function fitDialog()
 if mode=='phone' then return end
 if measureCards then measureCards(math.min(dialogWidth,math.max(240,gui.AbsoluteSize.X-32))-90) end
 local titleHeight=title.TextBounds and title.TextBounds.Y or 36
 local content=bodyLayout.AbsoluteContentSize and bodyLayout.AbsoluteContentSize.Y or 0
 if content>0 then content+=4 end
 local m=DialogLayout.measure(gui.AbsoluteSize.X,gui.AbsoluteSize.Y,titleHeight,content,secondary.Visible,{width=dialogWidth,primary=primary.Visible})
 if mode=='complete' or centeredDialog then m.centered=true end
 panel.Size=UDim2.fromOffset(m.width,m.height)
 panel.AnchorPoint=Vector2.new(m.centered and .5 or 1,.5)
 panel.Position=m.centered and UDim2.fromScale(.5,.5) or UDim2.new(1,-16,.5,0)
 body.Position=UDim2.fromOffset(24,m.bodyY);body.Size=UDim2.new(1,-48,0,m.bodyHeight)
 primary.Position=UDim2.fromOffset(24,m.primaryY);secondary.Position=UDim2.fromOffset(24,m.secondaryY)
end
bodyLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(requestLayout)
title:GetPropertyChangedSignal('TextBounds'):Connect(requestLayout)
secondary:GetPropertyChangedSignal('Visible'):Connect(requestLayout)
game:GetService('RunService').Heartbeat:Connect(function()
 if layoutDirty and panel.Visible and mode~='phone' then layoutDirty=false;fitDialog() end
end)
local doPrimary,doSecondary=nil,nil
secondary.Activated:Connect(function()if secondary.Visible and secondary.Active and not pending and doSecondary then doSecondary()end end)
local function alternate(caption,fn)
 secondary.Text=caption;secondary.Visible=true;secondary.Active=true;doSecondary=fn;requestLayout()
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
local function closePanel()cancelAcknowledgement();visibility(false);mode=nil end
if world and world:FindFirstChild('PierThumbsUp',true) then rewardView=require(script.Parent:WaitForChild('RewardClient')).start(gui)end
if world and world:FindFirstChild('AdvancedRoom',true) then advancedView=require(script.Parent:WaitForChild('AdvancedClient')).start(gui,closePanel,notice,function()closePanel();remote:FireServer({kind='rest'})end)end
local close=btn(panel,'×',closePanel);close.Name='ClosePanel';close.Position=UDim2.new(1,-56,0,12);close.Size=UDim2.fromOffset(44,44);close.TextSize=26
local function action(caption,fn,enabled)
 primary.Text=caption;primary.Active=enabled~=false;primary.AutoButtonColor=enabled~=false;primary.BackgroundColor3=enabled==false and C.line or C.pink;primary.TextColor3=enabled==false and C.gray or C.white;doPrimary=fn
end
primary.Activated:Connect(function()if primary.Active and not pending and doPrimary then doPrimary()end end)
body.ChildAdded:Connect(function(o)if o:IsA('GuiObject')then order+=1;o.LayoutOrder=order end end)
local function clear(heading,step)
 cancelAcknowledgement()
 tag.TextSize=T.label;tag.TextColor3=C.gray
 dialogWidth=560;centeredDialog=false;primary.Visible=true
 panelLimit.MaxSize=Vector2.new(560,780);panel.BackgroundColor3=C.paper
 tag.Visible=true;title.TextSize=T.title;title.TextColor3=C.ink;primary.TextSize=T.action
 tag.Position=UDim2.fromOffset(24,24);title.Position=UDim2.fromOffset(24,56);title.Size=UDim2.new(1,-48,0,0);title.AutomaticSize=Enum.AutomaticSize.Y
 primary.Size=UDim2.new(1,-48,0,52);secondary.Size=UDim2.new(1,-48,0,52)
 for _,o in ipairs(body:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
 order=0;body.CanvasPosition=Vector2.zero;title.Text=heading;tag.Text=step or 'SIRIAI';toast.Visible=false
 secondary.Visible=false;doSecondary=nil
 requestLayout();fitDialog();visibility(true);action('계속',nil,false)
end
local cards={}
local function card(label,value,color)
 local f=make('Frame',body,{Name='InfoCard',Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.soft,BorderSizePixel=0});round(f)
 make('UIPadding',f,{PaddingLeft=UDim.new(0,18),PaddingRight=UDim.new(0,18),PaddingTop=UDim.new(0,16),PaddingBottom=UDim.new(0,16)})
 make('UIListLayout',f,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
 local small=txt(f,label,T.label,C.gray);small.Name='CardLabel';small.LayoutOrder=1
 local main=txt(f,value,T.body,color or C.ink);main.Name='CardValue';main.LayoutOrder=2
 table.insert(cards,{frame=f,label=small,value=main})
 return f,main
end
measureCards=function(width)
 local service=game:GetService('TextService')
 local function measure(t)
  local lines=0
  for line in (t.Text..'\n'):gmatch('(.-)\n')do
   local pixels=0
   for _,code in utf8.codes(line)do pixels+=t.TextSize*(code>=0x2E80 and 1 or code==32 and .36 or .62)end
   lines+=math.max(1,math.ceil(pixels/math.max(80,width*.94)))
  end
  local height=math.ceil(lines*t.TextSize*1.24)+4
  if service then
   local ok,bounds=pcall(function()return service:GetTextSize(t.Text,t.TextSize,t.Font,Vector2.new(math.max(80,width),10000))end)
   if ok and bounds then height=math.max(height,math.ceil(bounds.Y*1.2)+2)end
  end
  t.AutomaticSize=Enum.AutomaticSize.None;t.Size=UDim2.new(1,0,0,height)
  return height
 end
 for i=#cards,1,-1 do
  local c=cards[i]
  if not c.frame.Parent then table.remove(cards,i)
  else local h=measure(c.label)+8+measure(c.value)+32;c.frame.AutomaticSize=Enum.AutomaticSize.None;c.frame.Size=UDim2.new(1,0,0,h)end
 end
end
local function note(value,color)return txt(body,value,T.note,color or C.gray)end
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
 local f=make('Frame',body,{Name='ProfilePreview',Size=UDim2.new(1,0,0,364),BackgroundColor3=C.white,BorderSizePixel=0});round(f,12)
 local logo=make('Frame',f,{Name='LogoSlot',Position=UDim2.fromOffset(14,14),Size=UDim2.fromOffset(58,58),BackgroundColor3=C.soft,BorderSizePixel=0});round(logo,29)
 if filled>=1 then Raster.draw(logo,'logo')else local t=txt(logo,'로고',T.label,C.gray,58);t.TextXAlignment=Enum.TextXAlignment.Center;t.TextYAlignment=Enum.TextYAlignment.Center end
 local handle=txt(f,'siriai_partner',20,C.ink,24);handle.Position=UDim2.fromOffset(86,14);handle.Size=UDim2.new(1,-100,0,24);handle.Font=Enum.Font.GothamBold
 local bio=txt(f,filled>=3 and data.bio or '프로필 소개',18,C.gray,68);bio.Name='BioSlot';bio.Position=UDim2.fromOffset(86,42);bio.Size=UDim2.new(1,-100,0,68)
 local link=txt(f,filled>=3 and '✓ 제공된 프로필 링크' or '프로필 링크',16,filled>=3 and C.green or C.gray,22);link.Name='LinkSlot';link.Position=UDim2.fromOffset(14,114);link.Size=UDim2.new(1,-28,0,22)
 local grid=make('Frame',f,{Name='PostSlots',Position=UDim2.fromOffset(14,146),Size=UDim2.new(1,-28,0,204),BackgroundTransparency=1})
 for i=1,6 do
  local col=(i-1)%3;local row=math.floor((i-1)/3)
  local slot=make('Frame',grid,{Name='Post'..i,Position=UDim2.new(col/3,0,row/2,0),Size=UDim2.new(1/3,-4,.5,-4),BackgroundColor3=C.soft,BorderSizePixel=0})
  if filled>=2 then local im=Raster.draw(slot,'brand'..i);make('UIAspectRatioConstraint',im,{AspectRatio=.8,AspectType=Enum.AspectType.FitWithinMaxSize});im.AnchorPoint=Vector2.new(.5,.5);im.Position=UDim2.fromScale(.5,.5)end
 end
end
local function connectionPreview(filled)
 local f=make('Frame',body,{Name='ConnectionPreview',Size=UDim2.new(1,0,0,374),BackgroundColor3=C.white,BorderSizePixel=0});round(f,12)
 local app=txt(f,filled>=1 and '✓ IG Lead Saver 설치됨' or 'IG Lead Saver',20,filled>=1 and C.green or C.gray,28);app.Name='ExtensionSlot';app.Position=UDim2.fromOffset(16,14);app.Size=UDim2.new(1,-32,0,28);app.Font=Enum.Font.GothamBold
 local function field(name,label,value,y,ready)
  local t=txt(f,label,T.label,C.gray,22);t.Position=UDim2.fromOffset(16,y);t.Size=UDim2.new(1,-32,0,22)
  local v=txt(f,value,20,ready and C.ink or C.gray,50);v.Name=name;v.Position=UDim2.fromOffset(16,y+26);v.Size=UDim2.new(1,-32,0,50);v.BackgroundColor3=C.soft;v.TextYAlignment=Enum.TextYAlignment.Center;round(v,6)
  make('UIPadding',v,{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)})
 end
 field('AddressSlot','웹앱 URL',filled>=2 and '✓ 받은 주소 입력됨' or '받은 주소가 들어갈 자리',50,filled>=2)
 field('SaverSlot','저장자 이름',filled>=2 and '✓ 본인 이름' or '이름이 들어갈 자리',138,filled>=2)
 field('CampaignSlot','진행 중인 캠페인',filled>=3 and data.campaign or '안내받은 캠페인',226,filled>=3)
 local result=txt(f,filled>=3 and '✓ 저장 완료 · 연락전 · 기존 목록 확인' or '',16,filled>=3 and C.green or C.gray,44);result.Name='ConnectionResult';result.Position=UDim2.fromOffset(16,314);result.Size=UDim2.new(1,-32,0,44)
end
local render
local function setupLesson(q,d)
 local profile=q.id=='profile';d.filled=d.filled or 0
 local section=profile and '계정 세팅' or '확장프로그램 설치·연결'
 local function complete(source)submit({assembled=true,understood=true,completion=source})end
 if d.view=='handoff' then
  clear('안내서로 설정하기',q.title)
  txt(body,'메일의 안내서에서 '..section..'을 마친 뒤 돌아오세요.',T.body)
  alternate('선택으로 돌아가기',function()d.view='choice';render()end)
  action('설정했습니다 · 계속',function()complete('guide_done')end)
 elseif d.view=='choice' then
  clear(profile and '실제 계정도 준비됐나요?' or '실제 연결도 마쳤나요?',q.title)
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
   local nextStep=steps[d.filled+1];note(nextStep.hint)
   action(nextStep.button,function()d.filled+=1;render()end)
  else
   txt(body,'설정 방법을 이해했나요?',T.body)
   btn(body,'다시 채워보기',function()d.filled=0;d.understood=false;render()end)
   action('이해했어요',function()d.understood=true;d.view='choice';render()end)
  end
 end
end
render=function(profileId)
 mode='work';pending=false
 local q=data.phases[state.phase]
 local lead=data.lead;for _,p in ipairs(data.profiles)do if p.handle==state.record.handle then lead=p end end
 local leadHandle=state.record.handle or data.lead.handle
 local leadFollowers=string.format('%.1f만',lead.followers/10000)
 local d=drafts[q.id] or {step=1};drafts[q.id]=d
 local function screen(heading,step,total)clear(heading,q.place..(total and ('  ·  '..step..' / '..total) or ''))end
 if q.id=='brief'then
  screen('첫 캠페인을 맡아볼까요?')
  card('이번 연습의 모집 기준',data.criteria)
  action('첫 캠페인 맡기',function()submit({reviewed=true})end)
 elseif q.id=='profile' or q.id=='connect'then
  setupLesson(q,d)
 elseif q.id=='discover'then
  Discovery.render({make=make,txt=txt,btn=btn,round=round,body=body,colors=C,raster=Raster,
   UDim2=UDim2,UDim=UDim,Vector2=Vector2,Enum=Enum,width=gui.AbsoluteSize.X,height=gui.AbsoluteSize.Y,
   clear=clear,card=card,action=action,alternate=alternate,submit=submit,render=function()render()end,
   configure=function(width,footer)
    dialogWidth=width;centeredDialog=true;panelLimit.MaxSize=Vector2.new(width,780);primary.Visible=footer
    requestLayout();fitDialog()
   end},data,d)
 elseif q.id=='send'then
  if d.step==1 then
   screen('DM 보낼 계정',1,3)
   card('지정 캠페인 · 발송 대상','@'..leadHandle..'\n실제 팔로워 '..leadFollowers..' · 연락전')
   note('인스타그램의 실제 팔로워 수로 문구를 골라요.')
   action('1만~5만 미만 문구 열기',function()d.step=2;render()end)
  elseif d.step==2 then
   screen('DM 미리보기',2,3)
   local bubble=card('@'..leadHandle..'에게',data.dmExample);bubble.Name='CampaignDM'
   action('DM 보내기',function()d.step=3;render()end)
  else
   screen('발송 기록',3,3)
   Sheet.render({make=make,txt=txt,btn=btn,body=body,colors=C,raster=Raster,UDim2=UDim2,Vector2=Vector2,Enum=Enum,width=gui.AbsoluteSize.X,
    render=function()render()end,configure=function(width,footer)dialogWidth=width;centeredDialog=true;panelLimit.MaxSize=Vector2.new(width,780);primary.Visible=footer;requestLayout()end},data,lead,d)
   note('발송 1건 · 특이사항 없음')
   action('발송 기록 완료',function()submit({handle=leadHandle,fee=data.lead.fee,sent=true,status='DM 발송'})end,d.status=='DM 발송')
  end
 elseif q.id=='reply'then
  screen('도착한 회신')
  card('받은 메시지 · @'..leadHandle,'안내해주신 캠페인에 지원했어요!')
  alternate('답장 없이 확인',function()submit({applicationRead=true,reaction='none'})end)
  action('♥ 좋아요',function()submit({applicationRead=true,reaction='like'})end)
 elseif q.id=='settle'then
  screen('정산 확인')
  note('최종 선정 확인 · @'..leadHandle,C.green)
  card('유효 DM 1건 + 최종 선정 1명','300원 + 2,000원')
  local _,total=card('세전 합계','2,300원',C.pink);total.TextSize=34;total.Font=Enum.Font.GothamBold
  note('월 1회, 계약서의 정산일에 지급해요.')
  action('정산 확인 완료',function()submit({reviewed=true,selectionRead=true})end)
 end
end
local marker,highlight=nil,nil
local function update()
 cancelAcknowledgement()
 if rewardView then rewardView.sync(state)end
 if advancedView then advancedView.sync(Reward.summary(state))end
 local q=data.phases[state.phase]
 phaseText.Text=state.complete and '첫 캠페인 완료' or q.title
 objective.Text=state.complete and '나루터로 이동 →' or q.place..'로 이동 →'
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
  clear(item.title,'부록')
  card('이런 문의가 오면',item.question)
  card('답장 예시',item.reply)
  note(item.note)
  action('부록 목록으로',function()appendix()end)
 else
  clear('부록','기본 과정 완료')
  for _,topic in ipairs(data.appendix)do
   local item=topic;local b=btn(body,item.title..'  →',function()appendix(item)end);b.TextXAlignment=Enum.TextXAlignment.Left;make('UIPadding',b,{PaddingLeft=UDim.new(0,16),PaddingRight=UDim.new(0,16)})
  end
  action('닫고 쉬기',closePanel)
 end
end
-- One original icon family: the same ink, accent and six-pixel stroke on every card.
-- The large menu-name / object pairing references Conveyor Sushi Restaurant's order screen.
local function chapterArt(parent,id)
 local function box(x,y,w,h,color,r,outline,angle)
  local f=make('Frame',parent,{Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),BackgroundColor3=color or C.ink,BorderSizePixel=0,Rotation=angle or 0,Active=false})
  round(f,r or 4)
  if outline then make('UIStroke',f,{Color=C.ink,Thickness=6,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})end
  return f
 end
 local function bar(x,y,w,h,color,angle)return box(x,y,w,h,color,3,false,angle)end
 local function check(x,y)
  bar(x,y,.20,.065,C.pink,42);bar(x+.12,y-.08,.34,.065,C.pink,-46)
 end
 if id=='brief' then
  box(.22,.15,.56,.72,C.paper,8,true);box(.36,.06,.28,.18,C.pink,4)
  bar(.33,.40,.34,.06);bar(.33,.57,.24,.06);bar(.33,.73,.34,.06)
 elseif id=='profile' then
  box(.10,.16,.80,.68,C.paper,8,true)
  box(.23,.31,.21,.21,C.pink,50);box(.18,.59,.31,.13,C.ink,12)
  bar(.58,.36,.19,.06);bar(.58,.52,.19,.06);bar(.58,.68,.13,.06)
 elseif id=='connect' then
  bar(.34,.09,.07,.25);bar(.59,.09,.07,.25)
  box(.25,.32,.50,.30,C.paper,8,true)
  bar(.46,.65,.08,.24,C.pink);bar(.46,.82,.31,.08,C.pink)
 elseif id=='discover' then
  box(.15,.10,.53,.53,C.paper,50,true)
  bar(.60,.67,.34,.12,C.pink,46)
 elseif id=='send' then
  box(.08,.24,.84,.55,C.paper,6,true)
  bar(.13,.40,.43,.065,C.ink,32);bar(.44,.40,.43,.065,C.ink,-32)
  box(.44,.46,.12,.12,C.pink,50)
 elseif id=='reply' then
  box(.10,.16,.59,.41,C.paper,8,true);bar(.16,.51,.08,.17)
  box(.47,.59,.41,.24,C.pink,6);bar(.76,.77,.08,.13,C.pink)
  bar(.23,.33,.33,.06)
 else
  box(.23,.08,.54,.80,C.paper,6,true)
  bar(.34,.27,.32,.06);bar(.34,.42,.22,.06);check(.30,.68)
 end
end
local function phone(refresh)
 -- Neither a tool equip nor a late packet can interrupt an active work screen.
 if (panel.Visible and not (refresh==true and mode=='phone')) or pending then return end
 local completed=state.completed or {}
 mode='phone';clear('챕터 선택')
 local narrow=gui.AbsoluteSize.X<700;local short=gui.AbsoluteSize.Y<700;local compact=gui.AbsoluteSize.X<1000
 panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.fromScale(.94,.90);panelLimit.MaxSize=Vector2.new(980,narrow and 740 or 680);panel.BackgroundColor3=C.ink
 primary.Position=UDim2.new(0,22,1,-74);primary.Size=UDim2.new(1,-44,0,52)
 tag.Visible=false;title.AutomaticSize=Enum.AutomaticSize.None;title.Position=UDim2.fromOffset(22,22);title.Size=UDim2.new(1,-86,0,42);title.TextSize=34;title.TextColor3=C.white
 body.Position=UDim2.fromOffset(22,84);body.Size=UDim2.new(1,-44,1,-172);primary.TextSize=22
 local earned=Reward.summary(state)
 local hasExtras=earned.basic>0 or state.complete or (earned.unlocked and advancedView~=nil)
 local panelHeight=math.min(gui.AbsoluteSize.Y*.90,narrow and 740 or 680)
 local tileHeight=narrow and 196 or (short and 176 or math.max(176,math.min(212,math.floor((panelHeight-172-(hasExtras and 80 or 16))/2))))
 local grid=make('Frame',body,{Name='ChapterMenu',Size=UDim2.new(1,0,0,narrow and tileHeight*4+36 or tileHeight*2+12),BackgroundTransparency=1})
 local captions={'캠페인 받기','프로필 세팅','시트 연결','태그됨 수집','DM 발송','회신 응대','정산 확인'}
 for i,q in ipairs(data.phases)do
  local chapter=q;local current=not state.complete and state.phase==i;local done=completed[q.id]==true
  local tile=make('TextButton',grid,{Name='Chapter_'..q.id,Text='',AutoButtonColor=true,BackgroundColor3=done and C.green or C.paper,BorderSizePixel=0,ClipsDescendants=true})
  round(tile,10)
  if narrow then
   if i==1 then tile.Position=UDim2.fromOffset(0,0);tile.Size=UDim2.new(1,0,0,tileHeight)
   else local j=i-2;tile.Position=UDim2.new((j%2)*.5,(j%2)*6,0,(tileHeight+12)*(1+math.floor(j/2)));tile.Size=UDim2.new(.5,-6,0,tileHeight)end
  elseif i==1 then tile.Position=UDim2.fromOffset(0,0);tile.Size=UDim2.new(.5,-6,0,tileHeight)
  elseif i<=3 then tile.Position=UDim2.new(.5+(i-2)*.25,6+(i-2)*3,0,0);tile.Size=UDim2.new(.25,-9,0,tileHeight)
  else local j=i-4;tile.Position=UDim2.new(j*.25,j*3,0,tileHeight+12);tile.Size=UDim2.new(.25,-9,0,tileHeight)end
  local caption=(compact and i==2) and '프로필\n세팅' or captions[i]
  local name=txt(tile,string.format('%02d ',i)..caption,compact and 22 or 26,done and C.white or C.ink,56)
  name.Name='ChapterTitle';name.Position=UDim2.fromOffset(12,12);name.Size=UDim2.new(1,-24,0,56);name.Font=Enum.Font.GothamBold;name.Active=false
  if current then make('UIStroke',tile,{Color=C.pink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})end
  if done then
   local stamp=make('Frame',tile,{Name='CompletionStamp',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,0,math.min(short and 119 or 136,tileHeight-62)),Size=UDim2.new(.80,0,0,short and 66 or 76),BackgroundTransparency=1,Rotation=-7,Active=false})
   round(stamp,8);make('UIStroke',stamp,{Color=C.white,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
   local mark=txt(stamp,'완료',compact and 44 or 54,C.white,76);mark.Name='CompletionText';mark.Size=UDim2.fromScale(1,1);mark.Font=Enum.Font.GothamBold;mark.TextXAlignment=Enum.TextXAlignment.Center;mark.TextYAlignment=Enum.TextYAlignment.Center;mark.Active=false
  else
   local size=short and 92 or (narrow and 108 or math.min(128,tileHeight-80))
   local art=make('Frame',tile,{Name='ChapterArt',AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,short and 74 or 72),Size=UDim2.fromOffset(size,size),BackgroundTransparency=1,Active=false});chapterArt(art,q.id)
  end
  tile.Activated:Connect(function()
   if pending then return end
   pending=true;closePanel();remote:FireServer({kind='chapter',revision=state.revision,chapter=chapter.id})
  end)
 end
 local extras={}
 if earned.unlocked and advancedView then table.insert(extras,{text='심화 도전',fn=advancedView.enter})end
 if state.complete then table.insert(extras,{text='부록',fn=function()appendix()end})
 elseif earned.basic>0 then table.insert(extras,{text='따봉 보기',fn=function()navigation('rest')end})end
 if #extras>0 then
  local row=make('Frame',body,{Name='PhoneExtras',Size=UDim2.new(1,0,0,52),BackgroundTransparency=1})
  for i,item in ipairs(extras)do local b=btn(row,item.text,item.fn);b.Position=UDim2.new((i-1)/#extras,(i-1)*6,0,0);b.Size=UDim2.new(1/#extras,#extras>1 and -6 or 0,1,0)end
 end
 if state.complete then
  action('따봉 보기',function()navigation('rest')end)
 else
  action('이어서 하기',function()navigation('resume')end)
 end
end
-- Completion occupies the existing header; it never obscures the next action.
local completedNames={brief='캠페인 확인 완료',profile='프로필 준비 완료',connect='시트 연결 완료',discover='계정 저장 완료',send='DM 발송 완료',reply='회신 응대 완료',settle='정산 확인 완료'}
local function acknowledge(id)
 completionSerial+=1;local token=completionSerial
 local label=panel.Visible and tag or phaseText
 local oldText,oldSize,oldColor=label.Text,label.TextSize,label.TextColor3
 restoreAcknowledgement=function()label.Text=oldText;label.TextSize=oldSize;label.TextColor3=oldColor end
 label.Text='✓ '..completedNames[id];label.TextSize=panel.Visible and 20 or 22
 label.TextColor3=panel.Visible and C.green or C.white
 task.delay(1.5,function()
  if completionSerial==token then cancelAcknowledgement()end
 end)
end
local function finished()
 mode='complete';clear('첫 캠페인 완료','수료')
 title.TextSize=34
 local checkRow=make('Frame',body,{Name='FinishCheck',Size=UDim2.new(1,0,0,100),BackgroundTransparency=1,Active=false})
 local circle=make('Frame',checkRow,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(88,88),BackgroundColor3=C.green,BorderSizePixel=0,Active=false});round(circle,44)
 for _,b in ipairs({{25,49,25,7,43},{42,40,35,7,-48}})do
  local stroke=make('Frame',circle,{Position=UDim2.fromOffset(b[1],b[2]),Size=UDim2.fromOffset(b[3],b[4]),Rotation=b[5],BackgroundColor3=C.white,BorderSizePixel=0,Active=false});round(stroke,3)
 end
 action('나루터로 가기',function()navigation('rest')end)
 alternate('챕터 선택',function()closePanel();phone()end)
 requestLayout();fitDialog()
end
phoneButton.Activated:Connect(phone)
gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()fitHud();if mode=='phone' and panel.Visible then phone(true)elseif mode=='work' and panel.Visible and (data.phases[state.phase].id=='discover' or (data.phases[state.phase].id=='send' and drafts.send and drafts.send.step==3)) then render()else requestLayout()end end)
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
 local freshCompletion
 if packet.kind=='done' and packet.state then
  for _,q in ipairs(data.phases)do if packet.state.completed and packet.state.completed[q.id] and not completedSnapshot[q.id] then freshCompletion=q.id end end
 end
 if packet.state then
  if packet.state.revision<state.revision then drafts={}end
  state=packet.state;update()
  completedSnapshot={};for id,done in pairs(state.completed or {})do completedSnapshot[id]=done end
 end
 if packet.kind=='open'then
  if mode=='work' and panel.Visible then return end
  if packet.resetDraft then drafts[data.phases[state.phase].id]=nil end
  render(packet.profile)
 elseif packet.kind=='done'then
  pending=false;closePanel()
  if packet.continueHere then render(data.phases[state.phase].target)
  elseif state.complete then if freshCompletion then finished()else phone()end end
  if freshCompletion and not state.complete then acknowledge(freshCompletion)end
 elseif packet.kind=='phone' or packet.kind=='finished'then phone()
 elseif packet.kind=='arrived'then closePanel()
 elseif packet.kind=='notice'then pending=false;notice(packet.text)
 elseif packet.kind=='state'then pending=false end
end)
for attempt=1,4 do remote:FireServer({kind='hello'});task.wait(1)end
end
return Client
