local Layout=require('./DialogLayout')
local H=require('./ClientHarness')
local Client=require('./CampusClient')
local checks=0
local function check(v,m)checks+=1;assert(v,m)end
for _,view in ipairs({{1280,720},{1440,900},{390,844},{844,390}})do
 for _,heading in ipairs({36,72})do
  for _,content in ipairs({0,100,240,700,1600})do
   for _,secondary in ipairs({false,true})do
    local m=Layout.measure(view[1],view[2],heading,content,secondary)
    check(m.width<=view[1]-32 and m.height<=view[2]-32,'within safe area')
    check(m.primaryY+52<=m.height-24,'primary inside footer')
    check(m.bodyY+m.bodyHeight<= (secondary and m.secondaryY or m.primaryY),'body cannot cover action')
    check(m.bodyHeight>=0 and m.scrolls==(m.bodyHeight<content),'bounded body with overflow')
    if secondary then check(m.secondaryY+52+12==m.primaryY,'consistent footer gap')end
    if content>0 then check((secondary and m.secondaryY or m.primaryY)-m.bodyY-m.bodyHeight==20,'no large blank before action')end
   end
  end
 end
end
check(Layout.measure(1280,720,36,120,false).height<400,'brief compact')
check(Layout.measure(1280,720,72,0,true).height<320,'empty choice compact')

local map=H.workspace:FindFirstChild('TrainingMap');local room=H.Instance.new('Model');room.Name='AdvancedRoom';room.Parent=map
for _,name in ipairs({'ConditionBoard','ChallengeConsole','ChoiceBoard1','ChoiceBoard2','ChoiceBoard3'})do local p=H.Instance.new('Part');p.Name=name;p.Parent=room end
local pg=H.Instance.new('PlayerGui');pg.Name='PlayerGui';pg.Parent=H.player
local ar=H.Instance.new('RemoteEvent');ar.Name='AdvancedEvent';ar.OnClientEvent=H.Mock.event();ar.Parent=H.game:GetService('ReplicatedStorage');function ar:FireServer()end

H.gui.AbsoluteSize=H.Vector2.new(1280,720);Client.start(H.gui);H.open('Manager')
local panel=H.gui:FindFirstChild('WorkPanel');local body=panel:FindFirstChild('WorkBody')
local title=panel:FindFirstChild('DialogTitle');local list=body:FindFirstChildOfClass('UIListLayout')
-- Inject engine-provided measurements: verifies the real client's resize/event wiring.
title.TextBounds=H.Vector2.new(390,36);list.AbsoluteContentSize=H.Vector2.new(500,120);H.run.Heartbeat:Fire(.016)
check(panel.Size.Y.Offset<400,'actual client fits measured short content')
check(title.TextSize==30 and title.AutomaticSize==H.Enum.AutomaticSize.Y,'heading wraps without shrinking')
for _,o in ipairs(panel:GetDescendants())do
 if o.Text then
  check(not o.Text:find('실제 업무 시작할 때',1,true),'ambiguous disclosure removed')
  check(o.TextSize>=16,'readable smallest label')
  if o.ClassName=='TextButton' then check(o.BackgroundTransparency~=1,'visible button affordance')end
 end
end
list.AbsoluteContentSize=H.Vector2.new(500,1400);H.run.Heartbeat:Fire(.016)
check(panel.Size.Y.Offset<=688,'long content capped')
check(body.Size.Y.Offset<1400 and body.AutomaticCanvasSize==H.Enum.AutomaticSize.Y,'long content scrolls')
H.gui.AbsoluteSize=H.Vector2.new(390,844);H.run.Heartbeat:Fire(.016)
check(panel.Size.X.Offset==358 and panel.AnchorPoint.X==.5,'resize to portrait centers work dialog')
H.gui.AbsoluteSize=H.Vector2.new(844,390);H.run.Heartbeat:Fire(.016)
check(panel.Size.Y.Offset<=358 and panel.AnchorPoint.X==.5,'landscape retains footer')
H.click('×');H.gui.AbsoluteSize=H.Vector2.new(1280,720)
for _,q in ipairs(require('./CaseData').phases)do H.state.completed[q.id]=true end;H.state.complete=true
H.remote.OnClientEvent:Fire({kind='state',state=H.state});H.click('폰  [P]')
local grid=H.gui:FindFirstChild('ChapterMenu',true);local extras=H.gui:FindFirstChild('PhoneExtras',true)
check(extras and #extras:GetChildren()==2,'advanced and appendix controls share one row')
check(extras and grid.Size.Y.Offset+12+52+4<=720*.9-172,'desktop phone auxiliary row fully visible')
for _,height in ipairs({500,600,650,700})do
 H.gui.AbsoluteSize=H.Vector2.new(1280,height)
 local first=H.gui:FindFirstChild('Chapter_brief',true)
 check(first.Size.Y.Offset>=176,'medium-height window keeps readable chapter cards')
 local stamp=first:FindFirstChild('CompletionStamp')
 check(stamp.Position.Y.Offset+stamp.Size.Y.Offset/2+24<=first.Size.Y.Offset,'rotated completion stamp remains inside card')
end
print('PASS: '..checks..' measured native dialog layout, typography, disclosure and resize checks; engine font metrics not simulated')
