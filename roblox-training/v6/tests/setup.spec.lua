local H=require('./ClientHarness')
require('./CampusClient').start(H.gui)
local function main()return H.gui:FindFirstChild('PrimaryAction',true)end
local function part(name)return H.gui:FindFirstChild(name,true)end
local n=0
local function expect(v,m)n+=1;assert(v,m)end
H.open('Manager');H.click('첫 캠페인 맡기')
H.click('로고 넣기');H.click('게시물 6장 채우기');H.click('소개·링크 채우기')
H.click('다시 채워보기');expect(main().Text=='로고 넣기' and not part('Image_brand1'),'replay clears preview without advancing')
H.click('로고 넣기');H.click('게시물 6장 채우기');H.click('소개·링크 채우기');H.click('이해했어요')
local phase=H.state.phase;local packets=#H.packets
H.click('지금 하기');expect(H.state.phase==phase and #H.packets==packets,'profile guide is not completion')
H.click('선택으로 돌아가기');expect(main().Text=='지금 하기','handoff can be cancelled')
H.click('지금 하기');H.click('설정했습니다 · 계속')
expect(H.state.record.setup.profile.completion=='guide_done','profile can complete after guide')
H.click('확장프로그램 준비하기');H.click('주소·이름 채우기');H.click('캠페인 연결·저장');H.click('이해했어요');H.click('이미 완료했습니다')
expect(H.state.phase==4 and H.state.record.setup.connect.completion=='already_done','connection can use already-done path')
for _,o in ipairs(H.gui:GetDescendants())do
 expect(not(o.ClassName=='TextBox' and o.PlaceholderText=='Apps Script 웹앱 URL'),'no fake connection form')
 if o.Text then expect(not o.Text:find('https://',1,true),'no external URL rendered in Roblox')end
end
print('PASS: progressive setup opposite branches, review reset, guide cancellation and explicit completion')
return true
