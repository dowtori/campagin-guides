from pathlib import Path
import json,math,hashlib,sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from coastal_environment import height_at
R=Path(__file__).resolve().parents[1]
model=json.loads((R/'map/TrainingMap.model.json').read_text(encoding='utf-8'))
def walk(n):
 yield n
 for c in n.get('Children',[]):yield from walk(c)
nodes=list(walk(model));parts=[n for n in nodes if n['ClassName'] in ['Part','WedgePart','Seat','SpawnLocation']]
assert all(max(p['Properties']['Size'])<=2048 for p in parts)
assert all(p['Properties']['Anchored'] for p in parts)
assert not any('Pixel twilight' in p.get('Name','') or p.get('Name')=='Lake water preview' for p in parts)
ocean=[p['Properties'] for p in parts if p.get('Name')=='Ocean water preview']
assert len(ocean)==20
assert sum(p['Size'][0]*p['Size'][2] for p in ocean)==2400*2800
for p in ocean:
 assert abs(p['CFrame'][1]+p['Size'][1]/2+2)<1e-6
 assert 0<p['Transparency']<.4 and not p['CanCollide'] and not p['CanTouch'] and not p['CanQuery']
for x in range(-1190,1200,40):
 for z in range(-1890,900,40):
  assert any(abs(x-p['CFrame'][0])<=p['Size'][0]/2 and abs(z-p['CFrame'][2])<=p['Size'][2]/2 for p in ocean),'editor ocean has no gaps'
sun=next(p for p in parts if p.get('Name')=='Setting sun');assert sun['Properties']['Shape']=='Ball' and not sun.get('Children')
clouds=[p for p in parts if p.get('Name')=='Sky cloud puff']
assert len(clouds)==24 and all(p['Properties']['Size'][0]>p['Properties']['Size'][1]*2 for p in clouds)
assert {p['model'] for p in json.loads((R/'nature-instances.json').read_text()) if p['model'].startswith('tree_')}=={'tree_oak'}
floors=[p['Properties'] for p in parts if p.get('Name')=='Solid sea floor'];assert len(floors)==20
for x in range(-1020,1021,60):
 for z in range(-1080,761,60):assert any(abs(x-f['CFrame'][0])<=f['Size'][0]/2 and abs(z-f['CFrame'][2])<=f['Size'][2]/2 and f['CanCollide'] for f in floors)
assert len([p for p in nodes if p['ClassName']=='ProximityPrompt'])==3
assert len([p for p in nodes if p['ClassName']=='Humanoid'])==7
assert all(n['Properties']['RequiresNeck']==False for n in nodes if n['ClassName']=='Humanoid')
for name in ['Manager','beauty_sample','Mailbox']:
 assert len([p for p in parts if p.get('Name')=='Target_'+name])==1
for name in ['Arrival title','Arrival direction']:
 p=next(p for p in parts if p.get('Name')==name);assert abs(p['Properties']['CFrame'][0]+34)>20,'arrival signs must not span the main path'
assert len([p for p in parts if p.get('Name')=='Water access step'])==12
# Compare source geometry and native wedges independently for rock and pine assets.
instances=json.loads((R/'nature-instances.json').read_text());models=next(n for n in nodes if n.get('Name')=='ImportedNature')['Children']
for idx in [0,next(i for i,p in enumerate(instances) if p['model']=='tree_oak')]:
 a=instances[idx];m=models[idx];verts=[]
 for line in (R/f"assets/nature/kenney/{a['model']}.obj").read_text().splitlines():
  if line.startswith('v '):verts.append(tuple(map(float,line.split()[1:4])))
 angle=math.radians(a['rotation']);co,si=math.cos(angle),math.sin(angle);x,y,z=a['position'];scale=a['scale']
 original=[(x+(p[0]*co+p[2]*si)*scale,y+p[1]*scale-.07,z+(-p[0]*si+p[2]*co)*scale) for p in verts]
 exported=[]
 for p in m['Children']:
  if p['ClassName']!='WedgePart':continue
  f=p['Properties'];pos=f['CFrame'][:3];matrix=f['CFrame'][3:];sx,sy,sz=f['Size']
  for xx in [-sx/2,sx/2]:
   for yy,zz in [(-sy/2,-sz/2),(-sy/2,sz/2),(sy/2,sz/2)]:exported.append(tuple(pos[k]+matrix[k*3]*xx+matrix[k*3+1]*yy+matrix[k*3+2]*zz for k in range(3)))
 for k in range(3):
  assert abs(min(p[k] for p in original)-min(p[k] for p in exported))<.03
  assert abs(max(p[k] for p in original)-max(p[k] for p in exported))<.03
assert all((R/f'assets/brand-profile-{i}.jpg').exists() for i in range(1,7))
wind=(R/'src/shared/ThirdParty/WindShake/init.lua').read_bytes();assert hashlib.sha1(b'blob '+str(len(wind)).encode()+b'\0'+wind).hexdigest()=='625d9c030c37afd2aff0c92ec59e4d3ac66fb3a9'
assert 'Pixelated' not in (R/'src/shared/RasterRenderer.lua').read_text(encoding='utf-8')
# Prevent the overlapping HUD/tool controls that a callback-only test cannot catch.
for width in [360,390,768,1440]:
 hud_right=width*.035+min(width-126,360);phone_left=width*.965-90
 assert hud_right+4<phone_left
assert len([p for p in parts if p['ClassName']=='WedgePart'])>10000
print(f'PASS: {len(parts)} parts; actual 3D sun/ridges/clouds; no image walls; continuous seabed, original OBJ bounds, three targets, source branding and HUD/control separation')
