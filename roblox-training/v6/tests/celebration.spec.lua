local H=require('./ClientHarness')
local data=require('./CaseData');local Engine=require('./CaseEngine')
local delayed={};H.task.delay=function(seconds,fn)table.insert(delayed,{seconds=seconds,fn=fn})end
H.gui.AbsoluteSize=H.Vector2.new(1280,720)
require('./CampusClient').start(H.gui)
local n=0;local function check(v,m)n+=1;assert(v,m)end
local function part(name)return H.gui:FindFirstChild(name,true)end
local function expire()local jobs=delayed;delayed={};for _,j in ipairs(jobs)do if j.seconds==1.5 then j.fn()end end end
H.open('Manager');H.click('첫 캠페인 맡기')
check(part('DialogContext').Text=='✓ 캠페인 확인 완료','same-place completion uses existing header')
check(part('PrimaryAction').Text=='로고 넣기' and part('PrimaryAction').Active,'next action stays usable')
expire();check(not part('DialogContext').Text:find('✓'),'header restores after acknowledgement')
H.click('×')
-- A fresh world-bound completion; immutable snapshot also survives shared mock state.
H.state.completed.connect=true;H.state.phase=4
H.remote.OnClientEvent:Fire({kind='done',state=H.state})
check(part('ObjectiveTitle').Text=='✓ 시트 연결 완료','world-bound completion uses objective title')
H.click('폰  [P]');H.click('×');check(part('ObjectiveTitle').Text==data.phases[4].title,'closing phone cannot leave stale completion')
expire();check(part('ObjectiveTitle').Text==data.phases[4].title,'old timer cannot overwrite later screen')
for _,q in ipairs(data.phases)do H.state.completed[q.id]=true end
H.state.complete=true
H.remote.OnClientEvent:Fire({kind='done',state=H.state})
check(part('FinishCheck')~=nil and part('WorkPanel').AnchorPoint.X==.5,'one centered finish card')
check(part('DialogTitle').Text=='첫 캠페인 완료','plain completion title')
check(part('PrimaryAction').Text=='나루터로 가기' and part('SecondaryAction').Text=='챕터 선택','two meaningful destinations')
H.click('나루터로 가기');check(H.packets[#H.packets].kind=='rest' and not part('WorkPanel').Visible,'travel only on user action')
H.remote.OnClientEvent:Fire({kind='done',state=H.state})
check(part('FinishCheck')==nil and part('ChapterMenu')~=nil,'duplicate/replay completion opens menu without celebration')
H.click('×');H.remote.OnClientEvent:Fire({kind='state',state=H.state})
check(not part('WorkPanel').Visible,'reconnect/progress packet does not launch finish overlay')
print('PASS: '..n..' celebration lifecycle, usable next action, timeout, stale timer, replay and explicit navigation checks')
