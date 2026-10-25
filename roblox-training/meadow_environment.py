"""Original sunset wetland: native Roblox parts shared with the browser preview."""
import math, random

PATH = [(0,68),(0,40),(3,20),(-2,-5),(1,-28),(-1,-50),(3,-76),(0,-100),(0,-140),(-5,-170),(4,-198),(-5,-226),(0,-267)]

def distance_to_path(x,z):
    result=10000
    for (ax,az),(bx,bz) in zip(PATH,PATH[1:]):
        dx,dz=bx-ax,bz-az
        t=max(0,min(1,((x-ax)*dx+(z-az)*dz)/(dx*dx+dz*dz)))
        result=min(result,math.hypot(x-ax-t*dx,z-az-t*dz))
    return result

def build_environment(world,stations,part,obj,rgb,cf,curriculum):
    rng=random.Random(1025)
    removed={'Soft blue surround','Island plinth','Campus ground','Central avenue','Avenue dash','Side border','End border','Tree trunk','Tree canopy','Plant leaf','Planter','Garden bed','Path lamp base','Path lamp pole','Path lamp head','Side window','Back number','Finish reminder','Finish reward','Lobby controls','Lobby welcome'}
    def convert(children):
        children[:]=[p for p in children if p['Name'] not in removed]
        for p in children:
            name=p['Name'];v=p['Properties']
            if p['ClassName'] in ('Part','SpawnLocation'):
                if name=='Back wall':
                    v.update(Size=[44,1.1,.6],CFrame=cf((v['CFrame'][0],1.65,v['CFrame'][2])),Color=rgb('B49A75'),Material='Wood')
                elif name in {'Pavilion floor','Arrival plaza','Graduation deck','Station approach'}:
                    v.update(Color=rgb('B69B73'),Material='WoodPlanks')
                elif name in {'Pavilion post','Pavilion beam','Front beam','Welcome portal pillar','Welcome portal top','Finish arch pillar','Finish arch top','Bench leg','Table stem','Stool leg'}:
                    v.update(Color=rgb('9D7D59'),Material='Wood')
                elif name=='Canopy rear': v.update(Color=rgb('E4D2AD'),Material='Fabric')
                elif name in {'Accent doorstep','Accent roof strip'}: v.update(Transparency=.65)
                elif name in {'Pavilion title','Welcome title','Graduation lettering'}:
                    v.update(Color=rgb('695540'),Material='Wood')
                elif name in {'Arrival wayfinding'}:
                    v.update(Size=[13,2.4,.4],CFrame=cf((10,2.7,28)),Color=rgb('E6D2AC'),Material='Wood')
                elif name=='Sculpture stroke': v.update(Color=rgb('DCAB77'),Material='Wood')
            convert(p['Children'])
    convert(world)
    for station in stations: convert(station['Children'])
    # Replace the saturated spawn tile with a flush, quiet arrival marker.
    for p in world:
        if p['ClassName']=='SpawnLocation':
            p['Properties'].update(Color=rgb('BEA681'),Material='WoodPlanks')
    part(world,'Meadow earth',(0,-2.2,800),(2400,4.8,2100),'AC9A71','Ground')
    part(world,'Lake water preview',(0,-2,-1250),(3000,3,2000),'A9958D','Glass',trans=.25,collide=False)
    # Many short planks follow a continuous path. Their tops overlap to keep walking safe.
    for (ax,az),(bx,bz) in zip(PATH,PATH[1:]):
        length=math.hypot(bx-ax,bz-az);n=math.ceil(length/1.35);angle=math.degrees(math.atan2(bx-ax,bz-az))
        for k in range(n):
            t=(k+.5)/n
            part(world,'Boardwalk plank',(ax+(bx-ax)*t,.84,az+(bz-az)*t),(11,.32,length/n+.1),rng.choice(['AD8F65','B39770','BEA27C','A98C65']),'WoodPlanks',rot=(0,angle,0))
    # Open pergolas, lit with small lanterns; no walls conceal the surrounding meadow.
    for stage,station in zip(curriculum['stages'],stations):
        x,_,z=stage['position'];children=station['Children']
        for dx in [-21,21]:
            part(children,'Rear timber post',(x+dx,7.7,z-16),(1,13.8,1),'9D7D59','Wood')
        for dz in [-9,-2,5,12]:
            part(children,'Pergola rafter',(x,14.6,z+dz),(44,.45,.8),'B29268','Wood')
        for dx in [-17,17]:
            part(children,'Lantern tether',(x+dx,13.4,z+13),(.08,1.6,.08),'8D7255',collide=False)
            lamp=part(children,'Pavilion lantern',(x+dx,12.2,z+13),(1.1,1.3,1.1),'FFE1A0','Neon',collide=False)
            lamp['Children'].append(obj('WarmGlow','PointLight',{'Color':rgb('FFD598'),'Brightness':.55,'Range':19,'Shadows':False}))
    # A walk beyond the teaching spaces reaches the lake and its sunset lookout.
    part(world,'Sunset lookout deck',(0,.82,-267),(38,.4,25),'B69B73','WoodPlanks')
    lookout=obj('LookoutSpawn','Part',{'Anchored':True,'CanCollide':False,'CanTouch':False,'CanQuery':False,'Transparency':1,'Size':[1,1,1],'CFrame':cf((0,4,-263))})
    world.append(lookout)
    for x in [-17,17]:
        for z in [-256,-267,-278]: part(world,'Lookout post',(x,2.1,z),(.35,3,.35),'A08361','Wood')
        part(world,'Lookout rail',(x,3.35,-267),(.25,.22,23),'C0A17A','Wood')
    for x in [-9,9]:
        seat=part(world,'Sunset seat',(x,1.9,-269),(6,.55,2.3),'A88861','Wood')
        seat['ClassName']='Seat';seat['Properties']['CanTouch']=True
        part(world,'Seat back',(x,3,-267.9),(6,1.9,.3),'B6966D','Wood')
        for dx in [-2.3,2.3]: part(world,'Seat feet',(x+dx,1.2,-269),(.4,1.3,1.9),'876D51','Wood')
    for x,z in [(-8,47),(8,22),(-8,-12),(8,-43),(-8,-70),(8,-102),(-8,-132),(8,-164),(-8,-199),(8,-234),(-15,-275),(15,-275)]:
        part(world,'Path lantern post',(x,1.55,z),(.22,1.2,.22),'8F7655','Wood')
        lamp=part(world,'Path lantern',(x,2.35,z),(.7,.85,.7),'FFDC98','Neon',collide=False)
        lamp['Children'].append(obj('Glow','PointLight',{'Color':rgb('FFD598'),'Brightness':.6,'Range':14,'Shadows':False}))
    # Distant silhouette layers deliberately avoid licensed models or texture assets.
    for layer,(base_z,colour,y,scale) in enumerate([(-560,'9A8791',8,1),(-730,'AC8D96',12,1.4),(-920,'BA939D',15,1.8)]):
        for k in range(12):
            x=(k-5.5)*110*scale+rng.uniform(-30,30)
            part(world,'Distant hill',(x,y-25,base_z+rng.uniform(-50,50)),(rng.uniform(130,220)*scale,rng.uniform(60,100)*scale,rng.uniform(100,180)) ,colour,'SmoothPlastic','Ball',collide=False)
    part(world,'Setting sun',(-200,48,-615),(49,49,49),'FFD6A0','Neon','Ball',collide=False)
    # Original reed clusters: thin stems, tapered-looking plume segments and angular leaves.
    reeds=obj('MeadowReeds','Folder');world.append(reeds)
    centers=[(s['position'][0],s['position'][2]) for s in curriculum['stages']]
    def allowed(x,z):
        if distance_to_path(x,z)<8.3:return False
        if abs(x)<29 and 24<z<64:return False
        if abs(x)<30 and -160<z<-131:return False
        if abs(x)<21 and -283<z<-252:return False
        if any(abs(x-cx)<24 and abs(z-cz)<21.5 for cx,cz in centers):return False
        if any(abs(z-(cz+12))<5 and abs(x)<20 for _,cz in centers):return False
        return True
    positions=[]
    for x in range(-205,206,7):
        for z in range(-252,101,7):
            px,pz=x+rng.uniform(-2.7,2.7),z+rng.uniform(-2.7,2.7)
            if not allowed(px,pz):continue
            # Keep far fields light while maintaining dense bands beside walkable routes.
            near=abs(px)<95 or (pz<-170 and abs(px)<145)
            if not near and rng.random()<.52:continue
            positions.append((px,pz,near))
    for i,(x,z,near) in enumerate(positions):
        cluster=obj(f'Reeds{i:04d}','Model');reeds['Children'].append(cluster)
        for stem in range(3 if near else 1):
            dx,dz=rng.uniform(-1.3,1.3),rng.uniform(-1.3,1.3)
            height=rng.uniform(4.8,8.2);tilt=rng.uniform(-9,9);azimuth=rng.uniform(0,360)
            part(cluster['Children'],'Reed stem',(x+dx,height*.46,z+dz),(.07,height-.3,.07),rng.choice(['9D905D','B09C62','AD9763']),'SmoothPlastic',rot=(0,azimuth,tilt),collide=False)
            part(cluster['Children'],'Reed plume',(x+dx+math.sin(math.radians(tilt))*height*.5,height-.12,z+dz),(.42,rng.uniform(2.1,2.9),.3),rng.choice(['DCC087','E9D1A1','D5AE66','C49D5F','F0DBB1']),'SmoothPlastic','Ball',rot=(0,azimuth,tilt),collide=False)
            if distance_to_path(x,z)<34 or (abs(x)<55 and z<-170):
                for side in [-1,1]:
                    part(cluster['Children'],'Reed plume branch',(x+dx+math.sin(math.radians(tilt))*height*.5+side*.21,height-.22,z+dz),(.15,1.8,.17),rng.choice(['E9D1A1','DCC087','F0DBB1']),'SmoothPlastic','Ball',rot=(0,azimuth,tilt+side*16),collide=False)
            part(cluster['Children'],'Reed leaf back',(x+dx-.45,height*.36,z+dz),(.11,height*.46,.045),'B2A16A','SmoothPlastic',rot=(-10,azimuth,38+tilt),collide=False)
            part(cluster['Children'],'Reed leaf',(x+dx+.42,height*.41,z+dz),(.12,height*.48,.04),'B8A467','SmoothPlastic',rot=(12,azimuth,-31+tilt),collide=False)
        for p in cluster['Children']:
            p['Properties'].update(CanQuery=False,CastShadow=False)
    return {'version':'3.0.0','title':'노을이 머무는 갈대밭','path':PATH,'reedClusters':len(positions),'sun':[-200,48,-615],
            'lake':{'position':[0,-2,-1250],'size':[3000,3,2000]},
            'views':{'sunset':{'position':[2,4.6,-177],'target':[-140,7,-550]},'lake':{'position':[0,5.5,-261],'target':[-160,10,-610]},'overview':{'position':[224,210,250],'target':[0,1,-85]}}}
