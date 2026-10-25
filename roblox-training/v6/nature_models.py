"""Import the actual CC0 Kenney OBJ vertices as native wedge geometry.
No re-creation from a screenshot: the original face topology is preserved.
"""
from pathlib import Path
import math,random,json
ROOT=Path(__file__).resolve().parent

def sub(a,b):return tuple(x-y for x,y in zip(a,b))
def add(a,b):return tuple(x+y for x,y in zip(a,b))
def mul(a,s):return tuple(x*s for x in a)
def dot(a,b):return sum(x*y for x,y in zip(a,b))
def length(a):return math.sqrt(dot(a,a))
def unit(a):return mul(a,1/length(a))
def cross(a,b):return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def euler(m):
    y=math.asin(max(-1,min(1,m[2])));c=math.cos(y)
    if abs(c)>1e-6:x=math.atan2(-m[5],m[8]);z=math.atan2(-m[1],m[0])
    else:x=math.atan2(m[7],m[4]);z=0
    return tuple(map(math.degrees,(x,y,z)))

def read_obj(name):
    directory=ROOT/'assets/nature/kenney';materials={};current=None
    for line in (directory/(name+'.mtl')).read_text().splitlines():
        words=line.split()
        if not words:continue
        if words[0]=='newmtl':current=words[1]
        if words[0]=='Kd':materials[current]=''.join(f'{round(float(v)*255):02X}' for v in words[1:4])
    vertices=[];faces=[]
    for line in (directory/(name+'.obj')).read_text().splitlines():
        words=line.split()
        if not words:continue
        if words[0]=='v':vertices.append(tuple(map(float,words[1:4])))
        elif words[0]=='usemtl':current=words[1]
        elif words[0]=='f':
            ids=[int(x.split('/')[0])-1 for x in words[1:]]
            for i in range(1,len(ids)-1):faces.append(([vertices[ids[k]] for k in (0,i,i+1)],materials.get(current,'92918C')))
    return faces

def triangle(parent,a,b,c,color,part,name):
    # Longest side as B-C guarantees an interior perpendicular foot.
    if dot(sub(b,a),sub(b,a))>dot(sub(c,b),sub(c,b)):a,c=c,a
    if dot(sub(c,a),sub(c,a))>dot(sub(c,b),sub(c,b)):a,b=b,a
    axis=unit(sub(c,b));d=add(b,mul(axis,dot(sub(a,b),axis)));height=length(sub(a,d))
    if height<.002:return 0
    up=unit(sub(a,d));count=0
    for end in (b,c):
        span=length(sub(d,end))
        if span<.002:continue
        back=unit(sub(d,end));right=unit(cross(up,back))
        m=[right[0],up[0],back[0],right[1],up[1],back[1],right[2],up[2],back[2]]
        center=mul(add(a,end),.5)
        p=part(parent,name,center,(.018,height,span),color,'SmoothPlastic','Wedge',rot=euler(m),collide=False)
        p['ClassName']='WedgePart';p['Properties'].pop('Shape',None);p['Properties']['CFrame']=list(center)+m
        p['Properties']['CanQuery']=False;p['Properties']['CastShadow']=name.startswith(('Kenney rock','Kenney stone','Kenney tree'))
        count+=1
    return count

def add_nature(world,part,obj,cf,height_at,distance_to_path,curriculum):
    rng=random.Random(49125);folder=obj('ImportedNature','Folder');world.append(folder)
    cache={};instances=[];wedges=0
    def place(name,x,z,scale,angle,tint=None):
        nonlocal wedges
        if name not in cache:cache[name]=read_obj(name)
        ground=height_at(x,z);rotation=math.radians(angle);co,si=math.cos(rotation),math.sin(rotation)
        children=[];model=obj('Kenney '+name,'Model',children=children);folder['Children'].append(model)
        def transform(v):return (x+(v[0]*co+v[2]*si)*scale,ground+v[1]*scale-.07,z+(-v[0]*si+v[2]*co)*scale)
        # obj() uses a new list for empty children, so keep its actual list.
        children=model['Children']
        for face,color in cache[name]:
            points=[transform(v) for v in face]
            wedges+=triangle(children,*points,tint or color,part,'Kenney '+name)
        children.append(obj('OriginalSource','StringValue',{'Value':'Kenney Nature Kit 2.1 / CC0 / '+name+'.obj'}))
        instances.append({'model':name,'position':[x,ground,z],'scale':scale,'rotation':angle,'tint':tint,'faces':len(cache[name])})
    for x,z,scale in [(-131,-276,16),(-107,-295,11),(-83,-286,9),(73,-286,18),(115,-282,12),(150,-260,16),(-177,-173,12),(176,-120,13),(-135,100,15),(155,86,11)]:
        place(rng.choice(['stone_largeA','stone_largeB']),x,z,scale,rng.uniform(0,360))
    for _ in range(15):
        x=rng.choice([-1,1])*rng.uniform(37,183);z=rng.uniform(-286,115)
        if distance_to_path(x,z)<13:continue
        if any(abs(x-s['position'][0])<28 and abs(z-s['position'][2])<28 for s in curriculum['stages']):continue
        place('stone_smallA',x,z,rng.uniform(4,10),rng.uniform(0,360))
    for _ in range(55):
        x=rng.uniform(-190,190);z=rng.uniform(-299,124)
        if distance_to_path(x,z)<9 or height_at(x,z)<-2.5:continue
        if any(abs(x-s['position'][0])<26 and abs(z-s['position'][2])<25 for s in curriculum['stages']):continue
        if abs(x)<29 and z>40:continue
        place('grass_leafs',x,z,rng.uniform(6,10),rng.uniform(0,360),rng.choice(['9B9B69','ADAB78','B6AE79']))
    for x,z,scale in [(-118,58,11),(-128,23,13),(-145,-22,12),(-152,-78,14),(-156,-131,12),(-153,-196,13),
                      (124,52,12),(140,15,14),(152,-43,11),(156,-109,13),(154,-177,12),(136,-233,12),
                      (-224,-170,15),(-244,-82,16),(-230,20,15),(-209,108,15),(221,154,16),(233,224,14),
                      (-97,189,14),(-41,219,12),(40,223,13),(99,179,13)]:
        place('tree_pineTallA' if x<0 else 'tree_pineDefaultB',x,z,scale,rng.uniform(0,360))
    for x,z in [(-78,69),(-81,-18),(80,-2),(73,-84),(-90,-103)]:place('tree_oak_fall',x,z,10,rng.uniform(0,360))
    for x,z in [(-66,57),(-10,55),(-78,-37),(-22,-26),(24,-38),(68,-59)]:place('plant_bushSmall',x,z,7,rng.uniform(0,360))
    (ROOT/'nature-instances.json').write_bytes(json.dumps(instances,separators=(',',':')).encode())
    print(f'Kenney CC0: {len(instances)} original OBJ instances / {wedges} native wedge faces')
