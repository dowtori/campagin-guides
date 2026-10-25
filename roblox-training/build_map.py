"""Build the original-part campus and its matching web preview scene.
Run: python build_map.py; then rojo build default.project.json -o downloads/SIRIAI_Training_Campus.rbxlx
No imported meshes, textures, audio, or free models are used.
"""
import json, math, random
from pathlib import Path
ROOT=Path(__file__).resolve().parent
random.seed(23)
PAPER='F7F5EF'; INK='252420'; PINK='FF234B'; SOFT='E7E3D9'; GREY='A6A39B'; GREEN='83B09A'; GOLD='EAC27B'
scene=[]
def rgb(h): return [int(h[i:i+2],16)/255 for i in (0,2,4)]
def rotation(x=0,y=0,z=0):
    a,b,c=map(math.radians,(x,y,z)); sx,cx=math.sin(a),math.cos(a); sy,cy=math.sin(b),math.cos(b); sz,cz=math.sin(c),math.cos(c)
    return [cy*cz,-cy*sz,sy, cx*sz+sx*sy*cz,cx*cz-sx*sy*sz,-sx*cy, sx*sz-cx*sy*cz,sx*cz+cx*sy*sz,cx*cy]
def cf(pos,rot=(0,0,0)): return list(pos)+rotation(*rot)
def obj(name,cls,props=None,children=None):
    return {'Name':name,'ClassName':cls,'Properties':props or {},'Children':children or []}
def part(parent,name,pos,size,color=PAPER,material='SmoothPlastic',shape='Block',rot=(0,0,0),trans=0,collide=True):
    props={'Anchored':True,'CanCollide':collide,'CanTouch':False,'CanQuery':True,'Size':list(size),'CFrame':cf(pos,rot),'Color':rgb(color),'Material':material,'Transparency':trans,'TopSurface':'Smooth','BottomSurface':'Smooth','Shape':shape,'CastShadow':material!='Neon'}
    p=obj(name,'Part',props); parent.append(p)
    scene.append({'name':name,'position':list(pos),'size':list(size),'rotation':list(rot),'color':'#'+color,'shape':shape,'material':material,'transparency':trans})
    return p

def sign(parent,name,pos,size,title,color=INK,bg=PAPER,scale=1):
    board=part(parent,name,pos,size,bg,collide=False)
    ui=obj('Lettering','SurfaceGui',{'Face':'Back','SizingMode':'PixelsPerStud','PixelsPerStud':28,'LightInfluence':0,'AlwaysOnTop':False})
    label=obj('Text','TextLabel',{'Size':{'UDim2':[[1,0],[1,0]]},'BackgroundTransparency':1,'Text':title,'TextColor3':rgb(color),'Font':'GothamBold','TextScaled':True,'TextWrapped':True})
    ui['Children']=[label]; board['Children'].append(ui)
    scene[-1]['label']=title
    return board

def cylinder(parent,name,pos,height,diameter,color,material='SmoothPlastic',collide=False):
    return part(parent,name,pos,(height,diameter,diameter),color,material,'Cylinder',(0,0,90),collide=collide)

def plant(parent,x,z,large=False):
    if large:
        cylinder(parent,'Tree trunk',(x,3.3,z),5.2,1.5,'A68C6F')
        for dx,dy,dz,r in [(0,7,0,6.2),(-2,6.1,.4,4.5),(2.1,6.2,.2,4.3)]:
            part(parent,'Tree canopy',(x+dx,dy,z+dz),(r,r,r),random.choice(['91B4A0','AEC4A1','B7C7AA']),shape='Ball',collide=False)
    else:
        cylinder(parent,'Planter',(x,1.4,z),1.8,2.8,'D5C3A5')
        for dx,dy,dz in [(0,3.4,0),(-.7,2.9,.3),(.6,3,.3)]:
            part(parent,'Plant leaf',(x+dx,dy,z+dz),(1.7,2.8,1.6),'8FAB92',shape='Ball',collide=False)

def bench(parent,x,z,rot=0):
    part(parent,'Bench seat',(x,1.7,z),(7,.5,2.4),'C2A98A',rot=(0,rot,0))
    for dx in [-2.5,2.5]: part(parent,'Bench leg',(x+dx,1,z),(.5,1.4,1.7),INK)

