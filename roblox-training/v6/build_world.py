"""Build v5: safe shoreline, original company guide visuals, native nature imports."""
import json,math,random
from pathlib import Path
ROOT=Path(__file__).resolve().parent
PAPER='F5F4F0';INK='1B1916';PINK='FF234B';GOLD='EAC27B'
random.seed(23)
scene=[];part_records={}
def rgb(h):return [int(h[i:i+2],16)/255 for i in (0,2,4)]
def rotation(x=0,y=0,z=0):
    a,b,c=map(math.radians,(x,y,z));sx,cx=math.sin(a),math.cos(a);sy,cy=math.sin(b),math.cos(b);sz,cz=math.sin(c),math.cos(c)
    return [cy*cz,-cy*sz,sy,cx*sz+sx*sy*cz,cx*cz-sx*sy*sz,-sx*cy,sx*sz-cx*sy*cz,sx*cz+cx*sy*sz,cx*cy]
def cf(pos,rot=(0,0,0)):return list(pos)+rotation(*rot)
def obj(name,cls,props=None,children=None):return {'Name':name,'ClassName':cls,'Properties':props or {},'Children':children or []}
def part(parent,name,pos,size,color=PAPER,material='SmoothPlastic',shape='Block',rot=(0,0,0),trans=0,collide=True):
    p=obj(name,'Part',{'Anchored':True,'CanCollide':collide,'CanTouch':False,'CanQuery':collide,'Size':list(size),'CFrame':cf(pos,rot),'Color':rgb(color),'Material':material,'Transparency':trans,'TopSurface':'Smooth','BottomSurface':'Smooth','Shape':shape,'CastShadow':material!='Neon' and not name.startswith(('Reed ','Kenney grass'))})
    if shape=='Wedge':p['ClassName']='WedgePart';p['Properties'].pop('Shape',None)
    parent.append(p);record={'name':name,'position':list(pos),'size':list(size),'rotation':list(rot),'color':'#'+color,'shape':shape,'material':material,'transparency':trans,'shadow':material!='Neon' and not name.startswith(('Reed ','Kenney grass')),'wind':name.startswith('Reed ')};scene.append(record);part_records[id(p)]=record
    return p
def sign(parent,name,pos,size,title,color=INK,bg=PAPER,rot=(0,0,0)):
    p=part(parent,name,pos,size,bg,rot=rot,collide=False)
    label=obj('Text','TextLabel',{'Size':{'UDim2':[[.9,0],[.86,0]]},'Position':{'UDim2':[[.05,0],[.07,0]]},'BackgroundTransparency':1,'Text':title,'TextColor3':rgb(color),'Font':'GothamBold','TextScaled':True,'TextWrapped':True,'RichText':False},[obj('ReadableSize','UITextSizeConstraint',{'MinTextSize':12,'MaxTextSize':72})])
    p['Children'].append(obj('Lettering','SurfaceGui',{'Face':'Back','SizingMode':'PixelsPerStud','PixelsPerStud':42,'LightInfluence':0,'MaxDistance':135},[label]));part_records[id(p)]['label']=title;part_records[id(p)]['labelColor']='#'+color
    return p
rasters=json.loads((ROOT/'raster-data.json').read_text(encoding='utf-8-sig'))
def raster(parent,name,pos,size,key,rot=(0,0,0),distance=130,bg=INK):
    p=part(parent,name,pos,size,bg,rot=rot,collide=False);a=rasters[key];w=a['fallbackWidth'];h=a['fallbackHeight'];palette=a['fallbackPalette'];rects=[]
    for i,(x,y,sw,sh,c) in enumerate(a['rects'] if key in ('wordmark','logo','logoWhite') else []):
        rects.append(obj('px','Frame',{'Position':{'UDim2':[[x/w,0],[y/h,0]]},'Size':{'UDim2':[[sw/w,0],[sh/h,0]]},'BackgroundColor3':rgb(palette[c][:6]),'BorderSizePixel':0}))
    holder=obj('Pixels','Frame',{'Size':{'UDim2':[[1,0],[1,0]]},'BackgroundTransparency':1,'BorderSizePixel':0,'ClipsDescendants':True},rects)
    gui=obj('RasterArt','SurfaceGui',{'Face':'Back','SizingMode':'FixedSize','CanvasSize':[a['width'],a['height']],'LightInfluence':0,'MaxDistance':distance,'AlwaysOnTop':False},[holder])
    p['Children'] += [gui,obj('RasterKey','StringValue',{'Value':key})];part_records[id(p)]['raster']=key
    return p
