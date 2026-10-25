"""Native v6.10: connected coastal surfaces, CC0 meadow and engine-aligned sunset."""
from coastal_environment import add_coast,height_at,coast_distance,HIKE
from nature_models import add_nature,compact_mesh,plant_mesh
import math,random,json
from pathlib import Path
from sunset import SUN_POSITION
from layout import PATH
def distance_to_path(x,z):
    result=10000
    for (ax,az),(bx,bz) in zip(PATH,PATH[1:]):
        dx,dz=bx-ax,bz-az;t=max(0,min(1,((x-ax)*dx+(z-az)*dz)/(dx*dx+dz*dz)))
        result=min(result,math.hypot(x-ax-t*dx,z-az-t*dz))
    return result

def build_environment(world,part,obj,rgb,cf,raster,curriculum):
    rng=random.Random(1025)
    coast=add_coast(world,part,obj,cf)
    for (ax,az),(bx,bz) in zip(PATH,PATH[1:]):
        length=math.hypot(bx-ax,bz-az);n=math.ceil(length/1.35);angle=math.degrees(math.atan2(bx-ax,bz-az))
        for k in range(n):
            t=(k+.5)/n;part(world,'Boardwalk plank',(ax+(bx-ax)*t,.84,az+(bz-az)*t),(11,.32,length/n+.1),rng.choice(['AD8F65','B39770','BEA27C','A98C65']),'WoodPlanks',rot=(0,angle,0))
    # The sun is a real sphere; mountains are the walkable terrain, never image walls.
    sun=part(world,'Setting sun',SUN_POSITION,(78,78,78),'D8412E','Neon','Ball',collide=False)
    sun['Properties'].update(CastShadow=False,CanQuery=False)
    # Native volumetric Clouds supply the sky; no solid pancake cloud props.
    # A connected ridge trail stays away from the work areas.
    for (ax,az),(bx,bz) in zip(HIKE,HIKE[1:]):
        length=math.hypot(bx-ax,bz-az);n=math.ceil(length/2.4);yaw=math.degrees(math.atan2(bx-ax,bz-az))
        for k in range(n):
            t=(k+.5)/n;x,z=ax+(bx-ax)*t,az+(bz-az)*t
            part(world,'Ridge trail',(x,height_at(x,z)+.22,z),(6,.4,length/n+.3),'C8BA9C','Sandstone',rot=(0,yaw,0))
    from ridge_lookout import add_lookout
    add_lookout(world,part,obj,rgb,height_at)
    part(world,'Sunset lookout deck',(-13,.82,-330),(64,.4,25),'B69B73','WoodPlanks')
    world.append(obj('LookoutSpawn','Part',{'Anchored':True,'CanCollide':False,'CanTouch':False,'CanQuery':False,'Transparency':1,'Size':[1,1,1],'CFrame':cf((0,4,-326))}))
    for x in [-43,17]:
        for z in [-319,-330,-341]:part(world,'Lookout post',(x,2.1,z),(.35,3,.35),'A08361','Wood')
        part(world,'Lookout rail',(x,3.35,-330),(.25,.22,23),'C0A17A','Wood')
    for x in [-9,9]:
        seat=part(world,'Sunset seat',(x,1.9,-332),(6,.55,2.3),'A88861','Wood');seat['ClassName']='Seat';seat['Properties']['CanTouch']=True
        part(world,'Seat back',(x,3,-330.9),(6,1.9,.3),'B6966D','Wood')
        for dx in [-2.3,2.3]:part(world,'Seat feet',(x+dx,1.2,-332),(.4,1.3,1.9),'876D51','Wood')
    for x,z in [(cx+s,z) for cx,z in [(-34,43),(-34,-15),(-34,-60),(0,-101),(0,-140),(0,-179),(0,-218),(0,-259),(0,-298),(0,-337)] for s in [-8,8]]:
        part(world,'Path lantern post',(x,1.55,z),(.22,1.2,.22),'8F7655','Wood')
        lamp=part(world,'Path lantern',(x,2.35,z),(.7,.85,.7),'FFDC98','Neon')
        lamp['Children'].append(obj('Glow','PointLight',{'Color':rgb('FFD598'),'Brightness':.5,'Range':13,'Shadows':False}))
    reeds=obj('MeadowReeds','Folder');world.append(reeds)
    centers=[(s['position'][0],s['position'][2]) for s in curriculum['stages']]
    # Compact stands at field margins: broad basal leaves, joined stems and soft
    # seed heads. No random crossing needles in the whole playable landscape.
    patches=[(-31,-254,20,18),(30,-249,18,21),(-40,-140,26,44),(-64,-213,35,48),(47,-173,29,54),(82,-231,36,42),
             (-117,-113,25,30),(102,-112,29,32),(-49,108,35,21),(59,77,28,30)]
    def allowed(x,z):
        if 7<x<113 and -120<z<-35:return False
        if distance_to_path(x,z)<11 or height_at(x,z)<-.2 or height_at(x,z)>5:return False
        if any(abs(x-cx)<35 and abs(z-cz)<29 for cx,cz in centers):return False
        if abs(x)<35 and z>0:return False
        if -54<x<8 and -34<z<-20:return False
        if 0<x<55 and -24<z<-9:return False
        return True
    # Overlapping original CC0 leaves, not procedural needles. One jittered field
    # prevents the same point being planted twice where meadow patches overlap.
    positions=[]
    for x in range(-146,123,5):
        for z in range(-278,133,5):
            px,pz=x+rng.uniform(-1.4,1.4),z+rng.uniform(-1.4,1.4)
            radius=min(((px-cx)/rx)**2+((pz-cz)/rz)**2 for cx,cz,rx,rz in patches)
            if radius>1 or (radius>.82 and rng.random()>.72) or not allowed(px,pz):continue
            positions.append((px,pz))
    rects,faces=compact_mesh('grass',ribbon_width=.45)
    instances=[]
    for i,(x,z) in enumerate(positions):
        cluster=obj(f'Meadow{i:04d}','Model');reeds['Children'].append(cluster);c=cluster['Children'];base=height_at(x,z)-.03
        angle=rng.uniform(0,math.tau);co,si=math.cos(angle),math.sin(angle)
        width=rng.uniform(14.5,17.5)
        near=distance_to_path(x,z)<17
        height=rng.uniform(5,7) if near else rng.uniform(9,13)
        tint=rng.choice(['BAAD70','C6B477','D1BA7C','B5AB70'])
        def transform(v):return (x+(v[0]*co+v[2]*si)*width,base+v[1]*height,z+(-v[0]*si+v[2]*co)*width)
        plant_mesh(c,rects,faces,transform,tint,part)
        # WindShake animates one invisible root per complete clump. All native
        # faces follow that transform together, so a leaf never splits apart.
        anchor=part(c,'Grass wind root',(x,base,z),(.1,.1,.1),'FFFFFF',trans=1,collide=False)
        for p in c:p['Properties'].update(CanQuery=False,CanTouch=False,CastShadow=False)
        instances.append({'position':[x,base,z],'widthScale':width,'heightScale':height,'angle':angle,'color':tint,'rectangles':len(rects),'triangles':len(faces),'asset':'grass','ribbonWidth':.45})
    (Path(__file__).parent/'meadow-instances.json').write_text(json.dumps(instances,separators=(',',':')),encoding='utf-8')
    # An easy route into and out of the shallows, with posts continuing below water.
    for k in range(12):
        part(world,'Water access step',(0,.64-k*.42,-343-k*1.4),(10,.45,1.65),'C6B59B','WoodPlanks')
    for x in [-40,-15,15]:part(world,'Lookout foundation',(x,-3,-333),(1,8,1),'887B65','Wood')
    add_nature(world,part,obj,cf,height_at,distance_to_path,curriculum)
    return {'version':'6.10','title':'갈대 바다와 입체 능선','path':PATH,'reedClusters':len(positions),'sun':SUN_POSITION,
            'lake':coast['ocean'],'seaLevel':coast['seaLevel'],'coastFile':'coast.json',
            'backdrop':'atmosphere','sceneryGeometry':'navigable-terrain','clouds':'native-volumetric',
            'views':{'sunset':{'position':[0,6,-180],'target':[35,27,-850]},'lake':{'position':[70,24,-270],'target':[0,-1,-345]},
                     'ridge':{'position':[352,154,205],'target':[0,12,-210]},'overview':{'position':[250,230,265],'target':[0,1,-105]}}}
