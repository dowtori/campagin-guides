"""Build v4: distinct pavilions, embedded approved/generated images, twilight world."""
import json,math,random
from pathlib import Path
ROOT=Path(__file__).resolve().parent
PAPER='F7F5EF';INK='252438';PINK='FF527D';GOLD='EAC27B'
random.seed(23)
scene=[];part_records={}
def rgb(h):return [int(h[i:i+2],16)/255 for i in (0,2,4)]
def rotation(x=0,y=0,z=0):
    a,b,c=map(math.radians,(x,y,z));sx,cx=math.sin(a),math.cos(a);sy,cy=math.sin(b),math.cos(b);sz,cz=math.sin(c),math.cos(c)
    return [cy*cz,-cy*sz,sy,cx*sz+sx*sy*cz,cx*cz-sx*sy*sz,-sx*cy,sx*sz-cx*sy*cz,sx*cz+cx*sy*sz,cx*cy]
def cf(pos,rot=(0,0,0)):return list(pos)+rotation(*rot)
def obj(name,cls,props=None,children=None):return {'Name':name,'ClassName':cls,'Properties':props or {},'Children':children or []}
def part(parent,name,pos,size,color=PAPER,material='SmoothPlastic',shape='Block',rot=(0,0,0),trans=0,collide=True):
    p=obj(name,'Part',{'Anchored':True,'CanCollide':collide,'CanTouch':False,'CanQuery':collide,'Size':list(size),'CFrame':cf(pos,rot),'Color':rgb(color),'Material':material,'Transparency':trans,'TopSurface':'Smooth','BottomSurface':'Smooth','Shape':shape,'CastShadow':material!='Neon' and not name.startswith('Reed ')})
    parent.append(p);record={'name':name,'position':list(pos),'size':list(size),'rotation':list(rot),'color':'#'+color,'shape':shape,'material':material,'transparency':trans,'shadow':material!='Neon' and not name.startswith('Reed '),'wind':name.startswith('Reed ')};scene.append(record);part_records[id(p)]=record
    return p
def sign(parent,name,pos,size,title,color=INK,bg=PAPER,rot=(0,0,0)):
    p=part(parent,name,pos,size,bg,rot=rot,collide=False)
    label=obj('Text','TextLabel',{'Size':{'UDim2':[[.9,0],[.86,0]]},'Position':{'UDim2':[[.05,0],[.07,0]]},'BackgroundTransparency':1,'Text':title,'TextColor3':rgb(color),'Font':'GothamBold','TextScaled':True,'TextWrapped':True,'RichText':False},[obj('ReadableSize','UITextSizeConstraint',{'MinTextSize':12,'MaxTextSize':72})])
    p['Children'].append(obj('Lettering','SurfaceGui',{'Face':'Back','SizingMode':'PixelsPerStud','PixelsPerStud':42,'LightInfluence':0,'MaxDistance':135},[label]));part_records[id(p)]['label']=title;part_records[id(p)]['labelColor']='#'+color
    return p
rasters=json.loads((ROOT/'raster-data.json').read_text(encoding='utf-8-sig'))
def raster(parent,name,pos,size,key,rot=(0,0,0),distance=130,bg=INK):
    p=part(parent,name,pos,size,bg,rot=rot,collide=False);a=rasters[key];w=a['fallbackWidth'];h=a['fallbackHeight'];palette=a['fallbackPalette'];rects=[]
    for i,(x,y,sw,sh,c) in enumerate(a['rects'] if key in ('sky','wordmark') or key.startswith('booth') else []):
        rects.append(obj('px','Frame',{'Position':{'UDim2':[[x/w,0],[y/h,0]]},'Size':{'UDim2':[[sw/w,0],[sh/h,0]]},'BackgroundColor3':rgb(palette[c][:6]),'BorderSizePixel':0}))
    holder=obj('Pixels','Frame',{'Size':{'UDim2':[[1,0],[1,0]]},'BackgroundTransparency':1,'BorderSizePixel':0,'ClipsDescendants':True},rects)
    gui=obj('RasterArt','SurfaceGui',{'Face':'Back','SizingMode':'FixedSize','CanvasSize':[a['width'],a['height']],'LightInfluence':0,'MaxDistance':distance,'AlwaysOnTop':False},[holder])
    p['Children'] += [gui,obj('RasterKey','StringValue',{'Value':key})];part_records[id(p)]['raster']=key
    return p
