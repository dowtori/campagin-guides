"""Native twilight landscape following the approved red-sun concept."""
import math,random
PATH=[(0,74),(0,42),(0,20),(0,-20),(0,-60),(0,-100),(0,-140),(0,-180),(0,-220),(-5,-255),(4,-285),(0,-330)]
def distance_to_path(x,z):
    result=10000
    for (ax,az),(bx,bz) in zip(PATH,PATH[1:]):
        dx,dz=bx-ax,bz-az;t=max(0,min(1,((x-ax)*dx+(z-az)*dz)/(dx*dx+dz*dz)))
        result=min(result,math.hypot(x-ax-t*dx,z-az-t*dz))
    return result

def build_environment(world,part,obj,rgb,cf,raster,curriculum):
    rng=random.Random(1025)
    part(world,'Meadow earth',(0,-2.2,785),(2400,4.8,2200),'AA9473','Ground')
    part(world,'Lake water preview',(0,-2,-1450),(3000,3,2300),'8F79A8','Glass',trans=.22,collide=False)
    for (ax,az),(bx,bz) in zip(PATH,PATH[1:]):
        length=math.hypot(bx-ax,bz-az);n=math.ceil(length/1.35);angle=math.degrees(math.atan2(bx-ax,bz-az))
        for k in range(n):
            t=(k+.5)/n;part(world,'Boardwalk plank',(ax+(bx-ax)*t,.84,az+(bz-az)*t),(11,.32,length/n+.1),rng.choice(['AD8F65','B39770','BEA27C','A98C65']),'WoodPlanks',rot=(0,angle,0))
    # The supplied/generated sky pixels are physically present in the exported place.
    backdrop=raster(world,'Pixel twilight horizon',(0,500,-1900),(2400,1350,.1),'sky',distance=8000,bg='393360')
    backdrop['Properties']['CastShadow']=False
    for pos,rot in [((1200,500,-700),(0,-90,0)),((-1200,500,-700),(0,90,0)),((0,500,500),(0,180,0))]:
        panel=raster(world,'Pixel twilight surround',pos,(2400,1350,.1),'skySides',rot=rot,distance=8000,bg='393360')
        panel['Properties']['CastShadow']=False
    part(world,'Sun position marker',(1000,20,-1890),(1,1,1),'CB2C4F',trans=1,collide=False)
    # Original broken rhombi: dark voxel sections, quiet cyan inner edges, separated fragments.
    for index,(cx,cy,cz,radius) in enumerate([(-75,104,-470,42),(35,78,-447,30)]):
        points=[(cx,cy+radius),(cx+radius,cy),(cx,cy-radius),(cx-radius,cy),(cx,cy+radius)]
        for side,((ax,ay),(bx,by)) in enumerate(zip(points,points[1:])):
            length=math.hypot(bx-ax,by-ay);angle=math.degrees(math.atan2(by-ay,bx-ax))
            for k in range(7):
                if (side==0 and k>4) or (side==2 and k<2):continue
                t=(k+.5)/7;x,y=ax+(bx-ax)*t,ay+(by-ay)*t
                part(world,'Floating rhombus segment',(x,y,cz),(length/7+.15,4.2,5.8),rng.choice(['302F45','3C3853','45405B']),rot=(0,0,angle),collide=False)
                if k in (2,3,4):part(world,'Cyan rhombus edge',(x,y-.9,cz+3.03),(length/7,.45,.3),'72DCD9','Neon',rot=(0,0,angle),collide=False)
        for k in range(12):
            part(world,'Floating pixel fragment',(cx+rng.uniform(10,45),cy+rng.uniform(-28,28),cz+rng.uniform(-4,8)),(1.7,1.7,1.7),'70D9D4' if k%3==0 else 'E7B369','Neon' if k%3==0 else 'SmoothPlastic',rot=(0,0,rng.uniform(-20,20)),collide=False)
    for node in world:
        if node['Name'].startswith(('Floating','Cyan')):node['Properties']['CastShadow']=False
    part(world,'Sunset lookout deck',(0,.82,-330),(38,.4,25),'B69B73','WoodPlanks')
    world.append(obj('LookoutSpawn','Part',{'Anchored':True,'CanCollide':False,'CanTouch':False,'CanQuery':False,'Transparency':1,'Size':[1,1,1],'CFrame':cf((0,4,-326))}))
    for x in [-17,17]:
        for z in [-319,-330,-341]:part(world,'Lookout post',(x,2.1,z),(.35,3,.35),'A08361','Wood')
        part(world,'Lookout rail',(x,3.35,-330),(.25,.22,23),'C0A17A','Wood')
    for x in [-9,9]:
        seat=part(world,'Sunset seat',(x,1.9,-332),(6,.55,2.3),'A88861','Wood');seat['ClassName']='Seat';seat['Properties']['CanTouch']=True
        part(world,'Seat back',(x,3,-330.9),(6,1.9,.3),'B6966D','Wood')
        for dx in [-2.3,2.3]:part(world,'Seat feet',(x+dx,1.2,-332),(.4,1.3,1.9),'876D51','Wood')
    for x,z in [(s,z) for z in [52,14,-23,-62,-101,-140,-179,-218,-259,-298,-337] for s in [-8,8]]:
        part(world,'Path lantern post',(x,1.55,z),(.22,1.2,.22),'8F7655','Wood')
        lamp=part(world,'Path lantern',(x,2.35,z),(.7,.85,.7),'FFDC98','Neon',collide=False)
        lamp['Children'].append(obj('Glow','PointLight',{'Color':rgb('FFD598'),'Brightness':.5,'Range':13,'Shadows':False}))
    reeds=obj('MeadowReeds','Folder');world.append(reeds)
    centers=[(s['position'][0],s['position'][2]) for s in curriculum['stages']]
    def allowed(x,z):
        if distance_to_path(x,z)<8.3:return False
        if abs(x)<29 and 42<z<78:return False
        if abs(x)<30 and -240<z<-211:return False
        if abs(x)<21 and -345<z<-317:return False
        if any(abs(x-cx)<25 and abs(z-cz)<23 for cx,cz in centers):return False
        if any(abs(z-(cz+29))<6 and abs(x)<64 for _,cz in centers):return False
        return True
    positions=[]
    for x in range(-205,206,7):
        for z in range(-312,101,7):
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
    return {'version':'4.0.0','title':'몽환적인 갈대밭과 붉은 태양','path':PATH,'reedClusters':len(positions),'sun':[1000,20,-1890],
            'lake':{'position':[0,-2,-1450],'size':[3000,3,2300]},'backdrop':'sky','skyAsset':'assets/world-sky.png',
            'views':{'sunset':{'position':[0,6,-180],'target':[0,23,-720]},'lake':{'position':[0,5.5,-320],'target':[130,23,-950]},'overview':{'position':[250,230,265],'target':[0,1,-105]}}}
