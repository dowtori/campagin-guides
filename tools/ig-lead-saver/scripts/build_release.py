"""Build runtime-only Chrome Web Store ZIP; no account access or network calls."""
from pathlib import Path
import argparse, hashlib, json, re, zipfile
ROOT=Path(__file__).resolve().parents[1]
ITEM_ID='ghakpcjppjjlcmfcalfklciejlbilonn'
def version(v):
 if not re.fullmatch(r'(0|[1-9]\d*)(\.(0|[1-9]\d*)){0,3}',v):raise ValueError('Invalid Chrome version')
 p=[int(n) for n in v.split('.')]
 if not any(p) or any(n>65535 for n in p):raise ValueError('Invalid Chrome version')
 return tuple(p+[0]*(4-len(p)))
def build(output):
 manifest=json.loads((ROOT/'manifest.json').read_text(encoding='utf-8-sig'))
 base=json.loads((ROOT/'releases/baseline-1.4.0.json').read_text(encoding='utf-8-sig'))
 assert version(manifest['version'])>version(base['version']), 'New version must exceed baseline'
 for key in ['permissions','host_permissions','optional_permissions','optional_host_permissions']:
  assert sorted(manifest.get(key,[]))==sorted(base.get(key,[])), 'Unexpected permission change: '+key
 assert {s for c in manifest['content_scripts'] for s in c['matches']}=={s for c in base['content_scripts'] for s in c['matches']},'Unexpected site scope change'
 files=[ROOT/'manifest.json']+sorted((ROOT/'src').rglob('*'))+sorted((ROOT/'icons').rglob('*'))
 files=[p for p in files if p.is_file()]
 names={p.relative_to(ROOT).as_posix() for p in files}
 refs=[manifest['background']['service_worker'],manifest['options_page'],manifest['action']['default_popup'],*manifest['icons'].values(),*manifest['action']['default_icon'].values()]
 for script in manifest['content_scripts']:refs+=script.get('js',[])+script.get('css',[])
 for ref in refs:assert ref in names,'Missing packaged resource: '+ref
 for p in files:
  if p.suffix=='.html':
   for ref in re.findall(r'(?:src|href)=[\"\x27]([^\"\x27]+)',p.read_text(encoding='utf-8-sig')):
    if ref.startswith(('https:','http:','#','data:')):continue
    target=(p.parent/ref).resolve().relative_to(ROOT.resolve()).as_posix()
    assert target in names,'Missing HTML resource: '+target
 assert 'manifest.json' in names and not any(n.startswith(('tests/','scripts/','apps-script/','releases/')) for n in names)
 output=output.resolve();output.mkdir(parents=True,exist_ok=True)
 package=output/f"IG-Lead-Saver-v{manifest['version']}-webstore.zip"
 with zipfile.ZipFile(package,'w',zipfile.ZIP_DEFLATED) as z:
  for p in files:
   info=zipfile.ZipInfo(p.relative_to(ROOT).as_posix(),date_time=(2026,1,1,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED
   z.writestr(info,p.read_bytes())
 with zipfile.ZipFile(package) as z:
  assert z.testzip() is None and 'manifest.json' in z.namelist()
  assert json.loads(z.read('manifest.json'))['version']==manifest['version']
 audit={'itemId':ITEM_ID,'baselineVersion':base['version'],'version':manifest['version'],'runtimeFiles':len(files),'manifestAtZipRoot':True,'addedPermissions':[],
 'sha256':hashlib.sha256(package.read_bytes()).hexdigest(),'storeSubmitted':False,'storePublished':False,'liveAccountUpgradeVerified':False}
 (output/f"IG-Lead-Saver-v{manifest['version']}-release-audit.json").write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 backend=output/f"IG-Lead-Saver-v{manifest['version']}-backend.zip"
 with zipfile.ZipFile(backend,'w',zipfile.ZIP_DEFLATED) as z:
  z.write(ROOT/'apps-script/Code.gs','Code.gs')
  z.write(ROOT/'releases/BACKEND_UPDATE.md','BACKEND_UPDATE.md')
 return audit
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path,required=True);args=parser.parse_args();print(json.dumps(build(args.output),ensure_ascii=False))
