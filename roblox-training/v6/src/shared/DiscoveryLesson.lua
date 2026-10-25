-- A guided brand/Tagged collection workspace, not a candidate-answer quiz.
local Lesson={}
function Lesson.render(ui,data,d)
 local UDim2,UDim,Vector2,Enum=ui.UDim2,ui.UDim,ui.Vector2,ui.Enum
 local make,txt,btn,round,body,C=ui.make,ui.txt,ui.btn,ui.round,ui.body,ui.colors
 local catalog=data.collection;d.view=d.view or 'brand';d.saved=d.saved or {};d.order=d.order or {}
 local profiles={};for _,p in ipairs(data.profiles)do profiles[p.id]=p end
 local function refresh()ui.render()end
 local function followers(p)return string.format('%.1f만',p.followers/10000)end
 local function postById(id)for _,p in ipairs(catalog.posts)do if p.id==id then return p end end end
 local function save(post)
  if not d.saved[post.author] then d.saved[post.author]=post.id;table.insert(d.order,post.author)end
  d.view='tagged';refresh()
 end
 local function finish()
  local rows={};for _,handle in ipairs(d.order)do table.insert(rows,{handle=handle,postId=d.saved[handle]})end
  ui.submit({sourceBrand=catalog.brandHandle,sourceTab='tagged',collected=rows})
 end
 local post=postById(d.postId)
 local detail=d.view=='post' or d.view=='profile'
 local profile=detail and profiles[post.author]
 ui.clear(detail and '@'..profile.handle or '@'..catalog.brandHandle,'태그됨에서 계정 수집')
 ui.configure(760,detail or #d.order>0)
 local criteria=make('Frame',body,{Name='CollectionCriteria',Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.soft,BorderSizePixel=0});round(criteria,8)
 make('UIPadding',criteria,{PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,10),PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14)})
 make('UIListLayout',criteria,{SortOrder=Enum.SortOrder.LayoutOrder})
 local criteriaText=ui.width<600 and string.gsub(data.criteria,' · ','\n') or data.criteria
 txt(criteria,criteriaText,20,C.ink)
 if detail then
  local info=txt(body,followers(profile)..' 팔로워  ·  '..profile.genre,20,C.ink);info.Name='CreatorFacts'
  local frame=make('Frame',body,{Name='CollectionDetail',Size=UDim2.new(1,0,0,d.view=='post' and 280 or 210),BackgroundTransparency=1})
  if d.view=='post' then
   local image=ui.raster.draw(frame,post.image,UDim2.fromScale(.5,0),UDim2.fromScale(1,1));image.AnchorPoint=Vector2.new(.5,0)
   make('UIAspectRatioConstraint',image,{AspectRatio=1,AspectType=Enum.AspectType.FitWithinMaxSize})
   txt(body,post.caption,22,C.ink)
   local open=btn(body,'@'..profile.handle..' 프로필 보기',function()d.view='profile';refresh()end);open.Name='OpenCreatorProfile'
  else
   for i,key in ipairs(profile.posts)do
    local image=ui.raster.draw(frame,'creator'..key,UDim2.new((i-1)/3,0,0,0),UDim2.new(1/3,-6,1,0))
    make('UIAspectRatioConstraint',image,{AspectRatio=1,AspectType=Enum.AspectType.FitWithinMaxSize})
   end
   txt(body,profile.recent,22,C.ink)
  end
  txt(body,profile.history,18,C.gray)
  ui.alternate('태그됨으로 돌아가기',function()d.view='tagged';refresh()end)
  if d.saved[post.author] then ui.action('저장됨',nil,false)else ui.action('시트에 저장',function()save(post)end)end
  return
 end
 local tabs=make('Frame',body,{Name='BrandTabs',Size=UDim2.new(1,0,0,48),BackgroundTransparency=1})
 for i,v in ipairs({{id='brand',label='게시물'},{id='tagged',label='태그됨'}})do
  local tab=btn(tabs,v.label,function()d.view=v.id;refresh()end);tab.Name=v.id=='tagged' and 'TaggedTab' or 'PostsTab'
  tab.Size=UDim2.new(.5,-4,1,0);tab.Position=UDim2.new((i-1)*.5,(i-1)*4,0,0)
  tab.BackgroundColor3=d.view==v.id and C.ink or C.soft;tab.TextColor3=d.view==v.id and C.white or C.gray
 end
 if d.view=='brand' then
  txt(body,'태그됨에서 협업 콘텐츠를 살펴봐요.',22,C.ink)
  local strip=make('Frame',body,{Name='BrandPosts',Size=UDim2.new(1,0,0,180),BackgroundTransparency=1})
  for i,key in ipairs({'creator2','creator3','creator6'})do
   local image=ui.raster.draw(strip,key,UDim2.new((i-1)/3,0,0,0),UDim2.new(1/3,-6,1,0));make('UIAspectRatioConstraint',image,{AspectRatio=1,AspectType=Enum.AspectType.FitWithinMaxSize})
  end
  if #d.order>0 then ui.action('수집 완료 · DM 대상 확인',finish)end
  return
 end
 if #d.order>0 then
  local rows={};for _,handle in ipairs(d.order)do table.insert(rows,'@'..handle..'  ·  '..followers(profiles[handle])..'  ·  연락전')end
  local f=ui.card('✓ 시트에 '..#d.order..'명 추가됨 · '..data.campaign,table.concat(rows,'\n'));f.Name='SavedSheetRows'
  ui.action('수집 완료 · DM 대상 확인',finish)
 end
 local columns=ui.width<600 and 2 or 3
 local available=math.min(760,ui.width-32)-54
 local cell=(available-10*(columns-1))/columns;local tileHeight=cell+48
 local grid=make('Frame',body,{Name='TaggedGrid',Size=UDim2.new(1,0,0,math.ceil(#catalog.posts/columns)*(tileHeight+12)-12),BackgroundTransparency=1})
 for i,entry in ipairs(catalog.posts)do
  local post=entry;local p=profiles[post.author];local saved=d.saved[post.author]~=nil
  local x=(i-1)%columns;local y=math.floor((i-1)/columns)
  local tile=make('Frame',grid,{Name='TaggedPost_'..post.id,Position=UDim2.new(x/columns,x*10/columns,0,y*(tileHeight+12)),Size=UDim2.new(1/columns,-10*(columns-1)/columns,0,tileHeight),BackgroundColor3=C.white,BorderSizePixel=0,ClipsDescendants=true});round(tile,8)
  ui.raster.draw(tile,post.image,UDim2.fromOffset(0,0),UDim2.new(1,0,0,cell))
  local open=make('TextButton',tile,{Name='Post_'..post.id,Text='',BackgroundTransparency=1,Size=UDim2.new(1,0,0,cell),AutoButtonColor=false})
  open.Activated:Connect(function()d.postId=post.id;d.view='post';refresh()end)
  local badge=txt(tile,followers(p),18,C.white,28);badge.Name='FollowerBadge';badge.Position=UDim2.fromOffset(6,6);badge.Size=UDim2.fromOffset(76,28);badge.BackgroundColor3=C.ink;badge.BackgroundTransparency=.08;badge.Font=Enum.Font.GothamBold;badge.TextXAlignment=Enum.TextXAlignment.Center;badge.TextYAlignment=Enum.TextYAlignment.Center;round(badge,6)
  local author=txt(tile,'@'..p.handle,16,C.ink,44);author.Name='PostAuthor';author.Position=UDim2.fromOffset(8,cell+4);author.Size=UDim2.new(1,-16,0,44);author.TextYAlignment=Enum.TextYAlignment.Center
  local saveButton=btn(tile,saved and '✓ 저장됨' or '+ 저장',function()save(post)end);saveButton.Name='Save_'..post.id
  saveButton.Position=UDim2.new(0,6,0,cell-50);saveButton.Size=UDim2.new(1,-12,0,44)
  saveButton.BackgroundColor3=saved and C.soft or C.pink;saveButton.TextColor3=saved and C.green or C.white;saveButton.Active=not saved;saveButton.AutoButtonColor=not saved
 end
end
return Lesson
