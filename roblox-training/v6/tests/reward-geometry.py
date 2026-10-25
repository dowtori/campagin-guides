from pathlib import Path
import json,math,re
r=Path('roblox-training/v6')
model=json.loads((r/'map/TrainingMap.model.json').read_text(encoding='utf-8'))
def walk(n):
 yield n
 for c in n.get('Children',[]):yield from walk(c)
nodes=list(walk(model));thumb=next(n for n in nodes if n.get('Name')=='PierThumbsUp')
config=json.loads((r/'src/shared/ThumbData.json').read_text(encoding='utf-8'))
origin=config['origin'];scales=[s['scale'] for s in config['stages']]
assert len(scales)==11 and all(b>a for a,b in zip(scales,scales[1:]))
for stage,scale in enumerate(scales):
 for p in thumb['Children']:
  f=p['Properties'];level=p['Children'][-1]['Properties']['Value']
  assert not f['CanCollide'] and not f['CanTouch'] and not f['CanQuery']
  assert f['CastShadow'], 'native and preview both cast the sculpture shadow'
  if level not in config['stages'][stage]['groups']:continue
  k=1 if level==0 else scale
  center=[origin[i]+(.486 if i==1 else 0)+(f['CFrame'][i]-origin[i]-(.486 if i==1 else 0))*k for i in range(3)]
  m=f['CFrame'][3:];ext=[sum(abs(m[j*3+i])*f['Size'][i]*k/2 for i in range(3)) for j in range(3)]
  assert -45<center[0]-ext[0] and center[0]+ext[0]<-18
  assert -342.5<center[2]-ext[2] and center[2]+ext[2]<-317.5
boards=[n for n in nodes if n.get('Name','').startswith('ChoiceBoard')]
assert len(boards)==3
condition=next(n for n in nodes if n.get('Name')=='ConditionBoard')['Properties']
for p in boards:
 f=p['Properties'];top=f['CFrame'][1]+f['Size'][1]/2
 assert top<condition['CFrame'][1]-condition['Size'][1]/2
 assert top-.96*f['Size'][1]>6.86,'button clears NPC head'
 assert f['CanQuery'] and not f['CanCollide']
console=next(n for n in nodes if n.get('Name')=='ChallengeConsole')['Properties']
assert console['CFrame'][1]+console['Size'][1]/2<6.0,'low console clears NPC faces and answer buttons'
assert console['CFrame'][0]==60,'central console reachable from entry'
room=json.loads((r/'src/shared/AdvancedData.json').read_text(encoding='utf-8'))['room']
floor=next(n for n in nodes if n.get('Name')=='Challenge floor')['Properties']
assert floor['Size'][0]*floor['Size'][2]<=92*68*.5
assert abs(room['arrival'][2]-boards[0]['Properties']['CFrame'][2])<=28
for name,cw,ch in [('ConditionBoard',1560,195),('ChallengeConsole',960,320)]+[(f'ChoiceBoard{i}',750,465) for i in range(1,4)]:
 f=next(n for n in nodes if n.get('Name')==name)['Properties']
 assert abs(f['Size'][0]/f['Size'][1]/(cw/ch)-1)<.01,name+' aspect ratio'
for i,stage in enumerate(config['stages']):
 assert stage['groups']==[0,i+1], 'one connected silhouette, no accumulating accessories'
 forbidden=('finger','thumbnail','eye','smile','glasses','bow','cape','crown','hat')
 assert not any(word in p['Name'].lower() for p in thumb['Children'] for word in forbidden)
assert (scales[-1]*(config['stages'][-1]['thumbHeight']-.54))/(scales[0]*(config['stages'][0]['thumbHeight']-.54))>=4
assert (r/'src/shared/AdvancedClient.lua').read_text(encoding='utf-8').count("make('ScreenGui'")==0
server=(r/'src/server/Campus.server.lua').read_text(encoding='utf-8')
arrival_z=float(re.search(r'Vector3.new\(-17,5,(-\d+)\)',server)[1])
deck=next(n for n in nodes if n.get('Name')=='Sunset lookout deck')['Properties']
assert abs(-17-deck['CFrame'][0])+2<deck['Size'][0]/2
assert abs(arrival_z-deck['CFrame'][2])+2<deck['Size'][2]/2,'reward arrival has solid deck underneath'
print('PASS: eleven growing sculptures within the widened pier, clear central path; world panels clear NPCs/each other')

# Use actual native prism vertices (not boxes around their empty triangular halves).
def vertex_points(p):
 f=p['Properties'];m=f['CFrame'][3:]
 if p['ClassName']=='WedgePart':unit=[(x,y,z) for x in [-.5,.5] for y,z in [(-.5,-.5),(-.5,.5),(.5,.5)]]
 else:unit=[(x,y,z) for x in [-.5,.5] for y in [-.5,.5] for z in [-.5,.5]]
 return [[f['CFrame'][j]+sum(m[j*3+i]*q[i]*f['Size'][i] for i in range(3)) for j in range(3)] for q in unit]
def sub(a,b):return [x-y for x,y in zip(a,b)]
def dot(a,b):return sum(x*y for x,y in zip(a,b))
def norm(a):return [v/math.sqrt(dot(a,a)) for v in a]
def cross(a,b):return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]
measured=[]
for i,stage in enumerate(config['stages']):
 hand=[];all_points=[];k=stage['scale'];h=stage['thumbHeight']*.9
 for p in thumb['Children']:
  level=p['Children'][-1]['Properties']['Value']
  if level not in stage['groups']:continue
  scale=1 if level==0 else k
  points=[[origin[j]+(.486 if j==1 else 0)+(q[j]-origin[j]-(.486 if j==1 else 0))*scale for j in range(3)] for q in vertex_points(p)]
  all_points+=points
  if level>0:hand+=points
 bottom=min(q[1] for q in hand);top=max(q[1] for q in hand)
 assert abs(bottom-(origin[1]+.486))<1e-6,'hand is grounded on the fixed plinth'
 measured.append(top-bottom)
 eye=[origin[j]+[14,h*.88,19][j]*k for j in range(3)]
 target=[origin[j]+[0,h*.45,0][j]*k for j in range(3)]
 forward=norm(sub(target,eye));right=norm(cross(forward,[0,1,0]));up=cross(right,forward)
 for q in all_points:
  d=sub(q,eye);depth=dot(d,forward)
  assert depth>0
  assert abs(dot(d,right)/(depth*math.tan(math.radians(17))*160/190))<.94,'portrait horizontal clipping'
  assert abs(dot(d,up)/(depth*math.tan(math.radians(17))))<.94,'portrait vertical clipping'
assert all(b>a for a,b in zip(measured,measured[1:])) and measured[-1]/measured[0]>=4
print(f'PASS: hand height {measured[0]:.2f} -> {measured[-1]:.2f} studs ({measured[-1]/measured[0]:.2f}x); all 11 hands grounded, portrait frame clear')