case=json.loads((ROOT/'case.json').read_text(encoding='utf-8'))
world=[]
from environment import build_environment
curriculum={'stages':[{'position':[-34,4,42]},{'position':[-50,4,-55]},{'position':[46,4,-44]}]}
env=build_environment(world,part,obj,rgb,cf,raster,curriculum)
# A small roleplay village: an agency house, a creator garden and a message kiosk.
# No numbered learning booths or landscape texture walls.
for x,z,w,d,name in [(-34,42,57,43,'Agency terrace'),(-50,-55,54,43,'Creator garden'),(46,-44,48,39,'Message deck')]:
    part(world,name,(x,.65,z),(w,.5,d),'C5AD8D','WoodPlanks')
for x,z,w,d in [(-17,60,42,8),(-25,-27,56,8),(24,-16,55,8)]:part(world,'Connecting path',(x,.64,z),(w,.4,d),'C5AD8D','WoodPlanks')
# Agency silhouette: a dark sloped roof, pale walls, broad open front.
part(world,'Agency back',(-34,6.3,22),(56,11,.6),PAPER)
for x in [-61,-7]:part(world,'Agency side',(x,6.3,36),(.65,11,27),PAPER)
for x,angle in [(-48,16),(-20,-16)]:part(world,'Agency roof',(x,16.6,36),(30,1,34),'494653','Slate',rot=(0,0,angle))
part(world,'Agency ridge',(-34,20.75,36),(1.3,1.2,35),'494653','Slate')
raster(world,'Agency wordmark',(-34,10.8,22.5),(20,5.83,.15),'wordmark',bg=INK)
# Timber framing, siding, roof ribs and planters give the agency a village silhouette.
for x in [-61,-7]:
    for z in [22,52]:part(world,'Agency timber post',(x,6.7,z),(1,12,1),'6E6262','Wood')
    for y in [2.1,4.0,5.9,7.8,9.7,11.6]:part(world,'Agency siding',(x,y,36),(.9,.11,27),'B6ACA0','Wood')
part(world,'Front timber beam',(-34,12.6,52),(55,.6,.65),'6E6262','Wood')
for x,angle in [(-48,16),(-20,-16)]:
    for z in [20,29,38,47,52]:part(world,'Roof rib',(x,17.15,z),(30,.15,.28),'716A78','Slate',rot=(0,0,angle))
for x in [-54,-14]:
    part(world,'Agency planter',(x,1.8,56),(3,2.3,3),'A48A72','WoodPlanks')
    for k in [-1,0,1]:part(world,'Planter leaf',(x+k*.65,3.2,56),(.7,2.5,.7),'9EAE86','SmoothPlastic','Ball',rot=(0,0,k*20),collide=False)
part(world,'Agency light',(-34,12.1,51),(20,.15,.25),'FFE3AF','Neon',collide=False)
# Workbench props use a proper computer silhouette rather than a wall of screenshots.
for x,z,title in [(-48,32,'프로필 준비'),(-19,32,'시트 연결')]:
    part(world,'Work desk',(x,3.0,z),(12,.55,5),'B6A18B','Wood')
    for dx in [-5,5]:part(world,'Desk leg',(x+dx,1.65,z),(1,2.4,4),'655F5A')
    part(world,'Monitor foot',(x,3.55,z),(4,.3,2),'38353C')
    part(world,'Monitor stalk',(x,4.8,z),(.6,2.4,.6),'38353C')
    screen=sign(world,'Monitor',(x,6.1,z),(8,4.7,.45),title,'FFFFFF',INK)
    part(world,'Keyboard',(x,3.38,z+1.8),(5,.15,1.2),'5C5863')
# Creator platforms form a garden trail; recognizable block avatars, not panels as buildings.
for x,z in [(-76,-47),(-52,-69),(-25,-49)]:
    part(world,'Creator platform',(x,1.1,z),(13,.8,13),'B3AD9A','Sandstone')
    part(world,'Garden back rail',(x,2,z-6),(12,.6,.5),'817B70','Wood')
# A ring light and compact camera identify the beauty creator's working corner.
part(world,'Ring light stand',(-82,3.7,-50),(.22,6,.22),'494653')
for i in range(16):
    angle=i*math.pi/8
    part(world,'Ring light',(-82+1.3*math.cos(angle),7.2+1.3*math.sin(angle),-50),(.55,.18,.16),'F7E6C9','Neon',rot=(0,0,math.degrees(angle)+90),collide=False)
