local H=require('./ClientHarness')
local Client=require('./CampusClient')
local n=0
local function expect(v,m)n+=1;assert(v,m)end
local function main()return H.gui:FindFirstChild('PrimaryAction',true)end
local function tile(id)return assert(H.gui:FindFirstChild('Chapter_'..id,true))end
local function pick(id)tile(id).Activated:Fire()end
local function menu()H.click('×');H.click('폰  [P]')end
H.gui.AbsoluteSize=H.Vector2.new(1440,900)
Client.start(H.gui)
H.click('폰  [P]')
expect(tile('brief').Size.X.Scale==.5 and tile('profile').Size.X.Scale==.25,'wide menu mirrors the seven large picture tile composition')
local grid=H.gui:FindFirstChild('ChapterMenu',true)
for _,o in ipairs(grid:GetDescendants())do expect(not o.Name:match('^Image_'),'phone contains no mixed raster assets')end
local heading=tile('brief'):FindFirstChild('ChapterTitle')
expect(heading.Text=='01 캠페인 받기' and heading.TextSize>=26,'number and title form one large heading')
pick('profile');expect(H.gui:FindFirstChild('WorkPanel').BackgroundColor3[1]==250,'work panel restores light style');expect(H.state.phase==2 and main().Text=='로고 넣기','one tile press opens selected chapter')
H.click('로고 넣기');menu();pick('send')
expect(main().Text=='1만~3만 구간 문구 열기' and not H.state.completed.profile,'skipping does not complete profile')
menu();pick('profile');expect(main().Text=='게시물 6장 채우기','return to unfinished chapter keeps partially filled preview')
menu();pick('settle');H.click('정산 확인 완료')
expect(H.state.completed.settle and not H.state.complete and H.state.record.total==2300,'last chapter alone does not finish the course')
H.click('폰  [P]')
local stamp=tile('settle'):FindFirstChild('CompletionStamp')
expect(stamp and stamp.Active==false and stamp:FindFirstChild('CompletionText').TextSize>=44,'large completion stamp remains noninteractive')
for _,o in ipairs(H.gui:FindFirstChild('WorkPanel'):GetDescendants())do
 if o.Text then expect(not o.Text:find('점'),'phone does not display game points')end
end
pick('settle');expect(main().Text=='정산 확인 완료','finished chapter opens for replay')
H.click('정산 확인 완료');expect(H.state.record.total==2300,'replay cannot add payout')
H.gui.AbsoluteSize=H.Vector2.new(390,844)
H.click('폰  [P]')
expect(tile('brief').Size.X.Scale==1 and tile('profile').Size.X.Scale==.5,'small screen uses two columns and full-width first tile')
expect(H.gui:FindFirstChild('ChapterMenu',true).Size.Y.Offset==820,'all seven mobile tiles scroll within body')
expect(tile('profile'):FindFirstChild('ChapterTitle').TextSize>=22,'compact headings remain large')
H.input.InputBegan:Fire({KeyCode=H.Enum.KeyCode.P},false)
expect(not H.gui:FindFirstChild('WorkPanel').Visible,'P closes chapter phone')
H.click('폰  [P]');H.click('이어서 하기')
expect(main().Text=='첫 캠페인 맡기','resume opens first unfinished chapter')
local current=main().Text;H.remote.OnClientEvent:Fire({kind='phone',state=H.state})
expect(main().Text==current,'late tool event still cannot cover work')
print('PASS: '..n..' native chapter-menu checks; native icons, large titles/completion stamps, direct entry, drafts, replay and mobile layout mode')
return true
