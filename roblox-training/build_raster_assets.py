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
    pal=q.getpalette();pal += [0]*(768-len(pal));raw=list(q.getdata());indices=[v+1 if a>100 else 0 for v,a in zip(raw,alpha.getdata())]
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

assets={
 'sky':encode('assets/world-sky.png',(256,144),48),
 'skySides':encode('assets/world-sky.png',(256,144),48,[0,0,1254,941]),
 'logo':encode('assets/siriai-symbol.png',(96,96),8),
 'logoWhite':encode('assets/siriai-symbol-white.png',(96,96),8),
 'wordmark':encode('assets/siriai-wordmark-white.png',(240,70),8),
 'settings':encode('assets/ig-lead-saver-settings.png',(280,402),48),
 'options':encode('assets/chrome-extension-options.png',(280,465),48),
 'profile':encode('assets/siriai-profile-gradient.jpg',(100,125),24),
}
with Image.open(ROOT/'assets/booth-art-atlas.png') as im:w,h=im.size
for i in range(6):
    x=i%3;y=i//3;crop=[round(x*w/3),round(y*h/2),round((x+1)*w/3),round((y+1)*h/2)]
    assets[f'booth{i+1}']=encode('assets/booth-art-atlas.png',(100,100),48,crop)
# Lower-resolution merged rectangles are embedded as an always-visible pixel-art fallback.
for key,data in assets.items():
    if key.startswith('sky'):size,colors=(128,72),32
    elif key.startswith('booth'):size,colors=(64,64),32
    elif key in ('settings','options'):size,colors=(140,round(data['height']/data['width']*140)),32
    else:size,colors=(data['width'],data['height']),8 if key!='profile' else 24
    fallback=encode(data['file'],size,colors,data.get('crop'))
    data['rects']=fallback['rects'];data['fallbackPalette']=fallback['palette'];data['fallbackWidth']=size[0];data['fallbackHeight']=size[1]
(ROOT/'raster-data.json').write_bytes(json.dumps(assets,ensure_ascii=False,separators=(',',':')).encode('utf-8'))
(ROOT/'raster-assets.json').write_bytes(json.dumps({k:{n:v for n,v in a.items() if n not in ('runs','rects')} for k,a in assets.items()},ensure_ascii=False).encode('utf-8'))
print('Embedded real image data:',{k:len(v['rects']) for k,v in assets.items()})


folder=ROOT/'src/shared/RasterData';folder.mkdir(exist_ok=True)
for key,data in assets.items():(folder/(key+'.json')).write_bytes(json.dumps(data,ensure_ascii=False,separators=(',',':')).encode('utf-8'))
allowed=','.join(key+'=true' for key in assets)
loader="local folder=script.Parent:WaitForChild('RasterData')\nlocal allowed={"+allowed+"}\nreturn setmetatable({},{__index=function(self,key)\n if not allowed[key]then return nil end\n local data=require(folder:WaitForChild(key))\n rawset(self,key,data)\n return data\nend})\n"
(ROOT/'src/shared/RasterAssets.lua').write_bytes(loader.encode('utf-8'))
legacy=ROOT/'src/shared/RasterAssets.json'
if legacy.exists():legacy.unlink()