curriculum=json.loads((ROOT/'src/server/Curriculum.json').read_text(encoding='utf-8-sig'));curriculum['version']='4.0.0'
for i,s in enumerate(curriculum['stages']):s['position']=[-58 if i%2==0 else 58,4,8-(i//2)*78]
(ROOT/'src/server/Curriculum.json').write_bytes(json.dumps(curriculum,ensure_ascii=False,indent=2).encode('utf-8'))
world=[];stations=[]
from environment_v4 import build_environment
env=build_environment(world,part,obj,rgb,cf,raster,curriculum)
# Arrival is free of posts and low signs across the player's sightline.
spawn=obj('ArrivalSpawn','SpawnLocation',{'Anchored':True,'CanCollide':True,'CanTouch':False,'Size':[8,.3,8],'CFrame':cf((0,.95,60)),'Color':rgb('B79E82'),'Material':'WoodPlanks','Neutral':True,'Enabled':True,'Duration':0,'Transparency':0,'TopSurface':'Smooth','BottomSurface':'Smooth'});world.append(spawn)
part(world,'Arrival deck',(0,.7,58),(45,.4,32),'B99C79','WoodPlanks')
raster(world,'Welcome wordmark',(-20,8,59),(18,5.2,.4),'wordmark',bg=INK)
sign(world,'Welcome instruction',(18,5.2,48),(13,7,.45),'여섯 공간을 돌며 직접 익혀요\n부스 안에서 E / 미션 시작\n미션지도로 빠르게 이동',INK,'F6EADC')
# No column intersects either welcome panel.
for x in [-27,27]:part(world,'Arrival lamp post',(x,3,58),(.45,5,.45),'8D735C','Wood')
intros=['제공된 자료로 프로필 준비\n로고 · 소개 · 링크','확장프로그램 연결\n주소 · 이름 · 캠페인','캠페인에 맞는 인원 찾기\n콘텐츠 · 팔로워 · 이력','구간별 DM을 보내고\n발송 상태까지 표시','고료 조정 요청은\n희망 금액 기록 · 공유','유효 발송과 최종 선정\n실적을 확인하고 정산']
for stage in curriculum['stages']:
    sid=stage['id'];x,_,z=stage['position'];accent=stage['color'];children=[]
    part(children,'Pavilion floor',(x,.8,z),(45,.45,42),'B39574','WoodPlanks')
    part(children,'Booth back wall',(x,6.7,z-20),(44,11.5,.6),'393448','Wood')
    part(children,'Booth color back',(x,7.2,z-19.6),(43,10.4,.18),accent,trans=.58,collide=False)
    for dx in [-21,21]:
        for dz in [-19,19]:part(children,'Pavilion post',(x+dx,7.7,z+dz),(1,13.5,1),'8C7059','Wood')
        part(children,'Side boundary',(x+dx,2.5,z),(.55,3,36),'8C7059','Wood')
        part(children,'Pavilion beam',(x+dx,14.4,z),(1,1,40),'8C7059','Wood')
    for dz in [-19,-11,-3,5,13,19]:part(children,'Pergola rafter',(x,14.45,z+dz),(44,.5,1),'AC8A65','Wood')
    part(children,'Front header',(x,15.2,z+20),(44,2.8,.65),INK,'Wood')
    sign(children,'Booth title',(x+3,15.2,z+20.5),(34,2.3,.2),stage['title'],'FFFFFF',INK)
    sign(children,'Booth number',(x-17.2,15.2,z+20.6),(6,2.8,.2),f'{sid:02d}','FFFFFF',accent)
    part(children,'Colored entry strip',(x,1.07,z+18),(40,.12,3),accent,collide=False)
    part(children,'Side light',(x-20.4,8,z+19.6),(.2,8,.2),accent,'Neon',collide=False)
    part(children,'Side light',(x+20.4,8,z+19.6),(.2,8,.2),accent,'Neon',collide=False)
    raster(children,'Booth artwork',(x-10,7.9,z-19.1),(17,13.5,.35),f'booth{sid}',bg=INK)
    sign(children,'Booth overview',(x+12,10,z-19.0),(14,4.5,.25),intros[sid-1],'FFFFFF',INK)
    raster(children,'Siriai brand mark',(x+17,3.5,z-18.9),(3,3,.2),'logoWhite',bg=INK)
    part(children,'Kiosk pedestal',(x-2,2.1,z+3),(11,2.5,2.4),accent)
    terminal=sign(children,'Terminal',(x-2,4.9,z+2.8),(11,4,.8),f'미션 {sid:02d} 시작\nE 키 / 화면 버튼','FFFFFF',INK)
    terminal['Children'].append(obj('StartMission','ProximityPrompt',{'ActionText':'미션 시작','ObjectText':f'{sid:02d} {stage["title"]}','KeyboardKeyCode':'E','GamepadKeyCode':'ButtonX','HoldDuration':0,'MaxActivationDistance':18,'RequiresLineOfSight':False,'ClickablePrompt':True,'Enabled':True}))
    part(children,'Terminal light',(x-2,7.05,z+2.8),(11,.15,1),accent,'Neon',collide=False)
    # All approach paths stop at the open entrance; they do not lead behind a sign or post.
    d=1 if x>0 else -1
    part(world,'Station approach',(x/2,.83,z+29),(abs(x)+9,.3,8),'B49A79','WoodPlanks')
    part(world,'Entrance bridge',(x,.83,z+23.5),(10,.3,10),'B49A79','WoodPlanks')
    for step in [12,27,42]:part(world,'Route marker',(d*step,1,z+29),(2,.09,2),accent,'Neon',collide=False)
    stations.append(obj(f'Station{sid:02d}','Model',children=children))
# Graduation deck sits beyond the six booths.
part(world,'Graduation deck',(0,.83,-226),(38,.4,24),'B49A79','WoodPlanks')
sign(world,'Graduation sign',(-31,5.5,-230),(20,4,.6),'여섯 미션 완료!\n이제 첫 연결을 준비해요','FFFFFF',INK)
# Export exactly the native part layout for the browser.
model=obj('TrainingMap','Model',children=[obj('Architecture','Folder',children=world),obj('Stations','Folder',children=stations)]);model.pop('Name',None)
(ROOT/'map/TrainingMap.model.json').write_bytes(json.dumps(model,ensure_ascii=False,separators=(',',':')).encode('utf-8'))
(ROOT/'scene.json').write_bytes(json.dumps(scene,ensure_ascii=False,separators=(',',':')).encode('utf-8'))
(ROOT/'environment.json').write_bytes(json.dumps(env,ensure_ascii=False,indent=2).encode('utf-8'))
project={'name':'SIRIAI Training Campus v4','tree':{'$className':'DataModel',
'Workspace':{'$properties':{'Gravity':196.2,'FallenPartsDestroyHeight':-35},'TrainingMap':{'$path':'map/TrainingMap.model.json'},'Terrain':{'$className':'Terrain','Clouds':{'$className':'Clouds','$properties':{'Cover':.15,'Density':.2,'Color':rgb('F1BDD0')}}}},
'Lighting':{'$properties':{'Ambient':rgb('8F7B9E'),'OutdoorAmbient':rgb('A494B7'),'Brightness':2,'ClockTime':18.1,'GeographicLatitude':28,'GlobalShadows':True,'ShadowSoftness':.65,'ColorShift_Top':rgb('F6BD93'),'EnvironmentDiffuseScale':.8,'EnvironmentSpecularScale':.7},'Atmosphere':{'$className':'Atmosphere','$properties':{'Density':.18,'Offset':.05,'Color':rgb('D2B3CF'),'Decay':rgb('8C7BAD'),'Haze':1.1,'Glare':.4}},'Sky':{'$className':'Sky','$properties':{'CelestialBodiesShown':False,'StarCount':0}},'Bloom':{'$className':'BloomEffect','$properties':{'Intensity':.2,'Size':30,'Threshold':1.4}},'WarmGrade':{'$className':'ColorCorrectionEffect','$properties':{'Brightness':.02,'Contrast':.035,'Saturation':.02,'TintColor':rgb('FFF1EF')}}},
'ReplicatedStorage':{'TrainingEvent':{'$className':'RemoteEvent'},'TrainingShared':{'$path':'src/shared'}},
'ServerScriptService':{'$path':'src/server'},
'StarterPlayer':{'$properties':{'CameraMaxZoomDistance':90,'CameraMinZoomDistance':5,'CharacterWalkSpeed':20,'CharacterJumpPower':50},'StarterPlayerScripts':{'$className':'StarterPlayerScripts','$path':'src/client'}},
'SoundService':{'$properties':{'RespectFilteringEnabled':True}}}}
(ROOT/'default.project.json').write_bytes(json.dumps(project,ensure_ascii=False,indent=2).encode('utf-8'))
missions=[{**{k:s[k] for k in ['id','title','subtitle','color','position']},'topics':[q['title'] for q in s['questions']]} for s in curriculum['stages']]
(ROOT/'missions.json').write_bytes(json.dumps(missions,ensure_ascii=False).encode('utf-8'))
(ROOT/'visual-assets.json').write_bytes((ROOT/'src/shared/VisualAssets.json').read_bytes())
(ROOT/'tutorials.json').write_bytes((ROOT/'src/server/Curriculum.json').read_bytes())
print(f'v4 native map: {len(scene)} parts; six separated booths; embedded raster imagery and red-sun sky')
