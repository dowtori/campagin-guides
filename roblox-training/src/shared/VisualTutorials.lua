-- Visual task workbenches. Every picture is drawn from original layered shapes;
-- no uploaded image IDs, editable-image permissions or external services are required.
local V = {}
local Assets = require(script.Parent:WaitForChild('VisualAssets'))
local Raster=require(script.Parent:WaitForChild('RasterRenderer'))
local TweenService = game:GetService('TweenService')
local C={paper=Color3.fromRGB(251,250,247),ink=Color3.fromRGB(28,27,25),muted=Color3.fromRGB(111,109,104),line=Color3.fromRGB(229,227,221),soft=Color3.fromRGB(239,237,231),pink=Color3.fromRGB(255,35,75),green=Color3.fromRGB(39,128,103),white=Color3.new(1,1,1)}
local function color(s) return Color3.fromHex(s) end
local function make(class,p,props)
    local o=Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    o.Parent=p
    return o
end
local function round(o,r) return make('UICorner',o,{CornerRadius=UDim.new(0,r or 12)}) end
local function stroke(o,c,w) return make('UIStroke',o,{Color=c or C.line,Thickness=w or 1.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
local function frame(ctx,h,bg)
    local f=make('Frame',ctx.body,{Name='VisualWorkbench',Size=UDim2.new(1,0,0,h),BackgroundColor3=bg or C.soft,BorderSizePixel=0})
    round(f,16)
    return f
end
local function box(p,x,y,w,h,bg)
    local f=make('Frame',p,{Position=UDim2.new(x,0,0,y),Size=UDim2.new(w,0,0,h),BackgroundColor3=bg or C.white,BorderSizePixel=0})
    round(f,10) return f
end
local function label(p,s,x,y,w,h,size,c,bold)
    return make('TextLabel',p,{BackgroundTransparency=1,Position=UDim2.new(x,0,0,y),Size=UDim2.new(w,0,0,h),Text=s,TextColor3=c or C.ink,TextSize=size or 15,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center})
end
local function tap(p,s,x,y,w,h,action,bg)
    local b=make('TextButton',p,{Position=UDim2.new(x,0,0,y),Size=UDim2.new(w,0,0,h),BackgroundColor3=bg or C.white,TextColor3=C.ink,Text=s,Font=Enum.Font.GothamBold,TextSize=14,TextWrapped=true,BorderSizePixel=0,AutoButtonColor=true})
    round(b,9)
    make('UIPadding',b,{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)})
    if action then b.Activated:Connect(action) end
    return b
end
local function art(p,key,pos,size)
    local actual=({brand='logo',mail='booth4',chat='booth5'})[key]
    if actual then return Raster.draw(p,actual,pos,size) end
    local source=Assets[key] or Assets.empty
    local root=make('Frame',p,{Name='Art_'..key,Position=pos,Size=size,BackgroundColor3=color(source.bg),BorderSizePixel=0,ClipsDescendants=true})
    for _,s in ipairs(source.shapes) do
        local f=make('Frame',root,{Position=UDim2.fromScale(s.x,s.y),Size=UDim2.fromScale(s.w,s.h),BackgroundColor3=color(s.color),BorderSizePixel=0,Rotation=s.rot or 0})
        if s.r and s.r>0 then make('UICorner',f,{CornerRadius=UDim.new(s.r,0)}) end
    end
    return root
end
local function caption(ctx,s)
    local t=ctx.text(ctx.body,s,14,C.muted)
    return t
end
local function selectable(ctx,items,height,paint,choose)
    local root=frame(ctx,height,C.paper)
    root.BackgroundTransparency=1
    local grid=make('UIGridLayout',root,{CellPadding=UDim2.fromOffset(12,12),SortOrder=Enum.SortOrder.LayoutOrder})
    local rows={}
    for i,item in ipairs(items) do
        local b=make('TextButton',root,{Name='VisualChoice_'..item.id,LayoutOrder=i,Text='',BorderSizePixel=0,BackgroundColor3=C.white,AutoButtonColor=false})
        round(b,12)
        local border=stroke(b)
        paint(b,item,i)
        b.Activated:Connect(function()
            for _,r in ipairs(rows) do r.border.Color=C.line r.border.Thickness=1.5 end
            border.Color=C.pink border.Thickness=3
            choose(item,b)
        end)
        table.insert(rows,{button=b,border=border,item=item})
    end
    local function resize()
        local columns=root.AbsoluteSize.X<540 and 1 or #items
        grid.CellSize=UDim2.new(1/columns,-12*(columns-1)/columns,0,height)
        root.Size=UDim2.new(1,0,0,math.ceil(#items/columns)*(height+12)-12)
    end
    local connection=root:GetPropertyChangedSignal('AbsoluteSize'):Connect(resize)
    root.Destroying:Connect(function() connection:Disconnect() end)
    resize()
    return rows
end
local function choices(ctx,items,change)
    local selected
    for _,item in ipairs(items) do
        local b=ctx.button(ctx.body,item.text,{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextXAlignment=Enum.TextXAlignment.Left,TextSize=15,Font=Enum.Font.Gotham,BackgroundColor3=C.white})
        make('UIPadding',b,{PaddingTop=UDim.new(0,15),PaddingBottom=UDim.new(0,15),PaddingLeft=UDim.new(0,16),PaddingRight=UDim.new(0,16)})
        local border=stroke(b)
        b.Activated:Connect(function()
            if selected then selected.Color=C.line selected.Thickness=1.5 end
            selected=border border.Color=C.pink border.Thickness=3
            change(item)
        end)
    end
end
local function referenceImage(ctx,key,title)
    local toggle=ctx.button(ctx.body,title,{TextSize=14,Size=UDim2.new(1,0,0,46),BackgroundColor3=C.soft})
    local panel=frame(ctx,440,C.white);panel.Visible=false
    local loaded=false
    toggle.Activated:Connect(function()
        panel.Visible=not panel.Visible
        if panel.Visible and not loaded then
            loaded=true
            local picture=Raster.draw(panel,key,UDim2.fromScale(.05,.03),UDim2.fromScale(.9,.94))
            make('UIAspectRatioConstraint',picture,{AspectRatio=key=='settings' and 280/402 or 280/465,AspectType=Enum.AspectType.FitWithinMaxSize})
        end
    end)
end
local function profile(ctx,q)
    local f=frame(ctx,272,C.white)
    label(f,'교육용 프로필 미리보기',.04,8,.92,20,11,C.muted)
    local portrait=art(f,'empty',UDim2.new(.04,0,0,42),UDim2.new(.16,0,0,70))
    local stats=label(f,'siriai_partner\n게시물 6     팔로워 · 팔로잉',.24,39,.7,66,16,C.ink,true)
    local bio=label(f,'프로필을 준비해주세요.',.04,119,.92,50,16,C.ink)
    Raster.draw(f,'profile',UDim2.new(.04,0,0,184),UDim2.new(.29,0,0,73))
    for i,key in ipairs({'skincare','travel'}) do art(f,key,UDim2.new(.35+(i-1)*.31,0,0,184),UDim2.new(.29,0,0,73)) end
    if q.visual.field=='photo' then
        selectable(ctx,q.visual.tiles,146,function(b,item)
            art(b,item.art,UDim2.fromOffset(10,10),UDim2.new(1,-20,0,90))
            label(b,item.title,.06,105,.88,31,14,C.ink,true)
        end,function(item)
            portrait:Destroy();portrait=art(f,item.art,UDim2.new(.04,0,0,42),UDim2.new(.16,0,0,70))
            ctx.primary('프로필 사진 적용',function()ctx.finish(item.id)end,true)
        end)
    else
        portrait:Destroy();portrait=art(f,'brand',UDim2.new(.04,0,0,42),UDim2.new(.16,0,0,70))
        choices(ctx,q.options,function(item)
            bio.Text=item.id=='a' and 'The most\nintuitive contents, Siriai.' or item.text
            ctx.primary('소개 문구 저장',function()ctx.finish(item.id)end,true)
        end)
    end
end
local function flow(ctx,q)
    local selected={}
    local line=frame(ctx,66,C.ink)
    local progress=label(line,'그림 카드를 순서대로 눌러보세요.',.05,8,.9,50,16,C.white,true)
    local rows={}
    selectable(ctx,q.options,190,function(b,item)
        art(b,q.visual.art[item.id],UDim2.fromOffset(10,10),UDim2.new(1,-20,0,126))
        rows[item.id]=label(b,item.text,.06,143,.88,34,15,C.ink,true)
    end,function(item)
        if table.find(selected,item.id) then return end
        table.insert(selected,item.id)
        rows[item.id].Text=tostring(#selected)..'  ✓  '..item.text
        local titles={}
        for _,id in ipairs(selected) do for _,it in ipairs(q.options) do if it.id==id then table.insert(titles,it.text) end end end
        progress.Text=table.concat(titles,' → ')
        ctx.primary('업무 흐름 연결 완료',function()ctx.finish(selected)end,#selected==#q.options)
    end)
end
local function options(ctx)
    referenceImage(ctx,'options','제공된 실제 크롬 화면 보기')
    local f=frame(ctx,338,C.white)
    box(f,0,0,1,38,C.line)
    label(f,'‹   chrome://extensions  /  IG Lead Saver',.04,4,.92,30,13,C.muted)
    label(f,'IG Lead Saver',.06,52,.88,34,22,C.ink,true)
    label(f,'버전 1.4.0                 Chrome Web Store',.06,92,.88,27,12,C.muted)
    tap(f,'서비스 워커 (비활성)',.06,132,.88,43,function()ctx.finish('b')end,C.soft)
    tap(f,'시크릿 모드에서 허용     ○',.06,186,.88,43,function()ctx.finish('c')end,C.soft)
    local target=tap(f,'확장 프로그램 옵션                         ↗',.06,244,.88,52,function()ctx.finish('a')end,Color3.fromRGB(255,229,235))
    stroke(target,C.pink,3)
    label(f,'↑  설치 후에는 여기를 눌러 연결 화면으로 이동해요.',.06,300,.88,28,12,C.pink,true)
    ctx.primary('화면에서 옵션을 눌러주세요',nil,false)
end
local function connection(ctx,q)
    referenceImage(ctx,'settings','제공된 실제 IG Lead Saver 설정 화면 보기')
    local f=frame(ctx,490,C.white)
    label(f,'IG Lead Saver  ·  구글시트 연결 연습',.05,12,.9,29,20,C.ink,true)
    local status=label(f,'1 / 5   주소와 저장자 이름을 넣어주세요.',.05,47,.9,30,14,C.pink,true)
    local phase,hasUrl,name=1,false,''
    local sequence={}
    local url,nameBox,test,campaign,save,load,refresh
    local function fieldsReady()
        if phase==1 and hasUrl and #name>0 then
            phase=2;table.insert(sequence,'fields');status.Text='2 / 5   연결 테스트를 눌러주세요.'
        end
    end
    url=tap(f,'웹앱 URL  ·  주소 붙여넣기 (연습)',.05,91,.9,47,function()
        if phase>1 then return end
        hasUrl=true;url.Text='✓  전달받은 웹앱 주소 … /exec';fieldsReady()
    end,C.soft)
    stroke(url,C.pink,2)
    nameBox=make('TextBox',f,{Name='SaverName',Position=UDim2.new(.05,0,0,150),Size=UDim2.new(.63,0,0,46),Text='',PlaceholderText='저장자에 내 이름 입력',ClearTextOnFocus=false,Font=Enum.Font.Gotham,TextSize=14,BackgroundColor3=C.soft,TextColor3=C.ink,BorderSizePixel=0})
    round(nameBox,9)
    tap(f,'이름 예시',.71,150,.24,46,function()nameBox.Text='소현' end,C.soft)
    local nameConnection=nameBox:GetPropertyChangedSignal('Text'):Connect(function()name=nameBox.Text:gsub('%s','');fieldsReady()end)
    f.Destroying:Connect(function()nameConnection:Disconnect()end)
    test=tap(f,'연결 테스트',.05,208,.9,44,function()
        if phase~=2 then ctx.hint('웹앱 주소와 본인 이름을 먼저 입력해주세요.') return end
        table.insert(sequence,'test');phase=3;test.Text='✓ 연결됨 (연습)';test.BackgroundColor3=Color3.fromRGB(220,239,230);status.Text='3 / 5   목록을 새로고침하고 캠페인을 골라요.'
    end,C.soft)
    campaign=tap(f,'↻  캠페인 목록 새로고침 → 탭 선택',.05,265,.9,46,function()
        if phase~=3 then ctx.hint('연결 테스트를 먼저 완료해주세요.') return end
        campaign.Text='✓ '..q.visual.campaign;table.insert(sequence,'campaign');phase=4;status.Text='4 / 5   연락전 상태를 확인하고 저장해요.'
    end,C.soft)
    label(f,'기본 상태: 연락전',.05,321,.45,28,14,C.ink,true)
    save=tap(f,'설정 저장',.53,318,.42,38,function()
        if phase~=4 then ctx.hint('연결과 캠페인 선택을 먼저 진행해주세요.') return end
        table.insert(sequence,'save');phase=5;save.Text='✓ 저장됨';status.Text='5 / 5   저장목록 불러오기 → 인스타 새로고침'
    end,C.soft)
    load=tap(f,'시트에서 저장목록 불러오기',.05,370,.9,43,function()
        if phase~=5 then ctx.hint('설정 저장을 먼저 눌러주세요.') return end
        load.Text='✓ 저장목록 불러옴';phase=6
    end,C.soft)
    refresh=tap(f,'인스타그램 새로고침',.05,426,.9,43,function()
        if phase~=6 then ctx.hint('저장목록을 먼저 불러와주세요.') return end
        table.insert(sequence,'reload');phase=7;refresh.Text='✓ 새로고침 완료';status.Text='연결 연습 완료! 아래에서 완료 버튼을 눌러주세요.'
        ctx.primary('연결 과정 완료',function()ctx.finish(sequence)end,true)
    end,C.soft)
    caption(ctx,'이 화면은 모의 연결입니다. 실제 웹앱 URL은 별도 업무 안내서의 복사 버튼을 사용해주세요.')
end
local function status(ctx)
    local f=frame(ctx,156,C.white)
    label(f,'IG Lead Saver  /  저장 기본값',.06,10,.88,31,18,C.ink,true)
    label(f,'아직 DM을 보내지 않은 계정',.06,48,.88,25,14,C.muted)
    local menu=box(f,.05,145,.9,145,C.soft)
    menu.Visible=false
    local current
    current=tap(f,'기본 상태 선택   ▼',.05,87,.9,47,function()
        menu.Visible=not menu.Visible
        f.Size=UDim2.new(1,0,0,menu.Visible and 307 or 156)
    end,C.soft)
    stroke(current,C.pink,2)
    for i,item in ipairs({{id='a',name='연락전'},{id='b',name='DM 발송'},{id='c',name='최종 선정'}}) do
        tap(menu,item.name,.04,7+(i-1)*45,.92,40,function()
            current.Text='기본 상태: '..item.name..'   ▼'
            menu.Visible=false;f.Size=UDim2.new(1,0,0,156)
            ctx.primary('기본 상태 저장',function()ctx.finish(item.id)end,true)
        end,C.white)
    end
end
local function gallery(ctx,q)
    local brief=frame(ctx,70,C.ink)
    label(brief,'연습 캠페인  /  뷰티 릴스  /  팔로워 5천~3만',.05,8,.9,50,16,C.white,true)
    selectable(ctx,q.visual.profiles,286,function(b,item)
        art(b,item.art,UDim2.fromOffset(10,10),UDim2.new(1,-20,0,148))
        label(b,'@'..item.handle,.06,168,.88,30,15,C.ink,true)
        label(b,'팔로워 '..item.followers,.06,205,.88,26,18,C.pink,true)
        label(b,item.genre,.06,240,.88,34,13,C.muted)
    end,function(item)
        ctx.primary('선택한 계정 시트에 저장',function()ctx.finish(item.id)end,true)
    end)
    caption(ctx,'계정과 그림은 가상 예시입니다. 실제 콘텐츠의 완성도와 캠페인 분위기도 함께 확인해주세요.')
end
local function history(ctx,q)
    local f=frame(ctx,274,C.white)
    art(f,'beauty',UDim2.new(.05,0,0,18),UDim2.new(.18,0,0,67))
    label(f,'@beauty_sample\n1.8만 · 뷰티 릴스',.27,18,.67,66,16,C.ink,true)
    local details=label(f,'노란 표시를 눌러 접촉 이력을 펼쳐주세요.',.06,161,.88,95,15,C.muted)
    local opened=false
    tap(f,'! 기존 접촉  ·  이력 보기',.05,100,.9,47,function()
        opened=true;details.Text='접촉 이력 확인됨\n이전 캠페인에서 연락한 기록이 있어요.\n이번 캠페인의 중복 제외 기준을 확인해주세요.';details.TextColor3=C.ink
    end,Color3.fromRGB(255,237,196))
    choices(ctx,{{id='a',text='이번 캠페인의 중복 제외 기준 확인'},{id='b',text='이력 확인 없이 바로 저장'},{id='c',text='모든 캠페인에서 영구 제외'}},function(item)
        if not opened then ctx.hint('먼저 노란 ‘기존 접촉’을 눌러 이력을 봐주세요.') return end
        ctx.primary('이 계정의 다음 행동 결정',function()ctx.finish(item.id)end,true)
    end)
end
local function compose(ctx,q)
    local f=frame(ctx,300,C.white)
    art(f,'beauty',UDim2.new(.05,0,0,16),UDim2.new(.14,0,0,57))
    label(f,'@beauty_sample  ·  팔로워 1.8만',.23,20,.72,48,16,C.ink,true)
    local bubble=box(f,.08,102,.84,157,C.soft)
    local message=label(bubble,'아래에서 DM 문구를 골라보세요.',.07,13,.86,130,16,C.ink)
    label(f,'모의 DM  ·  실제 메시지는 발송되지 않아요.',.06,267,.88,25,12,C.muted)
    selectable(ctx,q.visual.templates,108,function(b,item)
        label(b,item.title,.07,14,.86,31,15,C.ink,true)
        label(b,item.fee>0 and ('제안 '..tostring(item.fee/10000)..'만 원') or '고료 미기재',.07,52,.86,34,19,C.pink,true)
    end,function(item)
        message.Text='안녕하세요, 시리아이입니다 :)\n뷰티 캠페인 협업을 제안드립니다.\n'..(item.fee>0 and ('제안 고료는 '..tostring(item.fee/10000)..'만 원입니다.') or '고료 안내 없음')..'\n관심 있으시면 지원 부탁드립니다.'
        ctx.primary('선택한 문구로 DM 발송',function()ctx.finish(item.id)end,true)
    end)
end
local function workflow(ctx)
    local f=frame(ctx,328,C.white)
    local phase=1
    local banner=label(f,'1 / 3   시트의 발송 대상 행을 눌러주세요.',.05,12,.9,42,17,C.pink,true)
    local screen=box(f,.05,70,.9,236,C.soft)
    local function clearScreen()
        for _,o in ipairs(screen:GetChildren()) do if o:IsA('GuiObject') then o:Destroy() end end
    end
    local function stepThree()
        clearScreen();banner.Text='3 / 3   발송한 계정의 상태를 바꿔주세요.'
        label(screen,'캠페인 진행 시트',.05,8,.9,33,17,C.ink,true)
        label(screen,'@beauty_sample\n팔로워 18,000',.05,53,.9,51,15,C.ink,true)
        label(screen,'DM을 보냈어요. 현재 상태: 연락전',.05,114,.9,34,14,C.muted)
        for i,item in ipairs({{id='wrong',text='연락전'},{id='mark',text='DM 발송'},{id='selected',text='최종 선정'}}) do
            tap(screen,item.text,.04+(i-1)*.31,165,.29,52,function()
                ctx.primary('시트 상태 저장',function()ctx.finish({'check','send',item.id})end,true)
            end,C.white)
        end
    end
    local function stepTwo()
        phase=2;clearScreen();banner.Text='2 / 3   제공된 문구로 DM을 발송해요.'
        art(screen,'beauty',UDim2.new(.05,0,0,12),UDim2.new(.15,0,0,60))
        label(screen,'@beauty_sample',.25,15,.7,42,16,C.ink,true)
        label(screen,'시리아이 뷰티 캠페인에 초대드립니다 :)\n제안 고료 10만 원 · 전달받은 양식',.05,80,.9,80,15,C.ink)
        tap(screen,'DM 발송 (연습)',.05,176,.9,44,function()if phase~=2 then return end phase=3;stepThree()end,Color3.fromRGB(255,226,233))
    end
    label(screen,'구글시트  /  안내받은 캠페인 탭',.05,13,.9,38,16,C.ink,true)
    label(screen,'계정                     팔로워      상태',.05,68,.9,28,12,C.muted)
    tap(screen,'@beauty_sample  ·  18,000  ·  연락전',.05,111,.9,69,function()if phase==1 then stepTwo()end end,C.white)
    ctx.primary('화면의 작업을 차례대로 진행해주세요',nil,false)
end
local function ledger(ctx,q)
    local receipt=frame(ctx,79,C.ink)
    local amount=label(receipt,'유효 발송 영수증  /  아직 선택하지 않았어요.',.05,9,.9,60,19,C.white,true)
    selectable(ctx,q.visual.records,238,function(b,item)
        art(b,item.art,UDim2.fromOffset(10,10),UDim2.new(1,-20,0,104))
        label(b,item.name,.06,124,.88,28,14,C.ink,true)
        label(b,item.state,.06,158,.88,28,18,C.pink,true)
        label(b,item.detail,.06,193,.88,35,12,C.muted)
    end,function(item)
        amount.Text='선택 기록 1건  /  대상: '..item.state
        ctx.primary('유효 발송 정산함에 넣기',function()ctx.finish(item.id)end,true)
    end)
end
local function chat(ctx,q)
    local f=frame(ctx,282,C.white)
    label(f,q.id=='shortage' and '시리아이 · 모집 파트너 단톡 (연습)' or '@creator_sample  /  문의 응대 연습',.05,10,.9,31,15,C.ink,true)
    local incoming=box(f,.04,57,.81,85,C.soft)
    label(incoming,q.visual.incoming,.07,8,.86,69,15,C.ink)
    local outgoing=box(f,.15,162,.81,100,Color3.fromRGB(226,238,231))
    local draft=label(outgoing,'답장 초안을 고르면 여기에 미리 보여요.',.07,9,.86,82,15,C.muted)
    choices(ctx,q.visual.drafts,function(item)
        draft.Text=item.text;draft.TextColor3=C.ink
        ctx.primary(q.id=='shortage' and '도움 요청 공유 (연습)' or '답장 보내기 (연습)',function()ctx.finish(item.id)end,true)
    end)
end
local function fee(ctx,q)
    local f=frame(ctx,212,C.white)
    label(f,'고료 조정 요청',.05,12,.9,28,19,C.ink,true)
    label(f,q.visual.incoming,.05,49,.9,65,16,C.ink)
    local preview=label(f,'답장 초안 선택 → 희망 금액 기록 → 단톡 공유',.05,126,.9,70,14,C.muted)
    local selected,note,shared=nil,nil,false
    local function ready()
        ctx.primary('답장 · 비고 · 공유 완료',function()ctx.finish({reply=selected,note=note,shared=shared})end,selected~=nil and note~=nil and shared)
    end
    choices(ctx,q.visual.drafts,function(item)selected=item.id;preview.Text=item.text;preview.TextColor3=C.green;ready()end)
    local sheet=frame(ctx,183,C.soft)
    label(sheet,'시트 비고  /  희망 고료를 기록해요.',.05,8,.9,34,16,C.ink,true)
    local memo=label(sheet,'희망 고료 미입력',.05,53,.9,34,16,C.pink,true)
    for i,n in ipairs({100000,150000,200000}) do
        tap(sheet,tostring(n/10000)..'만 원',.05+(i-1)*.31,111,.28,49,function()note=n;memo.Text='희망 고료 '..tostring(n/10000)..'만 원 / 조정 요청';ready()end,C.white)
    end
    local share
    share=ctx.button(ctx.body,'□ 단톡에 계정과 희망 금액 공유 (연습)',{TextSize=15,BackgroundColor3=C.white})
    share.Activated:Connect(function()shared=not shared;share.Text=(shared and '✓ ' or '□ ')..'단톡에 계정과 희망 금액 공유 (연습)';share.BackgroundColor3=shared and Color3.fromRGB(220,239,230) or C.white;ready()end)
end
local function incentive(ctx,q)
    local token=frame(ctx,70,C.ink)
    label(token,'2,000원 인센티브  ·  어느 단계에 붙일까요?',.05,8,.9,51,19,C.white,true)
    local badges={}
    selectable(ctx,q.visual.people,241,function(b,item)
        art(b,item.art,UDim2.fromOffset(10,10),UDim2.new(1,-20,0,135))
        label(b,item.label,.06,153,.88,32,17,C.ink,true)
        badges[item.id]=label(b,'카드를 눌러 붙이기',.06,192,.88,33,13,C.muted)
    end,function(item,b)
        for _,v in pairs(badges) do v.Text='카드를 눌러 붙이기';v.TextColor3=C.muted end
        badges[item.id].Text='+ 2,000원';badges[item.id].TextColor3=C.pink
        ctx.primary('이 단계에 인센티브 적용',function()ctx.finish(item.id)end,true)
    end)
end
local function calculator(ctx,q)
    local f=frame(ctx,381,C.white)
    label(f,'교육용 정산표',.05,12,.9,30,21,C.ink,true)
    local a=box(f,.05,57,.43,67,C.soft)
    label(a,'유효 발송\n'..q.visual.sent..'건',.08,5,.84,57,18,C.ink,true)
    local b=box(f,.52,57,.43,67,C.soft)
    label(b,'최종 선정\n'..q.visual.selected..'명',.08,5,.84,57,18,C.ink,true)
    label(f,'발송 단가',.05,140,.43,30,14,C.muted)
    label(f,'선정 단가',.52,140,.43,30,14,C.muted)
    local baseRate,bonusRate=0,0
    local totalLabel=label(f,'단가를 넣으면 합계가 나와요.',.05,244,.9,45,23,C.ink,true)
    local baseBar=box(f,.05,310,0,18,C.pink)
    local bonusBar=box(f,.05,335,0,18,C.green)
    local details=label(f,'분홍: 발송 보수  /  초록: 선정 인센티브',.05,356,.9,20,12,C.muted)
    local baseButtons,bonusButtons={},{}
    local function update()
        local total=q.visual.sent*baseRate+q.visual.selected*bonusRate
        totalLabel.Text=string.format('%d + %d = %d원',q.visual.sent*baseRate,q.visual.selected*bonusRate,total)
        local max=math.max(total,1)
        baseBar.Size=UDim2.new(.9*q.visual.sent*baseRate/max,0,0,18)
        bonusBar.Size=UDim2.new(.9*q.visual.selected*bonusRate/max,0,0,18)
        for rate,but in pairs(baseButtons) do but.BackgroundColor3=baseRate==rate and Color3.fromRGB(255,226,233) or C.soft end
        for rate,but in pairs(bonusButtons) do but.BackgroundColor3=bonusRate==rate and Color3.fromRGB(220,239,230) or C.soft end
        ctx.primary('정산표 확인',function()ctx.finish({baseRate=baseRate,bonusRate=bonusRate,total=total})end,baseRate>0 and bonusRate>0)
    end
    for i,rate in ipairs({300,2000}) do
        baseButtons[rate]=tap(f,rate..'원',.05+(i-1)*.22,181,.2,45,function()baseRate=rate;update()end,C.soft)
        bonusButtons[rate]=tap(f,rate..'원',.52+(i-1)*.22,181,.2,45,function()bonusRate=rate;update()end,C.soft)
    end
    caption(ctx,'금액은 세전 예시입니다. 게임의 점수와 실제 보수는 연결되지 않아요.')
end
local function calendar(ctx,q)
    local f=frame(ctx,237,C.white)
    label(f,'월말에는 집계, 지급은 계약서의 날짜에',.05,9,.9,38,18,C.ink,true)
    for d=1,31 do
        local column=(d-1)%7;local row=math.floor((d-1)/7)
        local day=box(f,.05+column*.13,56+row*29,.11,24,d==31 and C.pink or C.soft)
        label(day,tostring(d),.06,0,.88,24,12,d==31 and C.white or C.muted,d==31)
    end
    label(f,'달력은 예시  /  실제 지급일은 계약서 기준',.05,207,.9,24,12,C.muted)
    choices(ctx,{{id='a',text='월말 실적 집계 → 계약서 기준·지급일에 정산'},{id='b',text='교육 게임 점수 → 실제 급여로 자동 지급'},{id='c',text='가상 예시 금액 → 모든 캠페인에 그대로 적용'}},function(item)
        ctx.primary('실제 업무 시작 기준 확인',function()ctx.finish(item.id)end,true)
    end)
end
local renderers={profile=profile,flow=flow,options=options,connection=connection,status=status,gallery=gallery,history=history,compose=compose,workflow=workflow,ledger=ledger,chat=chat,fee=fee,incentive=incentive,calculator=calculator,calendar=calendar}
function V.render(ctx,q)
    if not q.visual or not renderers[q.visual.kind] then return false end
    ctx.primary('화면에서 직접 진행해주세요',nil,false)
    ctx.secondary('화면 다시 보기',ctx.replay)
    local hint=ctx.text(ctx.body,'›  '..(q.visual.hint or '화면을 보고 직접 연습해요.'),15,C.pink,true)
    renderers[q.visual.kind](ctx,q)
    return true
end
function V.feedback(ctx,q,correct)
    if not q or not q.visual then return end
    local kind=q.visual.kind
    local key=({profile='brand',flow='mail',options='brand',connection='brand',status='chat',gallery='beauty',history='beauty',compose='mail',workflow='mail',ledger='mail',chat='chat',fee='chat',incentive='beauty',calculator='skincare',calendar='chat'})[kind] or 'brand'
    local f=frame(ctx,146,correct and Color3.fromRGB(224,239,230) or C.soft)
    art(f,key,UDim2.new(.04,0,0,16),UDim2.new(.25,0,0,112))
    label(f,correct and '✓ 화면 속 작업을 완료했어요' or '다시 화면을 보며 연습해요',.34,22,.61,47,19,correct and C.green or C.ink,true)
    local captions={profile='프로필에 선택한 자료 반영',connection='입력 → 테스트 → 캠페인 → 저장 → 불러오기',gallery='조건 확인 후 적합한 계정 저장',compose='기본 고료를 담은 구간별 DM',workflow='발송 후 시트 상태까지 변경',fee='희망 고료 기록 · 공유',calculator='발송 보수 + 최종 선정 인센티브'}
    label(f,captions[kind] or '설명을 읽고 다음 화면에서 다시 해봐요.',.34,78,.61,46,14,C.muted)
end
return V