part(world,'Creator camera',(-81,4.3,-44),(1.2,.9,.7),'37333F')
part(world,'Camera tripod',(-81,2.4,-44),(.2,3.1,.2),'494653')
part(world,'Travel camera',(-22,3,-48),(1.3,1,.7),'59505A')
# A chunky mailbox is the job prop. A short pulse and flying envelope mark a send.
part(world,'Mailbox post',(46,2.2,-47),(2,3.2,2),'67616E')
part(world,'Mailbox body',(46,5.1,-47),(9,4.4,5),PINK)
part(world,'Mailbox top',(46,7.1,-47),(9,.7,5.5),'DB1D43')
part(world,'Mailbox opening',(46,5.9,-44.42),(6,.45,.14),INK,collide=False)
raster(world,'Mailbox logo',(46,4.2,-44.4),(2,2,.1),'logoWhite',bg=PINK)
sign(world,'Mailbox sign',(46,10,-47),(17,2.8,.3),'DM POST','FFFFFF',INK)
part(world,'Reply desk',(60,3,-41),(10,.5,6),'B6A18B','Wood')
part(world,'Reply phone',(60,3.6,-40),(2.5,.35,4.2),INK)
# NPC geometry is built in Roblox's classic block-avatar proportions.
actors=obj('QuestObjects','Folder');world.append(actors)
def actor(name,x,z,shirt,hair):
    model=obj(name,'Model');actors['Children'].append(model);c=model['Children'];y=4.1
    c.append(obj('Humanoid','Humanoid',{'RequiresNeck':False,'BreakJointsOnDeath':False,'DisplayDistanceType':'None','HealthDisplayType':'AlwaysOff','NameDisplayDistance':0}))
    part(c,'Torso',(x,y,z),(2.2,2.2,1.15),shirt)
    part(c,'Head',(x,y+1.85,z),(1.55,1.55,1.45),'E8BD9D','SmoothPlastic','Ball')
    part(c,'Hair',(x,y+2.43,z-.12),(1.65,.65,1.45),hair,'SmoothPlastic','Ball')
    for side in [-1,1]:
        part(c,'Right Arm' if side>0 else 'Left Arm',(x+side*1.55,y-.05,z),(.85,2.2,1),'E8BD9D',rot=(0,0,side*-5))
        part(c,'Right Leg' if side>0 else 'Left Leg',(x+side*.59,y-2.03,z),(1,1.85,1),'403D49')
        part(c,'Right Shoe' if side>0 else 'Left Shoe',(x+side*.59,y-3.01,z+.18),(1.1,.4,1.4),'F2EDE7')
        part(c,'Eye',(x+side*.27,y+1.94,z+.7),(.12,.16,.06),'25232B',collide=False)
    part(c,'Smile',(x,y+1.57,z+.72),(.35,.06,.06),'5C4440',collide=False)
    if name=='Manager':raster(c,'Uniform symbol',(x,y+.25,z+.59),(.9,.9,.03),'logoWhite',bg=shirt)
    return model
actor('Manager',-34,55,'2D2B34','36333F')
actor('beauty_sample',-76,-47,'C7AA9B','51444A')
actor('tiny_sample',-52,-69,'A8B8C7','242632')
actor('trip_sample',-25,-49,'839A84','6C594C')
def target(name,pos,caption,parent=None):
    children=actors['Children'] if parent is None else parent
    p=part(children,'Target_'+name,pos,(4,5,4),trans=1,collide=False)
    p['Children'].append(obj('Interact','ProximityPrompt',{'ActionText':caption,'ObjectText':({'Manager':'시리아이 매니저','ProfileDesk':'프로필 PC','ConnectDesk':'연결 PC','Mailbox':'DM 우체통','ReplyDesk':'회신 확인','beauty_sample':'뷰티 크리에이터','tiny_sample':'뷰티 크리에이터','trip_sample':'여행 크리에이터'}).get(name,name),'KeyboardKeyCode':'E','GamepadKeyCode':'ButtonX','HoldDuration':0,'MaxActivationDistance':14,'RequiresLineOfSight':False,'ClickablePrompt':True,'Enabled':True}))
    p['Children'].append(obj('ActionID','StringValue',{'Value':name}))
    return p
for name,pos,caption in [('Manager',(-34,5,57),'매니저와 대화'),('ProfileDesk',(-48,5,36),'프로필 준비'),('ConnectDesk',(-19,5,36),'도구 연결'),('beauty_sample',(-76,5,-44),'크리에이터 살펴보기'),('tiny_sample',(-52,5,-66),'크리에이터 살펴보기'),('trip_sample',(-25,5,-46),'크리에이터 살펴보기'),('Mailbox',(46,5,-40),'모집 DM 보내기'),('ReplyDesk',(60,5,-36),'도착한 회신 확인')]:
    target(name,pos,caption)
