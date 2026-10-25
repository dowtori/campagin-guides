from pathlib import Path
import argparse
import xml.etree.ElementTree as ET,subprocess,tempfile,shutil,json
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--luau',required=True);args=parser.parse_args()
xml=ET.parse(ROOT/'downloads/SIRIAI_Recruiter_Island_v6.rbxlx').getroot()
items=list(xml.iter('Item'));modules={}
def name(it):return it.find("Properties/string[@name='Name']").text
def source(it):return it.find("Properties/*[@name='Source']").text
for it in items:
 if it.attrib['class']=='ModuleScript':modules[name(it)]=source(it)
assert sum(i.attrib['class']=='ProximityPrompt' for i in items)==8
assert sum(i.attrib['class']=='Humanoid' for i in items)==4
assert sum(i.attrib['class']=='Script' for i in items)==2
assert sum(i.attrib['class']=='LocalScript' for i in items)==3
with tempfile.TemporaryDirectory(prefix='native-',dir=ROOT/'tests') as path:
 p=Path(path)
 for key,value in modules.items():(p/(key+'.lua')).write_text(value,encoding='utf-8')
 for f in (ROOT/'tests').glob('*.lua'):shutil.copy2(f,p/f.name)
 clientPrefix="local H=require('./ClientHarness')\nlocal game,workspace,Instance,Vector2,Vector3,UDim,UDim2,Color3,Enum,task=H.game,H.workspace,H.Instance,H.Vector2,H.Vector3,H.UDim,H.UDim2,H.Color3,H.Enum,H.task\nlocal script={Parent={WaitForChild=function(_,name)return './'..name end}}\n"
 (p/'CampusClient.lua').write_text(clientPrefix+modules['CampusClient'],encoding='utf-8')
 rasterPrefix="local H=require('./ClientHarness')\nlocal game,Instance,Vector2,UDim2,Color3,Enum=H.game,H.Instance,H.Vector2,H.UDim2,H.Color3,H.Enum\n"
 (p/'RasterRenderer.lua').write_text(rasterPrefix+modules['RasterRenderer'].replace("require(script.Parent:WaitForChild('RasterAssets'))","require('./RasterAssets')"),encoding='utf-8')
 (p/'RasterAssets.lua').write_text("local script={Parent={WaitForChild=function()return {WaitForChild=function(_,key)return './'..key end}end}}\n"+modules['RasterAssets'],encoding='utf-8')
 water=next(source(i) for i in items if i.attrib['class']=='Script' and name(i)=='MeadowWater')
 header="local H=require('./WaterHarness')\nlocal game,workspace,Vector3,CFrame,Region3,Color3,Enum,task,warn=H.game,H.workspace,H.Vector3,H.CFrame,H.Region3,H.Color3,H.Enum,H.task,H.warn\nlocal script={Parent={WaitForChild=function(_,name)return './'..name end}}\nreturn function()\n"
 (p/'WaterServer.lua').write_text(header+water+'\nend',encoding='utf-8')
 server=next(source(i) for i in items if i.attrib['class']=='Script' and name(i)=='Campus')
 server=server.replace("require(Shared:WaitForChild('CaseData'))","require('./CaseData')").replace("require(Shared:WaitForChild('CaseEngine'))","require('./CaseEngine')")
 serverHeader="local H=require('./ServerHarness')\nlocal game,workspace,Instance,Vector3,CFrame,UDim2,Color3,Enum,TweenInfo,task=H.game,H.workspace,H.Instance,H.Vector3,H.CFrame,H.UDim2,H.Color3,H.Enum,H.TweenInfo,H.task\n"
 (p/'CampusServer.lua').write_text(serverHeader+server+'\nreturn true',encoding='utf-8')
 luau=Path(args.luau).resolve()
 for test in ['case.spec.lua','client.spec.lua','mobile.spec.lua','server.spec.lua','coast.spec.lua','water.spec.lua']:subprocess.run([str(luau),str(p/test)],cwd=p,check=True)
print('PASS: actual Rojo-exported module sources, 4 humanoid NPCs, 8 prompts, 2 server scripts and 3 client scripts')
print('Not verified: actual Roblox engine rendering, physics, UI text layout and multiplayer play sessions. Studio is not installed on this host.')
