from pathlib import Path
import json,math,sys
R=Path('roblox-training/v6');sys.path.insert(0,str(R.resolve()))
from nature_models import read_obj
m=json.loads((R/'map/TrainingMap.model.json').read_text(encoding='utf-8'))
def walk(n):
 yield n
 for c in n.get('Children',[]):yield from walk(c)
nodes=list(walk(m));checks=0
def check(v,msg):
 global checks
 checks+=1;assert v,msg
# Independent ray/triangle intersection against exported native WedgePart geometry.
def sub(a,b):return [x-y for x,y in zip(a,b)]
def cross(a,b):return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]
def dot(a,b):return sum(x*y for x,y in zip(a,b))
def hit_triangle(o,d,a,b,c):
 e1=sub(b,a);e2=sub(c,a);h=cross(d,e2);det=dot(e1,h)
 if abs(det)<1e-8:return False
 s=sub(o,a);u=dot(s,h)/det
 if u< -1e-6 or u>1.000001:return False
 q=cross(s,e1);v=dot(d,q)/det
 return v>=-1e-6 and u+v<=1.000001 and dot(e2,q)/det>=0
unit=[(x,y,z) for x in [-.5,.5] for y,z in [(-.5,-.5),(-.5,.5),(.5,.5)]]
faces=[(0,1,2),(3,5,4),(0,3,4),(0,4,1),(1,4,5),(1,5,2),(0,2,5),(0,5,3)]
def vertices(p):
 f=p['Properties'];rot=f['CFrame'][3:]
 return [[f['CFrame'][j]+sum(rot[j*3+i]*q[i]*f['Size'][i] for i in range(3)) for j in range(3)] for q in unit]
models=[n for n in nodes if n['ClassName']=='Model' and n.get('Name','').startswith('Kenney ')]
solid_models=0
for model in models:
 name=model['Name'];parts=[p for p in model['Children'] if p['ClassName']=='WedgePart']
 solids=[p for p in parts if p['Properties']['CanCollide']]
 if 'plant_bush' in name:check(not solids,'soft bush remains passable');continue
 solid_models+=1;check(bool(solids),name+' has real collision')
 for p in parts:
  f=p['Properties'];bark=all(abs(a-b)<.001 for a,b in zip(f['Color'],[120/255,97/255,78/255]))
  check(f['CanCollide']==('stone' in name or bark),name+' only solid materials collide')
  check(f['CanQuery']==f['CanCollide'],name+' ray visibility matches physical surface')
 mesh=[vertices(p) for p in solids];pts=[v for face in mesh for v in face]
 lo=[min(v[i] for v in pts) for i in range(3)];hi=[max(v[i] for v in pts) for i in range(3)]
 # Intersect through a solid source face centroid from outside its full world bounds.
 # This verifies rotated imported facets form actual collision surfaces, not origin-sized placeholders.
 for axis in [0,2]:
  chosen=max(mesh,key=lambda v:sum(p[axis] for p in v)/len(v))
  target=[sum(p[i] for p in chosen[:3])/3 for i in range(3)]
  origin=target.copy();origin[axis]=lo[axis]-4;direction=[0,0,0];direction[axis]=1
  check(any(hit_triangle(origin,direction,*(tri[j] for j in face)) for tri in mesh for face in faces),name+' lateral approach hits visible mesh')
check(solid_models==46,'25 trees + 21 rocks covered')
solid_names=['Monitor','Mailbox body','Mailbox sign','Agency wordmark','Work desk','Desk leg','Creator camera','Ring light stand','Ring light','Path lantern','ConditionBoard','ChoiceBoard1','ChoiceBoard2','ChoiceBoard3','ChallengeConsole','ThumbsUp pedestal','Agency side','Agency back wing','Challenge side wall']
for name in solid_names:
 group=[n for n in nodes if n.get('Name','')==name];check(bool(group),name+' fixture exists')
 for n in group:check(n['Properties']['CanCollide'],name+' is solid')
for n in nodes:
 f=n.get('Properties',{})
 if n.get('Name','').startswith(('Target_','Forward route arrow','Choice floor number','Kenney grass','Grass wind')) or n.get('Name','')=='Ocean water preview':
  if 'CanCollide' in f:check(not f['CanCollide'],n.get('Name','')+' remains passable')
for n in nodes:
 if n.get('Name','').startswith('AnswerNPC'):
  for p in n['Children']:
   if 'CanCollide' in p['Properties']:check(not p['Properties']['CanCollide'] and p['Properties']['Transparency']==1,'idle NPC cannot become invisible obstruction')
import xml.etree.ElementTree as ET
from collections import Counter
xml=ET.parse(R/'downloads/SIRIAI_Recruiter_Island_v6_12.rbxlx')
exported=next(it for it in xml.iter('Item') if it.find("Properties/string[@name='Name']") is not None and it.find("Properties/string[@name='Name']").text=='TrainingMap')
expected=Counter((n.get('Name',''),n['Properties']['CanCollide']) for n in nodes if 'CanCollide' in n.get('Properties',{}))
actual=Counter()
for it in exported.iter('Item'):
 if it.attrib['class'] not in ('Part','WedgePart','Seat','SpawnLocation'):continue
 props=it.find('Properties');value=props.find("bool[@name='CanCollide']")
 check(value is not None,'export includes explicit collision property')
 actual[(props.find("string[@name='Name']").text,value.text=='true')]+=1
check(expected==actual,'Rojo-exported collisions exactly match audited source geometry')
print(f'PASS: {checks} exported collision checks; 46 original solid nature models, physical fixtures, soft surfaces and idle NPCs')
print('NOT VERIFIED: native solver, other players and low-end device performance')
