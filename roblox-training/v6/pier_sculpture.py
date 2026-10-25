"""Original, rounded thumbs-up sculpture built from native Roblox solids."""
import math

def add_thumbs_up(world,part,obj,cf):
    model=obj('PierThumbsUp','Model');world.append(model);parts=model['Children']
    origin=(-12,1.03,-323.5);scale=.9;yaw=18
    angle=math.radians(yaw);co,si=math.cos(angle),math.sin(angle)
    def solid(name,pos,size,color='E6CD98',shape='Block',rot=(0,0,0)):
        x,y,z=pos
        p=part(parts,'ThumbsUp '+name,(origin[0]+scale*(x*co+z*si),origin[1]+scale*y,origin[2]+scale*(-x*si+z*co)),tuple(scale*v for v in size),color,'SmoothPlastic',shape,rot=(0,0,0))
        # Compose the global yaw with each primitive's local rotation.
        local=cf((0,0,0),rot)[3:];turn=cf((0,0,0),(0,yaw,0))[3:]
        matrix=[sum(turn[row*3+k]*local[k*3+col] for k in range(3)) for row in range(3) for col in range(3)]
        p['Properties']['CFrame'][3:]=matrix
        # The preview consumes the same composed native transform via matrix.
        p['Properties']['Reflectance']=.04
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
    return model
