"""Native v6.3: navigable coastal ridges, a 3D red sun and drifting cloud models."""
from coastal_environment import add_coast,height_at,coast_distance,HIKE
from nature_models import add_nature
import math,random
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
    sun=part(world,'Setting sun',(112,103,-1250),(78,78,78),'C7233B','Neon','Ball',collide=False)
    sun['Properties']['CastShadow']=False
    # Mid-distance cloud sculptures add actual parallax; native Clouds provide the high sky.
    clouds=obj('DriftingClouds','Folder');world.append(clouds)
    cloud_specs=[(-430,230,-740,130,22,48),(-170,266,-940,102,15,34),(342,237,-840,154,20,52),
                 (682,292,-320,168,23,60),(-645,270,-85,136,19,53),(140,298,515,153,20,50)]
    for index,(cx,cy,cz,w,h,d) in enumerate(cloud_specs):
        cluster=obj(f'Cloud{index:02d}','Model');clouds['Children'].append(cluster)
        for k in range(7):
            t=k/6-.5
            p=part(cluster['Children'],'Sky cloud puff',(cx+t*w,cy+(1-abs(t)*1.6)*h*.38,cz+rng.uniform(-d*.18,d*.18)),
                     (w*.38,h*rng.uniform(.75,1.3),d*rng.uniform(.75,1.15)),rng.choice(['E7D9CC','E4D2C3','EEDFD0']),'SmoothPlastic','Ball',trans=.18,collide=False)
            p['Properties']['CanQuery']=False;p['Properties']['CastShadow']=False
    # A connected ridge trail stays away from the work areas.
    for (ax,az),(bx,bz) in zip(HIKE,HIKE[1:]):
        length=math.hypot(bx-ax,bz-az);n=math.ceil(length/2.4);yaw=math.degrees(math.atan2(bx-ax,bz-az))
        for k in range(n):
            t=(k+.5)/n;x,z=ax+(bx-ax)*t,az+(bz-az)*t
            part(world,'Ridge trail',(x,height_at(x,z)+.22,z),(6,.4,length/n+.3),'C8BA9C','Sandstone',rot=(0,yaw,0))
    summit_y=height_at(300,110)
    part(world,'Ridge lookout',(300,summit_y+.2,110),(16,.4,13),'C8BA9C','Sandstone')
    part(world,'Sunset lookout deck',(0,.82,-330),(38,.4,25),'B69B73','WoodPlanks')
    world.append(obj('LookoutSpawn','Part',{'Anchored':True,'CanCollide':False,'CanTouch':False,'CanQuery':False,'Transparency':1,'Size':[1,1,1],'CFrame':cf((0,4,-326))}))
    for x in [-17,17]:
        for z in [-319,-330,-341]:part(world,'Lookout post',(x,2.1,z),(.35,3,.35),'A08361','Wood')
        part(world,'Lookout rail',(x,3.35,-330),(.25,.22,23),'C0A17A','Wood')
    for x in [-9,9]:
        seat=part(world,'Sunset seat',(x,1.9,-332),(6,.55,2.3),'A88861','Wood');seat['ClassName']='Seat';seat['Properties']['CanTouch']=True
        part(world,'Seat back',(x,3,-330.9),(6,1.9,.3),'B6966D','Wood')
        for dx in [-2.3,2.3]:part(world,'Seat feet',(x+dx,1.2,-332),(.4,1.3,1.9),'876D51','Wood')
    for x,z in [(cx+s,z) for cx,z in [(-34,43),(-34,-15),(-34,-60),(0,-101),(0,-140),(0,-179),(0,-218),(0,-259),(0,-298),(0,-337)] for s in [-8,8]]:
        part(world,'Path lantern post',(x,1.55,z),(.22,1.2,.22),'8F7655','Wood')
        lamp=part(world,'Path lantern',(x,2.35,z),(.7,.85,.7),'FFDC98','Neon',collide=False)
        lamp['Children'].append(obj('Glow','PointLight',{'Color':rgb('FFD598'),'Brightness':.5,'Range':13,'Shadows':False}))
    reeds=obj('MeadowReeds','Folder');world.append(reeds)
    centers=[(s['position'][0],s['position'][2]) for s in curriculum['stages']]
    # Compact stands at field margins: broad basal leaves, joined stems and soft
    # seed heads. No random crossing needles in the whole playable landscape.
    patches=[(-40,-140,26,44),(-64,-213,35,48),(47,-173,29,54),(82,-231,36,42),
             (-117,-113,25,30),(102,-112,29,32),(-49,108,35,21),(59,77,28,30)]
    def allowed(x,z):
        if distance_to_path(x,z)<11 or height_at(x,z)<-.2 or height_at(x,z)>5:return False
        if any(abs(x-cx)<35 and abs(z-cz)<29 for cx,cz in centers):return False
        if abs(x)<35 and z>0:return False
        if -54<x<8 and -34<z<-20:return False
        if 0<x<55 and -24<z<-9:return False
        return True
    positions=[]
    for cx,cz,rx,rz in patches:
        for x in range(int(cx-rx),int(cx+rx),5):
            for z in range(int(cz-rz),int(cz+rz),5):
                px,pz=x+rng.uniform(-2,2),z+rng.uniform(-2,2)
                radius=((px-cx)/rx)**2+((pz-cz)/rz)**2
                if radius>1 or rng.random()>.8-radius*.25 or not allowed(px,pz):continue
                positions.append((px,pz))
    for i,(x,z) in enumerate(positions):
        cluster=obj(f'Reeds{i:04d}','Model');reeds['Children'].append(cluster);c=cluster['Children'];base=height_at(x,z)
        for k in range(5):
            angle=k*math.tau/5+rng.uniform(-.3,.3);h=rng.uniform(1.3,2.1)
            # A fan whose leaves share the root; wider silhouettes read as grass.
            part(c,'Meadow blade',(x+math.cos(angle)*.38,base+h*.43,z+math.sin(angle)*.38),(.24,h,.1),rng.choice(['ABB27B','B6BA81','9CA66B']),'SmoothPlastic','Ball',rot=(0,math.degrees(-angle),-24),collide=False)
        for k in range(2):
            dx,dz=rng.uniform(-.5,.5),rng.uniform(-.5,.5);h=rng.uniform(2.5,3.6)
            # Vertical stems meet their plumes exactly. Gold comes from seed heads.
            part(c,'Meadow stem',(x+dx,base+h*.5,z+dz),(.075,h,.075),'A9A16C','SmoothPlastic',collide=False)
            part(c,'Meadow seedhead',(x+dx,base+h,z+dz),(.36,.95,.28),rng.choice(['D8C08D','E2CCA0','CEB47F']),'SmoothPlastic','Ball',rot=(0,rng.uniform(0,180),0),collide=False)
        for p in c:p['Properties'].update(CanQuery=False,CastShadow=False)
    # An easy route into and out of the shallows, with posts continuing below water.
    for k in range(12):
        part(world,'Water access step',(0,.64-k*.42,-343-k*1.4),(10,.45,1.65),'C6B59B','WoodPlanks')
    for x in [-15,15]:part(world,'Lookout foundation',(x,-3,-333),(1,8,1),'887B65','Wood')
    add_nature(world,part,obj,cf,height_at,distance_to_path,curriculum)
    return {'version':'6.3.0','title':'갈대 바다와 입체 능선','path':PATH,'reedClusters':len(positions),'sun':[112,103,-1250],
            'lake':coast['ocean'],'seaLevel':coast['seaLevel'],'coastFile':'coast.json',
            'backdrop':'atmosphere','sceneryGeometry':'navigable-terrain','clouds':'native-and-3d',
            'views':{'sunset':{'position':[0,6,-180],'target':[35,27,-850]},'lake':{'position':[70,24,-270],'target':[0,-1,-345]},
                     'ridge':{'position':[352,154,205],'target':[0,12,-210]},'overview':{'position':[250,230,265],'target':[0,1,-105]}}}
