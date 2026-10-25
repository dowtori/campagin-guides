"""Geometry and embedded image regression checks for the actual v4 project."""
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
assert any(n.get('Name')=='LookoutSpawn' and n['Properties']['CFrame'][:3]==[0,4,-326] for n in nodes)
assert project['tree']['Lighting']['$properties']['ClockTime']==18.1
assert project['tree']['Workspace']['Terrain']['Clouds']['$className']=='Clouds'
assert len([n for n in nodes if n.get('Name')=='Pixel twilight horizon'])==1
assert len([n for n in nodes if n.get('Name')=='Pixel twilight surround'])==3
planks=[n['Properties'] for n in parts if n.get('Name')=='Boardwalk plank'];assert len(planks)>250
assert all(p['CanCollide'] and p['Anchored'] for p in planks)
for a,b in zip(planks,planks[1:]):assert math.dist([a['CFrame'][0],a['CFrame'][2]],[b['CFrame'][0],b['CFrame'][2]])<1.5
stages=json.loads((ROOT/'src/server/Curriculum.json').read_text(encoding='utf-8-sig'))['stages']
for a in stages:
    for b in stages:
        if a['id']<b['id']:
            assert abs(a['position'][0]-b['position'][0])>50 or abs(a['position'][2]-b['position'][2])>50
for booth in [n for n in nodes if n.get('Name','').startswith('Station') and n['ClassName']=='Model']:
    children=booth['Children'];by_name={n['Name']:n for n in children}
    assert 'Booth back wall' in by_name and 'Booth artwork' in by_name and 'Booth title' in by_name
    assert by_name['Booth artwork']['Children'][1]['Properties']['Value'].startswith('booth')
    assert len(by_name['Booth artwork']['Children'][0]['Children'][0]['Children'])>1000, 'Booth image must already be visible before Play'
    # Number and title are disjoint and sit in front of the support posts.
    for name in ['Booth title','Booth number']:
        p=by_name[name]['Properties'];x,y,z=p['CFrame'][:3];w,h,d=p['Size']
        for post in [n['Properties'] for n in children if n['Name']=='Pavilion post']:
            px,py,pz=post['CFrame'][:3]
            assert abs(x-px)>(w+post['Size'][0])/2 or abs(z-pz)>(d+post['Size'][2])/2
    guide=by_name['Booth overview']['Properties'];terminal=by_name['Terminal']['Properties'];header=by_name['Front header']['Properties']
    assert guide['CFrame'][0]-guide['Size'][0]/2 > terminal['CFrame'][0]+terminal['Size'][0]/2+1
    assert header['CFrame'][1]-header['Size'][1]/2 > guide['CFrame'][1]+guide['Size'][1]/2+1
    assert any(c['ClassName']=='ProximityPrompt' and c['Properties']['Enabled'] for c in by_name['Terminal']['Children'])
assets=json.loads((ROOT/'raster-data.json').read_text(encoding='utf-8-sig'))
for key,a in assets.items():
    assert sum(r[1] for r in a['runs'])==a['width']*a['height'],key
    assert len(a['rects'])>10 and (ROOT/a['file']).exists(),key
assert all(key in assets for key in ['sky','logo','wordmark','settings','options']+[f'booth{i}' for i in range(1,7)])
print(f'PASS: six separated booths; no title/post intersection; actual raster image data; twilight surround; {len(reeds)} nonblocking reeds; continuous boardwalk')
