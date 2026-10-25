"""Original, rounded thumbs-up sculpture built from native Roblox solids."""
import math

def add_thumbs_up(world,part,obj,cf):
    model=obj('PierThumbsUp','Model');world.append(model);parts=model['Children']
    origin=(-29,1.03,-328);scale=.9;yaw=18
    angle=math.radians(yaw);co,si=math.cos(angle),math.sin(angle)
    def solid(name,pos,size,color='F0D5A8',shape='Block',rot=(0,0,0),level=0):
        x,y,z=pos
        p=part(parts,'ThumbsUp '+name,(origin[0]+scale*(x*co+z*si),origin[1]+scale*y,origin[2]+scale*(-x*si+z*co)),tuple(scale*v for v in size),color,'SmoothPlastic',shape,rot=(0,0,0))
        # Compose the global yaw with each primitive's local rotation.
        local=cf((0,0,0),rot)[3:];turn=cf((0,0,0),(0,yaw,0))[3:]
        matrix=[sum(turn[row*3+k]*local[k*3+col] for k in range(3)) for row in range(3) for col in range(3)]
        p['Properties']['CFrame'][3:]=matrix
        # The preview consumes the same composed native transform via matrix.
        p['Properties'].update(Reflectance=.02,CanCollide=False,CanTouch=False,CanQuery=False,Transparency=1 if level else 0)
        p['Children'].append(obj('ThumbStage','IntValue',{'Value':level}))
        return p,matrix
    def capsule(name,a,b,r,color='F0D5A8'):
        dx,dy,dz=(b[i]-a[i] for i in range(3));length=math.sqrt(dx*dx+dy*dy+dz*dz)
        assert abs(dz)<1e-8
        mid=tuple((a[i]+b[i])/2 for i in range(3));tilt=math.degrees(math.atan2(dy,dx))
        solid(name+' core',mid,(length,2*r,2*r),color,'Cylinder',(0,0,tilt))
        for i,v in enumerate([a,b]):solid(name+' round '+str(i),v,(2*r,2*r,2*r),color,'Ball')
    def rounded_box(name,pos,size,radius,color):
        x,y,z=pos;w,h,d=size;r=radius
        for i,sz in enumerate([(w,h-2*r,d-2*r),(w-2*r,h,d-2*r),(w-2*r,h-2*r,d)]):solid(name+' core '+str(i),pos,sz,color)
        for a in [-1,1]:
            for b in [-1,1]:
                solid(name+' edge X',(x,y+a*(h/2-r),z+b*(d/2-r)),(w-2*r,2*r,2*r),color,'Cylinder')
                solid(name+' edge Y',(x+a*(w/2-r),y,z+b*(d/2-r)),(h-2*r,2*r,2*r),color,'Cylinder',(0,0,90))
                solid(name+' edge Z',(x+a*(w/2-r),y+b*(h/2-r),z),(d-2*r,2*r,2*r),color,'Cylinder',(0,90,0))
                for c in [-1,1]:solid(name+' corner',(x+a*(w/2-r),y+b*(h/2-r),z+c*(d/2-r)),(2*r,2*r,2*r),color,'Ball')
    solid('pedestal',(0,.28,0),(.56,5.5,5.5),'77746D','Cylinder',(0,0,90))
    rounded_box('wrist',(.35,1.21,0),(2.3,1.5,2.3),.3,'DEC38C')
    rounded_box('palm',(.25,3.30,0),(3.5,3.65,2.15),.48,'E6CD98')
    for i,(y,w) in enumerate([(2.08,2.2),(2.88,2.65),(3.68,2.9),(4.48,2.8)]):
        capsule('curled finger '+str(i+1),(.52-w/2,y,.83),(.52+w/2,y,.83),.43,'EAD4A3')
    capsule('thumb base',(-1.03,3.5,.03),(-2.04,4.65,.03),.65)
    capsule('raised thumb',(-2.04,4.65,.03),(-2.12,7.05,.03),.64)
    solid('thumbnail',(-2.12,6.85,.605),(.61,.84,.17),'F5E4BC','Ball',(0,0,3))
    # Each stage declares its visible groups in ThumbData: accessories replace,
    # rather than obscure, the hand. The raised thumb always clears the crown.
    for level in [1,2,3]:
        if level==2:
            for x in [-.42,.98]:solid('cool sunglasses',(x,4.38,1.40),(1.05,.52,.18),'292B32',level=level)
            solid('glasses bridge',(.28,4.38,1.41),(.48,.10,.18),'292B32',level=level)
        else:
            for x in [-.34,.9]:solid('friendly eye',(x,4.37,1.28),(.20,.28,.12),'292B32','Ball',level=level)
        if level==3:
            solid('open smile',(.28,3.57,1.30),(.82,.48,.13),'292B32','Ball',level=level)
            solid('smile upper edge',(.28,3.76,1.32),(.78,.16,.14),'FFF4D7','Ball',level=level)
        else:
            for i in range(5):
                a=math.radians(210+i*30)
                solid('small smile',(.28+.37*math.cos(a),3.72+.26*math.sin(a),1.30),(.14,.12,.10),'292B32','Ball',level=level)
    for level,color in [(4,'39434C'),(9,'F9F0DC')]:
        for x,angle in [(-.32,-14),(.88,14)]:solid('bow tie',(x,1.78,1.25),(1.10,.62,.27),color,'Ball',(0,0,angle),level=level)
        solid('bow knot',(.28,1.78,1.40),(.32,.35,.28),color,'Ball',level=level)
    for x,angle in [(-.65,-10),(1.15,10)]:solid('cape',(x,2.80,-1.40),(2.0,3.7,.20),'AD354A','Block',(0,angle,angle),level=5)
    for x,y in [(-3.25,4.1),(2.95,5.0)]:
        solid('sparkle vertical',(x,y,0),(.13,.8,.13),'FFE2A3','Block',(0,0,20),level=6)
        solid('sparkle horizontal',(x,y,0),(.8,.13,.13),'FFE2A3','Block',(0,0,20),level=6)
    solid('champion cuff',(.35,1.04,0),(2.46,.53,2.46),'39434C',level=7)
    solid('champion medal',(.35,1.04,1.26),(.42,.42,.12),'F4D78E','Ball',level=7)
    solid('tiny top hat brim',(.25,5.45,0),(.16,3.05,2.3),'292B32','Cylinder',(0,0,90),level=8)
    solid('tiny top hat',(.25,6.02,0),(1.48,1.10,1.4),'292B32',level=8)
    solid('hat ribbon',(.25,5.70,.72),(1.5,.25,.05),'D5B68A',level=8)
    solid('king crown band',(.25,5.48,0),(.42,3.25,2.35),'E8B75E','Cylinder',(0,0,90),level=10)
    for x,y in [(-.78,5.97),(.25,6.22),(1.28,5.97)]:
        solid('king crown spike',(x,y,.48),(.45,.95,.46),'E8B75E','Block',(0,0,-x*13),level=10)
        solid('king crown jewel',(x,y+.43,.48),(.31,.31,.31),'CA4254','Ball',level=10)
    return model