def table(parent,x,z,color=SOFT):
    cylinder(parent,'Cafe tabletop',(x,3.2,z),.45,6,color,collide=True)
    cylinder(parent,'Table stem',(x,1.8,z),2.8,.55,INK)
    for dx,dz in [(-4,0),(4,0),(0,4)]:
        cylinder(parent,'Stool',(x+dx,1.9,z+dz),.55,2.4,PINK)
        cylinder(parent,'Stool leg',(x+dx,.95,z+dz),1.8,.5,INK)

world=[]; station_models=[]
part(world,'Soft blue surround',(0,-4,-45),(420,1,400),'BFD8DE',trans=.15,collide=False)
part(world,'Island plinth',(0,-1.1,-43),(172,3.2,238),'D6D1C5','Concrete')
part(world,'Campus ground',(0,.35,-43),(168,.5,234),'EEECE5','Concrete')
part(world,'Central avenue',(0,.68,-42),(15,.18,200),PAPER)
for z in range(-139,43,9): part(world,'Avenue dash',(0,.8,z),(.5,.06,3.4),'C4BFB2',collide=False)
# Physical perimeter rails keep walking routes forgiving.
for x in [-84,84]:
    part(world,'Side border',(x,1.4,-43),(.8,2.2,234),'C3BDAF')
for z in [-160,74]: part(world,'End border',(0,1.4,z),(168,2.2,.8),'C3BDAF')
# Arrival plaza and gateway.
part(world,'Arrival plaza',(0,.7,42),(54,.25,35),SOFT)
spawn=obj('ArrivalSpawn','SpawnLocation',{'Anchored':True,'CanCollide':True,'CanTouch':False,'Size':[8,.3,8],'CFrame':cf((0,.95,43)),'Color':rgb(PINK),'Material':'SmoothPlastic','Neutral':True,'Enabled':True,'Duration':0,'Transparency':0,'TopSurface':'Smooth','BottomSurface':'Smooth'})
world.append(spawn)
scene.append({'name':'Spawn','position':[0,.95,43],'size':[8,.3,8],'rotation':[0,0,0],'color':'#'+PINK,'shape':'Block','material':'SmoothPlastic','transparency':0})
for x in [-13,13]: part(world,'Welcome portal pillar',(x,7.2,28),(1.6,13,1.6),INK)
part(world,'Welcome portal top',(0,13.6,28),(27.6,1.4,1.6),INK)
sign(world,'Welcome title',(0,11,28),(22,3,.25),'SIRIAI CAMPUS',PAPER,INK)
sign(world,'Arrival wayfinding',(0,3.8,21),(16,3.6,.6),'분홍 표식을 따라 미션 시작\nE 키 · 모바일은 버튼 터치',INK,PAPER)
for x in [-26,26]: plant(world,x,42,True)
bench(world,-22,57);bench(world,22,57)
# Original monogram sculpture, built from simple tilted blocks.
for offset,angle in [((-4,3.6,59),-22),((0,5.8,59),22),((4,8,59),-22)]:
    part(world,'Sculpture stroke',offset,(9,1.3,1.5),PINK,rot=(0,0,angle),collide=False)
sign(world,'Lobby welcome',(-54,7.5,51),(29,12,.8),'소현님, 반가워요 :)\n\n찾고 · 보내고 · 연결하기\n6개 미션 / 18개 활동',PAPER,INK)
sign(world,'Lobby controls',(54,7.5,51),(29,12,.8),'HOW TO PLAY\n\nWASD 이동 · Space 점프\n단말기에서 E / 터치\n미션지도에서 빠른 이동',INK,PAPER)

