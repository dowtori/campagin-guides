"""Build v6.9: native coastal terrain, clustered nature and original company visuals."""
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
    parent.append(p);record={'name':name,'position':list(pos),'size':list(size),'rotation':list(rot),'color':'#'+color,'shape':shape,'material':material,'transparency':trans,'shadow':material!='Neon' and not name.startswith(('Reed ','Meadow ','Kenney grass')),'wind':name=='Meadow blade'};scene.append(record);part_records[id(p)]=record
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
from layout import TARGETS,SPAWN,PATH
case=json.loads((ROOT/'case.json').read_text(encoding='utf-8'))
world=[]
from environment import build_environment
curriculum={'stages':[{'position':[-34,4,66]},{'position':[-58,4,8]},{'position':[-42,4,-44]}]}
env=build_environment(world,part,obj,rgb,cf,raster,curriculum)
# A small roleplay village: an agency house, a creator garden and a message kiosk.
# No numbered learning booths or landscape texture walls.
for x,z,w,d,name in [(-34,66,57,43,'Agency terrace'),(-58,8,60,52,'Creator garden'),(-42,-44,48,39,'Message deck')]:
    part(world,name,(x,.65,z),(w,.5,d),'C5AD8D','WoodPlanks')
# Keep the main boardwalk continuous, including the preparation pavilion.
def shift_since(start,dx,dz):
    def visit(n):
        if n['ClassName'] in ['Part','WedgePart','Seat']:
            f=n['Properties']['CFrame'];f[0]+=dx;f[2]+=dz
            rec=part_records.get(id(n))
            if rec:rec['position'][0]+=dx;rec['position'][2]+=dz
        for child in n.get('Children',[]):visit(child)
    for n in world[start:]:visit(n)
house_start=len(world)
# Agency silhouette: a dark sloped roof, pale walls, broad open front.
# Two rear wings leave a 20-stud opening aligned with the forward route.
for x in [-53,-15]:part(world,'Agency back wing',(x,6.3,22),(18,11,.6),PAPER)
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
shift_since(house_start,0,24)
# Creator platforms form a garden trail; recognizable block avatars, not panels as buildings.
for x,z in [(-46,20),(-73,2),(-52,-13)]:
    part(world,'Creator platform',(x,1.1,z),(13,.8,13),'B3AD9A','Sandstone')
    part(world,'Garden back rail',(x,2,z-6),(12,.6,.5),'817B70','Wood')
# A ring light and compact camera identify the beauty creator's working corner.
part(world,'Ring light stand',(-52,3.7,17),(.22,6,.22),'494653')
for i in range(16):
    angle=i*math.pi/8
    part(world,'Ring light',(-52+1.3*math.cos(angle),7.2+1.3*math.sin(angle),17),(.55,.18,.16),'F7E6C9','Neon',rot=(0,0,math.degrees(angle)+90),collide=False)
part(world,'Creator camera',(-51,4.3,23),(1.2,.9,.7),'37333F')
part(world,'Camera tripod',(-51,2.4,23),(.2,3.1,.2),'494653')
part(world,'Travel camera',(-49,3,-12),(1.3,1,.7),'59505A')
message_start=len(world)
# A chunky mailbox is the job prop. A short pulse and flying envelope mark a send.
part(world,'Mailbox post',(46,2.2,-47),(2,3.2,2),'67616E')
part(world,'Mailbox body',(46,5.1,-47),(9,4.4,5),PINK)
part(world,'Mailbox top',(46,7.1,-47),(9,.7,5.5),'DB1D43')
part(world,'Mailbox opening',(46,5.9,-44.42),(6,.45,.14),INK,collide=False)
raster(world,'Mailbox logo',(46,4.2,-44.4),(2,2,.1),'logoWhite',bg=PINK)
sign(world,'Mailbox sign',(46,10,-47),(17,2.8,.3),'DM POST','FFFFFF',INK)
shift_since(message_start,-90,0)
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
    if name.startswith('AnswerNPC'):
        for p in c:
            if id(p) in part_records:part_records[id(p)]['answerNPC']=True
    return model
actor('Manager',-44,79,'2D2B34','36333F')
actor('beauty_sample',-46,20,'C7AA9B','51444A')
actor('tiny_sample',-73,2,'A8B8C7','242632')
actor('trip_sample',-52,-13,'839A84','6C594C')
def target(name,pos,caption,parent=None):
    children=actors['Children'] if parent is None else parent
    p=part(children,'Target_'+name,pos,(4,5,4),trans=1,collide=False)
    p['Children'].append(obj('Interact','ProximityPrompt',{'ActionText':caption,'ObjectText':({'Manager':'준비 테라스','ProfileDesk':'프로필 PC','ConnectDesk':'연결 PC','Mailbox':'DM 데스크','ReplyDesk':'회신 확인','beauty_sample':'뷰티 크리에이터','tiny_sample':'뷰티 크리에이터','trip_sample':'여행 크리에이터'}).get(name,name),'KeyboardKeyCode':'E','GamepadKeyCode':'ButtonX','HoldDuration':0,'MaxActivationDistance':14,'RequiresLineOfSight':False,'ClickablePrompt':True,'Enabled':True}))
    p['Children'].append(obj('ActionID','StringValue',{'Value':name}))
    return p
