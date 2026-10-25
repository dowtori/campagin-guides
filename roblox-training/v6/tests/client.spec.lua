local H=require('./ClientHarness')
local Client=require('./CampusClient')
local data=require('./CaseData')
Client.start(H.gui)
local n=0
local function expect(v,m)n+=1;assert(v,m)end
local function primary()local buttons=H.gui:GetDescendants();for _,o in ipairs(buttons)do if o.ClassName=='TextButton' and o.Text=='화면의 작업을 진행하세요'then assert(o.Active==false)end end end
H.open('Manager')
expect(H.find('가이드 받고 리크루터 폰 챙기기')~=nil,'first action is a manager quest, not a test')
for _,o in ipairs(H.gui:GetDescendants())do if o.Text then expect(not o.Text:find('소현',1,true),'welcome is not addressed to an individual')end end
H.click('가이드 받고 리크루터 폰 챙기기');expect(H.state.phase==2,'brief completed')
H.open();H.click('제공된 시리아이 로고');H.click('제공된 소개 문구');H.click('프로필 링크 적용');H.click('프로필 저장');expect(H.state.phase==3,'original brand profile done')
H.open();H.click('연결 테스트');expect(H.state.phase==3,'missing fields do not connect')
H.click('전달받은 URL 붙여넣기');H.click('연습용 이름');H.click('연결 테스트');H.click(data.campaign);H.click('설정 저장');H.click('새로고침');expect(H.state.phase==4,'connection tutorial done')
H.open('tiny_sample');H.click('다른 크리에이터');expect(H.state.phase==4,'non-fitting profile can be inspected without failed quiz')
H.open('beauty_sample');H.click('기존 접촉 이력');H.click('시트에 저장');expect(H.state.phase==5 and H.state.record.handle=='beauty_sample','actual collected record')
H.open();H.click('대상 프로필');H.click('1만~3만 구간');H.click('이 문구로 DM 보내기');H.click('×');H.open();expect(H.find('DM 발송으로 변경')~=nil,'closing the phone after sending resumes at sheet status instead of resending');H.click('DM 발송으로 변경');H.click('변경한 시트 저장');expect(H.state.phase==6 and H.state.record.sent==1,'send plus sheet status required')
H.open();H.click('단톡에 계정');expect(H.state.phase==6,'cannot share incomplete request')
H.click('확인 후 안내하겠다는');H.click('비고에 희망');H.click('단톡에 계정');H.click('응대와 기록');expect(H.state.record.requestedFee==150000 and H.state.phase==7,'fee request recorded, not approved')
H.open();H.click('담당자에게 조건');H.click('확인한 내용으로');H.click('최종 선정 안내 확인');expect(H.state.record.selected==1,'separate final selection notice')
H.open();H.click('첫 캠페인 마치기');expect(H.state.complete and H.state.record.total==2300,'one campaign complete')
H.click('폰 / 진행');expect(H.find('노을 바다로 가기')~=nil,'completion returns to social/rest space')
H.click('노을 바다로 가기');expect(H.packets[#H.packets].kind=='rest','rest request retains progress')
print('PASS: '..n..' checks of actual native client callbacks; one full campaign, profile assets, connection, creator inspection, DM, requested fee, handoff and record')

return true
