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
    """Curated coastal groves; one palette, crown overlap, open sight lines."""
    rng=random.Random(61025);folder=obj('ImportedNature','Folder');world.append(folder)
    cache={};instances=[];wedges=0
    def place(name,x,z,scale,angle,foliage='879669'):
        nonlocal wedges
        if 7<x<113 and -120<z<-30:return
        if name not in cache:cache[name]=read_obj(name)
        ground=height_at(x,z);rotation=math.radians(angle);co,si=math.cos(rotation),math.sin(rotation)
        model=obj('Kenney '+name,'Model');folder['Children'].append(model);children=model['Children']
        def transform(v):return (x+(v[0]*co+v[2]*si)*scale,ground+v[1]*scale-.07,z+(-v[0]*si+v[2]*co)*scale)
        for face,original in cache[name]:
            r,g,b=[int(original[i:i+2],16) for i in (0,2,4)]
            # Keep the original topology; map the kit's saturated colours into the
            # same restrained coastal palette. Bark and canopy remain distinct.
            if name.startswith('stone'):color='ADA48E'
            elif r>g*1.15:color='78614E'
            elif r>235 and g>235 and b>235:color='B3AE95'
            else:color=foliage
            wedges+=triangle(children,*[transform(v) for v in face],color,part,'Kenney '+name)
        children.append(obj('OriginalSource','StringValue',{'Value':'Kenney Nature Kit / CC0 / '+name+'.obj'}))
        instances.append({'model':name,'position':[x,ground,z],'scale':scale,'rotation':angle,'tint':foliage,'faces':len(cache[name])})
    # Three layered groves frame work areas. The centre stays open to the sea.
    groves=[(-126,60),(-151,-65),(143,-46),(-136,165),(130,183)]
    for gi,(cx,cz) in enumerate(groves):
        for j,(dx,dz,scale) in enumerate([(-8,-4,22),(2,1,27),(12,-8,20),(-2,12,24),(13,9,18)]):
            name='tree_oak'
            place(name,cx+dx,cz+dz,scale,rng.uniform(0,360),['8E9C78','7D906E','708463'][j%3])
        for dx,dz in [(-12,4),(5,-14),(18,2),(-4,9),(12,12)]:
            place('plant_bushLarge',cx+dx,cz+dz,rng.uniform(7,11),rng.uniform(0,360),'8E9C78')
    # Shore rocks are seated in groups rather than scattered as tiny grey dots.
    for cx,cz in [(-121,-279),(-78,-290),(-46,-271),(77,-287),(141,-269),(-193,-187),(188,-178)]:
        for dx,dz,scale in [(0,0,17),(-9,4,10),(12,2,12)]:
            place('stone_largeC' if dx else 'stone_largeD',cx+dx,cz+dz,scale,rng.uniform(0,360))
    # Low understorey borders terraces; it never intrudes into a work target.
    for x,z,scale in [(-70,23,10),(-70,37,9),(-66,67,9),(-10,67,8),(-88,-78,10),(-42,-83,9),(-15,-61,8),(76,-55,10),(76,-33,10),(28,-65,8)]:
        place('plant_bushLarge',x,z,scale,rng.uniform(0,360),'8E9C78')
    for x,z in [(-85,30),(-83,17),(-83,-3),(-70,-22),(-58,-23),(-9,51),(-9,67)]:
        for dx,dz,size in [(0,0,8),(3,2,5),(-2,3,6)]:place('plant_bushLarge',x+dx,z+dz,size,rng.uniform(0,360),'8E9C78')
    (ROOT/'nature-instances.json').write_bytes(json.dumps(instances,separators=(',',':')).encode())
    print(f'Nature: {len(instances)} curated CC0 instances / {wedges} wedges')
