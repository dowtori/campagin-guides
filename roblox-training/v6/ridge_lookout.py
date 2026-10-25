"""A real lookout at the existing summit, connected to the ridge trail."""
import math

def add_lookout(world,part,obj,rgb,height_at):
    cx,cz=300,110
    top=max(height_at(x,z) for x in range(285,316) for z in range(98,123))+.65
    model=obj('RidgeLookout','Model');world.append(model);p=model['Children']
    part(p,'Ridge lookout floor',(cx,top-.25,cz),(30,.5,24),'AA8660','WoodPlanks')
    for x in range(286,316,3):
        part(p,'Lookout board seam',(x,top+.006,cz),(.035,.012,24),'846449','Wood',collide=False)
    for x in [286,300,314]:
        for z in [99,121]:
            ground=height_at(x,z)-.5;h=top-ground
            part(p,'Lookout support',(x,ground+h/2,z),(.9,h,.9),'685744','Wood')
    # Six-stud mountain path enters the rear left opening (x 289..301).
    z0=129;entry_y=height_at(300-(z0-110)*19/43,z0)+.42
    for k in range(6):
        z=128.5-k*1.3;x=300-(z-110)*19/43
        step_top=entry_y+(top-entry_y)*(k+1)/6
        part(p,'Lookout entry step',(x,step_top-.2,z),(7.2,.4,1.7),'B99B74','WoodPlanks')
    def fence(ax,az,bx,bz):
        dx,dz=bx-ax,bz-az;length=math.hypot(dx,dz);yaw=math.degrees(math.atan2(dx,dz))
        for y in [1.25,3.5]:
            part(p,'Lookout guardrail',((ax+bx)/2,top+y,(az+bz)/2),(.25,.22,length+.2),'79634D','Wood',rot=(0,yaw,0))
        for i in range(math.ceil(length/2.5)+1):
            t=i/math.ceil(length/2.5)
            part(p,'Lookout rail post',(ax+dx*t,top+1.75,az+dz*t),(.28,3.5,.28),'79634D','Wood')
    for edge in [(285,98,315,98),(285,98,285,122),(315,98,315,122),(285,122,289,122),(301,122,315,122)]:fence(*edge)
    for x in [291,309]:
        seat=part(p,'Ridge sunset seat',(x,top+1.1,115),(6,.45,2),'BFA17D','Wood');seat['ClassName']='Seat';seat['Properties']['CanTouch']=True
        part(p,'Ridge seat back',(x,top+2.1,116),(6,1.7,.3),'BFA17D','Wood')
        for dx in [-2.3,2.3]:part(p,'Ridge seat leg',(x+dx,top+.5,115),(.35,1,1.9),'655648','Wood')
    # Fixed viewing scope: physical prop, no extra popup or instructions.
    part(p,'Lookout scope stand',(300,top+1.6,101),(.65,3.2,.65),'49494B','Metal')
    part(p,'Lookout scope body',(300,top+3.7,100.55),(2.5,.85,.85),'E1D5BC','Metal','Cylinder',rot=(0,90,0))
    part(p,'Lookout scope lens',(300,top+3.7,99.27),(.08,.64,.64),'465E67','Glass','Cylinder',rot=(0,90,0))
    for x in [286,314]:
        lamp=part(p,'Lookout warm lantern',(x,top+.5,120),(.55,.65,.55),'FFD1A1','Neon')
        lamp['Children'].append(obj('Glow','PointLight',{'Color':rgb('FFD1A1'),'Brightness':.45,'Range':12,'Shadows':False}))
    return top