for name,entry in TARGETS.items():target(name,entry['position'],entry['caption'])
# Arrival gives a view of the manager and a single short instruction.
spawn=obj('ArrivalSpawn','SpawnLocation',{'Anchored':True,'CanCollide':True,'CanTouch':False,'Size':[8,.3,8],'CFrame':cf((SPAWN[0],1,SPAWN[1])),'Color':rgb('C5AD8D'),'Material':'WoodPlanks','Neutral':True,'Duration':0,'Transparency':0});world.append(spawn)
part(world,'Arrival dock',(-34,.68,100),(29,.45,26),'C5AD8D','WoodPlanks')
sign(world,'Arrival title',(-8,7,97),(18,4,.35),'인플루언서 모집을 로블록스에서!',INK,PAPER,rot=(0,-65,0))
sign(world,'Arrival direction',(-8,3.5,97),(18,2.5,.3),'매니저에게 다가가 E / 터치',INK,PAPER,rot=(0,-65,0))
for x in [-50,-18]:part(world,'Arrival bollard',(x,2.1,94),(.8,3,.8),'6C6370','Wood')
# Original blunt thumbs-up stands to the side of the clear water-access path.
from pier_sculpture import add_thumbs_up
thumb=add_thumbs_up(world,part,obj,cf)
for primitive in thumb['Children']:
    record=part_records[id(primitive)];record['matrix']=primitive['Properties']['CFrame'][3:]
    record['thumbStage']=primitive['Children'][-1]['Properties']['Value'];record['thumb']=True
from advanced_room import add_room
add_room(world,part,obj,sign,actor)
sign(world,'Version plate',(-47,2.2,110),(8,1.4,.2),'SIRIAI v6.9','FFFFFF',INK)
# Short inset chevrons mark forward travel without a screen-size route diagram.
for z in [92,43,35,0,-19,-60]:
    for side in [-1,1]:part(world,'Forward route arrow',(-34+side*.5,1.03,z),(1.5,.055,.18),PINK,'SmoothPlastic',rot=(0,side*38,0),collide=False)
# New-world data remains independent of every previous training implementation.
env.update(version='6.9',views={'challenge':{'position':[60,9,-54],'target':[60,10,-89]},'challengeEntry':{'position':[60,6,-63],'target':[60,10,-89]},'pier':{'position':[-45,14,-280],'target':[-29,10,-328]},'pierClose':{'position':[-41,12,-295],'target':[-29,8,-328]},'meadow':{'position':[0,5,-230],'target':[15,4,-325]},'sunset':{'position':[0,8,-205],'target':[70,34,-850]},'overview':{'position':[164,143,172],'target':[0,3,-30]},'agency':{'position':[-10,19,113],'target':[-34,6,63]},'garden':{'position':[-4,11,25],'target':[-54,4,7]},'gardenOriginal':{'position':[-5,20,49],'target':[-47,5,8]}})
route={'version':'6.9','spawn':list(SPAWN),'path':PATH,'targets':TARGETS,'requiredStops':['Manager','beauty_sample','Mailbox']}
(ROOT/'route.json').write_text(json.dumps(route,ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'src/shared/RouteData.json').write_text(json.dumps(route,ensure_ascii=False,indent=2),encoding='utf-8')
model=obj('TrainingMap','Model',children=[obj('Architecture','Folder',children=world)]);model.pop('Name',None)
for name,value in [('map/TrainingMap.model.json',model),('scene.json',scene),('environment.json',env)]:
    (ROOT/name).write_text(json.dumps(value,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
project={'name':'SIRIAI Recruiter Island v6.9','tree':{'$className':'DataModel','Workspace':{'$properties':{'FallenPartsDestroyHeight':-4096,'GlobalWind':[4,0,1.5]},'TrainingMap':{'$path':'map/TrainingMap.model.json'},'Terrain':{'$className':'Terrain','$properties':{'Decoration':True,'WaterColor':rgb('7C9EAB'),'WaterTransparency':.48,'WaterReflectance':.42,'WaterWaveSize':.14,'WaterWaveSpeed':5},'Clouds':{'$className':'Clouds','$properties':{'Cover':.28,'Density':.25,'Color':rgb('E1D5C6')}}}},'Lighting':{'$properties':{'Ambient':rgb('9B9488'),'OutdoorAmbient':rgb('B6AC98'),'Brightness':2,'ClockTime':17.7,'GeographicLatitude':28,'GlobalShadows':True,'ShadowSoftness':.7,'ColorShift_Top':rgb('F6BD93'),'EnvironmentDiffuseScale':.85,'EnvironmentSpecularScale':.65},'Atmosphere':{'$className':'Atmosphere','$properties':{'Density':.24,'Offset':.12,'Color':rgb('DBCAAE'),'Decay':rgb('9DABB5'),'Haze':1.2,'Glare':.15}},'Sky':{'$className':'Sky','$properties':{'CelestialBodiesShown':False,'StarCount':0}},'Bloom':{'$className':'BloomEffect','$properties':{'Intensity':.14,'Size':24,'Threshold':1.5}}},'StarterGui':{'$className':'StarterGui','$path':'src/gui'},'ReplicatedStorage':{'CampusEvent':{'$className':'RemoteEvent'},'AdvancedEvent':{'$className':'RemoteEvent'},'CampusShared':{'$path':'src/shared'}},'ServerScriptService':{'$path':'src/server'},'StarterPlayer':{'$properties':{'CharacterWalkSpeed':20,'CameraMaxZoomDistance':65,'CameraMinZoomDistance':5},'StarterPlayerScripts':{'$className':'StarterPlayerScripts','$path':'src/client'}}}}
(ROOT/'default.project.json').write_text(json.dumps(project,indent=2),encoding='utf-8')
print('v6 fresh world:',len(scene),'parts, 3 job locations, 7 NPCs, 3 shared work targets; no scenery images')
