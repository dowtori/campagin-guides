import * as THREE from 'three';
import {OrbitControls} from './vendor/OrbitControls.js';
const viewer=document.querySelector('#viewer'),loading=document.querySelector('#loading');
const reduceMotion=matchMedia('(prefers-reduced-motion: reduce)').matches;
try{
 await document.fonts.ready;
 const [parts,env,rasterAssets,coast]=await Promise.all(['scene.json','environment.json','raster-assets.json','coast.json'].map(u=>fetch('./v6/'+u).then(r=>{if(!r.ok)throw Error(u);return r.json()})));
 const scene=new THREE.Scene();scene.fog=new THREE.FogExp2('#b3a2bb',.00068);
 const renderer=new THREE.WebGLRenderer({antialias:true});renderer.setPixelRatio(Math.min(devicePixelRatio,1.5));renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1;
 renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;viewer.prepend(renderer.domElement);
 const camera=new THREE.PerspectiveCamera(52,1,.1,6000),controls=new OrbitControls(camera,renderer.domElement);controls.enableDamping=true;controls.minDistance=10;controls.maxDistance=1200;controls.maxPolarAngle=Math.PI/2-.01;
 scene.add(new THREE.HemisphereLight(0xe5d3ec,0x7e7792,2.1));
 const sun=new THREE.DirectionalLight(0xffd1a0,2.6);sun.position.set(-200,130,-600);sun.target.position.set(0,0,-50);sun.castShadow=true;sun.shadow.mapSize.set(2048,2048);Object.assign(sun.shadow.camera,{left:-180,right:180,top:180,bottom:-180,near:10,far:1000});sun.shadow.bias=-.0006;sun.shadow.normalBias=.15;scene.add(sun,sun.target);
 const time={value:0};
 // A procedural atmospheric gradient. There is no photo, painted sun or painted mountain.
 const sky=new THREE.Mesh(new THREE.SphereGeometry(3000,32,16),new THREE.ShaderMaterial({side:THREE.BackSide,depthWrite:false,uniforms:{},vertexShader:`varying vec3 vDir;void main(){vDir=position;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}`,fragmentShader:`varying vec3 vDir;void main(){float y=normalize(vDir).y;vec3 horizon=vec3(.83,.66,.67);vec3 upper=vec3(.29,.28,.48);vec3 lower=vec3(.52,.49,.60);vec3 c=mix(horizon,upper,smoothstep(0.,.42,y));c=mix(c,lower,smoothstep(0.,.45,-y));gl_FragColor=vec4(c,1.);}` }));sky.material.toneMapped=false;scene.add(sky);
  const box=new THREE.BoxGeometry(1,1,1),sphere=new THREE.SphereGeometry(.5,16,10),cylinder=new THREE.CylinderGeometry(.5,.5,1,12);cylinder.rotateZ(Math.PI/2);
  const wedge=new THREE.BufferGeometry();
  wedge.setAttribute('position',new THREE.Float32BufferAttribute([-.5,-.5,-.5,-.5,-.5,.5,-.5,.5,.5,.5,-.5,-.5,.5,-.5,.5,.5,.5,.5],3));
  wedge.setIndex([0,1,2,3,5,4,0,3,4,0,4,1,1,4,5,1,5,2,0,2,5,0,5,3]);wedge.computeVertexNormals();
  const materials=new Map(),batches=new Map(),dummy=new THREE.Object3D();let partCount=0;
  function material(p){
    const key=p.color+p.transparency+p.material+p.wind;
    if(!materials.has(key)){
      let m=new THREE.MeshStandardMaterial({color:p.color,roughness:p.material==='WoodPlanks'?.92:.85,metalness:0,transparent:p.transparency>0,opacity:1-p.transparency,emissive:p.material==='Neon'?p.color:0,emissiveIntensity:p.name==='Setting sun'?.5:p.material==='Neon'?.65:0,depthWrite:p.transparency<.5});
      if(p.name==='Setting sun'){m=new THREE.MeshBasicMaterial({color:'#c7233b',toneMapped:false,fog:false});}
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
    if(p.name==='Coast ground preview'||p.name==='Solid sea floor'||p.name==='Mountain terrain preview'||p.name.startsWith('Target_'))continue;
    const geom=p.shape==='Wedge'?wedge:p.shape==='Ball'?sphere:p.shape==='Cylinder'?cylinder:box,m=material(p),key=geom.uuid+m.uuid+Boolean(p.shadow);
    if(!p.name.startsWith('Pixel twilight')){if(!batches.has(key))batches.set(key,{geom,material:m,shadow:p.shadow!==false&&p.material!=='Neon'&&p.transparency<.6&&!p.name.startsWith('Distant')&&!p.name.startsWith('Floating')&&!p.name.startsWith('Cyan'),parts:[]});batches.get(key).parts.push(p);}partCount++;
    if(p.label||p.art||p.raster){
      const group=new THREE.Group();group.position.fromArray(p.position);group.rotation.set(...p.rotation.map(v=>v*Math.PI/180),'XYZ');
      if(p.label){
        const ink=['#252420','#ff234b','#695540'].includes(p.color.toLowerCase())||p.name==='Back number';
        const plane=new THREE.Mesh(new THREE.PlaneGeometry(p.size[0]*.94,p.size[1]*(p.art?.22:.9)),new THREE.MeshBasicMaterial({map:labelTexture(p.label,p.size[0],p.size[1]),transparent:true,color:p.labelColor||(ink?0xffffff:0x33291e),depthWrite:false}));plane.position.z=p.size[2]/2+.025;if(p.art)plane.position.y=-p.size[1]*.34;group.add(plane);
      }
      if(p.raster){
        const a=rasterAssets[p.raster],texture=new THREE.TextureLoader().load('./v6/'+a.file);
        texture.colorSpace=THREE.SRGBColorSpace;texture.magFilter=THREE.LinearFilter;
        if(a.crop){const [x,y,x2,y2]=a.crop;const [w,h]=a.sourceSize;texture.offset.set(x/w,1-y2/h);texture.repeat.set((x2-x)/w,(y2-y)/h);}
        const image=new THREE.Mesh(new THREE.PlaneGeometry(p.size[0],p.size[1]),new THREE.MeshBasicMaterial({map:texture,transparent:true,toneMapped:false,fog:false,polygonOffset:true,polygonOffsetFactor:-4,polygonOffsetUnits:-4}));
        image.position.set(0,0,p.size[2]/2+(p.name.startsWith('Pixel twilight')?3:.05));if(p.name.startsWith('Pixel twilight')){image.material.depthWrite=false;image.renderOrder=-1;}group.add(image);
      }
      if(false&&p.art){const texture=new THREE.TextureLoader().load('data:image/svg+xml;charset=utf-8,'+encodeURIComponent(illustration(p.art,artAssets)));texture.colorSpace=THREE.SRGBColorSpace;const image=new THREE.Mesh(new THREE.PlaneGeometry(p.size[0]*.9,p.size[1]*.65),new THREE.MeshBasicMaterial({map:texture}));image.position.set(0,p.size[1]*.12,p.size[2]/2+.03);group.add(image);}scene.add(group);
    }
  }
  for(const batch of batches.values()){
    const mesh=new THREE.InstancedMesh(batch.geom,batch.material,batch.parts.length);mesh.castShadow=batch.shadow;mesh.receiveShadow=!batch.parts[0].wind;
    batch.parts.forEach((p,i)=>{dummy.position.fromArray(p.position);dummy.rotation.set(...p.rotation.map(v=>v*Math.PI/180),'XYZ');dummy.scale.fromArray(p.size);dummy.updateMatrix();mesh.setMatrixAt(i,dummy.matrix);});mesh.computeBoundingSphere();scene.add(mesh);
  }
  // The same height samples used for native terrain drive this continuous preview mesh.
  const positions=[],colours=[],indices=[];const sand=new THREE.Color('#b7aa8e'),meadow=new THREE.Color('#a3a374'),rock=new THREE.Color('#817e8d');
  for(let x=0;x<coast.nx;x++)for(let z=0;z<coast.nz;z++){
    const h=coast.heights[x*coast.nz+z];positions.push(coast.x0+x*coast.step,h,coast.z0+z*coast.step);
    const c=sand.clone().lerp(meadow,THREE.MathUtils.smoothstep(h,-.35,.15));c.lerp(rock,THREE.MathUtils.smoothstep(h,30,80));colours.push(c.r,c.g,c.b);
    if(x<coast.nx-1&&z<coast.nz-1){const i=x*coast.nz+z;indices.push(i,i+1,i+coast.nz,i+1,i+coast.nz+1,i+coast.nz);}
  }
  const groundGeometry=new THREE.BufferGeometry();groundGeometry.setAttribute('position',new THREE.Float32BufferAttribute(positions,3));groundGeometry.setAttribute('color',new THREE.Float32BufferAttribute(colours,3));groundGeometry.setIndex(indices);groundGeometry.computeVertexNormals();
  const ground=new THREE.Mesh(groundGeometry,new THREE.MeshStandardMaterial({vertexColors:true,roughness:1,flatShading:true}));ground.receiveShadow=true;scene.add(ground);
  const heightBytes=new Uint8Array(coast.nx*coast.nz);
  for(let z=0;z<coast.nz;z++)for(let x=0;x<coast.nx;x++)heightBytes[z*coast.nx+x]=Math.round((coast.heights[x*coast.nz+z]+40)/216*255);
  const heights=new THREE.DataTexture(heightBytes,coast.nx,coast.nz,THREE.RedFormat);heights.minFilter=THREE.LinearFilter;heights.magFilter=THREE.LinearFilter;heights.needsUpdate=true;
  const water=new THREE.Mesh(new THREE.PlaneGeometry(env.lake.size[0],env.lake.size[2]),new THREE.ShaderMaterial({transparent:true,depthWrite:false,uniforms:{uTime:time,sunPosition:{value:new THREE.Vector3(...env.sun)},uHeights:{value:heights},uBounds:{value:new THREE.Vector4(coast.x0,coast.z0,(coast.nx-1)*coast.step,(coast.nz-1)*coast.step)},uSea:{value:coast.seaLevel}},vertexShader:`varying vec3 vWorld;void main(){vec4 world=modelMatrix*vec4(position,1.);vWorld=world.xyz;gl_Position=projectionMatrix*viewMatrix*world;}`,fragmentShader:`
    uniform float uTime;uniform vec3 sunPosition;uniform sampler2D uHeights;uniform vec4 uBounds;uniform float uSea;varying vec3 vWorld;
    void main(){
      vec2 uv=(vWorld.xz-uBounds.xy)/uBounds.zw;
      float h=-40.;if(uv.x>=0.&&uv.x<=1.&&uv.y>=0.&&uv.y<=1.)h=texture2D(uHeights,uv).r*216.-40.;
      float depth=max(0.,uSea-h);if(depth<.025)discard;
      vec3 eye=normalize(cameraPosition-vWorld);float w=sin(vWorld.x*.23+vWorld.z*.45+uTime*.7)*.5+sin(vWorld.z*.73-vWorld.x*.14-uTime*.5)*.3;
      vec3 normal=normalize(vec3(w*.025,1.,cos(vWorld.z*.37+uTime*.6)*.018));vec3 reflected=reflect(-eye,normal);vec3 sunDir=normalize(sunPosition-vWorld);float sparkle=pow(max(dot(reflected,sunDir),0.),90.);
      float fresnel=pow(1.-max(dot(eye,normal),0.),2.);vec3 shallow=vec3(.46,.60,.61);vec3 deep=vec3(.28,.35,.47);
      vec3 colour=mix(shallow,deep,smoothstep(1.,20.,depth));colour=mix(colour,vec3(.69,.52,.66),fresnel*.72);colour+=w*.017;colour+=vec3(1.,.68,.35)*sparkle*.95;
      float ripple=sin(vWorld.z*2.+w*3.+uTime*.4)*.5+.5;colour+=vec3(.25,.13,.045)*sparkle*ripple;
      float fog=1.-exp(-length(cameraPosition-vWorld)*.0013);colour=mix(colour,vec3(.68,.57,.72),fog);gl_FragColor=vec4(colour,mix(.72,.97,smoothstep(.2,8.,depth)));
    }`
  }));water.rotation.x=-Math.PI/2;water.position.set(env.lake.center[0],coast.seaLevel,env.lake.center[2]);water.material.toneMapped=false;scene.add(water);

 let mode='overview';
 function view(name){mode=name;const v=env.views[name]||env.views.overview;camera.position.fromArray(v.position);controls.target.fromArray(v.target);controls.update();document.querySelectorAll('[data-view]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.view===name)));}
 document.querySelectorAll('[data-view]').forEach(b=>b.addEventListener('click',()=>view(b.dataset.view)));
 function resize(){renderer.setSize(viewer.clientWidth,viewer.clientHeight,false);camera.aspect=viewer.clientWidth/viewer.clientHeight;camera.fov=viewer.clientWidth<600?72:52;camera.updateProjectionMatrix();}
 new ResizeObserver(resize).observe(viewer);resize();view('overview');
 let last=performance.now();
 function draw(now){requestAnimationFrame(draw);const dt=Math.min(.1,(now-last)/1000);last=now;if(!reduceMotion)time.value+=dt;controls.update();sky.position.copy(camera.position);renderer.render(scene,camera);window.__mapRendered=true;window.__mapStats={parts:partCount,drawCalls:renderer.info.render.calls,view:mode,scenery:'3D terrain + sphere sun + cloud geometry'};}
 requestAnimationFrame(draw);loading.remove();window.__mapReady=true;
}catch(e){console.error(e);loading.textContent='3D 미리보기를 불러오지 못했어요. 맵 파일은 위에서 받을 수 있습니다.';window.__mapError=String(e);}