curriculum=json.loads((ROOT/'src/server/Curriculum.json').read_text(encoding='utf-8-sig'))
for stage in curriculum['stages']:
    sid=stage['id']; x,_,z=stage['position']; accent=stage['color']; children=[]
    part(children,'Pavilion floor',(x,.8,z),(45,.45,39),PAPER)
    part(children,'Accent doorstep',(x,1.06,z+16),(36,.08,2.5),accent,collide=False)
    part(children,'Back wall',(x,6.6,z-17),(44,12,.8),SOFT)
    for dx in [-21,21]:
        part(children,'Pavilion post',(x+dx,7.8,z+16),(1,14,1),INK)
        part(children,'Pavilion beam',(x+dx,14.6,z),(1,1,34),INK)
        part(children,'Side window',(x+dx,6,z-10),(.35,10,12),'CCD6D1','Glass',trans=.62)
    part(children,'Canopy rear',(x,14.6,z-13),(44,1,9),PAPER)
    part(children,'Front beam',(x,14.6,z+16),(44,1,1),INK)
    part(children,'Accent roof strip',(x,15.2,z-10),(44,.15,.6),accent,'Neon',collide=False)
    sign(children,'Pavilion title',(x,12.8,z+16.6),(34,2.5,.3),f'{sid:02d}  {stage["title"]}',PAPER,INK)
    sign(children,'Back number',(x-16,8.3,z-16.3),(8,8,.3),f'{sid:02d}',PAPER,accent)
    # A small paved branch from the central path.
    direction=-1 if x<0 else 1
    part(world,'Station approach',(direction*16,.76,z+12),(18,.16,7),PAPER)
    for a in range(3):
        part(world,'Guide lights',(direction*(9+a*5),.88,z+12),(1.4,.12,1.4),accent,'Neon',collide=False)
    # Kiosk screen parent is intentionally directly under StationXX for prompt resolution.
    part(children,'Kiosk pedestal',(x,2.1,z+6),(8,2.5,2.4),accent)
    terminal=part(children,'Terminal',(x,4.5,z+5.8),(8,3,.8),INK)
    terminal['Children'].append(obj('StartMission','ProximityPrompt',{'ActionText':'미션 열기','ObjectText':stage['title'],'KeyboardKeyCode':'E','GamepadKeyCode':'ButtonX','HoldDuration':0,'MaxActivationDistance':12,'RequiresLineOfSight':False,'ClickablePrompt':True}))
    ui=obj('Screen','SurfaceGui',{'Face':'Back','SizingMode':'PixelsPerStud','PixelsPerStud':35,'LightInfluence':0})
    ui['Children'].append(obj('ScreenText','TextLabel',{'Size':{'UDim2':[[1,0],[1,0]]},'BackgroundTransparency':1,'Text':f'START  {sid:02d}  →\n미션을 열어주세요','TextColor3':rgb('FFFFFF'),'TextScaled':True,'TextWrapped':True,'Font':'GothamBold'}))
    terminal['Children'].append(ui)
    scene[-1]['label']=f'START {sid:02d}'
    part(children,'Terminal light',(x,6.2,z+5.8),(8,.16,.9),accent,'Neon',collide=False)
    plant(children,x-18,z+10);plant(children,x+18,z+10)
    if sid==1:
        sign(children,'Profile board',(x+4,7.8,z-10),(18,9,.6),'SIRIAI PROFILE\n\nThe most\nintuitive contents, Siriai.',INK,PAPER)
        part(children,'Profile portrait',(x-8,5.3,z-3),(4.5,5.2,.6),accent,rot=(0,0,-7),collide=False)
        part(children,'Profile portrait 2',(x+8,4.3,z-1),(4.5,5.2,.6),'C9B9D6',rot=(0,0,8),collide=False)
        bench(children,x,z-4)
    elif sid==2:
        part(children,'Laptop keyboard',(x+4,3.2,z-7),(15,.5,7),'C7C7C1')
        sign(children,'Laptop screen',(x+4,7,z-10),(15,8,.6),'IG LEAD SAVER\nURL · 내 이름 · 캠페인\n\n연결 테스트 → 설정 저장',PAPER,INK)
        part(children,'Laptop accent',(x+4,11.2,z-10),(15,.25,.8),accent,'Neon',collide=False)
        for k in range(7): part(children,'Key',(x-1+k*1.5,3.55,z-6),(.9,.1,1.1),INK,collide=False)
    elif sid==3:
        for dx,col,title in [(-10,'B9CBB7','뷰티 릴스'),(1,'D2BEDA','분위기 · 품질'),(12,'E4C49B','조건 확인')]:
            sign(children,'Creator card',(x+dx,6.5,z-8),(8,9,.6),title,INK,col)
            part(children,'Creator avatar',(x+dx,9,z-7.5),(2.4,2.4,1),PAPER,shape='Ball',collide=False)
        plant(children,x-13,z+1,False);plant(children,x+14,z+1,False)
    elif sid==4:
        part(children,'Envelope',(x+4,7,z-10),(17,10,.6),PAPER)
        for dx,angle in [(-3.8,-30),(3.8,30)]:
            part(children,'Envelope fold',(x+4+dx,8.4,z-9.5),(9,.35,.3),accent,rot=(0,0,angle),collide=False)
        sign(children,'Mail desk title',(x+4,4,z-9.4),(16,2,.3),'보내고 · 상태 표시',INK,PAPER)
        for dx in [-10,10]:
            part(children,'Mail crate',(x+dx,2.2,z-2),(4,2.6,4),accent)
            part(children,'Mail slip',(x+dx,3.7,z-2),(3.4,.2,2.5),PAPER,rot=(0,15,0),collide=False)
    elif sid==5:
        table(children,x+8,z-4)
        sign(children,'Chat bubble',(x+3,8,z-11),(20,6,.7),'고료 조정을 희망해요!\n\n희망 금액 확인 → 기록·공유',INK,PAPER)
        for dx in [-8,-3,2]: cylinder(children,'Reply dots',(x+dx,3,z-3),1.5,1.5,accent)
    elif sid==6:
        sign(children,'Reward equation',(x+4,8,z-12),(24,7,.7),'300 + 2,000\n유효 발송 + 최종 선정\n\n100건 + 5명 = 40,000원',PAPER,INK)
        for dx,h in [(-8,2),(0,3),(8,4.5)]:
            for level in range(int(h*2)):
                cylinder(children,'Reward token',(x+dx,1.5+level*.42,z-3),.32,4,GOLD)
    station_models.append(obj(f'Station{sid:02d}','Model',children=children))

