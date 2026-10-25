import {illustration} from './visual-art.js';
import * as THREE from 'three';
import { OrbitControls } from './vendor/OrbitControls.js';
const viewer=document.querySelector('#viewer');
const loading=document.querySelector('#loading');
const labelRoot=document.querySelector('#mapLabels');
const stationRoot=document.querySelector('#stations');
const reduceMotion=window.matchMedia('(prefers-reduced-motion: reduce)').matches;
try {
  await document.fonts.ready;
  const [parts,missions,artAssets]=await Promise.all([fetch('./scene.json').then(r=>r.json()),fetch('./missions.json').then(r=>r.json()),fetch('./visual-assets.json').then(r=>r.json())]);
  const scene=new THREE.Scene();
  scene.background=new THREE.Color('#dae5e5');
  const renderer=new THREE.WebGLRenderer({antialias:true,alpha:false});
  renderer.setPixelRatio(Math.min(devicePixelRatio,2));
  renderer.shadowMap.enabled=true;
  renderer.shadowMap.type=THREE.PCFSoftShadowMap;
  renderer.outputColorSpace=THREE.SRGBColorSpace;
  renderer.toneMapping=THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure=1.18;
  renderer.domElement.setAttribute('aria-label','시리아이 트레이닝 캠퍼스의 3D 공간 미리보기');
  viewer.prepend(renderer.domElement);
  const camera=new THREE.PerspectiveCamera(38,1,.1,1600);
  const controls=new OrbitControls(camera,renderer.domElement);
  controls.enableDamping=true;
  controls.dampingFactor=.09;
  controls.maxPolarAngle=Math.PI/2.1;
  controls.minDistance=35;
  controls.maxDistance=700;
  controls.target.set(0,2,-44);
  scene.add(new THREE.HemisphereLight(0xffffff,0xabb1b0,2));
  const sun=new THREE.DirectionalLight(0xfff3da,3.2);
  sun.position.set(-100,200,130);
  sun.castShadow=true;
  sun.shadow.mapSize.set(2048,2048);
  Object.assign(sun.shadow.camera,{left:-170,right:170,top:170,bottom:-170,near:10,far:520});
  sun.shadow.bias=-.0004;
  sun.shadow.normalBias=.2;
  sun.target.position.set(0,0,-45);
  scene.add(sun,sun.target);
  const box=new THREE.BoxGeometry(1,1,1);
  const sphere=new THREE.SphereGeometry(.5,18,12);
  const cylinder=new THREE.CylinderGeometry(.5,.5,1,20);
  cylinder.rotateZ(Math.PI/2); // Roblox cylinders are aligned along local X.
  const materials=new Map();
  function material(p) {
    const key=p.color+p.transparency+p.material;
    if(!materials.has(key)) materials.set(key,new THREE.MeshStandardMaterial({color:p.color,roughness:.84,metalness:0,transparent:p.transparency>0,opacity:1-p.transparency,emissive:p.material==='Neon'?p.color:0x000000,emissiveIntensity:p.material==='Neon'?.35:0,depthWrite:p.transparency<.5}));
    return materials.get(key);
  }
  function labelTexture(value,width,height) {
    const canvas=document.createElement('canvas');
    canvas.width=1024;canvas.height=Math.max(160,Math.round(1024*height/width));
    const ctx=canvas.getContext('2d');
    const lines=value.split('\n');
    let fontSize=Math.min(110,canvas.height/(lines.length+1.1));
    for (const line of lines) fontSize=Math.min(fontSize,940/Math.max(1,[...line].reduce((n,c)=>n+(/[\u3131-\uD79D]/.test(c)?1:.58),0)));
    ctx.fillStyle='#ffffff';ctx.textAlign='center';ctx.textBaseline='middle';
    ctx.font=`700 ${fontSize}px Pretendard, sans-serif`;
    const lineHeight=fontSize*1.3;
    lines.forEach((line,i)=>ctx.fillText(line,512,(canvas.height-(lines.length-1)*lineHeight)/2+i*lineHeight));
    const texture=new THREE.CanvasTexture(canvas);texture.colorSpace=THREE.SRGBColorSpace;
    return texture;
  }
  for(const p of parts) {
    const group=new THREE.Group();
    group.position.fromArray(p.position);
    group.rotation.set(...p.rotation.map(v=>v*Math.PI/180),'XYZ');
    const mesh=new THREE.Mesh(p.shape==='Ball'?sphere:p.shape==='Cylinder'?cylinder:box,material(p));
    mesh.scale.fromArray(p.size);
    mesh.castShadow=p.material!=='Neon' && p.transparency<.6;
    mesh.receiveShadow=true;
    group.add(mesh);
    if(p.label) {
      const ink=p.color.toLowerCase()==='#252420'||p.color.toLowerCase()==='#ff234b'||p.name==='Back number';
      const texture=labelTexture(p.label,p.size[0],p.size[1]);
      const plane=new THREE.Mesh(new THREE.PlaneGeometry(p.size[0]*.94,p.size[1]*(p.art ? .22 : .9)),new THREE.MeshBasicMaterial({map:texture,transparent:true,color:ink?0xffffff:0x252420,depthWrite:false}));
      plane.position.z=p.size[2]/2+.025;
      if(p.art)plane.position.y=-p.size[1]*.34;
      group.add(plane);
    }
    if(p.art){
      const texture=new THREE.TextureLoader().load('data:image/svg+xml;charset=utf-8,'+encodeURIComponent(illustration(p.art,artAssets)));
      texture.colorSpace=THREE.SRGBColorSpace;
      const image=new THREE.Mesh(new THREE.PlaneGeometry(p.size[0]*.9,p.size[1]*.65),new THREE.MeshBasicMaterial({map:texture}));
      image.position.set(0,p.size[1]*.12,p.size[2]/2+.03);group.add(image);
    }
    scene.add(group);
  }
  let selected=0,animating=false;
  const goalPosition=new THREE.Vector3(),goalTarget=new THREE.Vector3();
  const pins=[];
  function overview() {
    selected=0;
    const factor=Math.max(1,1.12/(viewer.clientWidth/viewer.clientHeight));
    goalTarget.set(0,2,-43);
    goalPosition.set(202*factor,230*factor,247*factor-43);
    animateTo();updateSelection();
    document.querySelector('#detail').innerHTML='<span class="detail-tag">업무를 게임으로 연습해요.</span><p>오답에는 설명과 재시도 기회를,<br>완료한 미션에는 스탬프를 줍니다.<br>완료 후에는 언제든 복습할 수 있어요.</p>';
  }
  function animateTo() {
    if(reduceMotion) {camera.position.copy(goalPosition);controls.target.copy(goalTarget);controls.update();}
    else animating=true;
  }
  function updateSelection(){
    stationRoot.querySelectorAll('button').forEach(b=>b.setAttribute('aria-pressed',String(Number(b.dataset.id)===selected)));
    pins.forEach(p=>p.button.classList.toggle('selected',p.id===selected));
    viewer.dataset.selected=String(selected);
  }
  function focus(m){
    selected=m.id;
    goalTarget.set(m.position[0],4,m.position[2]);
    const f=Math.max(1,.95/(viewer.clientWidth/viewer.clientHeight));
    goalPosition.set(m.position[0]+45*f,45*f,m.position[2]+55*f);
    animateTo();updateSelection();
    const detail=document.querySelector('#detail');detail.replaceChildren();
    const tag=document.createElement('span');tag.className='detail-tag';tag.textContent=m.title+'에서 연습할 내용';
    const p=document.createElement('p');p.textContent=m.topics.join(' / ');detail.append(tag,p);
  }
  for(const m of missions){
    const b=document.createElement('button');b.className='station';b.dataset.id=m.id;b.style.setProperty('--color','#'+m.color);b.setAttribute('aria-pressed','false');
    b.innerHTML=`<span class="number">${String(m.id).padStart(2,'0')}</span><span><b>${m.title}</b><small>${m.subtitle}</small></span><span class="arrow">↗</span>`;
    b.addEventListener('click',()=>focus(m));stationRoot.append(b);
    const pin=document.createElement('button');pin.className='map-pin';pin.textContent=String(m.id).padStart(2,'0');pin.setAttribute('aria-label',m.title+' 미리보기');pin.addEventListener('click',()=>focus(m));labelRoot.append(pin);
    pins.push({id:m.id,button:pin,position:new THREE.Vector3(m.position[0],20,m.position[2]+11)});
  }
  controls.addEventListener('start',()=>animating=false);
  document.querySelector('#reset').addEventListener('click',overview);
  function resize(){
    renderer.setSize(viewer.clientWidth,viewer.clientHeight,false);
    camera.aspect=viewer.clientWidth/viewer.clientHeight;camera.updateProjectionMatrix();
    if(!selected) overview();
  }
  new ResizeObserver(resize).observe(viewer);
  overview();camera.position.copy(goalPosition);controls.target.copy(goalTarget);animating=false;
  resize();
  const projected=new THREE.Vector3();
  let inView=true;new IntersectionObserver(entries=>{inView=entries[0].isIntersecting;},{rootMargin:'100px'}).observe(viewer);
  let lastFrame=performance.now();
  function draw(now=performance.now()){
    requestAnimationFrame(draw);
    const dt=Math.min((now-lastFrame)/1000,.2);lastFrame=now;
    if(document.hidden||!inView) return;
    if(animating){
      const blend=1-Math.exp(-7*dt);
      camera.position.lerp(goalPosition,blend);controls.target.lerp(goalTarget,blend);
      if(camera.position.distanceTo(goalPosition)<.08)animating=false;
    }
    controls.update();renderer.render(scene,camera);window.__mapRendered=true;
    for(const p of pins){
      projected.copy(p.position).project(camera);
      const visible=projected.z<1 && Math.abs(projected.x)<1.05 && Math.abs(projected.y)<1.05;
      p.button.hidden=!visible;
      if(visible){p.button.style.left=((projected.x+1)/2*viewer.clientWidth)+'px';p.button.style.top=((-projected.y+1)/2*viewer.clientHeight)+'px';}
    }
  }
  draw();loading.remove();window.__mapReady=true;
}catch(error){
  console.error(error);
  loading.textContent='3D 미리보기를 불러오지 못했어요. 위의 맵 파일은 그대로 받을 수 있습니다.';
  window.__mapError=String(error);
}
