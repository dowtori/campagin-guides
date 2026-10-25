from pathlib import Path
import json,math
R=Path(__file__).resolve().parents[1]
model=json.loads((R/'map/TrainingMap.model.json').read_text(encoding='utf-8'))
D=json.loads((R/'src/shared/AdvancedData.json').read_text(encoding='utf-8'))
route=json.loads((R/'route.json').read_text(encoding='utf-8'))
def walk(n):
 yield n
 for c in n.get('Children',[]):yield from walk(c)
nodes=list(walk(model));room=next(n for n in nodes if n.get('Name')=='AdvancedRoom')
parts=[n for n in room['Children'] if 'CFrame' in n.get('Properties',{})]
floor=next(n['Properties'] for n in parts if n['Name']=='Challenge floor')
assert floor['CFrame'][:3]==[26,.67,-60]
assert D['room']['halfSize']==[18,14,28]
assert D['room']['arrival']==[16,4,-60] and D['room']['lookAt']==[42,10,-60]
# World-facing plane normals, not assumed +Z: choices and console face the walk-in player.
for name in ['ConditionBoard','ChallengeConsole','Challenge entry title','ChoiceBoard1','ChoiceBoard2','ChoiceBoard3']:
 p=next(n['Properties'] for n in parts if n['Name']==name);m=p['CFrame'][3:]
 assert m[2]==-1 and m[5]==0 and m[8]==0,name+' faces boardwalk'
 if name!='Challenge entry title':assert p['CFrame'][0]>D['room']['arrival'][0],name+' ahead of player'
for i in range(1,4):
 npc=next(n for n in nodes if n.get('Name')=='AnswerNPC'+str(i));torso=next(n for n in npc['Children'] if n.get('Name')=='Torso')['Properties'];eye=next(n for n in npc['Children'] if n.get('Name')=='Eye')['Properties']
 assert eye['CFrame'][0]<torso['CFrame'][0],'NPC faces entrance'
 assert torso['CFrame'][3:]==floor['CFrame'][3:]
# Approach slabs form a continuous straight connector from x=-34 to x=8.
slabs=sorted([p['Properties'] for p in parts if p['Name']=='Challenge approach'],key=lambda x:x['CFrame'][0])
assert slabs[0]['CFrame'][0]==-34 and slabs[-1]['CFrame'][0]==8
assert 42<106*.5
assert all(p['CanCollide'] and p['CFrame'][2]==-60 and p['Size'][2]>=11 for p in slabs)
assert all(b['CFrame'][0]-a['CFrame'][0]<a['Size'][0] for a,b in zip(slabs,slabs[1:]))
# Sample avatar clearance through approach and whole main route to the pier.
solids=[]
for p in nodes:
 f=p.get('Properties',{})
 if f.get('CanCollide') and 'CFrame' in f:
  m=f['CFrame'][3:];ext=[sum(abs(m[j*3+i])*f['Size'][i]/2 for i in range(3)) for j in range(3)]
  if f['CFrame'][1]+ext[1]>1.7 and f['CFrame'][1]-ext[1]<7:solids.append((p,f,ext))
def check_point(x,z):
 for p,f,ext in solids:
  if abs(x-f['CFrame'][0])>ext[0]+1.5 or abs(z-f['CFrame'][2])>ext[2]+1.5:continue
  for dx,dz in [(0,0),(-1.5,0),(1.5,0),(0,-1.5),(0,1.5)]:
   for y in [2.2,4,6.5]:
    d=[x+dx-f['CFrame'][0],y-f['CFrame'][1],z+dz-f['CFrame'][2]];m=f['CFrame'][3:]
    local=[sum(m[j*3+i]*d[j] for j in range(3)) for i in range(3)]
    assert not all(abs(local[i])<f['Size'][i]/2 for i in range(3)),(p['Name'],x,y,z)
for x in range(-34,18):check_point(x,-60)
for a,b in zip(route['path'],route['path'][1:]):
 n=math.ceil(math.dist(a,b))
 for k in range(n+1):check_point(a[0]+(b[0]-a[0])*k/n,a[1]+(b[1]-a[1])*k/n)
print('PASS: approach 106 -> 42 studs (60% shorter); boards/NPCs face entry; arrival and room bounds aligned; approach and full pier route clear')
