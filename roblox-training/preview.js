import {illustration} from './visual-art.js';
import * as THREE from 'three';
import {OrbitControls} from './vendor/OrbitControls.js';
const viewer=document.querySelector('#viewer'),loading=document.querySelector('#loading'),labelRoot=document.querySelector('#mapLabels'),stationRoot=document.querySelector('#stations');
const reduceMotion=matchMedia('(prefers-reduced-motion: reduce)').matches;
try{
  await document.fonts.ready;
  const [parts,missions,artAssets,env,rasterAssets]=await Promise.all(['scene.json','missions.json','visual-assets.json','environment.json','raster-assets.json'].map(url=>fetch('./'+url).then(r=>{if(!r.ok)throw Error(url);return r.json();})));
  const scene=new THREE.Scene();scene.fog=new THREE.FogExp2('#b7a0bf',.0008);
  const renderer=new THREE.WebGLRenderer({antialias:true});
  renderer.setPixelRatio(Math.min(devicePixelRatio,1.7));renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;
  renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.05;
  renderer.domElement.setAttribute('aria-label','황금빛 갈대밭과 노을 호수, 나무 정자로 이루어진 시리아이 교육 맵');viewer.prepend(renderer.domElement);
  const camera=new THREE.PerspectiveCamera(52,1,.1,6000);
  const controls=new OrbitControls(camera,renderer.domElement);controls.enableDamping=true;controls.dampingFactor=.07;controls.maxPolarAngle=Math.PI/2-.015;controls.minDistance=15;controls.maxDistance=800;
  scene.add(new THREE.HemisphereLight(0xf0d4f3,0x83749b,2.3));
  const sun=new THREE.DirectionalLight(0xffd29a,3.4);sun.position.set(-200,100,-615);sun.target.position.set(0,0,-90);sun.castShadow=true;sun.shadow.mapSize.set(2048,2048);
  Object.assign(sun.shadow.camera,{left:-230,right:230,top:230,bottom:-230,near:10,far:1000});sun.shadow.bias=-.0006;sun.shadow.normalBias=.18;scene.add(sun,sun.target);
  const time={value:0};
  const sky=new THREE.Mesh(new THREE.SphereGeometry(1800,48,24),new THREE.ShaderMaterial({side:THREE.BackSide,depthWrite:false,uniforms:{uTime:time},vertexShader:`varying vec3 vDirection;void main(){vDirection=position;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}`,fragmentShader:`
    varying vec3 vDirection;uniform float uTime;
    float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
    float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1.,0.)),f.x),mix(hash(i+vec2(0.,1.)),hash(i+1.),f.x),f.y);}
    void main(){vec3 d=normalize(vDirection);float h=max(d.y,0.);vec3 c=mix(vec3(.98,.67,.53),vec3(.48,.36,.64),smoothstep(0.,.3,h));c=mix(c,vec3(.12,.14,.32),smoothstep(.18,.95,h));
    vec2 q=d.xz/(h+.23)*vec2(2.,9.);float n=noise(q*.8)+.5*noise(q*1.7)+.22*noise(q*3.9);float cloud=smoothstep(.9,1.32,n)*smoothstep(.02,.13,h)*(1.-smoothstep(.45,.8,h));c=mix(c,vec3(.99,.80,.70),cloud*.47);gl_FragColor=vec4(c,1.);}`
  }));sky.material.toneMapped=false;sky.renderOrder=-2;scene.add(sky);
  // Original radial glow, generated locally; no remote texture or licensed image.
  const glowCanvas=document.createElement('canvas');glowCanvas.width=glowCanvas.height=256;const glowContext=glowCanvas.getContext('2d'),gradient=glowContext.createRadialGradient(128,128,3,128,128,128);
  gradient.addColorStop(0,'rgba(255,220,162,0.8)');gradient.addColorStop(.2,'rgba(255,192,119,0.35)');gradient.addColorStop(1,'rgba(255,179,123,0)');glowContext.fillStyle=gradient;glowContext.fillRect(0,0,256,256);
  const glow=new THREE.Sprite(new THREE.SpriteMaterial({map:new THREE.CanvasTexture(glowCanvas),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));glow.position.fromArray(env.sun);glow.scale.set(220,220,1);scene.add(glow);glow.visible=env.version!=='4.0.0';
  const box=new THREE.BoxGeometry(1,1,1),sphere=new THREE.SphereGeometry(.5,16,10),cylinder=new THREE.CylinderGeometry(.5,.5,1,12);cylinder.rotateZ(Math.PI/2);
  const materials=new Map(),batches=new Map(),dummy=new THREE.Object3D();let partCount=0;
  function material(p){
    const key=p.color+p.transparency+p.material+p.wind;
    if(!materials.has(key)){
      const m=new THREE.MeshStandardMaterial({color:p.color,roughness:p.material==='WoodPlanks'?.92:.85,metalness:0,transparent:p.transparency>0,opacity:1-p.transparency,emissive:p.material==='Neon'?p.color:0,emissiveIntensity:p.name==='Setting sun'?3:p.material==='Neon'?.65:0,depthWrite:p.transparency<.5});
      if(p.wind)m.onBeforeCompile=shader=>{shader.uniforms.uTime=time;shader.vertexShader='uniform float uTime;\n'+shader.vertexShader;shader.vertexShader=shader.vertexShader.replace('#include <project_vertex>',`vec4 mvPosition=vec4(transformed,1.);
        #ifdef USE_INSTANCING
        mvPosition=instanceMatrix*mvPosition;
        #endif
        float sway=sin(uTime*.85+mvPosition.x*.07+mvPosition.z*.05)*.036*max(mvPosition.y-.2,0.);
        mvPosition.x+=sway;mvPosition.z+=sway*.3;mvPosition=modelViewMatrix*mvPosition;gl_Position=projectionMatrix*mvPosition;`);};
      materials.set(key,m);
    }return materials.get(key);
  }
  function labelTexture(value,width,height){
    const canvas=document.createElement('canvas');canvas.width=1024;canvas.height=Math.max(160,Math.round(1024*height/width));const ctx=canvas.getContext('2d'),lines=value.split('\n');
    let fontSize=Math.min(110,canvas.height/(lines.length+1.1));for(const line of lines)fontSize=Math.min(fontSize,940/Math.max(1,[...line].reduce((n,c)=>n+(/[\u3131-\uD79D]/.test(c)?1:.58),0)));
    ctx.fillStyle='#ffffff';ctx.textAlign='center';ctx.textBaseline='middle';ctx.font=`700 ${fontSize}px Pretendard,sans-serif`;lines.forEach((line,i)=>ctx.fillText(line,512,(canvas.height-(lines.length-1)*fontSize*1.3)/2+i*fontSize*1.3));const texture=new THREE.CanvasTexture(canvas);texture.colorSpace=THREE.SRGBColorSpace;return texture;
  }
  for(const p of parts){
    if(p.name==='Lake water preview')continue;
    const geom=p.shape==='Ball'?sphere:p.shape==='Cylinder'?cylinder:box,m=material(p),key=geom.uuid+m.uuid+Boolean(p.shadow);
    if(!p.name.startsWith('Pixel twilight')){if(!batches.has(key))batches.set(key,{geom,material:m,shadow:p.shadow!==false&&p.material!=='Neon'&&p.transparency<.6&&!p.name.startsWith('Distant')&&!p.name.startsWith('Floating')&&!p.name.startsWith('Cyan'),parts:[]});batches.get(key).parts.push(p);}partCount++;
    if(p.label||p.art||p.raster){
      const group=new THREE.Group();group.position.fromArray(p.position);group.rotation.set(...p.rotation.map(v=>v*Math.PI/180),'XYZ');
      if(p.label){
        const ink=['#252420','#ff234b','#695540'].includes(p.color.toLowerCase())||p.name==='Back number';
        const plane=new THREE.Mesh(new THREE.PlaneGeometry(p.size[0]*.94,p.size[1]*(p.art?.22:.9)),new THREE.MeshBasicMaterial({map:labelTexture(p.label,p.size[0],p.size[1]),transparent:true,color:p.labelColor||(ink?0xffffff:0x33291e),depthWrite:false}));plane.position.z=p.size[2]/2+.025;if(p.art)plane.position.y=-p.size[1]*.34;group.add(plane);
      }
      if(p.raster){
        const a=rasterAssets[p.raster],texture=new THREE.TextureLoader().load('./'+a.file);
        texture.colorSpace=THREE.SRGBColorSpace;texture.magFilter=THREE.NearestFilter;
        if(a.crop){const [x,y,x2,y2]=a.crop;const [w,h]=a.sourceSize;texture.offset.set(x/w,1-y2/h);texture.repeat.set((x2-x)/w,(y2-y)/h);}
        const image=new THREE.Mesh(new THREE.PlaneGeometry(p.size[0],p.size[1]),new THREE.MeshBasicMaterial({map:texture,transparent:true,toneMapped:false,fog:false,polygonOffset:true,polygonOffsetFactor:-4,polygonOffsetUnits:-4}));
        image.position.set(0,0,p.size[2]/2+(p.name.startsWith('Pixel twilight')?3:.05));if(p.name.startsWith('Pixel twilight')){image.material.depthWrite=false;image.renderOrder=-1;}group.add(image);
      }
      if(p.art){const texture=new THREE.TextureLoader().load('data:image/svg+xml;charset=utf-8,'+encodeURIComponent(illustration(p.art,artAssets)));texture.colorSpace=THREE.SRGBColorSpace;const image=new THREE.Mesh(new THREE.PlaneGeometry(p.size[0]*.9,p.size[1]*.65),new THREE.MeshBasicMaterial({map:texture}));image.position.set(0,p.size[1]*.12,p.size[2]/2+.03);group.add(image);}scene.add(group);
    }
  }
  for(const batch of batches.values()){
    const mesh=new THREE.InstancedMesh(batch.geom,batch.material,batch.parts.length);mesh.castShadow=batch.shadow;mesh.receiveShadow=!batch.parts[0].wind;
    batch.parts.forEach((p,i)=>{dummy.position.fromArray(p.position);dummy.rotation.set(...p.rotation.map(v=>v*Math.PI/180),'XYZ');dummy.scale.fromArray(p.size);dummy.updateMatrix();mesh.setMatrixAt(i,dummy.matrix);});mesh.computeBoundingSphere();scene.add(mesh);
  }
  const water=new THREE.Mesh(new THREE.PlaneGeometry(env.lake.size[0],env.lake.size[2]),new THREE.ShaderMaterial({uniforms:{uTime:time,sunPosition:{value:new THREE.Vector3(...env.sun)}},vertexShader:`varying vec3 vWorld;void main(){vec4 world=modelMatrix*vec4(position,1.);vWorld=world.xyz;gl_Position=projectionMatrix*viewMatrix*world;}`,fragmentShader:`
    uniform float uTime;uniform vec3 sunPosition;varying vec3 vWorld;
    void main(){vec3 eye=normalize(cameraPosition-vWorld);float w=sin(vWorld.x*.23+vWorld.z*.45+uTime*.7)*.5+sin(vWorld.z*.73-vWorld.x*.14-uTime*.5)*.3;
      vec3 normal=normalize(vec3(w*.035,1.,cos(vWorld.z*.37+uTime*.6)*.023));vec3 reflected=reflect(-eye,normal);vec3 sunDir=normalize(sunPosition-vWorld);float sparkle=pow(max(dot(reflected,sunDir),0.),90.);
      float fresnel=pow(1.-max(dot(eye,normal),0.),2.);vec3 colour=mix(vec3(.35,.29,.49),vec3(.77,.52,.58),fresnel);colour+=w*.025;colour+=vec3(1.,.68,.30)*sparkle*1.15;
      float ripple=sin(vWorld.z*2.+w*3.+uTime*.4)*.5+.5;colour+=vec3(.25,.13,.045)*sparkle*ripple;
      float fog=1.-exp(-length(cameraPosition-vWorld)*.0019);colour=mix(colour,vec3(.68,.57,.72),fog);gl_FragColor=vec4(colour,1.);}`
  }));water.rotation.x=-Math.PI/2;water.position.set(env.lake.position[0],-.48,env.lake.position[2]);water.material.toneMapped=false;scene.add(water);
  let selected=0,mode='sunset',animating=false;const goalPosition=new THREE.Vector3(),goalTarget=new THREE.Vector3(),pins=[];
  function animateTo(){if(reduceMotion){camera.position.copy(goalPosition);controls.target.copy(goalTarget);controls.update();}else animating=true;}
  function updateSelection(){
    stationRoot.querySelectorAll('button').forEach(b=>b.setAttribute('aria-pressed',String(Number(b.dataset.id)===selected)));pins.forEach(p=>p.button.classList.toggle('selected',p.id===selected));viewer.dataset.selected=String(selected);viewer.dataset.view=mode;
    for(const [id,value]of [['sunset','sunset'],['lakeView','lake'],['reset','overview']])document.getElementById(id).setAttribute('aria-pressed',String(mode===value));
  }
  const descriptions={sunset:['붉은 태양 아래','보랏빛 하늘과 청록색 마름모, 금빛 갈대.<br>미션 사이, 잠시 풍경을 보며 쉬어가세요.'],lake:['물가에서 쉬어가기','물가 데크에는 앉아서 노을을 보는 자리가 있어요.<br>실제 맵에서는 ‘노을 산책’으로 바로 이동합니다.'],overview:['색과 그림으로 나눈 여섯 공간','갈대밭 안의 여섯 나무 정자에서 업무를 연습해요.<br>옆의 미션을 누르면 각 공간을 볼 수 있어요.']};
  function view(name){
    selected=0;mode=name;const v=env.views[name];goalPosition.fromArray(v.position);goalTarget.fromArray(v.target);
    if(name==='overview'){const f=Math.max(1,1.1/(viewer.clientWidth/viewer.clientHeight));goalPosition.sub(goalTarget).multiplyScalar(f).add(goalTarget);}
    animateTo();updateSelection();const d=descriptions[name];document.querySelector('#detail').innerHTML=`<span class="detail-tag">${d[0]}</span><p>${d[1]}</p>`;
  }
  function focus(m){selected=m.id;mode='mission';goalTarget.set(m.position[0],7,m.position[2]);const f=Math.max(1,.95/(viewer.clientWidth/viewer.clientHeight));goalPosition.set(m.position[0]+12*f,9+3*f,m.position[2]+55*f);animateTo();updateSelection();const detail=document.querySelector('#detail');detail.replaceChildren();const tag=document.createElement('span');tag.className='detail-tag';tag.textContent=m.title+'에서 연습할 내용';const p=document.createElement('p');p.textContent=m.topics.join(' / ');detail.append(tag,p);}
  for(const m of missions){
    const b=document.createElement('button');b.className='station';b.dataset.id=m.id;b.style.setProperty('--color','#'+m.color);b.setAttribute('aria-pressed','false');b.innerHTML=`<span class="number">${String(m.id).padStart(2,'0')}</span><span><b>${m.title}</b><small>${m.subtitle}</small></span><span class="arrow">↗</span>`;b.addEventListener('click',()=>focus(m));stationRoot.append(b);
    const pin=document.createElement('button');pin.className='map-pin';pin.textContent=String(m.id).padStart(2,'0');pin.setAttribute('aria-label',m.title+' 미리보기');pin.addEventListener('click',()=>focus(m));labelRoot.append(pin);pins.push({id:m.id,button:pin,position:new THREE.Vector3(m.position[0],20,m.position[2]+11)});
  }
  controls.addEventListener('start',()=>animating=false);document.querySelector('#reset').addEventListener('click',()=>view('overview'));document.querySelector('#sunset').addEventListener('click',()=>view('sunset'));document.querySelector('#lakeView').addEventListener('click',()=>view('lake'));
  function resize(){renderer.setSize(viewer.clientWidth,viewer.clientHeight,false);camera.aspect=viewer.clientWidth/viewer.clientHeight;camera.fov=viewer.clientWidth<600?78:52;camera.updateProjectionMatrix();if(mode!=='mission')view(mode);}
  new ResizeObserver(resize).observe(viewer);view('sunset');camera.position.copy(goalPosition);controls.target.copy(goalTarget);animating=false;resize();
  const projected=new THREE.Vector3();let inView=true;new IntersectionObserver(entries=>inView=entries[0].isIntersecting,{rootMargin:'100px'}).observe(viewer);let lastFrame=performance.now();
  function draw(now=performance.now()){
    requestAnimationFrame(draw);const dt=Math.min((now-lastFrame)/1000,.2);lastFrame=now;if(document.hidden||!inView)return;if(!reduceMotion)time.value+=dt;
    if(animating){const blend=1-Math.exp(-5*dt);camera.position.lerp(goalPosition,blend);controls.target.lerp(goalTarget,blend);if(camera.position.distanceTo(goalPosition)<.08)animating=false;}
    sky.position.copy(camera.position);controls.update();renderer.render(scene,camera);window.__mapRendered=true;
    for(const p of pins){projected.copy(p.position).project(camera);const visible=(mode==='overview'||(mode==='mission'&&selected===p.id))&&projected.z<1&&Math.abs(projected.x)<1.05&&Math.abs(projected.y)<1.05;p.button.hidden=!visible;if(visible){p.button.style.left=((projected.x+1)/2*viewer.clientWidth)+'px';p.button.style.top=((-projected.y+1)/2*viewer.clientHeight)+'px';}}
    window.__meadowStats={parts:partCount,clusters:env.reedClusters,drawCalls:renderer.info.render.calls,view:mode,wind:!reduceMotion,time:time.value};
  }
  draw();loading.remove();window.__mapReady=true;
}catch(error){console.error(error);loading.textContent='풍경 미리보기를 불러오지 못했어요. 맵 파일은 위에서 받을 수 있습니다.';window.__mapError=String(error);}
