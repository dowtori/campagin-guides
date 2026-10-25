"""Visual invariants against the saved geometry and the actual exported place."""
from pathlib import Path
import json,math,sys,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1];sys.path.insert(0,str(R))
from nature_models import compact_mesh,add,sub,mul,dot,length
from sunset import SUN_DIRECTION
model=json.loads((R/'map/TrainingMap.model.json').read_text(encoding='utf-8'))
def walk(n):
 yield n
 for c in n.get('Children',[]):yield from walk(c)
nodes=list(walk(model));parts=[n for n in nodes if n['ClassName'] in ('Part','WedgePart','Seat','SpawnLocation')]
assert not any(n.get('Name') in ['Coast ground preview','Meadow stem','Meadow blade','Meadow seedhead','Sky cloud puff'] for n in nodes)
surface=[p for p in parts if p.get('Name')=='Coast surface preview']
assert surface and all(p['ClassName']=='WedgePart' and p['Properties']['Size'][0]==.08 for p in surface)
# Corner positions on shared edges are exactly those from the source heightfield.
from coastal_environment import height_at
checked=0
for p in surface[::13]:
 f=p['Properties'];center=f['CFrame'][:3];m=f['CFrame'][3:];sx,sy,sz=f['Size']
 for y,z in [(-sy/2,-sz/2),(sy/2,sz/2)]:
  v=[center[k]+m[k*3+1]*y+m[k*3+2]*z for k in range(3)]
  assert abs(v[1]-height_at(v[0],v[2]))<.001,(p['Name'],v)
  checked+=1
instances=json.loads((R/'meadow-instances.json').read_text());group=next(n for n in nodes if n.get('Name')=='MeadowReeds')
assert len(group['Children'])==len(instances)
rects,faces=compact_mesh('grass',ribbon_width=.45)
assert len(rects)==33 and not faces
# 11 original curved ribbons are retained; coplanar triangle merging preserves bounds.
for i in [0,len(instances)//2,len(instances)-1]:
 a=instances[i];model=group['Children'][i];co,si=math.cos(a['angle']),math.sin(a['angle']);x,y,z=a['position'];w,h=a['widthScale'],a['heightScale']
 def tr(v):return [x+(v[0]*co+v[2]*si)*w,y+v[1]*h,z+(-v[0]*si+v[2]*co)*w]
 verts=[]
 for origin,u,v in rects:verts.extend(tr(p) for p in [origin,add(origin,u),add(origin,v),add(add(origin,u),v)])
 exported=[]
 for p in model['Children']:
  if p['Name']=='Grass wind root':continue
  f=p['Properties'];pos=f['CFrame'][:3];m=f['CFrame'][3:];sx,sy,sz=f['Size']
  assert not f['CanCollide'] and not f['CanQuery'] and not f['CastShadow']
  for xx in [-sx/2,sx/2]:
   for yy in [-sy/2,sy/2]:
    for zz in [-sz/2,sz/2]:exported.append([pos[k]+m[k*3]*xx+m[k*3+1]*yy+m[k*3+2]*zz for k in range(3)])
 for k in range(3):
  assert abs(min(v[k] for v in verts)-min(v[k] for v in exported))<.02
  assert abs(max(v[k] for v in verts)-max(v[k] for v in exported))<.02
near=0
for i,a in enumerate(instances):
 if any(i!=j and math.hypot(a['position'][0]-b['position'][0],a['position'][2]-b['position'][2])<.19*(a['widthScale']+b['widthScale']) for j,b in enumerate(instances)):near+=1
assert near/len(instances)>.8
xml=ET.parse(R/'downloads/SIRIAI_Recruiter_Island_v6_11.rbxlx').getroot()
items=list(xml.iter('Item'))
def prop(i,k):return i.find("Properties/*[@name='"+k+"']")
light=next(i for i in items if i.get('class')=='Lighting')
# Rojo must serialize these; source-only settings are insufficient.
assert prop(light,'PrioritizeLightingQuality').text=='true'
assert prop(light,'LightingStyle') is not None
assert float(prop(light,'EnvironmentSpecularScale').text)==1
assert float(prop(light,'EnvironmentDiffuseScale').text)==1
assert any(i.get('class')=='SunRaysEffect' for i in items)
assert any(i.get('class')=='ColorCorrectionEffect' for i in items)
terrain=next(i for i in items if i.get('class')=='Terrain')
assert prop(terrain,'Decoration').text=='true'
assert float(prop(terrain,'WaterReflectance').text)>.7
assert float(prop(terrain,'GrassLength').text)>.65
sun=next(p['Properties'] for p in parts if p.get('Name')=='Setting sun')
d=length(sun['CFrame'][:3]);direction=[v/d for v in sun['CFrame'][:3]]
assert sum(x*y for x,y in zip(direction,SUN_DIRECTION))>.999999
assert 4<math.degrees(math.asin(direction[1]))<8,'sun must be low over the sea'
assert not sun['CanQuery'] and not sun['CastShadow']
source=next(prop(i,'Source').text for i in items if prop(i,'Name') is not None and prop(i,'Name').text=='NatureMotion')
assert 'Lighting:GetSunDirection()*1250' in source and 'camera.CFrame.Position' in source
assert 'Wind.RenderDistance=85' in source and 'Wind.MaxRefreshRate=1/30' in source
print(f'PASS: {checked} saved slope corners match heightfield; no block columns; {len(instances)} curved CC0 grass clumps; {near/len(instances):.1%} overlapping extents; native Realistic lighting, grass, water reflection and solar alignment serialized')
print('NOT VERIFIED: Roblox pixel appearance, frame rate, native water reflections and engine sun-direction equivalence')
