export function illustration(key,assets){
 const a=assets[key]||assets.empty;
 const shapes=a.shapes.map(s=>{const x=s.x*400,y=s.y*300,w=s.w*400,h=s.h*300;return `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${Math.min(w,h)*Math.min(s.r||0,.5)}" fill="#${s.color}" transform="rotate(${s.rot||0} ${x+w/2} ${y+h/2})"/>`}).join('');
 return `<svg viewBox="0 0 400 300" preserveAspectRatio="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="직접 제작한 ${key} 일러스트"><rect width="400" height="300" fill="#${a.bg}"/>${shapes}</svg>`;
}
