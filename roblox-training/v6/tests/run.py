from pathlib import Path
import argparse,re
import xml.etree.ElementTree as ET,subprocess,tempfile,shutil,json
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--luau',required=True);parser.add_argument('--test',action='append');args=parser.parse_args()
xml=ET.parse(ROOT/'downloads/SIRIAI_Recruiter_Island_v6_11.rbxlx').getroot()
items=list(xml.iter('Item'));modules={}
def name(it):return it.find("Properties/string[@name='Name']").text
def source(it):return it.find("Properties/*[@name='Source']").text
for it in items:
 if it.attrib['class']=='ModuleScript':modules[name(it)]=source(it)
assert sum(i.attrib['class']=='ProximityPrompt' for i in items)==3
assert sum(i.attrib['class']=='Humanoid' for i in items)==7
assert sum(i.attrib['class']=='Script' for i in items)==2
assert sum(i.attrib['class']=='LocalScript' for i in items)==3
ocean=[i for i in items if name(i)=='Ocean water preview']
assert len(ocean)==20,'editor water must exist in actual exported place'
for i in ocean:
 props=i.find('Properties')
 for key in ['CanCollide','CanTouch','CanQuery']:
  assert props.find("bool[@name='"+key+"']").text=='false'
 assert float(props.find("float[@name='Transparency']").text)<.4
 assert abs(float(props.find("CoordinateFrame[@name='CFrame']/Y").text)+2.06)<.001
print('PASS: saved editor water exists in exported place with noncolliding properties')
with tempfile.TemporaryDirectory(prefix='native-',dir=ROOT/'tests') as path:
 p=Path(path)
 for key,value in modules.items():(p/(key+'.lua')).write_text(value,encoding='utf-8')
 for f in (ROOT/'tests').glob('*.lua'):shutil.copy2(f,p/f.name)
 clientPrefix="local H=require('./ClientHarness')\nlocal game,workspace,Instance,Vector2,Vector3,UDim,UDim2,Color3,Enum,task=H.game,H.workspace,H.Instance,H.Vector2,H.Vector3,H.UDim,H.UDim2,H.Color3,H.Enum,H.task\nlocal script={Parent={WaitForChild=function(_,name)return './'..name end}}\n"
 (p/'CampusClient.lua').write_text(clientPrefix+modules['CampusClient'],encoding='utf-8')
 (p/'AdvancedClient.lua').write_text(clientPrefix+modules['AdvancedClient'],encoding='utf-8')
 (p/'RewardClient.lua').write_text(clientPrefix+"local CFrame=H.CFrame;local os={clock=function()return H.now end}\n"+modules['RewardClient'],encoding='utf-8')
 model=json.loads((ROOT/'map/TrainingMap.model.json').read_text(encoding='utf-8'))
 def walk(n):
  yield n
  for c in n.get('Children',[]):yield from walk(c)
 thumb=next(n for n in walk(model) if n.get('Name')=='PierThumbsUp')
 fixture=[]
 for item in thumb['Children']:
  f=item['Properties'];level=item['Children'][-1]['Properties']['Value']
  vec=lambda v:'{'+','.join(str(x) for x in v)+'}'
  fixture.append('{name='+json.dumps(item['Name'])+',position='+vec(f['CFrame'][:3])+',size='+vec(f['Size'])+',color='+vec(f['Color'])+',level='+str(level)+'}')
 (p/'ThumbFixture.lua').write_text('return {'+','.join(fixture)+'}',encoding='utf-8')

 rasterPrefix="local H=require('./ClientHarness')\nlocal game,Instance,Vector2,UDim2,Color3,Enum=H.game,H.Instance,H.Vector2,H.UDim2,H.Color3,H.Enum\n"
 (p/'RasterRenderer.lua').write_text(rasterPrefix+modules['RasterRenderer'].replace("require(script.Parent:WaitForChild('RasterAssets'))","require('./RasterAssets')"),encoding='utf-8')
 (p/'RasterAssets.lua').write_text("local script={Parent={WaitForChild=function()return {WaitForChild=function(_,key)return './'..key end}end}}\n"+modules['RasterAssets'],encoding='utf-8')
 water=next(source(i) for i in items if i.attrib['class']=='Script' and name(i)=='MeadowWater')
 header="local H=require('./WaterHarness')\nlocal game,workspace,Vector3,CFrame,Region3,Color3,Enum,task,warn=H.game,H.workspace,H.Vector3,H.CFrame,H.Region3,H.Color3,H.Enum,H.task,H.warn\nlocal script={Parent={WaitForChild=function(_,name)return './'..name end}}\nreturn function()\n"
 (p/'WaterServer.lua').write_text(header+water+'\nend',encoding='utf-8')
 server=next(source(i) for i in items if i.attrib['class']=='Script' and name(i)=='Campus')
 server=re.sub(r"require\(Shared:WaitForChild\('([^']+)'\)\)",lambda m:"require('./"+m[1]+"')",server)
 serverHeader="local H=require('./ServerHarness')\nlocal game,workspace,Instance,Vector3,CFrame,UDim2,Color3,Enum,TweenInfo,task=H.game,H.workspace,H.Instance,H.Vector3,H.CFrame,H.UDim2,H.Color3,H.Enum,H.TweenInfo,H.task\n"
 (p/'CampusServer.lua').write_text(serverHeader+server+'\nreturn true',encoding='utf-8')
 luau=Path(args.luau).resolve()
 for test in args.test or ['advanced.spec.lua','workflow.spec.lua','advanced-client.spec.lua','advanced-server.spec.lua','reward-client.spec.lua','case.spec.lua','client.spec.lua','dialog-layout.spec.lua','setup.spec.lua','chapter-client.spec.lua','mobile.spec.lua','server.spec.lua','chapters.spec.lua','coast.spec.lua','water.spec.lua']:subprocess.run([str(luau),str(p/test)],cwd=p,check=True)
print('PASS: actual Rojo-exported module sources, 7 humanoid NPCs, 3 prompts, 2 server scripts and 3 client scripts')
print('Not verified: actual Roblox engine rendering, physics, UI text layout and multiplayer play sessions. Studio is not installed on this host.')
