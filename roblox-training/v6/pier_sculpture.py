"""Original, rounded thumbs-up sculpture built from native Roblox solids."""
import math

def add_thumbs_up(world,part,obj,cf):
    model=obj('PierThumbsUp','Model');world.append(model);parts=model['Children']
    origin=(-29,1.03,-328);scale=.9;yaw=18
    angle=math.radians(yaw);co,si=math.cos(angle),math.sin(angle)
    def solid(name,pos,size,color='E6CD98',shape='Block',rot=(0,0,0),level=0):
        x,y,z=pos
        p=part(parts,'ThumbsUp '+name,(origin[0]+scale*(x*co+z*si),origin[1]+scale*y,origin[2]+scale*(-x*si+z*co)),tuple(scale*v for v in size),color,'SmoothPlastic',shape,rot=(0,0,0))
        # Compose the global yaw with each primitive's local rotation.
        local=cf((0,0,0),rot)[3:];turn=cf((0,0,0),(0,yaw,0))[3:]
        matrix=[sum(turn[row*3+k]*local[k*3+col] for k in range(3)) for row in range(3) for col in range(3)]
        p['Properties']['CFrame'][3:]=matrix
        # The preview consumes the same composed native transform via matrix.
        p['Properties'].update(Reflectance=.04,CanCollide=False,CanTouch=False,CanQuery=False,Transparency=1 if level else 0)
        p['Children'].append(obj('ThumbStage','IntValue',{'Value':level}))
        return p,matrix
    def capsule(name,a,b,r,color='E6CD98'):
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
    capsule('raised thumb',(-2.04,4.65,.03),(-2.12,6.46,.03),.64)
    solid('thumbnail',(-2.12,6.27,.605),(.61,.84,.17),'F5E4BC','Ball',(0,0,3))
    # Accessories have real thickness and unlock on the player's own sculpture.
    for x in [-.45,.95]:solid('cool sunglasses',(x,4.35,1.45),(1.25,.62,.16),'22222B',level=2)
    solid('glasses bridge',(.25,4.35,1.46),(.40,.12,.18),'22222B',level=2)
    for i in range(7):
        a=math.radians(205+i*21)
        solid('grin tooth',(.30+.63*math.cos(a),3.58+.52*math.sin(a),1.52),(.21,.23,.13),'FFF6DE','Ball',level=3)
    for x,angle in [(-.45,-16),(.95,16)]:solid('bow tie',(x,1.82,1.22),(1.35,.72,.26),'DF1940','Ball',(0,0,angle),level=4)
    solid('bow knot',(.25,1.82,1.42),(.45,.45,.32),'F45977','Ball',level=4)
    for x,angle in [(-.72,-10),(1.22,10)]:solid('cape',(x,2.75,-1.54),(2.5,4.0,.26),'C9264B','Block',(0,angle,angle),level=5)
    for x in [-2.8,3.0]:
        solid('sparkle vertical',(x,4.7,.5),(.15,1.05,.15),'FFE3A0','Block',(0,0,25),level=6)
        solid('sparkle horizontal',(x,4.7,.5),(1.05,.15,.15),'FFE3A0','Block',(0,0,25),level=6)
    solid('champion medal',(.25,2.35,1.62),(.72,.72,.16),'FFD658','Ball',level=7)
    solid('tiny top hat brim',(.25,5.35,0),(.17,3.2,2.3),'2E2A35','Cylinder',(0,0,90),level=8)
    solid('tiny top hat',(.25,5.82,0),(1.5,.85,1.4),'2E2A35',level=8)
    for x in [-.15,.65]:solid('silly moustache',(x,3.65,1.63),(.70,.25,.23),'352931','Ball',(0,0,-25 if x<0 else 25),level=9)
    solid('king crown band',(.25,5.47,0),(.45,3.55,2.50),'FFD15A','Cylinder',(0,0,90),level=10)
    for x,y in [(-1.0,6.12),(-.4,5.93),(.25,6.4),(.9,5.93),(1.5,6.12)]:
        solid('king crown spike',(x,y,.55),(.38,1.1,.42),'FFD15A','Block',(0,0,-x*10),level=10)
        solid('king crown jewel',(x,y+.5,.55),(.42,.42,.42),'F64B73','Ball',level=10)
    return model
