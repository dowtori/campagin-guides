"""Shared, navigable 3D coastal terrain; no scenery image walls."""
from pathlib import Path
import math,json
ROOT=Path(__file__).resolve().parent
SEA_LEVEL=-2.0
HIKE=[(126,74),(164,90),(190,120),(205,155),(245,178),(281,153),(300,110)]

def bump(x,z,cx,cz,rx,rz,amplitude):
    r=((x-cx)/rx)**2+((z-cz)/rz)**2
    return amplitude*max(0,1-r)**1.65

def coast_distance(x,z):
    north=-286+13*math.sin(x/37)+8*math.sin(x/91)
    width=344+35*math.sin(z/181)+12*math.sin(z/57)
    rear=573+22*math.sin(x/124)
    return max(north-z,abs(x)-width,z-rear)

def height_at(x,z):
    d=coast_distance(x,z)
    if d<=-22:
        h=.12+.06*math.sin(x/21)*math.sin(z/31)
        # Slopes begin outside the campus. The southern ridge is connected dry land.
        hills=max(bump(x,z,-277,-4,146,276,58),bump(x,z,300,110,165,284,65),
                  bump(x,z,-78,391,299,219,95),bump(x,z,155,412,176,179,77))
        # Irregular rock contours keep the ridge from reading as a smooth green dome.
        detail=(math.sin(x/27+z/43)+.55*math.sin(x/12-z/33))*min(3.2,hills*.045)
        h+=max(0,hills+detail)
        # Ease every mountain into its actual shoreline, without a vertical edge.
        return h*min(1,(-d-22)/32)+.12*(1-min(1,(-d-22)/32))
    if d<0:h=.12-(d+22)*.62/22
    elif d<38:h=-.5-d*3.6/38
    elif d<110:h=-4.1-(d-38)*9.9/72
    elif d<200:h=-14-(d-110)*18/90
    else:h=-32
    # Two complete offshore islands. Their silhouettes have volume and real beaches.
    islands=max(-32+max(bump(x,z,-532,-648,202,242,168),bump(x,z,-480,-604,108,135,188),bump(x,z,-612,-650,106,140,137)),
                -32+max(bump(x,z,527,-708,216,215,166),bump(x,z,598,-663,96,138,181),bump(x,z,443,-748,92,132,144)))
    if islands>-31:islands+=(math.sin(x/23+z/39)+.5*math.sin(x/13-z/26))*min(5,(islands+32)*.06)
    return max(h,islands)

def write_coast_data():
    step=8;x0,z0=-768,-992;nx,nz=193,217
    heights=[round(height_at(x0+x*step,z0+z*step),3) for x in range(nx) for z in range(nz)]
    data={'version':'6.5','step':step,'x0':x0,'z0':z0,'nx':nx,'nz':nz,'heights':heights,
          'seaLevel':SEA_LEVEL,'minY':-40,'maxY':176,'voxelSize':4,'chunkCells':32,
          'adaptiveChunkHeight':True,'hikePath':HIKE,
          'ocean':{'center':[0,-21,-500],'size':[2400,38,2800]},
          'rescue':{'minY':-38,'maxX':1030,'minZ':-1090,'maxZ':760,'shore':[0,5,-326],'arrival':[-34,5,100]},
          'materialColors':{'Sand':'CCBA96','Ground':'AAB78A','Grass':'AAB78A','Rock':'9B998B'},
          'waterColor':'7C9EAB','waterTransparency':.48,'waterReflectance':.42,'waveSize':.14,'waveSpeed':5}
    (ROOT/'coast.json').write_bytes(json.dumps(data,separators=(',',':')).encode())
    (ROOT/'src/server/CoastData.json').write_bytes(json.dumps(data,separators=(',',':')).encode())
    return data

def add_coast(world,part,obj,cf):
    from nature_models import triangle
    data=write_coast_data();folder=obj('CoastPreview','Folder');world.append(folder)
    # Preview colliders remain until native terrain is ready. No pretend-water surface.
    for x in range(-368,369,16):
        for z in range(-448,641,16):
            h=height_at(x,z)
            if h<-14:continue
            color='CCBA96' if h<-.15 or coast_distance(x,z)>-27 else 'AAB78A'
            p=part(folder['Children'],'Coast ground preview',(x,(h-40)/2,z),(16,h+40,16),color,'Sand' if color=='CCBA96' else 'Ground')
            p['Properties']['CastShadow']=False
    # Volumetric offshore islands also appear before Play, with the same sampled heights.
    def preview_part(parent,name,pos,size,color,material,shape,rot,collide):
        p=part(parent,'Mountain terrain preview',pos,(.25,size[1],size[2]),color,'Rock',shape,rot,collide=True)
        p['Properties']['CanQuery']=True
        return p
    for cx,cz in [(-532,-648),(527,-708)]:
        for x in range(cx-224,cx+224,32):
            for z in range(cz-256,cz+256,32):
                pts=[(xx,height_at(xx,zz),zz) for xx,zz in [(x,z),(x+32,z),(x,z+32),(x+32,z+32)]]
                if max(v[1] for v in pts)<-8:continue
                for ids in [(0,2,1),(1,2,3)]:triangle(folder['Children'],*(pts[i] for i in ids),'817E8D',preview_part,'Mountain terrain preview')
    # A tiled solid ocean floor stays below the real Terrain seabed at all times.
    for x in [-900,-300,300,900]:
        for z in [-1600,-1000,-400,200,800]:
            p=part(world,'Solid sea floor',(x,-46,z),(600,8,600),'A59A85','Sand');p['Properties']['CastShadow']=False
    return data
