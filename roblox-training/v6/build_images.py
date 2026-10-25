"""Embed approved company images and generated artwork as paletted pixels and merged rectangles.
This is asset encoding for Roblox, not a recreation of the artwork using placeholder shapes.
"""
from pathlib import Path
from PIL import Image,ImageOps
import json
ROOT=Path(__file__).resolve().parent

def encode(path,size,colors=48,crop=None):
    src=Image.open(ROOT/path).convert('RGBA');original_size=list(src.size)
    if crop:src=src.crop(crop)
    if 'wordmark' in str(path):
        fitted=ImageOps.contain(src,size,Image.Resampling.LANCZOS);canvas=Image.new('RGBA',size,(0,0,0,0));canvas.paste(fitted,((size[0]-fitted.width)//2,(size[1]-fitted.height)//2));src=canvas
    else:src=src.resize(size,Image.Resampling.LANCZOS)
    alpha=src.getchannel('A')
    q=src.convert('RGB').quantize(colors=colors,dither=Image.Dither.NONE)
    palette=['00000000']+['%02X%02X%02XFF'%tuple(pal[i*3:i*3+3]) for i in range(colors)]
    rle=[]
    for index in indices:
        if rle and rle[-1][0]==index:rle[-1][1]+=1
        else:rle.append([index,1])
    rects=[];active={}
    for y in range(size[1]):
        current={};x=0
        while x<size[0]:
            c=indices[y*size[0]+x];end=x+1
            while end<size[0] and indices[y*size[0]+end]==c:end+=1
            if c:
                key=(x,end-x,c)
                if key in active:
                    rect=active[key];rect[3]+=1
                else:
                    rect=[x,y,end-x,1,c];rects.append(rect)
                current[key]=rect
            x=end
        active=current
    return {'width':size[0],'height':size[1],'palette':palette,'runs':rle,'rects':rects,'file':str(path).replace('\\','/'),'crop':crop,'sourceSize':original_size}

assets={'logo':encode('assets/siriai-symbol.png',(192,192),8),'logoWhite':encode('assets/siriai-symbol-white.png',(192,192),8),'wordmark':encode('assets/siriai-wordmark-white.png',(480,140),8)}
for i in range(1,7):assets[f'brand{i}']=encode(f'assets/brand-profile-{i}.jpg',(240,300),48)
for i in range(1,10):
    path=ROOT/f'assets/creator-{i}.jpg'
    if path.exists():assets[f'creator{i}']=encode(f'assets/creator-{i}.jpg',(192,192),48)
for key,data in assets.items():
    size=(128,128) if key.startswith('creator') else (144,180) if key.startswith('brand') else (data['width'],data['height'])
    fallback=encode(data['file'],size,32 if key.startswith(('brand','creator')) else 8)
    data.update(rects=fallback['rects'],fallbackPalette=fallback['palette'],fallbackWidth=size[0],fallbackHeight=size[1])
(ROOT/'raster-data.json').write_text(json.dumps(assets,separators=(',',':')),encoding='utf-8')
folder=ROOT/'src/shared/RasterData';folder.mkdir(exist_ok=True)
for key,data in assets.items():(folder/(key+'.json')).write_text(json.dumps(data,separators=(',',':')),encoding='utf-8')
allowed=','.join(key+'=true' for key in assets)
(ROOT/'src/shared/RasterAssets.lua').write_text("local folder=script.Parent:WaitForChild('RasterData')\nlocal allowed={"+allowed+"}\nreturn setmetatable({},{__index=function(self,key)if not allowed[key]then return nil end local d=require(folder:WaitForChild(key));rawset(self,key,d);return d end})\n",encoding='utf-8')
print('Encoded original brand assets:',len(assets))

(ROOT/'raster-assets.json').write_text(json.dumps({k:{n:a[n] for n in ['file','width','height','crop','sourceSize'] if n in a} for k,a in assets.items()}),encoding='utf-8')
