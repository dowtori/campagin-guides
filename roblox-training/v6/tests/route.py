from pathlib import Path
import json, math
r=Path(__file__).resolve().parents[1];model=json.loads((r/'map/TrainingMap.model.json').read_text(encoding='utf-8'));route=json.loads((r/'route.json').read_text(encoding='utf-8'));data=json.loads((r/'case.json').read_text(encoding='utf-8'))
def walk(n):
 yield n
 for c in n.get('Children',[]):yield from walk(c)
nodes=list(walk(model));parts=[n for n in nodes if n['ClassName'] in ['Part','WedgePart','Seat','SpawnLocation']]
for key in route['requiredStops']:
 target=next(p for p in parts if p.get('Name')=='Target_'+key)
 assert target['Properties']['CFrame'][:3]==route['targets'][key]['position']
stops=[]
for q in data['phases']:
 if not stops or stops[-1]!=q['target']:stops.append(q['target'])
assert stops==route['requiredStops']==['Manager','beauty_sample','Mailbox']
arrivals=[(route['spawn'][0],route['spawn'][1])]+[(route['targets'][k]['position'][0],route['targets'][k]['position'][2]+7) for k in stops]
assert all(b[1]<a[1] for a,b in zip(arrivals,arrivals[1:]))
distance=sum(math.dist(a,b) for a,b in zip(arrivals,arrivals[1:]));assert distance<150
candidates=[]
for p in parts:
 f=p['Properties'];m=f['CFrame'][3:];h=[v/2 for v in f['Size']];y=f['CFrame'][1]
 ey=sum(abs(m[3+i])*h[i] for i in range(3))
 if f['CanCollide'] and y+ey>1.6 and y-ey<7.0:candidates.append(p)
collisions=[]
# Independent capsule samples through the entire required walking corridor.
for z in range(-40,101):
 for x in [-35.3,-34,-32.7]:
  for y in [2,3.5,5,6.5]:
   for p in candidates:
    f=p['Properties'];m=f['CFrame'][3:];d=[x-f['CFrame'][0],y-f['CFrame'][1],z-f['CFrame'][2]]
    local=[sum(m[j*3+i]*d[j] for j in range(3)) for i in range(3)]
    if all(abs(local[i])<f['Size'][i]/2 for i in range(3)):collisions.append((p['Name'],x,y,z))
assert not collisions,collisions[:12]
print('PASS: 3 forward stops,',distance,'studs spawn-to-final-arrival; no solid obstruction in required corridor')
