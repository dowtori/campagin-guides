"""An original, blunt thumbs-up: one solid silhouette, no fingers or mascot face.

Each growth stage is a closed extruded polygon made of native WedgeParts.
The fist stays broad while the lateral thumb becomes disproportionately tall.
No third-party mesh, decal or asset upload is required.
"""
import json,math
from pathlib import Path
from nature_models import triangle

def cross2(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
def triangulate(points):
    # Ear clipping preserves the concave notch between thumb and fist.
    remaining=list(points);out=[]
    while len(remaining)>3:
        for i,b in enumerate(remaining):
            a=remaining[i-1];c=remaining[(i+1)%len(remaining)]
            if cross2(a,b,c)<=1e-8:continue
            def inside(p):return min(cross2(a,b,p),cross2(b,c,p),cross2(c,a,p))>=-1e-8
            if any(inside(p) for p in remaining if p not in (a,b,c)):continue
            out.append((a,b,c));remaining.pop(i);break
        else:raise ValueError('Invalid hand silhouette')
    out.append(tuple(remaining));return out

def outline(height):
    # Wrist at the bottom; one flat fist on the right; raised thumb on the left.
    # Angular corner cuts replace anatomical/sausage-like finger segments.
    points=[(-.65,.54),(1.65,.54),(1.65,1.52),(2.65,1.92),
            (3.05,2.38),(3.05,4.16),(2.65,4.62),(-.82,4.62),
            (-1.03,height-.28),(-1.40,height),(-2.18,height),
            (-2.55,height-.40),(-2.55,3.68),(-1.88,2.50),
            (-1.10,2.05),(-.65,1.48)]
    # An outward lean distinguishes the thumb from an upright L-shaped block.
    return [(x-.38*max(0,y-4.62),y) for x,y in points]

def add_thumbs_up(world,part,obj,cf):
    model=obj('PierThumbsUp','Model');world.append(model);parts=model['Children']
    origin=(-29,1.03,-328);base_scale=.9;yaw=18
    a=math.radians(yaw);co,si=math.cos(a),math.sin(a)
    def point(p):
        x,y=p
        return (origin[0]+base_scale*x*co,origin[1]+base_scale*y,origin[2]-base_scale*x*si)
    pedestal=part(parts,'ThumbsUp pedestal',(origin[0],origin[1]+.27*base_scale,origin[2]),(.54*base_scale,5.7*base_scale,5.7*base_scale),'444547','SmoothPlastic','Cylinder',rot=(0,0,90))
    pedestal['Children'].append(obj('ThumbStage','IntValue',{'Value':0}))
    stages=json.loads((Path(__file__).parent/'src/shared/ThumbData.json').read_text(encoding='utf-8'))['stages']
    for stage,item in enumerate(stages):
        level=stage+1
        def prism(parent,name,center,size,color,material,shape,rot,collide):
            p=part(parent,name,center,(2.18*base_scale,size[1],size[2]),color,material,shape,rot=rot,collide=stage==0)
            p['Properties'].update(Transparency=0 if stage==0 else 1,CanTouch=False,CanQuery=stage==0,CastShadow=True)
            p['Children'].append(obj('ThumbStage','IntValue',{'Value':level}))
            return p
        for i,tri in enumerate(triangulate(outline(item['thumbHeight']))):
            triangle(parts,*(point(v) for v in tri),'E5E4DE',prism,f'ThumbsUp silhouette {stage:02d} prism {i:02d}')
    for p in parts:
        props=p['Properties'];level=p['Children'][-1]['Properties']['Value']
        props.update(CastShadow=True,CanCollide=level in (0,1),CanQuery=level in (0,1))
    config_path=Path(__file__).parent/'src/shared/ThumbData.json'
    config=json.loads(config_path.read_text(encoding='utf-8'))
    for item in config['stages']:
        target=item.get('origin',origin);points=[]
        for p in parts:
            f=p['Properties'];level=p['Children'][-1]['Properties']['Value']
            if level not in item['groups']:continue
            k=1 if level==0 else item['scale'];center=[target[j]+(.486 if j==1 else 0)+(f['CFrame'][j]-origin[j]-(.486 if j==1 else 0))*k for j in range(3)];size=[v*k for v in f['Size']]
            if level==0 and 'pedestal' in item:center=item['pedestal']['position'];size=item['pedestal']['size']
            elif level==0:center=f['CFrame'][:3]
            m=f['CFrame'][3:];ext=[sum(abs(m[j*3+i])*size[i]/2 for i in range(3)) for j in range(3)]
            points.extend([[center[j]+sign*ext[j] for j in range(3)] for sign in [-1,1]])
        item['bounds']={'min':[min(p[j] for p in points) for j in range(3)],'max':[max(p[j] for p in points) for j in range(3)]}
    config_path.write_text(json.dumps(config,ensure_ascii=False,indent=2),encoding='utf-8')
    return model
