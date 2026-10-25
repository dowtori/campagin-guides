local H=require('./ClientHarness')
local Client=require('./CampusClient')
local data=require('./CaseData')
Client.start(H.gui)
local n=0
local function expect(v,m)n+=1;assert(v,m)end
local function main()return H.gui:FindFirstChild('WorkPanel'):FindFirstChild('PrimaryAction')end
local function close()H.click('×')end
local function resume()H.click('폰  [P]');H.click('이어서 하기')end
local function absent(text)
 for _,o in ipairs(H.gui:GetDescendants())do if o.Text and o.Text:find(text,1,true)then return false end end;return true
end
H.click('폰  [P]');expect(absent('부록'),'appendix hidden before completion');close()
H.open('Manager');expect(main().Text=='첫 캠페인 맡기','job context before work')
H.remote.OnClientEvent:Fire({kind='phone',state=H.state})
expect(main().Text=='첫 캠페인 맡기','phone cannot interrupt work')
H.click('첫 캠페인 맡기')
expect(H.state.phase==2 and main().Text=='로고 넣기','profile starts empty with a single next action')
local function part(name)return H.gui:FindFirstChild(name,true)end
local before=#H.packets
expect(not part('Image_logo') and not part('Image_brand1'),'profile begins with empty slots')
H.click('로고 넣기');expect(part('LogoSlot'):FindFirstChild('Image_logo') and not part('Image_brand1'),'only logo fills first')
close();resume();expect(main().Text=='게시물 6장 채우기','partial preview resumes')
H.click('게시물 6장 채우기');expect(part('Image_brand1') and part('Image_brand6'),'original six posts fill preview')
expect(part('BioSlot').Text=='프로필 소개','intro remains empty until filled')
H.click('소개·링크 채우기');expect(part('BioSlot').Text==data.bio and main().Text=='이해했어요','completed profile asks for understanding')
H.click('이해했어요');expect(main().Text=='지금 하기' and part('SecondaryAction').Text=='이미 완료했습니다' and part('SecondaryAction').Visible,'two clear completion choices')
H.click('이미 완료했습니다')
expect(H.state.phase==3 and H.state.record.setup.profile.completion=='already_done','already completed continues at same place')
expect(main().Text=='확장프로그램 준비하기','connection also starts with one fill action')
H.click('확장프로그램 준비하기');expect(part('ExtensionSlot').Text=='✓ IG Lead Saver 설치됨','installed state is visible')
H.click('주소·이름 채우기');expect(part('AddressSlot').Text=='✓ 받은 주소 입력됨' and part('SaverSlot').Text=='✓ 본인 이름','address and saver fields fill')
H.click('캠페인 연결·저장');expect(part('CampaignSlot').Text==data.campaign and main().Text=='이해했어요','campaign and completion states fill')
H.click('이해했어요');local revision=H.state.revision;local count=#H.packets
H.click('지금 하기');expect(H.state.phase==3 and H.state.revision==revision and #H.packets==count,'guide handoff does not claim setup completed')
expect(main().Text=='설정했습니다 · 계속','guide waits for return')
close();resume();expect(main().Text=='설정했습니다 · 계속','handoff resumes without repeating the lesson')
H.click('설정했습니다 · 계속');expect(H.state.phase==4 and H.state.record.setup.connect.completion=='guide_done','explicit return completion advances')
expect(not H.gui:FindFirstChild('WorkPanel').Visible,'world reopens for creator walk')
H.click('크리에이터 정원 · 바로 이동');expect(H.packets[#H.packets].kind=='travel','objective offers one-click travel')
H.open('beauty_sample');H.click('기존 접촉 이력 확인');H.click('시트에 저장')
expect(H.state.phase==5,'lead saved')
resume();H.click('1만~5만 미만 문구 열기');H.click('DM 보내기');close();resume()
expect(main().Text=='DM 발송으로 저장','resume does not repeat send')
H.click('DM 발송으로 저장')
expect(H.state.phase==6 and main().Text=='이렇게 답장하기','ordinary reply opens at the same desk')
expect(absent('15만') and absent('얼굴 전체'),'no exception lesson in basic response')
H.click('이렇게 답장하기')
expect(H.state.phase==7 and main().Text=='정산 확인 완료','finish at same desk without returning to manager')
expect(H.state.record.selected==nil,'reply does not imply selection')
H.click('정산 확인 완료');expect(H.state.complete and H.state.record.total==2300,'basic course complete')
expect(main().Text=='따봉 보기','completion prioritizes leaving/resting')
expect(absent('15만') and absent('얼굴 전체'),'appendix does not open automatically')
local revision=H.state.revision;local packets=#H.packets
H.click('부록');H.click('고료 조정 요청이 오면')
expect(not absent('15만'),'optional fee reference available after finish')
H.click('부록 목록으로');H.click('모르는 조건을 물어보면')
expect(not absent('얼굴 노출'),'optional condition reference available')
expect(#H.packets==packets and H.state.revision==revision and H.state.record.total==2300,'appendix neither changes completion nor awards/requires credit')
H.click('부록 목록으로');H.click('닫고 쉬기')
H.click('폰  [P]');H.click('따봉 보기');expect(H.packets[#H.packets].kind=='rest','optional rest')
print('PASS: '..n..' client checks; three visits, continuous same-place work, normal reply, optional read-only appendix')
return true
