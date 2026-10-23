/* Local profile cache, passive parser and bounded Instagram reads. No credentials stored. */
(function (root) {
  'use strict';
  const TTL = 24 * 60 * 60 * 1000;
  const validUser = u => typeof u === 'string' && /^[a-z0-9._]{1,30}$/i.test(u);
  const key = u => String(u || '').replace(/^@/, '').trim().toLowerCase();
  const num = v => typeof v === 'number' && Number.isSafeInteger(v) && v >= 0 ? v : '';
  const clean = v => typeof v === 'string' ? v.slice(0, 5000) : '';
  function normalize(u) {
    if (!u || !validUser(u.username)) return null;
    const p = { username: key(u.username), profileUrl: `https://www.instagram.com/${key(u.username)}/` };
    const strings = {
      fullName: u.fullName ?? u.full_name, biography: u.biography,
      category: u.category_name ?? u.category, externalUrl: u.externalUrl ?? u.external_url,
      profilePic: u.profilePic ?? u.profile_pic_url_hd ?? u.hd_profile_pic_url_info?.url ?? u.profile_pic_url,
      email: u.email ?? u.public_email ?? u.business_email, phone: u.phone ?? u.public_phone_number ?? u.business_phone_number
    };
    for (const [k, v] of Object.entries(strings)) if (typeof v === 'string') p[k] = clean(v);
    for (const [k, v] of Object.entries({followers: u.followers ?? u.follower_count ?? u.edge_followed_by?.count,
      following: u.following ?? u.following_count ?? u.edge_follow?.count,
      posts: u.posts ?? u.media_count ?? u.edge_owner_to_timeline_media?.count})) if (num(v) !== '') p[k] = v;
    for (const [k, v] of Object.entries({isVerified: u.isVerified ?? u.is_verified, isPrivate: u.isPrivate ?? u.is_private,
      isBusiness: u.isBusiness ?? u.is_business_account ?? u.is_business})) if (typeof v === 'boolean') p[k] = v;
    const pk = String(u.pk ?? u.id ?? ''); if (/^\d{1,30}$/.test(pk)) p.pk = pk;
    if (u.followersApprox === true) p.followersApprox = true;
    return p;
  }
  function merge(a, b) {
    const out = { ...(a || {}) };
    for (const [k, v] of Object.entries(b || {})) if (v !== '' && v != null) out[k] = v;
    if (typeof b?.followers === 'number') out.followersApprox = b.followersApprox === true;
    return out;
  }
  function extract(data, maxNodes = 30000) {
    const users = new Map(), media = new Map(), queue = [data]; let visited = 0;
    while (queue.length && visited++ < maxNodes) {
      const v = queue.pop(); if (!v || typeof v !== 'object') continue;
      if (Array.isArray(v)) { for (let i = Math.min(v.length, 1000) - 1; i >= 0; i--) queue.push(v[i]); continue; }
      const p = normalize(v); if (p) users.set(p.username, merge(users.get(p.username), p));
      const code = v.code ?? v.shortcode, owner = normalize(v.owner ?? v.user);
      if (owner && typeof code === 'string' && /^[A-Za-z0-9_-]{4,40}$/.test(code)) {
        media.set(code, { shortcode: code, ...owner }); users.set(owner.username, merge(users.get(owner.username), owner));
      }
      for (const child of Object.values(v)) if (child && typeof child === 'object') queue.push(child);
      if (users.size >= 500 || media.size >= 500) break;
    }
    return { users: [...users.values()], media: [...media.values()] };
  }
  function parseCount(text) {
    const s = String(text || '').replace(/\s|\u00a0/g, ''), m = s.match(/([\d][\d,.]*)(천|만|억|[kmb])?/i);
    if (!m) return null;
    const unit = (m[2] || '').toLowerCase(), scales = { 천:1000, 만:10000, 억:100000000, k:1000, m:1000000, b:1000000000 };
    const n = Math.round(Number(unit ? m[1].replace(/,/g, '') : m[1].replace(/[,.]/g, '')) * (scales[unit] || 1));
    return Number.isSafeInteger(n) && n >= 0 ? { value: n, approximate: !!unit } : null;
  }
  function parseStat({href='',text='',title='',aria=''}) {
    const label = text + ' ' + aria;
    const field = /\/followers\/?(?:[?#]|$)/.test(href) || /팔로워|\bfollowers?\b/i.test(label) ? 'followers'
      : /\/following\/?(?:[?#]|$)/.test(href) || /팔로우|팔로잉|\bfollowing\b/i.test(label) ? 'following' : null;
    const count = field && parseCount(title || text || aria);
    return count ? {field,...count} : null;
  }
  function createClient(o) {
    const now = o.now || Date.now, sleep = o.sleep || (n => new Promise(r => setTimeout(r,n)));
    const profiles = new Map(), media = new Map(), pending = new Map(), failures = new Map();
    const metrics = {requests:0, cacheHits:0, passiveUsers:0, timeouts:0, lastError:'', lastStatus:0};
    let chain = Promise.resolve(), nextAt = 0, persistTimer, state = {until:0,status:0};
    const persist = () => {
      clearTimeout(persistTimer); persistTimer = setTimeout(() => {
        o.storage?.set({iglsProfilesV15:Object.fromEntries([...profiles].slice(-2000)),iglsMediaV15:Object.fromEntries([...media].slice(-2000))}).catch(() => {});
      },500);
    };
    function record(raw, source='page') {
      const p = normalize(raw); if (!p) return;
      const old = profiles.get(p.username), countAt = typeof p.followers === 'number' ? now() : (old?.countAt || 0);
      const fresh = !old || !old.countAt || now()-old.countAt<TTL;
      const base = fresh ? old : {...old,followers:undefined,followersApprox:undefined};
      const merged = merge(base,p); merged.at=now();merged.countAt=countAt;merged.source=source;
      profiles.delete(p.username); profiles.set(p.username,merged);persist();o.onData?.(p.username);return merged;
    }
    async function load() {
      const s = await o.storage?.get(['iglsProfilesV15','iglsMediaV15','iglsNetState']) || {};
      for (const [u,p] of Object.entries(s.iglsProfilesV15 || {})) if (validUser(u)) profiles.set(key(u),p);
      for (const [c,m] of Object.entries(s.iglsMediaV15 || {})) if (validUser(m?.username)) media.set(c,m);
      if (s.iglsNetState?.until>now()) state=s.iglsNetState;
    }
    function accept(packet) {
      if (!packet || !Array.isArray(packet.users) || !Array.isArray(packet.media)) return;
      for (const u of packet.users.slice(0,500)) { record(u); metrics.passiveUsers++; }
      for (const m of packet.media.slice(0,500)) { const p=normalize(m);if(p&&/^[A-Za-z0-9_-]{4,40}$/.test(m.shortcode))media.set(m.shortcode,{...p,at:now()}); }
      persist();
    }
    async function pause(status,ms,reason) {
      state={until:now()+ms,status,reason};await o.storage?.set({iglsNetState:state});o.onState?.(state);
    }
    function error(message,status,kind) { const e=new Error(message);e.status=status;e.kind=kind;return e; }
    async function perform(url) {
      const shared=await o.storage?.get('iglsNetState') || {};
      if(shared.iglsNetState?.until>state.until)state=shared.iglsNetState;
      if(state.until>now())throw error('cooldown',state.status,state.status===401?'auth':'limit');
      const wait=nextAt-now();if(wait>0)await sleep(wait);
      const afterWait=await o.storage?.get('iglsNetState') || {};
      if(afterWait.iglsNetState?.until>state.until)state=afterWait.iglsNetState;
      if(state.until>now())throw error('cooldown',state.status,state.status===401?'auth':'limit');
      nextAt=now()+(o.gapMs??800);
      const ctl=new AbortController(), timer=setTimeout(()=>ctl.abort(),o.timeoutMs??8000);metrics.requests++;
      try {
        const r=await o.fetch(url,{credentials:'include',headers:o.headers?.()||{},signal:ctl.signal});metrics.lastStatus=r.status;
        const text=await r.text();let data;try{data=JSON.parse(text);}catch{data=null;}
        const msg=String(data?.message||'');
        if(r.status===429||/please wait|rate.?limit|too many/i.test(msg)) {
          const retry=r.headers?.get('retry-after'),seconds=/^\d+$/.test(retry||'')?Number(retry):60;
          await pause(429,Math.max(60000,Math.min(seconds*1000,86400000)),'rate_limit');throw error('api_429',429,'limit');
        }
        if(r.status===401||/login_required|challenge_required|checkpoint_required/.test(msg)||data?.challenge||
          (r.redirected&&/\/accounts\/login|\/challenge\//.test(r.url||''))) {
          await pause(401,30*60000,'login_or_challenge');throw error('로그인 또는 계정 확인이 필요합니다',401,'auth');
        }
        if(!r.ok||!data||data.status==='fail')throw error(`api_${r.status}${msg?':'+msg.slice(0,120):''}`,r.status,'route');
        return data;
      } catch(e) {
        if(e.name==='AbortError'){metrics.timeouts++;throw error('조회 응답 시간 초과',0,'timeout');}
        metrics.lastError=e.kind || 'network';throw e;
      } finally {clearTimeout(timer);}
    }
    function request(url) {
      const k='url:'+url;if(pending.has(k))return pending.get(k);
      const task=chain.catch(()=>{}).then(()=>perform(url));chain=task;pending.set(k,task);
      task.finally(()=>pending.delete(k)).catch(()=>{});return task;
    }
    function peek(username) {
      const p=profiles.get(key(username));if(!p)return null;
      if(p.countAt&&now()-p.countAt>=TTL)return {...p,followers:undefined,followersApprox:undefined};return p;
    }
    async function get(username,opts={}) {
      username=key(username);if(!validUser(username))throw new Error('invalid_username');
      const dom=o.readDOM?.(username);if(dom)record(dom,'visible-page');
      const hit=peek(username);if(typeof hit?.followers==='number'){metrics.cacheHits++;return hit;}
      if(pending.has(username))return pending.get(username);
      const fail=failures.get(username);if(fail&&now()-fail.at<60000)throw fail.error;
      const task=(async()=>{
        let p=peek(username),pk=p?.pk||opts.pk;
        if(!pk){
          const feed=await request(`https://www.instagram.com/api/v1/feed/user/${encodeURIComponent(username)}/username/?count=1`);
          const user=normalize(feed.user);if(!user||user.username!==username)throw new Error('프로필 소유자를 확인하지 못했습니다');
          p=record(user,'feed');pk=user.pk;if(typeof p.followers==='number')return p;
        }
        if(!/^\d{1,30}$/.test(String(pk||'')))throw new Error('profile_id_unavailable');
        const json=await request(`https://www.instagram.com/api/v1/users/${pk}/info/`),user=normalize(json.user);
        if(!user||user.username!==username)throw new Error('profile_owner_mismatch');return record(user,'users-info');
      })().catch(e=>{failures.set(username,{at:now(),error:e});throw e;});
      pending.set(username,task);task.finally(()=>pending.delete(username)).catch(()=>{});return task;
    }
    return {load,accept,record,peek,get,request,metrics,owner:c=>media.get(c)||null,netState:()=>({...state}),
      resume:async()=>{failures.clear();state={until:0,status:0};await o.storage?.set({iglsNetState:state});o.onState?.(state);}};
  }
  const api={normalize,merge,extract,parseCount,parseStat,createClient,key,TTL};root.IGLSCore=api;
  if(typeof module!=='undefined')module.exports=api;
})(globalThis);
