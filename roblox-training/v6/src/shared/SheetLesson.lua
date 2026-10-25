-- Captured real blank sheet with native practice data and the actual status options.
local Sheet={}
function Sheet.render(ui,data,lead,d)
 local make,txt,btn,C=ui.make,ui.txt,ui.btn,ui.colors
 local UDim2,Vector2,Enum=ui.UDim2,ui.Vector2,ui.Enum
 d.status=d.status or '연락전'
 ui.configure(840,true)
 txt(ui.body,'신규모집 · @'..lead.handle,20,C.ink)
 local width=math.max(720,math.min(840,ui.width-32)-54);local height=width*168/653
 local viewport=make('ScrollingFrame',ui.body,{Name='SheetViewport',Size=UDim2.new(1,0,0,height+8),CanvasSize=UDim2.fromOffset(width,height),ScrollingDirection=Enum.ScrollingDirection.X,ScrollBarThickness=4,BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true})
 local sheet=make('Frame',viewport,{Name='ActualSheet',Size=UDim2.fromOffset(width,height),BackgroundTransparency=1})
 ui.raster.draw(sheet,'sheetStatus')
 local function cell(name,text,x,w)
  local t=txt(sheet,text,16,C.ink,28);t.Name=name;t.Position=UDim2.new(x/653,4,58/168,0);t.Size=UDim2.new(w/653,-8,21/168,0);t.TextYAlignment=Enum.TextYAlignment.Center;t.TextWrapped=false
 end
 cell('SheetProfile',lead.handle,67,151);cell('SheetLink','instagram.com/'..lead.handle,218,251);cell('SheetFollowers',string.format('%.1f만',lead.followers/10000),469,91)
 local status=btn(sheet,d.status..' ▾',function()d.statusMenu=not d.statusMenu;ui.render()end);status.Name='SheetStatusCell';status.Position=UDim2.new(560/653,0,58/168,-8);status.Size=UDim2.new(91/653,0,0,44);status.TextSize=16;status.BackgroundColor3=d.status=='DM 발송' and C.green or C.soft;status.TextColor3=d.status=='DM 발송' and C.white or C.ink
 if d.statusMenu then
  local choices=make('Frame',ui.body,{Name='StatusOptions',Size=UDim2.new(1,0,0,156),BackgroundTransparency=1})
  for i,value in ipairs({'연락전','DM 발송','회신 옴','협업 진행','보류','부적합'})do
   local choice=value;local b=btn(choices,value,function()d.status=choice;d.statusMenu=false;ui.render()end);b.Name='SetStatus'..i;b.Position=UDim2.new(((i-1)%2)/2,0,0,math.floor((i-1)/2)*52);b.Size=UDim2.new(.5,-6,0,46);b.TextSize=18
  end
 end
end
return Sheet
