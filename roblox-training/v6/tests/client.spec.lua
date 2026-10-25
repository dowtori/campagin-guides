local H=require('./ClientHarness')
local Client=require('./CampusClient')
local data=require('./CaseData')
Client.start(H.gui)
local n=0
local function expect(v,m)n+=1;assert(v,m)end
local function visibleText(value)
 for _,o in ipairs(H.gui:GetDescendants())do if o.Text==value then return true end end;return false
end
local function main()return H.gui:FindFirstChild('WorkPanel'):FindFirstChild('PrimaryAction')end
local function close()H.click('×')end
local function resume()
 H.click('폰  [P]');H.click('이어서 하기')
end
H.open('Manager');expect(main().Text=='첫 캠페인 맡기','first action explains the job')
for _,o in ipairs(H.gui:GetDescendants())do if o.Text then expect(not o.Text:find('소현',1,true),'welcome is not personal')end end
-- Tool packets must never replace a work screen, including lagged equip events.
H.remote.OnClientEvent:Fire({kind='phone',state=H.state})
expect(main().Text=='첫 캠페인 맡기','phone equip cannot interrupt work')
H.click('첫 캠페인 맡기');expect(H.state.phase==2,'campaign accepted')
H.open();expect(main().Text=='이 프로필 적용','one clear profile action');H.click('이 프로필 적용');expect(H.state.phase==3,'profile applied')
resume();H.click('연결 확인');expect(H.state.phase==3,'missing URL does not progress')
H.click('받은 주소 붙여넣기');H.click('연결 확인');close();resume()
expect(main().Text=='설정 저장 · 목록 불러오기','connection substep resumes')
H.click('설정 저장 · 목록 불러오기');expect(H.state.phase==4,'connection saved')
H.open('tiny_sample');H.click('다른 계정 살펴보기');expect(H.state.phase==4,'inspection not a failed quiz')
H.open('beauty_sample');H.click('기존 접촉 이력 확인');H.click('시트에 저장');expect(H.state.phase==5,'lead recorded')
resume();H.click('1만~3만 구간 문구 열기');H.click('DM 보내기');close();resume()
expect(main().Text=='DM 발송으로 저장','resume never repeats sending')
H.remote.OnClientEvent:Fire({kind='phone',state=H.state});expect(main().Text=='DM 발송으로 저장','phone cannot overwrite send status screen')
H.click('DM 발송으로 저장');expect(H.state.phase==6 and H.state.record.sent==1,'send and status complete')
resume();H.click('확인 후 안내하겠다고 답장');close();resume()
expect(main().Text=='비고에 저장','reply resumes after sending acknowledgment')
H.click('비고에 저장');close();resume();expect(main().Text=='계정과 희망 금액 공유','reply resumes after note')
H.click('계정과 희망 금액 공유');expect(H.state.phase==7 and H.state.record.requestedFee==150000,'fee request recorded without approval')
resume();H.click('담당자에게 확인 요청');H.click('이 내용으로 회신');H.click('선정 안내 확인');expect(H.state.record.selected==1,'separate final selection')
resume();H.click('첫 캠페인 마치기');expect(H.state.complete and H.state.record.total==2300,'campaign complete')
H.click('노을 바다로 가기');expect(H.packets[#H.packets].kind=='rest','rest preserves progress')
H.click('폰  [P]');expect(main().Text=='노을 바다로 가기','explicit phone button works')
print('PASS: '..n..' native client callback checks; one action per screen, no phone interruption, connect/send/reply resume, full campaign')
return true
