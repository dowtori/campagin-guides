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
expect(H.state.phase==2 and main().Text=='이 프로필 적용','profile continues without another interaction or walk')
H.click('이 프로필 적용')
expect(H.state.phase==3 and main().Text=='연결 확인','connection continues at same location')
H.click('받은 주소 붙여넣기');H.click('연결 확인');close();resume()
expect(main().Text=='설정 저장 · 목록 불러오기','setup substep resumes')
H.click('설정 저장 · 목록 불러오기');expect(H.state.phase==4,'setup complete')
expect(not H.gui:FindFirstChild('WorkPanel').Visible,'world reopens for creator walk')
H.click('크리에이터 정원 · 바로 이동');expect(H.packets[#H.packets].kind=='travel','objective offers one-click travel')
H.open('beauty_sample');H.click('기존 접촉 이력 확인');H.click('시트에 저장')
expect(H.state.phase==5,'lead saved')
resume();H.click('1만~3만 구간 문구 열기');H.click('DM 보내기');close();resume()
expect(main().Text=='DM 발송으로 저장','resume does not repeat send')
H.click('DM 발송으로 저장')
expect(H.state.phase==6 and main().Text=='이렇게 답장하기','ordinary reply opens at the same desk')
expect(absent('15만') and absent('얼굴 전체'),'no exception lesson in basic response')
H.click('이렇게 답장하기')
expect(H.state.phase==7 and main().Text=='첫 캠페인 마치기','finish at same desk without returning to manager')
expect(H.state.record.selected==nil,'reply does not imply selection')
H.click('첫 캠페인 마치기');expect(H.state.complete and H.state.record.total==2300,'basic course complete')
expect(main().Text=='노을 바다로 가기','completion prioritizes leaving/resting')
expect(absent('15만') and absent('얼굴 전체'),'appendix does not open automatically')
local revision=H.state.revision;local packets=#H.packets
H.click('필요할 때 보는 부록');H.click('고료 조정 요청이 오면')
expect(not absent('15만'),'optional fee reference available after finish')
H.click('부록 목록으로');H.click('모르는 조건을 물어보면')
expect(not absent('얼굴 전체'),'optional condition reference available')
expect(#H.packets==packets and H.state.revision==revision and H.state.record.total==2300,'appendix neither changes completion nor awards/requires credit')
H.click('부록 목록으로');H.click('닫고 쉬기')
H.click('폰  [P]');H.click('노을 바다로 가기');expect(H.packets[#H.packets].kind=='rest','optional rest')
print('PASS: '..n..' client checks; three visits, continuous same-place work, normal reply, optional read-only appendix')
return true
