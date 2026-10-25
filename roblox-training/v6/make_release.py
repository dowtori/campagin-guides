"""Package the already-built v6.9 place and its exact editable sources."""
from pathlib import Path
import hashlib,json,zipfile
ROOT=Path(__file__).resolve().parent
VERSION='6.9'
BINARY='SIRIAI_Recruiter_Island_v6_9.rbxl'
ZIP='SIRIAI_Recruiter_Island_v6_9_Source.zip'
place=ROOT/'downloads'/BINARY
assert place.read_bytes().startswith(b'<roblox!')
with zipfile.ZipFile(ROOT/'downloads'/ZIP,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
 for p in sorted(ROOT.rglob('*')):
  if not p.is_file():continue
  relative=p.relative_to(ROOT)
  if '__pycache__' in relative.parts or any(x.startswith('native-') for x in relative.parts):continue
  if p.suffix in {'.pyc','.rbxlx','.zip'} or p.name=='release.json':continue
  if relative.parts[0]=='downloads' and p.name!=BINARY:continue
  archive.write(p,Path('SIRIAI_Recruiter_Island_v6_9')/relative)
with zipfile.ZipFile(ROOT/'downloads'/ZIP) as archive:
 assert archive.testzip() is None
 assert archive.read('SIRIAI_Recruiter_Island_v6_9/downloads/'+BINARY)==place.read_bytes()
release={'version':VERSION,'date':'2026-10-26','status':'review-build','verification':{
 'chapterMenu':'seven native icon tiles; grouped number/title; 44–54px completion stamps; direct entry and replay; three-size native-property render checks; reference screenshot inspected, game not directly played',
 'chapterProgress':'arbitrary order does not fabricate skipped completion; unfinished drafts preserved; replay does not duplicate example payout',
 'copyAudit':'removed visible game scores, duplicate arrival/completion notices, repeated setup and challenge instructions; retained campaign conditions, actionable errors and actual compensation',
 'pierSculpture':'original solid thumbs-up; old pier logo removed; front/side geometry preview inspected; center path and water steps clear',
 'setupFlow':'progressive original-asset previews, self-confirmed understanding, two completion paths; opening guide does not advance',
 'guideHandoff':'native instructions with web/email anchors; no external URLs or browser API calls in native setup UI',
 'coreFlow':'seven phases at three forward stops; ordinary reply and separate selection notice',
 'advancedGames':'three optional world-space games; explicit start, server-owned 30s scout deadline, untimed NPC answers; immediate retry, stale attempt and outside-room rejection',
 'advancedRewards':'100 first-clear game points per challenge; three clears unlock king; independent of compensation example; no replay farming',
 'rewardEvolution':'11 plain extruded hand silhouettes; no segmented fingers, face or costumes; fixed pedestal and exaggerated growth; 160x190 model preview',
 'advancedChecks':'exported engine/session, client, server and reward adapter checks; compact room bounds and world-panel aspect ratios checked',
 'optionalAppendix':'ten completion-only read-only topics; no new mandatory stages or tests',
 'requiredRoute':'133 studs to final arrival; no obstruction in sampled avatar corridor of exported geometry',
 'phoneInput':'no click activation handler; deliberate equip, P and explicit button only',
 'resumeAndTravel':'passed exported server/client callback adapters, current target and revision enforced',
 'nativeClientAndServerCallbacks':'passed desktop and touch adapters, full campaign and partial task resume',
 'nativeWaterServer':'136 API/compatibility/failure/rescue checks; preview hidden only after native water succeeds',
 'editorWater':'20 serialized noncolliding water surface tiles at sea level -2; 2400x2800 coverage; verified in exported place, geometry and web comparison, not in Studio',
 'workflowAudit':'anonymized operational chat compared in workflow-audit-v6.9.md; campaign-specific intake and approval ranges; actual followers, assigned targets, contact history, completion reports and final selection distinction',
 'revisedScenarios':'254 checks across all eight scenario variants and every answer; correct/wrong outcomes, timing, immediate retry and compensation isolation',
 'terrainAndGeometry':'passed original geometry bounds, clear paths, continuous seabed',
 'visualCriteria':'pre-implementation water/workflow criteria and results in design-review-v6.9.md; desktop/mobile native-property renders of revised lessons, web editor-geometry comparison and fee room inspected; Roblox engine rendering remains unverified',
 'webViewsAndMobilePage':'desktop world views inspected with browser; no new real-device play verification',
 'robloxStudioPlay':'not tested; Studio unavailable'},'files':{}}
for name in [BINARY,ZIP]:
 blob=(ROOT/'downloads'/name).read_bytes();release['files'][name]={'bytes':len(blob),'sha256':hashlib.sha256(blob).hexdigest()}
(ROOT/'release.json').write_text(json.dumps(release,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(release['files'],indent=2))
