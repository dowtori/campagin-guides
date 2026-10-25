-- Exact supplied Instagram capture with native hit areas; example metadata is explicit.
local Lesson={}
function Lesson.render(ui,data,d)
 local UDim2,UDim,Vector2,Enum=ui.UDim2,ui.UDim,ui.Vector2,ui.Enum
 local make,txt,btn,body,C=ui.make,ui.txt,ui.btn,ui.body,ui.colors
 local catalog=data.collection;d.view=d.view or 'tagged';d.saved=d.saved or {};d.order=d.order or {}
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
 local post=postById(d.postId);local detail=d.view=='post'
 local preferred=math.min(840,math.max(574,((ui.height or 720)-300)*510/362+54))
 ui.clear(detail and '@'..post.author or catalog.brandHandle,detail and '태그됨에서 계정 수집' or '태그됨 · 계정 정보는 연습용')
 ui.configure(detail and 700 or preferred,detail or #d.order>0)
 if detail then
  local p=profiles[post.author]
  txt(body,catalog.metadataNotice,16,C.gray)
  local info=txt(body,followers(p)..' 팔로워 · '..p.genre,20,C.ink);info.Name='CreatorFacts'
  local frame=make('Frame',body,{Name='CollectionDetail',Size=UDim2.new(1,0,0,300),BackgroundTransparency=1})
  local im=ui.raster.draw(frame,post.image,UDim2.fromScale(.5,0),UDim2.fromOffset(225,300));im.AnchorPoint=Vector2.new(.5,0)
  ui.alternate('태그됨으로 돌아가기',function()d.view='tagged';refresh()end)
  if d.saved[post.author] then ui.action('저장됨',nil,false)else ui.action('시트에 저장',function()save(post)end)end
  return
 end
 local gridWidth=math.max(520,math.min(preferred,ui.width-32)-54)
 local gridHeight=gridWidth*362/510
 local viewport=make('ScrollingFrame',body,{Name='InstagramViewport',Size=UDim2.new(1,0,0,gridHeight+8),CanvasSize=UDim2.fromOffset(gridWidth,gridHeight),ScrollingDirection=Enum.ScrollingDirection.X,ScrollBarThickness=4,BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true})
 local grid=make('Frame',viewport,{Name='TaggedGrid',Size=UDim2.fromOffset(gridWidth,gridHeight),BackgroundTransparency=1})
 ui.raster.draw(grid,'oddtypeTagged')
 for i,entry in ipairs(catalog.posts)do
  local post=entry;local saved=d.saved[post.author]~=nil
  local x=(i-1)%4;local y=math.floor((i-1)/4)
  local tile=make('Frame',grid,{Name='TaggedPost_'..post.id,Position=UDim2.new(x/4,0,(22+y*170)/362,0),Size=UDim2.new(.25,0,170/362,0),BackgroundTransparency=1})
  local open=make('TextButton',tile,{Name='Post_'..post.id,Text='',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),AutoButtonColor=false})
  open.Activated:Connect(function()d.postId=post.id;d.view='post';refresh()end)
  local saveButton=btn(tile,saved and '✓ 저장됨' or '+ 저장',function()save(post)end);saveButton.Name='Save_'..post.id
  saveButton.AnchorPoint=Vector2.new(1,1);saveButton.Position=UDim2.new(1,-6,1,-6);saveButton.Size=UDim2.new(1,-12,0,44);saveButton.TextSize=18
  saveButton.BackgroundColor3=saved and C.green or C.ink;saveButton.TextColor3=C.white;saveButton.Active=not saved
 end
 if #d.order>0 then
  local saved=txt(body,'✓ 시트에 '..#d.order..'명 추가됨',20,C.green);saved.Name='SavedSheetRows'
  ui.action('수집 완료 · DM 대상 확인',finish)
 end
end
return Lesson
