local H=require('./ClientHarness');local E=require('./CaseEngine');local D=require('./CaseData');local A=require('./AdvancedData');local R=require('./RewardPolicy')
H.gui.AbsoluteSize=H.Vector2.new(1280,720)
local n=0;local function check(v,m)n+=1;assert(v,m)end
local function click(name)assert(H.gui:FindFirstChild(name,true),name).Activated:Fire()end
for _,q in ipairs(D.phases)do H.state.completed[q.id]=true end
H.state.complete=true;H.state.record={sent=1,status='DM 발송',applied=true,total=2300};H.state.advanced={completed={scout=true,fee=true,conditions=true},attempts={fee=2},serial=19}
H.CFrame={lookAt=function(p,t)return {Position=p,Target=t}end}
require('./CampusClient').start(H.gui)
H.click('폰  [P]');H.click('진행 초기화');click('Reset_send')
local revision=H.state.revision;H.click('취소');check(H.state.revision==revision and R.summary(H.state).king,'cancel preserves all progress')
click('Reset_send');H.click('이 챕터 초기화')
check(not H.state.completed.send and H.state.completed.reply and H.state.completed.settle,'only selected basic check removed')
check(H.state.record.sent==nil and H.state.record.applied and H.state.record.total==2300,'only selected action record removed')
check(H.state.advanced.completed.fee and not R.summary(H.state).king,'advanced retained; king revoked until basic restored')
check(H.state.phase==5 and H.gui:FindFirstChild('PrimaryAction',true).Text=='1만~5만 미만 문구 열기','reset opens selected chapter at first screen')
H.click('1만~5만 미만 문구 열기');H.click('DM 보내기');H.click('DM 발송으로 변경');H.click('발송 기록 완료')

check(H.state.completed.send and R.summary(H.state).king,'recompletion restores reward without clearing other work')
H.click('챕터 선택');H.click('진행 초기화');click('Reset_send');H.click('이 챕터 초기화')
check(H.gui:FindFirstChild('PrimaryAction',true).Text=='1만~5만 미만 문구 열기','completed send draft cleared, not resumed at saved sheet')
H.click('×');H.click('폰  [P]');H.click('진행 초기화');click('Reset_fee');H.click('이 챕터 초기화')
check(not H.state.advanced.completed.fee and H.state.advanced.completed.scout and H.state.advanced.completed.conditions,'advanced reset isolated')
check(H.state.advanced.attempts.fee==nil and H.state.advanced.serial>19,'attempt token invalidated')
H.click('진행 초기화');click('ResetAll');H.click('전체 초기화')
check(H.state.phase==1 and next(H.state.completed)==nil and next(H.state.record)==nil,'full reset clears all chapters and records')
check(next(H.state.advanced.completed)==nil and R.summary(H.state).stage==0,'full reset clears bonus and thumb')
check(H.gui:FindFirstChild('PrimaryAction',true).Text=='첫 캠페인 맡기','full reset opens first chapter')
local rev=H.state.revision;check(not E.reset(H.state,'forged',D,A) and H.state.revision==rev,'invalid reset cannot mutate')
check(rev>revision,'monotonic revision across full reset')
H.workspace.CurrentCamera={}
H.remote.OnClientEvent:Fire({kind='kingReward',state=H.state})
check(H.workspace.CurrentCamera.CFrame.Target.Y==90 and H.workspace.CurrentCamera.CFrame.Target.X==-165,'native reward camera faces giant without control lock')
print('PASS: '..n..' chapter/advanced/full reset callbacks, cancel, drafts and rewards')