# Arrival gives a view of the manager and a single short instruction.
spawn=obj('ArrivalSpawn','SpawnLocation',{'Anchored':True,'CanCollide':True,'CanTouch':False,'Size':[8,.3,8],'CFrame':cf((0,1,100)),'Color':rgb('C5AD8D'),'Material':'WoodPlanks','Neutral':True,'Duration':0,'Transparency':0});world.append(spawn)
part(world,'Arrival dock',(0,.68,100),(29,.45,26),'C5AD8D','WoodPlanks')
sign(world,'Arrival title',(26,7,97),(18,4,.35),'인플루언서 모집을 로블록스에서!',INK,PAPER,rot=(0,-65,0))
sign(world,'Arrival direction',(26,3.5,97),(18,2.5,.3),'매니저에게 다가가 E / 터치',INK,PAPER,rot=(0,-65,0))
for x in [-16,16]:part(world,'Arrival bollard',(x,2.1,94),(.8,3,.8),'6C6370','Wood')
# Final reward is a real object beside the sea: a branded pin sculpture and seats.
raster(world,'Lookout brand',(0,7,-341),(5,5,.3),'logoWhite',bg=INK)
sign(world,'Version plate',(-13,2.2,110),(8,1.4,.2),'SIRIAI v6','FFFFFF',INK)
for x,z in [(-34,64),(-48,38),(-19,38),(-50,-28),(46,-30)]:
    part(world,'Quest paving marker',(x,1.01,z),(2.7,.12,2.7),PINK,'Neon',collide=False)
# New-world data remains independent of every previous training implementation.
env.update(version='6.0.0',views={'sunset':{'position':[0,8,-205],'target':[70,34,-850]},'overview':{'position':[164,143,172],'target':[0,3,-30]},'agency':{'position':[-12,17,103],'target':[-34,6,38]},'garden':{'position':[-19,18,-12],'target':[-50,5,-63]}})
model=obj('TrainingMap','Model',children=[obj('Architecture','Folder',children=world)]);model.pop('Name',None)
for name,value in [('map/TrainingMap.model.json',model),('scene.json',scene),('environment.json',env)]:
    (ROOT/name).write_text(json.dumps(value,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
project={'name':'SIRIAI Recruiter Island v6','tree':{'$className':'DataModel','Workspace':{'$properties':{'FallenPartsDestroyHeight':-4096,'GlobalWind':[4,0,1.5]},'TrainingMap':{'$path':'map/TrainingMap.model.json'},'Terrain':{'$className':'Terrain','Clouds':{'$className':'Clouds','$properties':{'Cover':.28,'Density':.25,'Color':rgb('D6C2D9')}}}},'Lighting':{'$properties':{'Ambient':rgb('8F7B9E'),'OutdoorAmbient':rgb('A494B7'),'Brightness':2,'ClockTime':18.05,'GeographicLatitude':28,'GlobalShadows':True,'ShadowSoftness':.7,'ColorShift_Top':rgb('F6BD93'),'EnvironmentDiffuseScale':.85,'EnvironmentSpecularScale':.65},'Atmosphere':{'$className':'Atmosphere','$properties':{'Density':.21,'Offset':.12,'Color':rgb('CDB1C9'),'Decay':rgb('8375A4'),'Haze':1.2,'Glare':.15}},'Sky':{'$className':'Sky','$properties':{'CelestialBodiesShown':False,'StarCount':0}},'Bloom':{'$className':'BloomEffect','$properties':{'Intensity':.14,'Size':24,'Threshold':1.5}}},'StarterGui':{'$className':'StarterGui','$path':'src/gui'},'ReplicatedStorage':{'CampusEvent':{'$className':'RemoteEvent'},'CampusShared':{'$path':'src/shared'}},'ServerScriptService':{'$path':'src/server'},'StarterPlayer':{'$properties':{'CharacterWalkSpeed':20,'CameraMaxZoomDistance':65,'CameraMinZoomDistance':5},'StarterPlayerScripts':{'$className':'StarterPlayerScripts','$path':'src/client'}}}}
(ROOT/'default.project.json').write_text(json.dumps(project,indent=2),encoding='utf-8')
print('v6 fresh world:',len(scene),'parts, 3 job locations, 4 NPCs, 8 contextual targets; no scenery images')
