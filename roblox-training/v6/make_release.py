"""Package the already-built v6.6 place and its exact editable sources."""
from pathlib import Path
import hashlib,json,zipfile
ROOT=Path(__file__).resolve().parent
VERSION='6.6'
BINARY='SIRIAI_Recruiter_Island_v6_6.rbxl'
ZIP='SIRIAI_Recruiter_Island_v6_6_Source.zip'
place=ROOT/'downloads'/BINARY
assert place.read_bytes().startswith(b'<roblox!')
with zipfile.ZipFile(ROOT/'downloads'/ZIP,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
 for p in sorted(ROOT.rglob('*')):
  if not p.is_file():continue
  relative=p.relative_to(ROOT)
  if '__pycache__' in relative.parts or any(x.startswith('native-') for x in relative.parts):continue
  if p.suffix in {'.pyc','.rbxlx','.zip'} or p.name=='release.json':continue
  if relative.parts[0]=='downloads' and p.name!=BINARY:continue
  archive.write(p,Path('SIRIAI_Recruiter_Island_v6_6')/relative)
with zipfile.ZipFile(ROOT/'downloads'/ZIP) as archive:
 assert archive.testzip() is None
 assert archive.read('SIRIAI_Recruiter_Island_v6_6/downloads/'+BINARY)==place.read_bytes()
release={'version':VERSION,'date':'2026-10-25','status':'review-build','verification':{
 'chapterMenu':'seven illustrated native tiles; direct teleport/start, progress and replay; responsive menu; reference screenshots inspected, game not directly played',
 'chapterProgress':'arbitrary order does not fabricate skipped completion; unfinished drafts preserved; replay does not duplicate example payout',
 'copyAudit':'removed repeated setup summaries, redundant send instructions, phone travel duplication and implementation explanations',
 'pierSculpture':'original solid thumbs-up; old pier logo removed; front/side geometry preview inspected; center path and water steps clear',
 'setupFlow':'progressive original-asset previews, self-confirmed understanding, two completion paths; opening guide does not advance',
 'guideHandoff':'native instructions with web/email anchors; no external URLs or browser API calls in native setup UI',
 'coreFlow':'seven phases at three forward stops; ordinary reply and separate selection notice',
 'advancedGames':'three optional world-space games; explicit start, server-owned 30s scout deadline, untimed NPC answers; immediate retry, stale attempt and outside-room rejection',
 'advancedRewards':'100 first-clear game points per challenge; three clears unlock king; independent of compensation example; no replay farming',
 'rewardEvolution':'11 stages with explicit non-accumulating accessory groups; 160x190 model preview; king silhouette keeps thumb clear of crown',
 'advancedChecks':'exported engine/session, client, server and reward adapter checks; compact room bounds and world-panel aspect ratios checked',
 'optionalAppendix':'completion-only read-only reference remains alongside the optional minigames',
 'requiredRoute':'133 studs to final arrival; no obstruction in sampled avatar corridor of exported geometry',
 'phoneInput':'no click activation handler; deliberate equip, P and explicit button only',
 'resumeAndTravel':'passed exported server/client callback adapters, current target and revision enforced',
 'nativeClientAndServerCallbacks':'passed desktop and touch adapters, full campaign and partial task resume',
 'nativeWaterServer':'passed API/compatibility/failure/rescue adapters',
 'terrainAndGeometry':'passed original geometry bounds, clear paths, continuous seabed',
 'visualCriteria':'pre-implementation criteria and results in design-review-v6.6.md; desktop world preview and native UI property-tree adapter inspected; final engine/device checks remain open',
 'webViewsAndMobilePage':'desktop world views inspected with browser; no new real-device play verification',
 'robloxStudioPlay':'not tested; Studio unavailable'},'files':{}}
for name in [BINARY,ZIP]:
 blob=(ROOT/'downloads'/name).read_bytes();release['files'][name]={'bytes':len(blob),'sha256':hashlib.sha256(blob).hexdigest()}
(ROOT/'release.json').write_text(json.dumps(release,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(release['files'],indent=2))