# Shared streetscape: trees and low garden beds between the pavilions.
for z in [7,-46,-100]:
    for x in [-74,74]: plant(world,x,z,True)
for z in [32,-18,-73,-126]:
    for x in [-13,13]:
        cylinder(world,'Path lamp base',(x,1,z),1,1.5,INK)
        part(world,'Path lamp pole',(x,4,z),(.22,5.5,.22),INK,collide=False)
        part(world,'Path lamp head',(x,7,z),(1.5,.45,1.5),'FFF2CE','Neon',collide=False)
for x in [-73,73]:
    for z in [38,-20,-74,-130]:
        part(world,'Garden bed',(x,1,z),(10,.6,12),'CBC2B1')
        for k in range(5): plant(world,x+random.uniform(-3,3),z+random.uniform(-4,4))
# Graduation deck and original geometric trophy.
part(world,'Graduation deck',(0,.85,-145),(51,.35,23),SOFT)
for x in [-20,20]: part(world,'Finish arch pillar',(x,9,-152),(1.5,17,1.5),INK)
part(world,'Finish arch top',(0,17.5,-152),(41.5,1.4,1.5),INK)
sign(world,'Graduation lettering',(0,14,-151),(34,4,.5),'READY TO CONNECT.',PAPER,INK)
cylinder(world,'Trophy pedestal',(0,1.8,-153),2,10,PAPER,collide=True)
cylinder(world,'Trophy stem',(0,4.5,-153),4,.9,GOLD)
cylinder(world,'Trophy cup',(0,7.3,-153),3.2,5.2,GOLD)
part(world,'Trophy top',(0,9.5,-153),(3.4,3.4,3.4),PINK,rot=(0,45,25),collide=False)
for x in [-3.5,3.5]:
    part(world,'Trophy handle',(x,7,-153),(1.1,3.8,1.1),GOLD,rot=(0,0,-25 if x<0 else 25),collide=False)
