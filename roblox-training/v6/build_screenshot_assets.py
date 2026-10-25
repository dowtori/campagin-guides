from pathlib import Path
from PIL import Image
import json
r=Path(__file__).resolve().parent
assets=json.loads((r/'raster-data.json').read_text(encoding='utf-8'))
def encode(path,colors=256):
 im=Image.open(r/path).convert('RGB');w,h=im.size;q=im.quantize(colors=colors,dither=Image.Dither.NONE);pal=q.getpalette();indices=list(q.getdata());palette=['%02X%02X%02XFF'%tuple(pal[i*3:i*3+3]) for i in range(colors)];runs=[]
 for v in indices:
  if runs and runs[-1][0]==v:runs[-1][1]+=1
  else:runs.append([v,1])
 # Higher fidelity fallback for screenshots than the old 128px illustrations.
 f=q if 'sheet' in path else im.resize((round(w*.65),round(h*.65)),Image.Resampling.LANCZOS).quantize(colors=96,dither=Image.Dither.NONE)
 fw,fh=f.size;fp=f.getpalette();fi=list(f.getdata());rects=[];active={}
 for y in range(fh):
  cur={};x=0
  while x<fw:
   c=fi[y*fw+x];end=x+1
   while end<fw and fi[y*fw+end]==c:end+=1
   key=(x,end-x,c)
   if key in active:rect=active[key];rect[3]+=1
   else:rect=[x,y,end-x,1,c];rects.append(rect)
   cur[key]=rect;x=end
  active=cur
 return dict(width=w,height=h,palette=palette,runs=runs,rects=rects,file=path,sourceSize=[w,h],fallbackWidth=fw,fallbackHeight=fh,fallbackPalette=['%02X%02X%02XFF'%tuple(fp[i*3:i*3+3]) for i in range(len(fp)//3)])
for key,path in [('oddtypeTagged','assets/oddtype-tagged-top-two.png'),('sheetStatus','assets/sheet-status-capture.png')]+[(f'oddtypePost{i}',f'assets/oddtype-post-{i}.png') for i in range(1,9)]:
 a=encode(path);assets[key]=a;(r/f'src/shared/RasterData/{key}.json').write_text(json.dumps(a,separators=(',',':')),encoding='utf-8')
(r/'raster-data.json').write_text(json.dumps(assets,separators=(',',':')),encoding='utf-8')
(r/'raster-assets.json').write_text(json.dumps({k:{n:a[n] for n in ['file','width','height','crop','sourceSize'] if n in a} for k,a in assets.items()}),encoding='utf-8')
allowed=','.join(key+'=true' for key in assets)
(r/'src/shared/RasterAssets.lua').write_text("local folder=script.Parent:WaitForChild('RasterData')\nlocal allowed={"+allowed+"}\nreturn setmetatable({},{__index=function(self,key)if not allowed[key]then return nil end local d=require(folder:WaitForChild(key));rawset(self,key,d);return d end})\n",encoding='utf-8')
