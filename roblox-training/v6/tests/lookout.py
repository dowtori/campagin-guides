from pathlib import Path
import json,sys,math,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1];sys.path.insert(0,str(R))
from coastal_environment import height_at
model=json.loads((R/'map/TrainingMap.model.json').read_text(encoding='utf-8'))
def walk(n):
 yield n
 for c in n.get('Children',[]):yield from walk(c)
nodes=list(walk(model));lookout=next(n for n in nodes if n.get('Name')=='RidgeLookout')
p=lookout['Children'];floor=next(n['Properties'] for n in p if n['Name']=='Ridge lookout floor');top=floor['CFrame'][1]+floor['Size'][1]/2
assert floor['Size']==[30,.5,24] and floor['CanCollide']
for x in range(285,316):
 for z in range(98,123):assert height_at(x,z)<top-.5,'ground cannot poke through deck'
steps=[n['Properties'] for n in p if n['Name']=='Lookout entry step']
assert len(steps)==6
for a,b in zip(steps,steps[1:]):
 assert abs(a['CFrame'][1]-b['CFrame'][1])<.6,'walkable step height'
 assert abs(a['CFrame'][2]-b['CFrame'][2])<1.7,'steps overlap'
assert abs(steps[-1]['CFrame'][1]+.2-top)<1e-6
assert steps[-1]['CFrame'][2]-steps[-1]['Size'][2]/2<122
assert all(s['CanCollide'] and 289<s['CFrame'][0]<301 for s in steps)
posts=[n['Properties'] for n in p if n['Name']=='Lookout rail post']
assert len(posts)>30
assert not any(289.2<q['CFrame'][0]<300.8 and q['CFrame'][2]==122 for q in posts),'rear entry clear'
for n in p:
 if n['Name']!='Lookout board seam':assert n['Properties']['CanCollide'],n['Name']
assert len([n for n in p if n['ClassName']=='Seat'])==2
for n in p:
 if n['Name']=='Lookout support':
  f=n['Properties'];x,y,z=f['CFrame'][:3]
  assert y-f['Size'][1]/2<=height_at(x,z)
  assert abs(y+f['Size'][1]/2-top)<1e-6
items=list(ET.parse(R/'downloads/SIRIAI_Recruiter_Island_v6_16.rbxlx').getroot().iter('Item'))
def prop(i,k):return i.find("Properties/*[@name='"+k+"']")
light=next(i for i in items if i.get('class')=='Lighting')
atmo=next(i for i in items if i.get('class')=='Atmosphere')
cloud=next(i for i in items if i.get('class')=='Clouds')
def channels(i,key):
 c=prop(i,key);return [float(c.find(q).text) for q in ['R','G','B']]
for obj,key in [(light,'ColorShift_Top'),(atmo,'Color'),(cloud,'Color')]:
 a=channels(obj,key);assert a[0]>a[1]*1.2 and a[0]>a[2]*1.35,(key,a)
assert float(prop(light,'Brightness').text)>=2.5
assert float(prop(atmo,'Haze').text)>2
assert any(prop(i,'Name') is not None and prop(i,'Name').text=='RidgeLookout' for i in items)
print('PASS: ridge floor above terrain, six connected low steps, clear 12-stud entry, physical rails/seats/supports; red atmosphere/light/cloud settings serialized')
