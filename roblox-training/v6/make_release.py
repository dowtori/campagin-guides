"""Package the already-built v6.1 place and its exact editable sources."""
from pathlib import Path
import hashlib,json,zipfile
ROOT=Path(__file__).resolve().parent
VERSION='6.1.0'
BINARY='SIRIAI_Recruiter_Island_v6_1.rbxl'
ZIP='SIRIAI_Recruiter_Island_v6_1_Source.zip'
place=ROOT/'downloads'/BINARY
assert place.read_bytes().startswith(b'<roblox!')
with zipfile.ZipFile(ROOT/'downloads'/ZIP,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
 for p in sorted(ROOT.rglob('*')):
  if not p.is_file():continue
  relative=p.relative_to(ROOT)
  if '__pycache__' in relative.parts or any(x.startswith('native-') for x in relative.parts):continue
  if p.suffix in {'.pyc','.rbxlx','.zip'} or p.name=='release.json':continue
  if relative.parts[0]=='downloads' and p.name!=BINARY:continue
  archive.write(p,Path('SIRIAI_Recruiter_Island_v6_1')/relative)
with zipfile.ZipFile(ROOT/'downloads'/ZIP) as archive:
 assert archive.testzip() is None
 assert archive.read('SIRIAI_Recruiter_Island_v6_1/downloads/'+BINARY)==place.read_bytes()
release={'version':VERSION,'date':'2026-10-25','status':'review-build','verification':{
 'phoneInput':'no click activation handler; deliberate equip, P and explicit button only',
 'resumeAndTravel':'passed exported server/client callback adapters, current target and revision enforced',
 'nativeClientAndServerCallbacks':'passed desktop and touch adapters, full campaign and partial task resume',
 'nativeWaterServer':'passed API/compatibility/failure/rescue adapters',
 'terrainAndGeometry':'passed original geometry bounds, clear paths, continuous seabed',
 'webViewsAndMobilePage':'passed local browser checks',
 'robloxStudioPlay':'not tested; Studio unavailable'},'files':{}}
for name in [BINARY,ZIP]:
 blob=(ROOT/'downloads'/name).read_bytes();release['files'][name]={'bytes':len(blob),'sha256':hashlib.sha256(blob).hexdigest()}
(ROOT/'release.json').write_text(json.dumps(release,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(release['files'],indent=2))
