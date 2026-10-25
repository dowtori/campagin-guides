"""Check that the exported native landscape keeps its walkable route and scenery."""
import json,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
project=json.loads((ROOT/'default.project.json').read_text(encoding='utf-8-sig'))
model=json.loads((ROOT/'map/TrainingMap.model.json').read_text(encoding='utf-8-sig'))
def walk(node):
    yield node
    for child in node.get('Children',[]):yield from walk(child)
nodes=list(walk(model));parts=[n for n in nodes if n['ClassName'] in ('Part','Seat','SpawnLocation')]
reeds=[n for n in parts if n.get('Name').startswith('Reed ')]
assert len(reeds)>10000
assert all(not n['Properties']['CanCollide'] and not n['Properties']['CanQuery'] and not n['Properties']['CastShadow'] for n in reeds)
assert len([n for n in nodes if n['ClassName']=='Seat'])==2
assert any(n.get('Name')=='LookoutSpawn' and n['Properties']['CFrame'][:3]==[0,4,-263] for n in nodes)
lighting=project['tree']['Lighting'];assert lighting['$properties']['ClockTime']==17.7
assert lighting['Atmosphere']['$properties']['Haze']>1
assert project['tree']['Workspace']['Terrain']['Clouds']['$className']=='Clouds'
planks=[n['Properties'] for n in parts if n.get('Name')=='Boardwalk plank'];assert len(planks)>200
assert all(p['CanCollide'] and p['Anchored'] for p in planks)
# Adjacent plank centers always overlap along the path; the walking surface stays level.
for a,b in zip(planks,planks[1:]):
    distance=math.dist([a['CFrame'][0],a['CFrame'][2]],[b['CFrame'][0],b['CFrame'][2]])
    assert distance<1.5
    assert abs(a['CFrame'][1]-b['CFrame'][1])<.01
for node in nodes:
    if node.get('Name')=='Terminal':assert any(c['ClassName']=='ProximityPrompt' for c in node['Children'])
water=next(n['Properties'] for n in parts if n.get('Name')=='Lake water preview');assert not water['CanCollide']
assert len([n for n in nodes if n.get('Name')=='Terminal'])==6
print(f'PASS: sunset lighting/clouds, {len(reeds)} nonblocking reed parts, continuous {len(planks)}-plank route, 2 seats, lookout, 6 mission terminals')
