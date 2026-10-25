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
  if level not in config['stages'][stage]['groups']:continue
  center=[origin[i]+(f['CFrame'][i]-origin[i])*scale for i in range(3)]
  m=f['CFrame'][3:];ext=[sum(abs(m[j*3+i])*f['Size'][i]*scale/2 for i in range(3)) for j in range(3)]
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
for stage in config['stages']:
 assert len([g for g in stage['groups'] if g>3])<=3
 assert len([g for g in stage['groups'] if 1<=g<=3])==1
assert (r/'src/shared/AdvancedClient.lua').read_text(encoding='utf-8').count("make('ScreenGui'")==0
server=(r/'src/server/Campus.server.lua').read_text(encoding='utf-8')
arrival_z=float(re.search(r'Vector3.new\(-17,5,(-\d+)\)',server)[1])
deck=next(n for n in nodes if n.get('Name')=='Sunset lookout deck')['Properties']
assert abs(-17-deck['CFrame'][0])+2<deck['Size'][0]/2
assert abs(arrival_z-deck['CFrame'][2])+2<deck['Size'][2]/2,'reward arrival has solid deck underneath'
print('PASS: eleven growing sculptures within the widened pier, clear central path; world panels clear NPCs/each other')