for x in [-28,28]: plant(world,x,-144,True)
sign(world,'Finish reminder',(-49,6,-144),(29,9,.7),'WE HELP.\n\n어려운 문의는 단톡에서 함께\n실제 업무는 받은 안내서로',INK,PAPER)
sign(world,'Finish reward',(49,6,-144),(29,9,.7),'NICE WORK :)\n\n6개 미션의 스탬프를 모아\n첫 연결을 준비해요.',INK,PAPER)
# Illustrated workbench signs in the actual 3D world (native SurfaceGui shapes).
art_assets=json.loads((ROOT/'src/client/VisualAssets.json').read_text(encoding='utf-8-sig'))
for stage,station,key in zip(curriculum['stages'],station_models,['brand','brand','beauty','mail','chat','skincare']):
    x,_,z=stage['position'];children=station['Children']
    panel=part(children,'VisualTutorialBoard',(x+12,6.8,z+6),(6.8,9,.5),PAPER,collide=False)
    data=art_assets[key]
    picture=obj('OriginalIllustration','Frame',{'Position':{'UDim2':[[.05,0],[.04,0]]},'Size':{'UDim2':[[.9,0],[.65,0]]},'BackgroundColor3':rgb(data['bg']),'BorderSizePixel':0,'ClipsDescendants':True})
    for shape in data['shapes']:
        v=obj('Shape','Frame',{'Position':{'UDim2':[[shape['x'],0],[shape['y'],0]]},'Size':{'UDim2':[[shape['w'],0],[shape['h'],0]]},'BackgroundColor3':rgb(shape['color']),'BorderSizePixel':0,'Rotation':shape.get('rot',0)})
        if shape.get('r',0): v['Children'].append(obj('Round','UICorner',{'CornerRadius':{'UDim':[shape['r'],0]}}))
        picture['Children'].append(v)
    gui=obj('VisualGuide','SurfaceGui',{'Face':'Back','SizingMode':'PixelsPerStud','PixelsPerStud':35,'LightInfluence':0},[picture,obj('Instruction','TextLabel',{'Position':{'UDim2':[[.06,0],[.73,0]]},'Size':{'UDim2':[[.88,0],[.22,0]]},'BackgroundTransparency':1,'Text':'보고 · 직접 해보고\n결과 확인하기','TextColor3':rgb(INK),'TextScaled':True,'TextWrapped':True,'Font':'GothamBold'})])
    panel['Children'].append(gui);scene[-1]['art']=key;scene[-1]['label']='보고 · 직접 해보기'
model=obj('TrainingMap','Model',children=[obj('Architecture','Folder',children=world),obj('Stations','Folder',children=station_models)])
model.pop('Name',None)
(ROOT/'map/TrainingMap.model.json').write_text(json.dumps(model,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
(ROOT/'scene.json').write_text(json.dumps(scene,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
project={'name':'SIRIAI Training Campus','tree':{'$className':'DataModel',
 'Workspace':{'$properties':{'Gravity':196.2,'FallenPartsDestroyHeight':-35},'TrainingMap':{'$path':'map/TrainingMap.model.json'}},
 'Lighting':{'$properties':{'Ambient':rgb('B9B5AE'),'OutdoorAmbient':rgb('D4D7D9'),'Brightness':2.3,'ClockTime':14,'GlobalShadows':True,'ShadowSoftness':.25},'Atmosphere':{'$className':'Atmosphere','$properties':{'Density':.18,'Offset':.1,'Color':rgb('D7E2E5'),'Decay':rgb('A9C0D0'),'Haze':.7}},'Bloom':{'$className':'BloomEffect','$properties':{'Intensity':.15,'Size':24,'Threshold':1.25}}},
 'ReplicatedStorage':{'TrainingEvent':{'$className':'RemoteEvent'}},
 'ServerScriptService':{'$path':'src/server'},
 'StarterPlayer':{'$properties':{'CameraMaxZoomDistance':65,'CameraMinZoomDistance':5,'CharacterWalkSpeed':20,'CharacterJumpPower':50},'StarterPlayerScripts':{'$path':'src/client'}},
 'SoundService':{'$properties':{'RespectFilteringEnabled':True}}
}}
(ROOT/'default.project.json').write_text(json.dumps(project,ensure_ascii=False,indent=2),encoding='utf-8')
print(f'Original campus generated: {len(scene)} parts, 6 stations, 1 spawn')



missions=[{**{k:s[k] for k in ['id','title','subtitle','color','position']},'topics':[q['title'] for q in s['questions']]} for s in curriculum['stages']]
(ROOT/'missions.json').write_text(json.dumps(missions,ensure_ascii=False),encoding='utf-8')

(ROOT/'visual-assets.json').write_bytes((ROOT/'src/client/VisualAssets.json').read_bytes())
(ROOT/'tutorials.json').write_bytes((ROOT/'src/server/Curriculum.json').read_bytes())
