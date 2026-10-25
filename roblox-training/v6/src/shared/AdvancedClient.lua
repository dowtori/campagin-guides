-- Choices live on physical walls and a console, never a modal.
local Client={}
function Client.start(gui,closeWork,notice,viewThumb)
 local RS=game:GetService('ReplicatedStorage')
 local remote=RS:WaitForChild('AdvancedEvent')
 local data=require(script.Parent:WaitForChild('AdvancedData'))
 local Raster=require(script.Parent:WaitForChild('RasterRenderer'))
 local player=game:GetService('Players').LocalPlayer
 local map=workspace:WaitForChild('TrainingMap')
 local room=map:FindFirstChild('AdvancedRoom',true)
 local paper=Color3.fromRGB(249,246,238);local ink=Color3.fromRGB(37,33,45);local pink=Color3.fromRGB(223,25,64)
 local run=nil;local cleared={};local reward={unlocked=false};local choices={};local prompts={};local timer
 local function make(class,parent,props)
  local o=Instance.new(class);for k,v in pairs(props or {})do o[k]=v end;o.Parent=parent;return o
 end
 local function text(parent,value,x,y,w,h,size,color)
  return make('TextLabel',parent,{Text=value,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),TextSize=size,Font=Enum.Font.GothamBold,TextWrapped=true,BackgroundTransparency=1,TextColor3=color or ink})
 end
 local function surface(name,w,h)
  return make('SurfaceGui',player:WaitForChild('PlayerGui'),{Name='Challenge_'..name,Adornee=room:WaitForChild(name),Face=Enum.NormalId.Back,SizingMode=Enum.SurfaceGuiSizingMode.FixedSize,CanvasSize=Vector2.new(w,h),LightInfluence=0,AlwaysOnTop=false,Active=true,MaxDistance=130,ZOffset=.05,ResetOnSpawn=false})
 end
 local condition=surface('ConditionBoard',1640,170)
 local console=surface('ChallengeConsole',960,320)
 for i=1,3 do choices[i]=surface('ChoiceBoard'..i,750,465) end
 local function button(parent,caption,x,y,w,h,fn,color)
  local b=make('TextButton',parent,{Text=caption,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),TextSize=30,Font=Enum.Font.GothamBold,TextWrapped=true,TextColor3=paper,BackgroundColor3=color or pink,BorderSizePixel=0,AutoButtonColor=true})
  make('UICorner',b,{CornerRadius=UDim.new(0,10)});b.Activated:Connect(fn);return b
 end
 local function send(kind,slot)if run then remote:FireServer({kind=kind,token=run.token,slot=slot})end end
 local function pick(i)
  if run and run.status=='brief' then send('start')
  elseif run and run.status=='active' then send('answer',i)
  elseif run and run.status~='brief' then send('retry')end
 end
 for i=1,3 do
  local p=make('ProximityPrompt',room:WaitForChild('ChoiceBoard'..i),{Name='ChooseAnswer',ActionText='선택',ObjectText=tostring(i)..'번',KeyboardKeyCode=Enum.KeyCode.E,HoldDuration=0,MaxActivationDistance=20,RequiresLineOfSight=false,ClickablePrompt=true,Enabled=false})
  p.Triggered:Connect(function()pick(i)end);prompts[i]=p
 end
 local entry=make('ProximityPrompt',room:WaitForChild('ChallengeConsole'),{Name='ChallengeEntry',ActionText='도전하기',ObjectText='따봉 챌린지',KeyboardKeyCode=Enum.KeyCode.E,HoldDuration=0,MaxActivationDistance=22,RequiresLineOfSight=false,ClickablePrompt=true})
 entry.Triggered:Connect(function()remote:FireServer({kind='enter',id='scout'})end)
 local function clear(s)for _,c in ipairs(s:GetChildren())do c:Destroy()end end
 local function render()
  clear(condition);clear(console);timer=nil
  for _,s in ipairs(choices)do clear(s)end
  entry.Enabled=not run
  local challenge,round
  if run then for _,c in ipairs(data.challenges)do if c.id==run.id then challenge=c;round=c.rounds[run.round] end end end
  text(condition,run and ((run.status=='passed' or run.status=='failed' or run.status=='timeout') and run.feedback or round.conditions) or '따봉 챌린지',.025,.02,.79,.96,40,paper)
  timer=text(condition,run and (run.status=='passed' and (run.firstClear and '+100점' or '클리어') or (run.status=='failed' or run.status=='timeout') and '재도전' or (challenge.timed and '30초' or '시간제한 없음')) or '심화 과정',.83,.1,.16,.8,32,paper)
  for i,p in ipairs(prompts)do p.Enabled=run~=nil;p.ActionText=run and (run.status=='brief' and '시작' or run.status=='active' and '선택') or '다시 도전' end
  for i=1,3 do
   local npc=map:FindFirstChild('AnswerNPC'..i,true)
   if npc then for _,p in ipairs(npc:GetDescendants())do if p:IsA('BasePart') and p.Name~='HumanoidRootPart' then p.LocalTransparencyModifier=(not run or challenge.timed) and 1 or 0 end end end
   local s=choices[i]
   if run and run.status~='brief' then
    local option=round.options[run.order[i]]
    local bg=make('Frame',s,{Size=UDim2.fromScale(1,1),BackgroundColor3=paper,BorderSizePixel=0})
    text(bg,tostring(i)..'  '..option.name,.04,.025,.92,.14,34)
    if challenge.timed then
     local im=Raster.draw(bg,option.image,UDim2.fromScale(.04,.20),UDim2.fromScale(.44,.56));make('UIAspectRatioConstraint',im,{AspectRatio=1,AspectType=Enum.AspectType.FitWithinMaxSize})
     text(bg,option.facts,.51,.22,.45,.50,34)
    else text(bg,option.answer,.06,.19,.88,.52,44) end
    if run.status=='active' then button(bg,challenge.timed and '이 크리에이터 선택' or '이 답변 선택',.04,.80,.92,.16,function()pick(i)end)
    else button(bg,'다시 도전',.04,.80,.92,.16,function()send('retry')end) end
   else
    text(s,tostring(i),.1,.20,.8,.45,100,paper)
    if run then button(s,challenge.timed and '조건 읽었어요 · 시작' or 'NPC 답변 보기',.04,.80,.92,.16,function()send('start')end)end
   end
  end
  if not run then
   text(console,reward.unlocked and '준비됐다면 도전해봐요' or '기본 챕터를 마치면 열려요',.04,.06,.92,.36,38,paper)
   button(console,'도전하기',.04,.50,.92,.40,function()remote:FireServer({kind='enter',id='scout'})end)
   return
  end
  for i,c in ipairs(data.challenges)do
   button(console,c.title..(cleared[c.id] and ' ✓' or ''),(i-1)/3+.012,.025,.309,.22,function()remote:FireServer({kind='enter',id=c.id})end,c.id==run.id and pink or Color3.fromRGB(83,75,92))
  end
  if run.status=='brief' then
   text(console,challenge.timed and '벽 위 조건을 읽고 시작하세요.' or '벽 위 문의를 읽고 답변을 들어봐요.',.03,.30,.94,.25,33,paper)
   button(console,challenge.timed and '시작 · 30초' or 'NPC 답변 보기',.03,.62,.94,.32,function()send('start')end)
  elseif run.status=='active' then
   text(console,challenge.timed and '벽면에서 한 명을 선택!' or 'NPC의 답변 중 하나를 선택!',.03,.31,.94,.46,40,paper)
  else
   text(console,run.feedback or '',.035,.29,.93,.32,30,paper)
   button(console,'다시 도전',.03,.66,.44,.29,function()send('retry')end)
   local nextId
   for i,c in ipairs(data.challenges)do if c.id==run.id then nextId=data.challenges[i%3+1].id end end
   if reward.king and viewThumb then button(console,'왕따봉 보러 가기',.50,.66,.47,.29,viewThumb)
   else button(console,run.status=='passed' and (run.firstClear and '+100점 · 다음 도전' or '다음 도전') or '다른 도전',.50,.66,.47,.29,function()remote:FireServer({kind='enter',id=nextId})end)end
  end
 end
 remote.OnClientEvent:Connect(function(packet)
  if packet.run then closeWork() end
  run=packet.run;cleared=packet.cleared or {};reward=packet.reward or reward;render()
 end)
 local elapsed=0
 game:GetService('RunService').Heartbeat:Connect(function(dt)
  elapsed+=dt;if elapsed<.1 then return end;elapsed=0
  if timer and run and run.status=='active' and run.deadline then timer.Text=tostring(math.max(0,math.ceil(run.deadline-workspace:GetServerTimeNow())))..'초' end
 end)
 render()
 return {enter=function()closeWork();remote:FireServer({kind='enter',id='scout'})end,sync=function(r)local changed=reward.unlocked~=r.unlocked;reward=r;if changed and not run then render()end end}
end
return Client
