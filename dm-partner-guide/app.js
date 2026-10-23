(() => {
const slides=[...document.querySelectorAll('.slide')];
const names=['시작하기','진행 방식','계정 세팅','설치와 옵션 열기','구글시트 연결과 저장','인플루언서 수집','DM 발송과 시트 표기','문의 응대','보수와 시작 자료'];
const total=slides.length;
slides.forEach((s,i)=>{
 const head=document.createElement('header');head.className='brand';head.innerHTML='<img src="assets/symbol.png" alt=""><span class="wordmark">Siriai</span><i></i><span>'+names[i]+'</span>';s.prepend(head);
 const foot=document.createElement('footer');foot.innerHTML='<span>SIRIAI · Partner guide</span><span>'+names[i]+'</span><b>'+String(i+1).padStart(2,'0')+' <em>/ '+String(total).padStart(2,'0')+'</em></b>';s.append(foot);
});
const mobile=matchMedia('(max-width:760px)'),toc=document.querySelector('#toc');
document.querySelector('.toc-links').innerHTML=names.map((n,i)=>'<button data-go="'+i+'"><span>'+String(i+1).padStart(2,'0')+'</span>'+n+'</button>').join('');
let current=Math.max(0,slides.findIndex(s=>'#'+s.id===location.hash));
function paint(){slides.forEach((s,i)=>{s.classList.toggle('active',i===current);s.inert=!mobile.matches&&i!==current;});document.querySelector('#counter').textContent=String(current+1).padStart(2,'0')+' / '+String(total).padStart(2,'0');document.querySelector('#prev').disabled=current===0;document.querySelector('#next').disabled=current===total-1;}
function go(i,scroll=true){current=Math.max(0,Math.min(total-1,i));paint();history.replaceState(null,'','#'+slides[current].id);if(mobile.matches&&scroll)slides[current].scrollIntoView({behavior:matchMedia('(prefers-reduced-motion:reduce)').matches?'auto':'smooth'});if(toc.open)toc.close();}
function resize(){document.documentElement.style.setProperty('--scale',Math.min(innerWidth/1280,innerHeight/720));paint();}
document.querySelector('#next').onclick=()=>go(current+1);document.querySelector('#prev').onclick=()=>go(current-1);
document.querySelectorAll('[data-go]').forEach(b=>b.onclick=()=>go(Number(b.dataset.go)));
document.querySelector('#tocOpen').onclick=()=>toc.showModal();document.querySelector('#tocClose').onclick=()=>toc.close();
toc.addEventListener('click',e=>{if(e.target===toc){const r=toc.getBoundingClientRect();if(e.clientX<r.left||e.clientX>r.right||e.clientY<r.top||e.clientY>r.bottom)toc.close();}});
addEventListener('keydown',e=>{if(toc.open||e.altKey||e.ctrlKey||e.metaKey||/INPUT|TEXTAREA|SELECT/.test(e.target.tagName))return;if(['ArrowRight','PageDown'].includes(e.key)){e.preventDefault();go(current+1);}if(['ArrowLeft','PageUp'].includes(e.key)){e.preventDefault();go(current-1);}if(e.key==='Home'){e.preventDefault();go(0);}if(e.key==='End'){e.preventDefault();go(total-1);}});
addEventListener('resize',resize);addEventListener('hashchange',()=>{const i=slides.findIndex(s=>'#'+s.id===location.hash);if(i>=0)go(i);});
const observer=new IntersectionObserver(es=>{if(!mobile.matches)return;const a=es.filter(e=>e.isIntersecting).sort((a,b)=>b.intersectionRatio-a.intersectionRatio);if(a[0]){current=slides.indexOf(a[0].target);paint();}},{rootMargin:'-10% 0px -45% 0px',threshold:[0,.15,.4]});slides.forEach(s=>observer.observe(s));
addEventListener('beforeprint',()=>slides.forEach(s=>s.inert=false));addEventListener('afterprint',paint);

document.querySelectorAll('[data-copy-target]').forEach(button=>button.addEventListener('click',async()=>{
 const field=document.getElementById(button.dataset.copyTarget),status=document.getElementById('copyStatus');
 try{await navigator.clipboard.writeText(field.value);button.textContent='복사 완료 ✓';status.textContent='복사했습니다. 설정 화면의 URL 칸에 붙여넣어주세요.';}
 catch{field.focus();field.select();field.setSelectionRange(0,field.value.length);status.textContent='주소를 선택했습니다. Ctrl+C 또는 길게 눌러 복사해주세요.';}
}));
resize();if(location.hash&&mobile.matches)requestAnimationFrame(()=>slides[current].scrollIntoView());
})();
