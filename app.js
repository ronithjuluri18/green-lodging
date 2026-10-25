/* ===========================================================================
   GREEN LODGING LLC — property management portal
   Runs entirely in the browser. All data lives in Supabase, and what each
   person can see is enforced by the database, not by this file.
   =========================================================================== */
(function () {
"use strict";

/* ------------------------------------------------------------------ utils */
const $  = (s, r) => (r || document).querySelector(s);
const el = (t, a, k) => {
  const n = document.createElement(t);
  if (a) for (const p in a) {
    if (a[p] == null) continue;
    if (p === 'html') n.innerHTML = a[p];
    else if (p === 'text') n.textContent = a[p];
    else if (p.slice(0,2) === 'on') n.addEventListener(p.slice(2), a[p]);
    else n.setAttribute(p, a[p]);
  }
  if (k) (Array.isArray(k) ? k : [k]).forEach(c => c && n.appendChild(typeof c === 'string' ? document.createTextNode(c) : c));
  return n;
};
const uid4 = () => (crypto.randomUUID ? crypto.randomUUID()
  : 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
      const r = Math.random()*16|0; return (c==='x'?r:(r&0x3|0x8)).toString(16); }));

const TODAY = new Date();
const isoOf = d => { const z = new Date(d); return new Date(z.getTime() - z.getTimezoneOffset()*6e4).toISOString().slice(0,10); };
const TODAY_ISO  = isoOf(TODAY);
const CUR_PERIOD = TODAY_ISO.slice(0,7);
const MON = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
const MONL= ['January','February','March','April','May','June','July','August','September','October','November','December'];

const days = (a,b) => { if(!a) return 0; return Math.round((new Date(a+'T00:00:00') - new Date((b||TODAY_ISO)+'T00:00:00'))/864e5); };
const fmtDate  = s => { if(!s) return '—'; const p=String(s).slice(0,10).split('-'); return MON[+p[1]-1]+' '+(+p[2])+', '+p[0]; };
const fmtShort = s => { if(!s) return '—'; const p=String(s).slice(0,10).split('-'); return MON[+p[1]-1]+' '+(+p[2]); };
const fmtPeriod= p => { if(!p) return '—'; const x=p.split('-'); return MONL[+x[1]-1]+' '+x[0]; };
const money  = n => (n==null||n==='') ? '—' : '$'+Number(n).toLocaleString('en-US',{minimumFractionDigits:2,maximumFractionDigits:2});
const money0 = n => '$'+Math.round(Number(n)||0).toLocaleString('en-US');
const addMonths = (p,k) => { let [y,m]=p.split('-').map(Number); m+=k; y+=Math.floor((m-1)/12); m=((m-1)%12+12)%12+1; return y+'-'+String(m).padStart(2,'0'); };
const periodDue = (p,d) => p+'-'+String(Math.min(Math.max(+d||1,1),28)).padStart(2,'0');
const ord = d => { d=Number(d)||1; return d+(d%10===1&&d!==11?'st':d%10===2&&d!==12?'nd':d%10===3&&d!==13?'rd':'th'); };
const cleanName = s => String(s||'file').replace(/[^A-Za-z0-9._-]+/g,'_').slice(-80);

function toast(msg, bad) {
  const t = el('div', {class:'toast'+(bad?' bad':''), text:msg});
  document.body.appendChild(t);
  setTimeout(() => t.remove(), bad ? 5200 : 3200);
}

/* NYC rent-stabilized: the renewal offer must be served 90–150 days before
   the lease ends (DHCR form RTP-8). These two numbers drive the reminders. */
const RENEW_OPEN = 150, RENEW_CLOSE = 90;

const CFG = window.GL_CONFIG || {};
const CO  = CFG.COMPANY_NAME || 'Green Lodging LLC';

/* ------------------------------------------------------------ app state */
const S = {
  route:'today', session:null, me:null, sb:null, tab:{}, filter:{},
  period:CUR_PERIOD, loading:true,
  buildings:[], units:[], tenancies:[], leases:[], rent:[],
  utilAccounts:[], utilBills:[], complaints:[], cupdates:[],
  documents:[], profiles:[], invites:[]
};
const isStaff  = () => S.me && (S.me.role === 'owner' || S.me.role === 'manager');
const isOwner  = () => S.me && S.me.role === 'owner';

const byId    = (c,id) => S[c].find(x => x.id === id);
const bName   = id => { const b = byId('buildings', id); return b ? b.name : '—'; };
const uLabel  = id => { const u = byId('units', id); return u ? u.label : '—'; };
const uFull   = id => { const u = byId('units', id); return u ? (u.label + ' · ' + bName(u.building_id)) : '—'; };
const unitsOf = bid => S.units.filter(u => u.building_id === bid).sort(cmpUnit);
const cmpUnit = (a,b) => String(a.label||'').localeCompare(String(b.label||''), undefined, {numeric:true});
const activeLease = unitId => {
  const ls = S.leases.filter(l => l.unit_id === unitId);
  return ls.filter(l => !l.end_date || l.end_date >= TODAY_ISO)
           .sort((a,b)=>String(b.start_date).localeCompare(String(a.start_date)))[0]
      || ls.sort((a,b)=>String(b.end_date).localeCompare(String(a.end_date)))[0];
};
const leaseFor  = (unitId, period) => S.leases.filter(l => l.unit_id===unitId
  && (!l.start_date || l.start_date.slice(0,7) <= period)
  && (!l.end_date   || l.end_date.slice(0,7)   >= period))
  .sort((a,b)=>String(b.start_date).localeCompare(String(a.start_date)))[0];
const rentFor = (unitId, period) => S.rent.find(r => r.unit_id===unitId && r.period===period);
const myUnitIds = () => S.tenancies.filter(t => t.profile_id === (S.me && S.me.id)).map(t => t.unit_id);

/* ====================================================================
   CONNECT
   ==================================================================== */
function configProblem() {
  if (!window.supabase || !window.supabase.createClient) return 'The Supabase library did not load. Check your internet connection and refresh.';
  if (!CFG.SUPABASE_URL || CFG.SUPABASE_URL.indexOf('PASTE') === 0) return 'config.js still has the placeholder text in it. Open config.js and paste your Supabase Project URL.';
  if (!CFG.SUPABASE_ANON_KEY || CFG.SUPABASE_ANON_KEY.indexOf('PASTE') === 0) return 'config.js still has the placeholder text in it. Open config.js and paste your Supabase anon key.';
  if (!/^https:\/\/[^\s/]+\.[^\s/]+$/.test(CFG.SUPABASE_URL.replace(/\/$/,''))) return 'The Project URL in config.js does not look right. It should look like https://abcdefgh.supabase.co';
  return null;
}

function showSetupError(msg) {
  $('#root').innerHTML = '';
  $('#root').appendChild(
    el('div',{class:'authpage'},[
      el('div',{class:'authbar'},[ el('div',{class:'co', text:CO}) ]),
      el('div',{class:'authwrap'},[
        el('div',{class:'authcard'},[
          el('div',{class:'pad'},[
            el('h2',{style:'font-size:17px;margin-bottom:10px', text:'Not connected yet'}),
            el('div',{class:'errbox', text:msg}),
            el('p',{class:'authnote', style:'margin-top:14px',
              text:'Once config.js has the two values from Supabase in it, upload the folder again and this page will work.'})
          ])
        ])
      ])
    ])
  );
}

/* ====================================================================
   SIGN IN  /  SIGN UP
   ==================================================================== */
const LOGO = () => {
  const s = document.createElementNS('http://www.w3.org/2000/svg','svg');
  s.setAttribute('viewBox','0 0 32 32'); s.setAttribute('width','26'); s.setAttribute('height','26');
  s.innerHTML = '<rect width="32" height="32" rx="7" fill="rgba(255,255,255,.16)"/>'
    + '<path d="M8 23V13l8-5 8 5v10" stroke="currentColor" stroke-width="2.2" fill="none" stroke-linejoin="round"/>'
    + '<rect x="13.5" y="17" width="5" height="6" fill="currentColor"/>';
  return s;
};

function field(o) {
  const w = el('div',{class:'fld'+(o.type==='checkbox'?' check':'')});
  const i = el('input',{type:o.type||'text', id:o.id, placeholder:o.ph||'',
    autocomplete:o.ac||null, inputmode:o.im||null, value:o.value||null});
  if (o.type === 'checkbox') { w.appendChild(i); w.appendChild(el('label',{for:o.id, text:o.label})); }
  else { w.appendChild(el('label',{for:o.id, text:o.label})); w.appendChild(i); }
  if (o.help) w.appendChild(el('div',{class:'help', text:o.help}));
  return {wrap:w, input:i};
}

function renderAuth(mode) {
  const root = $('#root'); root.innerHTML = '';
  let tab = mode || 'tenant';

  const card = el('div',{class:'authcard'});
  const tabs = el('div',{class:'authtabs'});
  const pad  = el('div',{class:'pad'});

  function setTab(t) {
    tab = t;
    Array.from(tabs.children).forEach(b => b.setAttribute('aria-selected', b.dataset.k === t ? 'true' : 'false'));
    pad.innerHTML = '';
    (t === 'staff' ? paneStaff : t === 'signup' ? paneSignup : paneTenant)(pad, setTab);
  }
  [['tenant','Resident'],['staff','Management']].forEach(([k,l]) => {
    const b = el('button',{class:'authtab', text:l, onclick:()=>setTab(k)});
    b.dataset.k = k; tabs.appendChild(b);
  });

  card.appendChild(tabs); card.appendChild(pad);

  root.appendChild(el('div',{class:'authpage'},[
    el('div',{class:'authbar'},[
      el('div',{class:'co'},[LOGO(), CO]),
      el('div',{class:'tag', text:'Resident and management portal · Brooklyn, NY'})
    ]),
    el('div',{class:'authwrap'},[card])
  ]));
  setTab(tab === 'signup' ? 'signup' : tab);
  if (tab === 'signup') { tabs.querySelectorAll('.authtab').forEach(b=>b.setAttribute('aria-selected','false')); }
}

/* --- management: email + password ---------------------------------- */
function paneStaff(pad) {
  pad.appendChild(el('p',{class:'authnote', text:'For the owner, property manager and office staff.'}));
  const form = el('form',{class:'formstack'});
  const em = field({label:'Email', id:'st_email', type:'email', ac:'username', ph:'you@example.com'});
  const pw = field({label:'Password', id:'st_pw', type:'password', ac:'current-password'});
  const err = el('div',{class:'errbox hide'});
  const btn = el('button',{class:'btn pri big', type:'submit', text:'Sign in'});
  form.appendChild(em.wrap); form.appendChild(pw.wrap); form.appendChild(err); form.appendChild(btn);

  form.addEventListener('submit', async e => {
    e.preventDefault(); err.classList.add('hide');
    btn.disabled = true; btn.textContent = 'Signing in…';
    const { error } = await S.sb.auth.signInWithPassword({ email: em.input.value.trim(), password: pw.input.value });
    if (error) {
      err.textContent = friendlyAuthError(error); err.classList.remove('hide');
      btn.disabled = false; btn.textContent = 'Sign in';
    }
  });
  pad.appendChild(form);

  const f = el('div',{class:'authswitch'});
  f.appendChild(el('button',{class:'doclink', type:'button', text:'Forgot your password?', onclick:async()=>{
    const e2 = em.input.value.trim();
    if (!e2) { toast('Type your email above first, then tap this again.', true); return; }
    const { error } = await S.sb.auth.resetPasswordForEmail(e2, { redirectTo: location.origin + location.pathname });
    toast(error ? 'Could not send the reset email.' : 'Reset link sent — check your email.', !!error);
  }}));
  pad.appendChild(f);
}

/* --- resident sign in ---------------------------------------------- */
function paneTenant(pad, setTab) {
  const smsOn = !!CFG.ENABLE_SMS_LOGIN;
  pad.appendChild(el('p',{class:'authnote',
    text: smsOn ? 'Enter your mobile number and we will text you a 6-digit code.'
                : 'Sign in with the email and password you set up.'}));

  if (smsOn) { paneSms(pad, setTab); return; }

  const form = el('form',{class:'formstack'});
  const em = field({label:'Email', id:'tn_email', type:'email', ac:'username'});
  const pw = field({label:'Password', id:'tn_pw', type:'password', ac:'current-password'});
  const err = el('div',{class:'errbox hide'});
  const btn = el('button',{class:'btn pri big', type:'submit', text:'Sign in'});
  form.appendChild(em.wrap); form.appendChild(pw.wrap); form.appendChild(err); form.appendChild(btn);
  form.addEventListener('submit', async e => {
    e.preventDefault(); err.classList.add('hide');
    btn.disabled = true; btn.textContent = 'Signing in…';
    const { error } = await S.sb.auth.signInWithPassword({ email: em.input.value.trim(), password: pw.input.value });
    if (error) { err.textContent = friendlyAuthError(error); err.classList.remove('hide');
                 btn.disabled = false; btn.textContent = 'Sign in'; }
  });
  pad.appendChild(form);
  pad.appendChild(el('div',{class:'authswitch'},[
    'First time here? ',
    el('button',{class:'doclink', type:'button', text:'Set up your account with an invite code', onclick:()=>setTab('signup')})
  ]));
}

/* --- resident sign in by text message (only when SMS is switched on) - */
function paneSms(pad) {
  const form = el('form',{class:'formstack'});
  const ph = field({label:'Mobile number', id:'sm_phone', type:'tel', im:'tel', ph:'(718) 555-0134', ac:'tel'});
  const err = el('div',{class:'errbox hide'});
  const btn = el('button',{class:'btn pri big', type:'submit', text:'Text me a code'});
  form.appendChild(ph.wrap); form.appendChild(err); form.appendChild(btn);

  form.addEventListener('submit', async e => {
    e.preventDefault(); err.classList.add('hide');
    const digits = ph.input.value.replace(/\D/g,'');
    if (digits.length < 10) { err.textContent = 'Enter your full 10-digit mobile number.'; err.classList.remove('hide'); return; }
    const phone = digits.length === 10 ? (CFG.PHONE_COUNTRY_CODE||'+1') + digits : '+' + digits;
    btn.disabled = true; btn.textContent = 'Sending…';
    const { error } = await S.sb.auth.signInWithOtp({ phone });
    if (error) { err.textContent = friendlyAuthError(error); err.classList.remove('hide');
                 btn.disabled = false; btn.textContent = 'Text me a code'; return; }
    pad.innerHTML = '';
    pad.appendChild(el('p',{class:'authnote', text:'We texted a 6-digit code to '+ph.input.value+'. It expires in a few minutes.'}));
    const f2 = el('form',{class:'formstack'});
    const cd = field({label:'6-digit code', id:'sm_code', type:'text', im:'numeric', ph:'123456'});
    const e2 = el('div',{class:'errbox hide'});
    const b2 = el('button',{class:'btn pri big', type:'submit', text:'Sign in'});
    f2.appendChild(cd.wrap); f2.appendChild(e2); f2.appendChild(b2);
    f2.addEventListener('submit', async ev => {
      ev.preventDefault(); e2.classList.add('hide');
      b2.disabled = true; b2.textContent = 'Checking…';
      const { error:err2 } = await S.sb.auth.verifyOtp({ phone, token: cd.input.value.trim(), type:'sms' });
      if (err2) { e2.textContent = 'That code did not work. Check it and try again.'; e2.classList.remove('hide');
                  b2.disabled = false; b2.textContent = 'Sign in'; }
    });
    pad.appendChild(f2);
  });
  pad.appendChild(form);
}

/* --- resident first-time setup with an invite code ------------------ */
function paneSignup(pad, setTab) {
  pad.appendChild(el('p',{class:'authnote',
    text:'Your landlord gave you a code for your apartment. Use it once to create your account.'}));
  const form = el('form',{class:'formstack'});
  const code = field({label:'Invite code', id:'su_code', ph:'RALPH-2R-4K9', help:'From the slip you were given.'});
  const name = field({label:'Your full name', id:'su_name', ac:'name'});
  const phone= field({label:'Mobile number', id:'su_phone', type:'tel', im:'tel', ph:'(718) 555-0134'});
  const em   = field({label:'Email', id:'su_email', type:'email', ac:'username'});
  const pw   = field({label:'Choose a password', id:'su_pw', type:'password', ac:'new-password', help:'At least 8 characters.'});
  const err  = el('div',{class:'errbox hide'});
  const btn  = el('button',{class:'btn pri big', type:'submit', text:'Create my account'});
  [code,name,phone,em,pw].forEach(f => form.appendChild(f.wrap));
  form.appendChild(err); form.appendChild(btn);

  form.addEventListener('submit', async e => {
    e.preventDefault(); err.classList.add('hide');
    if (pw.input.value.length < 8) { err.textContent = 'Your password needs at least 8 characters.'; err.classList.remove('hide'); return; }
    if (!code.input.value.trim())  { err.textContent = 'Enter the invite code from your slip.'; err.classList.remove('hide'); return; }
    btn.disabled = true; btn.textContent = 'Creating…';

    const { data, error } = await S.sb.auth.signUp({
      email: em.input.value.trim(), password: pw.input.value,
      options:{ data:{ full_name: name.input.value.trim() } }
    });
    if (error) { err.textContent = friendlyAuthError(error); err.classList.remove('hide');
                 btn.disabled=false; btn.textContent='Create my account'; return; }

    if (!data.session) {
      const s2 = await S.sb.auth.signInWithPassword({ email: em.input.value.trim(), password: pw.input.value });
      if (s2.error) {
        pad.innerHTML = '';
        pad.appendChild(el('div',{class:'okbox', text:'Account created. Check your email to confirm it, then come back and sign in — and enter your invite code then.'}));
        return;
      }
    }
    const r = await S.sb.rpc('redeem_invite', {
      p_code: code.input.value.trim(), p_full_name: name.input.value.trim(), p_phone: phone.input.value.trim()
    });
    if (r.error || (r.data && r.data.ok === false)) {
      err.textContent = (r.data && r.data.error) || 'That invite code did not work.';
      err.classList.remove('hide'); btn.disabled=false; btn.textContent='Create my account'; return;
    }
    location.reload();
  });
  pad.appendChild(form);
  pad.appendChild(el('div',{class:'authswitch'},[
    'Already set up? ',
    el('button',{class:'doclink', type:'button', text:'Sign in instead', onclick:()=>setTab('tenant')})
  ]));
}

/* --- a signed-in tenant who has not claimed an apartment yet -------- */
function renderClaim() {
  const root = $('#root'); root.innerHTML = '';
  const pad = el('div',{class:'pad'});
  pad.appendChild(el('h2',{style:'font-size:17px;margin-bottom:8px', text:'One more step'}));
  pad.appendChild(el('p',{class:'authnote', text:'Enter the invite code for your apartment. Your landlord gives you this once.'}));
  const form = el('form',{class:'formstack'});
  const code = field({label:'Invite code', id:'cl_code', ph:'RALPH-2R-4K9'});
  const name = field({label:'Your full name', id:'cl_name', value:(S.me && S.me.full_name) || ''});
  const phone= field({label:'Mobile number', id:'cl_phone', type:'tel', im:'tel', value:(S.me && S.me.phone) || ''});
  const err  = el('div',{class:'errbox hide'});
  const btn  = el('button',{class:'btn pri big', type:'submit', text:'Connect my apartment'});
  [code,name,phone].forEach(f=>form.appendChild(f.wrap));
  form.appendChild(err); form.appendChild(btn);
  form.addEventListener('submit', async e => {
    e.preventDefault(); err.classList.add('hide');
    btn.disabled=true; btn.textContent='Checking…';
    const r = await S.sb.rpc('redeem_invite', { p_code: code.input.value.trim(),
      p_full_name: name.input.value.trim(), p_phone: phone.input.value.trim() });
    if (r.error || (r.data && r.data.ok === false)) {
      err.textContent = (r.data && r.data.error) || 'That code did not work.';
      err.classList.remove('hide'); btn.disabled=false; btn.textContent='Connect my apartment'; return;
    }
    location.reload();
  });
  pad.appendChild(form);
  pad.appendChild(el('div',{class:'authswitch'},[
    el('button',{class:'doclink', type:'button', text:'Sign out', onclick:()=>S.sb.auth.signOut().then(()=>location.reload())})
  ]));
  root.appendChild(el('div',{class:'authpage'},[
    el('div',{class:'authbar'},[ el('div',{class:'co'},[LOGO(), CO]) ]),
    el('div',{class:'authwrap'},[ el('div',{class:'authcard'},[pad]) ])
  ]));
}

function friendlyAuthError(e) {
  const m = String(e && e.message || '').toLowerCase();
  if (m.includes('invalid login')) return 'That email and password do not match. Check for typos, or use "Forgot your password?".';
  if (m.includes('email not confirmed')) return 'Your email is not confirmed yet. Check your inbox for the confirmation link.';
  if (m.includes('already registered') || m.includes('already been registered')) return 'There is already an account with that email. Sign in instead.';
  if (m.includes('rate') || m.includes('too many')) return 'Too many attempts. Wait a minute and try again.';
  if (m.includes('sms') || m.includes('phone')) return 'Text-message sign-in is not switched on yet. Use email and password.';
  if (m.includes('password')) return 'That password is too short or too weak. Use at least 8 characters.';
  return (e && e.message) || 'Something went wrong. Try again.';
}

/* ====================================================================
   LOAD DATA
   ==================================================================== */
async function loadAll() {
  const q = (t, sel) => S.sb.from(t).select(sel || '*');
  const jobs = [
    ['buildings',    q('buildings')],
    ['units',        q('units')],
    ['tenancies',    q('tenancies')],
    ['leases',       q('leases')],
    ['rent',         q('rent_payments')],
    ['complaints',   q('complaints')],
    ['cupdates',     q('complaint_updates')],
    ['documents',    q('documents')],
    ['utilBills',    q('utility_bills')]
  ];
  if (isStaff()) {
    jobs.push(['utilAccounts', q('utility_accounts')]);
    jobs.push(['profiles',     q('profiles')]);
    jobs.push(['invites',      q('unit_invites')]);
  }
  const res = await Promise.all(jobs.map(j => j[1]));
  res.forEach((r, i) => {
    const key = jobs[i][0];
    if (r.error) { console.warn('load', key, r.error.message); S[key] = []; }
    else S[key] = r.data || [];
  });
  S.loading = false;
}

async function loadMe() {
  const { data, error } = await S.sb.from('profiles').select('*').eq('id', S.session.user.id).maybeSingle();
  if (error) { console.warn(error.message); }
  S.me = data || { id:S.session.user.id, role:'tenant', full_name:'', email:S.session.user.email };
}

/* ====================================================================
   FILES
   ==================================================================== */
async function uploadTo(path, file) {
  const { error } = await S.sb.storage.from('docs').upload(path, file, { upsert:false, contentType:file.type || undefined });
  if (error) throw error;
  return path;
}
function staffPath(buildingId, unitId, tenantVisible, filename) {
  const stamp = uid4().slice(0,8) + '-' + cleanName(filename);
  return (tenantVisible && unitId) ? ('t/' + unitId + '/' + stamp) : ('s/' + (buildingId || 'misc') + '/' + stamp);
}
function tenantInboxPath(unitId, filename) {
  return 't/' + unitId + '/inbox/' + uid4().slice(0,8) + '-' + cleanName(filename);
}
async function openFile(path) {
  if (!path) return;
  const { data, error } = await S.sb.storage.from('docs').createSignedUrl(path, 3600);
  if (error || !data) { toast('Could not open that file.', true); return; }
  window.open(data.signedUrl, '_blank', 'noopener');
}
function fileBtn(path, label) {
  if (!path) return el('span',{class:'sub', text:'—'});
  return el('button',{class:'doclink', type:'button', text:label||'View', onclick:()=>openFile(path)});
}

/* Records a document row; uploads first. Returns the row or null. */
async function fileDocument(file, meta) {
  if (!file) return null;
  if (file.size > 20*1024*1024) { toast('That file is larger than 20 MB. Try a photo instead of a scan.', true); return null; }
  const path = meta.asTenant ? tenantInboxPath(meta.unit_id, file.name)
                             : staffPath(meta.building_id, meta.unit_id, meta.tenant_visible, file.name);
  try { await uploadTo(path, file); }
  catch (e) { toast('Upload failed: ' + (e.message || 'unknown error'), true); return null; }
  const row = {
    building_id: meta.building_id || null, unit_id: meta.unit_id || null,
    category: meta.category || 'Other', name: file.name, storage_path: path,
    size_bytes: file.size, content_type: file.type || null,
    tenant_visible: meta.asTenant ? true : !!meta.tenant_visible,
    note: meta.note || null, uploaded_by: S.me.id
  };
  const { data, error } = await S.sb.from('documents').insert(row).select().single();
  if (error) { toast('File uploaded but not filed: ' + error.message, true); return { storage_path: path }; }
  S.documents.push(data);
  return data;
}

/* ====================================================================
   SAVE HELPERS
   ==================================================================== */
async function put(table, stateKey, row, id) {
  let res;
  if (id) res = await S.sb.from(table).update(row).eq('id', id).select().single();
  else    res = await S.sb.from(table).insert(row).select().single();
  if (res.error) { toast(friendlyDbError(res.error), true); return null; }
  const arr = S[stateKey];
  const i = arr.findIndex(x => x.id === res.data.id);
  if (i >= 0) arr[i] = res.data; else arr.push(res.data);
  return res.data;
}
async function del(table, stateKey, id, keyCol) {
  const col = keyCol || 'id';
  const { error } = await S.sb.from(table).delete().eq(col, id);
  if (error) { toast(friendlyDbError(error), true); return false; }
  S[stateKey] = S[stateKey].filter(x => x[col] !== id);
  return true;
}
function friendlyDbError(e) {
  const m = String(e && e.message || '');
  if (/row-level security|violates row-level/i.test(m)) return 'Your account is not allowed to do that.';
  if (/duplicate key/i.test(m) && /unit_invites/i.test(m)) return 'That invite code already exists. Pick another.';
  if (/duplicate key/i.test(m) && /units/i.test(m)) return 'That unit number already exists in this building.';
  if (/duplicate key/i.test(m) && /rent_payments/i.test(m)) return 'There is already a rent record for that unit and month.';
  if (/duplicate key/i.test(m)) return 'That record already exists.';
  if (/foreign key/i.test(m)) return 'Something it points at was deleted. Refresh the page.';
  return m || 'Could not save.';
}

/* ====================================================================
   MODAL / FORM ENGINE
   ==================================================================== */
function closeModal(){ $('#modalRoot').innerHTML=''; document.body.style.overflow=''; }

function openForm(o) {
  const root = $('#modalRoot'); root.innerHTML=''; document.body.style.overflow='hidden';
  const body = el('div',{class:'mb'});
  if (o.note) body.appendChild(el('div',{class:'note', text:o.note}));
  const errBox = el('div',{class:'errbox hide'});
  const inputs = {};

  const make = f => {
    const id = 'gf_' + f.k;
    const v  = (o.values || {})[f.k];
    const w  = el('div',{class:'fld' + (f.t==='checkbox'?' check':'')});
    let inp;
    if (f.t === 'select') {
      inp = el('select',{id});
      if (f.ph) inp.appendChild(el('option',{value:'', text:f.ph}));
      (f.opts||[]).forEach(x => {
        const val = (typeof x==='string') ? x : x.v, lab = (typeof x==='string') ? x : x.l;
        inp.appendChild(el('option',{value:val, text:lab}));
      });
      inp.value = (v==null ? '' : String(v));
      if (inp.selectedIndex < 0) inp.selectedIndex = 0;
    } else if (f.t === 'textarea') {
      inp = el('textarea',{id, placeholder:f.ph||''}); inp.value = v || '';
    } else if (f.t === 'file') {
      inp = el('input',{id, type:'file', accept:f.accept || 'image/*,application/pdf'});
    } else if (f.t === 'checkbox') {
      inp = el('input',{id, type:'checkbox'}); inp.checked = !!v;
    } else {
      inp = el('input',{id, type:f.t||'text', placeholder:f.ph||'',
        step: f.t==='number' ? '0.01' : null, inputmode: f.t==='number' ? 'decimal' : null});
      inp.value = (v==null ? '' : v);
    }
    if (f.t === 'checkbox') { w.appendChild(inp); w.appendChild(el('label',{for:id, text:f.l})); }
    else { w.appendChild(el('label',{for:id, text:f.l})); w.appendChild(inp); }
    if (f.help) w.appendChild(el('div',{class:'help', text:f.help}));
    inputs[f.k] = { inp, f };
    return w;
  };

  for (let i=0; i<o.fields.length; i++) {
    const f = o.fields[i];
    if (f.t === 'hr') { body.appendChild(el('div',{class:'eyebrow', text:f.l, style:'margin-top:4px'})); continue; }
    const n = o.fields[i+1];
    if (f.half && n && n.half) { const r = el('div',{class:'row2'}); r.appendChild(make(f)); r.appendChild(make(n)); body.appendChild(r); i++; }
    else body.appendChild(make(f));
  }
  body.appendChild(errBox);

  const foot = el('div',{class:'mf'});
  if (o.danger && isOwner()) foot.appendChild(el('button',{class:'btn danger', text:o.danger.label, style:'margin-right:auto',
    onclick: async () => { if (!confirm('Delete this permanently? This cannot be undone.')) return; closeModal(); await o.danger.fn(); render(); }}));
  foot.appendChild(el('button',{class:'btn', text:'Cancel', onclick:closeModal}));
  const go = el('button',{class:'btn pri', text:o.submit || 'Save'});
  foot.appendChild(go);

  const modal = el('div',{class:'modal'},[ el('div',{class:'mh'},[el('h3',{text:o.title})]), body, foot ]);
  const scrim = el('div',{class:'scrim', onclick:e=>{ if(e.target===scrim) closeModal(); }},[modal]);
  root.appendChild(scrim);
  const esc = e => { if (e.key === 'Escape') { closeModal(); document.removeEventListener('keydown', esc); } };
  document.addEventListener('keydown', esc);
  const first = body.querySelector('input,select,textarea'); if (first) first.focus();

  go.addEventListener('click', async () => {
    const vals = {}, files = {};
    let missing = null;
    for (const k in inputs) {
      const { inp, f } = inputs[k];
      if (f.t === 'file') { files[k] = (inp.files && inp.files[0]) || null; continue; }
      let v = (f.t === 'checkbox') ? inp.checked : inp.value;
      if (f.req && (v === '' || v == null)) missing = missing || f.l;
      if (f.t === 'number') v = (v === '' ? null : Number(v));
      if (typeof v === 'string') v = v.trim();
      if (v === '') v = null;
      vals[k] = v;
    }
    if (missing) { errBox.textContent = '“' + missing + '” is required.'; errBox.classList.remove('hide'); return; }
    errBox.classList.add('hide');
    go.disabled = true; go.textContent = 'Saving…';
    try { await o.onSubmit(vals, files); closeModal(); render(); }
    catch (err) {
      go.disabled = false; go.textContent = o.submit || 'Save';
      errBox.textContent = (err && err.message) || 'Could not save.'; errBox.classList.remove('hide');
    }
  });
}

const buildingOpts = () => S.buildings.slice().sort((a,b)=>a.name.localeCompare(b.name)).map(b=>({v:b.id,l:b.name}));
const unitOptsAll  = () => S.units.slice()
  .sort((a,b)=>(bName(a.building_id)+a.label).localeCompare(bName(b.building_id)+b.label, undefined, {numeric:true}))
  .map(u=>({v:u.id, l:bName(u.building_id)+' — '+u.label}));

/* ====================================================================
   ALERT ENGINE   (staff view)
   ==================================================================== */
function buildAlerts() {
  const A = [];
  const push = (sev,type,t,d,when,go) => A.push({sev,type,t,d,when,go});

  S.leases.forEach(l => {
    if (!l.end_date) return;
    const n = days(l.end_date);
    if (!byId('units', l.unit_id)) return;
    const who = l.tenant_name || 'vacant';
    if (n < 0)
      push('crit','Lease', uFull(l.unit_id)+' — lease expired',
        who+' · expired '+fmtDate(l.end_date)+', '+Math.abs(n)+' days ago. The tenancy continues month-to-month until renewed.', Math.abs(n)+'d ago','buildings');
    else if (n <= RENEW_CLOSE)
      push('crit','Renewal', uFull(l.unit_id)+' — renewal offer is late',
        'Lease ends '+fmtDate(l.end_date)+'. The 90–150 day window to serve the renewal offer has closed. Serve DHCR form RTP-8 immediately.', 'in '+n+'d','buildings');
    else if (n <= RENEW_OPEN)
      push('warn','Renewal', uFull(l.unit_id)+' — serve the renewal lease now',
        who+' · lease ends '+fmtDate(l.end_date)+'. You are inside the 90–150 day window to offer a renewal (DHCR form RTP-8).', 'in '+n+'d','buildings');
    else if (n <= 210)
      push('info','Lease', uFull(l.unit_id)+' — renewal window opens soon',
        'Lease ends '+fmtDate(l.end_date)+'. You may serve the renewal offer from '+fmtDate(isoOf(new Date(new Date(l.end_date+'T00:00:00') - RENEW_OPEN*864e5)))+'.', 'in '+n+'d','buildings');

    const u = byId('units', l.unit_id);
    if (u && u.is_stabilized && l.rider_signed === false && n > 0)
      push('warn','Rider', uFull(l.unit_id)+' — rent stabilization rider not signed',
        'A signed DHCR rider must be attached to every stabilized lease.', '', 'buildings');
  });

  [addMonths(CUR_PERIOD,-1), CUR_PERIOD].forEach(period => {
    S.units.forEach(u => {
      const l = leaseFor(u.id, period);
      if (!l || !Number(l.monthly_rent)) return;
      const r = rentFor(u.id, period);
      const due  = Number(l.monthly_rent);
      const paid = r ? Number(r.amount_paid||0) : 0;
      if (paid >= due - 0.5) return;
      const dueDate = periodDue(period, l.rent_due_day||1);
      const n = days(dueDate), bal = due - paid;
      if (n < 0)
        push('crit','Rent', uFull(u.id)+' — '+fmtPeriod(period)+' rent unpaid',
          (l.tenant_name||'tenant')+' · '+money(bal)+' outstanding, '+Math.abs(n)+' days past the '+fmtShort(dueDate)+' due date.', money0(bal),'rent');
      else if (n <= 7)
        push('warn','Rent', uFull(u.id)+' — rent due '+fmtShort(dueDate),
          (l.tenant_name||'tenant')+' · '+money(bal)+' due in '+n+' day'+(n===1?'':'s')+'.', money0(bal),'rent');
    });
  });

  S.utilBills.forEach(b => {
    if (b.paid_date || !b.due_date) return;
    const n = days(b.due_date);
    const where = b.unit_id ? uFull(b.unit_id) : bName(b.building_id);
    const lab = String(b.utility_type||'utility').replace(/^./,c=>c.toUpperCase());
    if (n < 0)
      push('crit','Utility', where+' — '+lab+' bill overdue',
        (b.provider?b.provider+' · ':'')+money(b.amount)+' was due '+fmtDate(b.due_date)+' ('+Math.abs(n)+' days ago). Late fees and liens accrue.', money0(b.amount),'utilities');
    else if (n <= 14)
      push('warn','Utility', where+' — '+lab+' bill due '+fmtShort(b.due_date),
        (b.provider?b.provider+' · ':'')+money(b.amount)+' due in '+n+' day'+(n===1?'':'s')+'.', money0(b.amount),'utilities');
  });

  S.utilAccounts.forEach(a => {
    if (!a.due_day) return;
    const cycle = Number(a.cycle_months||1);
    for (let k=0;k<=1;k++) {
      const period = addMonths(CUR_PERIOD,k);
      if (cycle > 1 && (((+period.split('-')[1]) - 1) % cycle !== 0)) continue;
      const dueDate = periodDue(period, a.due_day);
      const n = days(dueDate);
      if (n < 0 || n > 10) continue;
      if (S.utilBills.some(b => b.account_id === a.id && b.due_date && b.due_date.slice(0,7) === period)) continue;
      push('info','Expected', bName(a.building_id)+' — '+a.utility_type+' bill expected by '+fmtShort(dueDate),
        (a.provider||'Account')+(a.account_number?' #'+a.account_number:'')+' bills around the '+ord(a.due_day)+'. Nothing entered for '+fmtPeriod(period)+' yet.', 'in '+n+'d','utilities');
    }
  });

  S.complaints.forEach(c => {
    if (c.status === 'resolved') return;
    const n = Math.abs(days(c.opened_date));
    const official = ['hpd','dob','311'].indexOf(c.source) >= 0;
    const where = c.unit_id ? uFull(c.unit_id) : bName(c.building_id);
    if (official)
      push(n>14?'crit':'warn','Violation', where+' — '+String(c.source).toUpperCase()+' complaint open '+n+' days',
        (c.title||'Complaint')+'. Official complaints become violations if not certified as corrected.', n+'d','complaints');
    else if (n >= 14)
      push(n>30?'crit':'warn','Complaint', where+' — tenant complaint open '+n+' days',
        (c.title||'Complaint')+'. No resolution recorded.', n+'d','complaints');
    else if (n >= 3)
      push('info','Complaint', where+' — '+(c.title||'complaint'),
        'Opened '+fmtDate(c.opened_date)+'. Add an update so the record shows progress.', n+'d','complaints');
  });

  const yr = TODAY.getFullYear(), regDue = yr+'-07-31', nReg = days(regDue);
  if (S.buildings.length && nReg >= -60 && nReg <= 75)
    push(nReg<0?'crit':'warn','DHCR','Annual rent registration — due '+fmtDate(regDue),
      nReg<0 ? 'The '+yr+' Annual Rent Registration (RR-2) deadline has passed. Unregistered units cannot take rent increases.'
             : 'File the '+yr+' Annual Rent Registration for every stabilized unit with DHCR by July 31.',
      nReg<0 ? Math.abs(nReg)+'d ago' : 'in '+nReg+'d', 'buildings');

  const rank = {crit:0, warn:1, info:2};
  return A.sort((a,b) => rank[a.sev]-rank[b.sev]);
}

/* ====================================================================
   STAFF SHELL
   ==================================================================== */
const NAV = [
  {k:'today',      l:'Today',      c:'Overview'},
  {k:'buildings',  l:'Buildings',  c:'Portfolio'},
  {k:'rent',       l:'Rent',       c:'Ledger'},
  {k:'utilities',  l:'Utilities',  c:'Bills & accounts'},
  {k:'complaints', l:'Complaints', c:'Issues & violations'},
  {k:'documents',  l:'Documents',  c:'File room'},
  {k:'people',     l:'People',     c:'Accounts & invites'}
];

function renderStaffShell() {
  const root = $('#root');
  if (!$('.app')) {
    root.innerHTML = '';
    root.appendChild(el('div',{class:'app'},[
      el('aside',{class:'rail'},[
        el('div',{class:'brand'},[
          el('div',{class:'mark'},[CO]),
          el('div',{class:'sub', text: S.buildings.length + ' buildings · Brooklyn'})
        ]),
        el('nav',{class:'navlist', id:'nav'}),
        el('div',{class:'railfoot', id:'railfoot'})
      ]),
      el('main',{class:'main'},[
        el('header',{class:'topbar'},[
          el('div',{},[ el('span',{class:'crumb', id:'crumb'}), el('h1',{id:'ttl'}) ]),
          el('div',{class:'spacer'}),
          el('div',{id:'topact', style:'display:flex;gap:8px;flex-wrap:wrap'})
        ]),
        el('div',{class:'wrap', id:'view'})
      ])
    ]));
  }
  const nav = $('#nav'); nav.innerHTML='';
  const alerts = buildAlerts();
  const crit = alerts.filter(a=>a.sev==='crit').length;
  const openC = S.complaints.filter(c=>c.status!=='resolved').length;
  NAV.forEach(it => {
    const b = el('button',{class:'navbtn', onclick:()=>go(it.k)},[it.l]);
    b.setAttribute('aria-current', S.route===it.k ? 'true':'false');
    if (it.k==='today' && crit) b.appendChild(el('span',{class:'cnt', text:String(crit)}));
    if (it.k==='complaints' && openC) b.appendChild(el('span',{class:'cnt', text:String(openC), style:'background:var(--ink-3)'}));
    nav.appendChild(b);
  });
  const rf = $('#railfoot'); rf.innerHTML='';
  rf.appendChild(el('div',{},[
    el('span',{class:'who', text:(S.me.full_name || S.me.email || 'Signed in')}),
    el('span',{text: S.me.role === 'owner' ? 'Owner' : 'Property manager'})
  ]));
  rf.appendChild(el('button',{class:'btn sm', text:'Sign out', onclick:signOut}));

  const cur = NAV.find(n => n.k === S.route) || NAV[0];
  $('#crumb').textContent = cur.c; $('#ttl').textContent = cur.l;
  const act = $('#topact'); act.innerHTML='';
  const view = $('#view'); view.innerHTML='';
  ({ today:vToday, buildings:vBuildings, rent:vRent, utilities:vUtilities,
     complaints:vComplaints, documents:vDocuments, people:vPeople }[S.route] || vToday)(view, act, alerts);
}

function go(r){ S.route = r; window.scrollTo(0,0); render(); }
async function signOut(){ await S.sb.auth.signOut(); location.reload(); }

/* ---------------------------------------------------------- TODAY */
function vToday(v, act, alerts) {
  act.appendChild(el('button',{class:'btn', text:'Record rent', onclick:()=>go('rent')}));
  act.appendChild(el('button',{class:'btn pri', text:'Log a complaint', onclick:()=>fComplaint()}));

  let expected=0, collected=0;
  S.units.forEach(u => {
    const l = leaseFor(u.id, CUR_PERIOD); if (!l || !Number(l.monthly_rent)) return;
    expected += Number(l.monthly_rent);
    const r = rentFor(u.id, CUR_PERIOD); collected += r ? Number(r.amount_paid||0) : 0;
  });
  const occupied = S.units.filter(u => activeLease(u.id)).length;
  const unpaidUtil = S.utilBills.filter(b=>!b.paid_date).reduce((s,b)=>s+Number(b.amount||0),0);
  const crit = alerts.filter(a=>a.sev==='crit').length;

  const kpi = (val,lab,note,cls) => {
    const k = el('div',{class:'kpi'+(cls?' '+cls:'')});
    k.appendChild(el('div',{class:'v', text:val}));
    k.appendChild(el('div',{class:'l', text:lab}));
    if (note) k.appendChild(el('div',{class:'n', text:note}));
    return k;
  };
  const kp = el('div',{class:'kpis'});
  kp.appendChild(kpi(money0(collected), fmtPeriod(CUR_PERIOD)+' collected',
    expected ? money0(Math.max(expected-collected,0))+' still outstanding of '+money0(expected) : 'No rents entered yet',
    (expected && collected>=expected) ? 'brand' : (expected ? 'warn' : '')));
  kp.appendChild(kpi(String(crit),'Needs action today', crit?'Overdue rent, late filings or violations':'Nothing overdue', crit?'crit':'brand'));
  kp.appendChild(kpi(occupied+'/'+S.units.length,'Units leased',
    S.units.length ? (S.units.length-occupied)+' with no active lease' : 'Add your units to begin'));
  kp.appendChild(kpi(money0(unpaidUtil),'Utility bills unpaid',
    S.utilBills.filter(b=>!b.paid_date).length+' open bill(s)', unpaidUtil?'warn':'brand'));
  v.appendChild(kp);

  const stack = el('div',{class:'stack', style:'margin-top:16px'});

  const steps = [
    {d:S.units.length>0,        t:'Add your apartments and stores',   s:'Buildings → pick a building → Add unit.',                        g:'buildings'},
    {d:S.leases.length>0,       t:'Enter one lease per occupied unit', s:'Tenant name, rent, start and end date. This drives every reminder.', g:'buildings'},
    {d:S.utilAccounts.length>0, t:'Add your utility accounts',        s:'Con Edison, National Grid, NYC DEP — with the day each bills.',  g:'utilities'},
    {d:S.rent.length>0,         t:'Record your first rent payment',   s:'Rent → find the unit → Record. Attach the check photo.',         g:'rent'},
    {d:S.invites.length>0,      t:'Invite your first tenant',         s:'People → Create invite code, then hand the slip to the tenant.',  g:'people'}
  ];
  if (steps.some(s=>!s.d)) {
    const p = el('div',{class:'panel'});
    p.appendChild(el('div',{class:'panel-h'},[el('h2',{text:'Getting set up'}), el('div',{class:'spacer'}),
      el('span',{class:'eyebrow', text: steps.filter(s=>s.d).length+' of '+steps.length+' done'})]));
    steps.forEach(s => {
      const row = el('div',{class:'chk'+(s.d?' done':'')});
      row.appendChild(el('div',{class:'mk', text:s.d?'✓':''}));
      row.appendChild(el('div',{class:'tx'},[ el('b',{text:s.t}), el('span',{text:s.s}) ]));
      if (!s.d) row.appendChild(el('button',{class:'btn sm', text:'Go', onclick:()=>go(s.g)}));
      p.appendChild(row);
    });
    stack.appendChild(p);
  }

  const p2 = el('div',{class:'panel'});
  p2.appendChild(el('div',{class:'panel-h'},[el('h2',{text:'What needs you'}), el('div',{class:'spacer'}),
    el('span',{class:'eyebrow', text: alerts.length+' item'+(alerts.length===1?'':'s')})]));
  if (!alerts.length) {
    p2.appendChild(el('div',{class:'empty'},[
      el('strong',{text:'Nothing is overdue.'}),
      'Once leases, rents and utility accounts are entered, deadlines appear here on their own.'
    ]));
  } else {
    const list = el('div',{class:'alerts'});
    alerts.slice(0,50).forEach(a => {
      const row = el('div',{class:'alert '+a.sev});
      const b = el('div',{class:'body'});
      b.appendChild(el('div',{style:'display:flex;gap:8px;align-items:center;flex-wrap:wrap'},[
        el('span',{class:'pill '+(a.sev==='crit'?'crit':a.sev==='warn'?'warn':'info'), text:a.type}),
        el('span',{class:'t', text:a.t})
      ]));
      b.appendChild(el('div',{class:'d', text:a.d}));
      row.appendChild(b);
      if (a.when) row.appendChild(el('div',{class:'when', text:a.when}));
      row.appendChild(el('button',{class:'btn sm', text:'Open', onclick:()=>go(a.go)}));
      list.appendChild(row);
    });
    p2.appendChild(list);
  }
  stack.appendChild(p2);
  v.appendChild(stack);
}

/* ------------------------------------------------------ BUILDINGS */
function vBuildings(v, act) {
  act.appendChild(el('button',{class:'btn', text:'Add building', onclick:()=>fBuilding()}));
  act.appendChild(el('button',{class:'btn pri', text:'Add unit', onclick:()=>fUnit()}));

  if (!S.buildings.length) {
    v.appendChild(el('div',{class:'panel'},[el('div',{class:'empty'},[el('strong',{text:'No buildings yet.'}),'Add your first building to begin.'])]));
    return;
  }
  const f = el('div',{class:'filters'});
  const sel = el('select',{id:'flt_b', onchange:e=>{S.filter.b = e.target.value; render();}});
  sel.appendChild(el('option',{value:'', text:'All buildings'}));
  S.buildings.forEach(b => sel.appendChild(el('option',{value:b.id, text:b.name})));
  sel.value = S.filter.b || '';
  f.appendChild(sel); v.appendChild(f);

  const list = (S.filter.b ? S.buildings.filter(b=>b.id===S.filter.b) : S.buildings)
    .slice().sort((a,b)=>a.name.localeCompare(b.name));
  const stack = el('div',{class:'stack'});

  list.forEach(b => {
    const us = unitsOf(b.id);
    const p = el('div',{class:'panel'});
    const h = el('div',{class:'panel-h'});
    h.appendChild(el('div',{},[
      el('div',{class:'eyebrow', text:'Brooklyn, NY ' + (b.zip||'')}),
      el('h2',{text:b.name})
    ]));
    h.appendChild(el('div',{class:'spacer'}));
    h.appendChild(el('button',{class:'btn sm', text:'Edit', onclick:()=>fBuilding(b)}));
    h.appendChild(el('button',{class:'btn sm', text:'+ Unit', onclick:()=>fUnit(null,b.id)}));
    p.appendChild(h);

    if (!us.length) {
      p.appendChild(el('div',{class:'empty'},[el('strong',{text:'No units entered.'}),'Add each apartment and each store front.']));
    } else {
      const t = el('table',{class:'t'});
      t.appendChild(el('thead',{},[el('tr',{html:'<th>Unit</th><th>Type</th><th>Tenant</th><th class="r">Rent</th><th>Lease ends</th><th>Status</th><th></th>'})]));
      const tb = el('tbody');
      us.forEach(u => {
        const l = activeLease(u.id);
        const n = (l && l.end_date) ? days(l.end_date) : null;
        let pill;
        if (!l) pill = el('span',{class:'pill mute', text:'No lease'});
        else if (n<0) pill = el('span',{class:'pill crit', text:'Expired'});
        else if (n<=RENEW_CLOSE) pill = el('span',{class:'pill crit', text:'Renew now'});
        else if (n<=RENEW_OPEN)  pill = el('span',{class:'pill warn', text:'Renewal window'});
        else pill = el('span',{class:'pill settled', text:'Current'});
        const tr = el('tr');
        const c1 = el('td',{},[ el('div',{style:'font-weight:600', text:u.label}) ]);
        if (u.is_stabilized) c1.appendChild(el('div',{class:'sub', text:'Rent stabilized'}));
        tr.appendChild(c1);
        tr.appendChild(el('td',{class:'sub', text: u.unit_type==='commercial' ? 'Commercial' : 'Apartment'}));
        tr.appendChild(el('td',{text: l ? (l.tenant_name||'—') : '—'}));
        tr.appendChild(el('td',{class:'r mono', text: l && l.monthly_rent ? money(l.monthly_rent) : '—'}));
        tr.appendChild(el('td',{class:'mono', style:'font-size:12.5px', text: l ? fmtDate(l.end_date) : '—'}));
        tr.appendChild(el('td',{},[pill]));
        tr.appendChild(el('td',{class:'r'},[
          el('button',{class:'btn sm', text: l ? 'Lease' : 'Add lease', onclick:()=>fLease(l,u)}),
          el('button',{class:'btn sm', text:'Edit', style:'margin-left:6px', onclick:()=>fUnit(u)})
        ]));
        tb.appendChild(tr);
      });
      t.appendChild(tb);
      p.appendChild(el('div',{class:'tblwrap'},[t]));
    }
    stack.appendChild(p);
  });
  v.appendChild(stack);
}

function fBuilding(b) {
  openForm({
    title: b ? 'Edit building' : 'Add a building',
    values: b || {},
    fields: [
      {k:'name', l:'Building name', t:'text', req:true, ph:'1403 Fulton Street', help:'Use the street address — that is how you recognise it.'},
      {k:'address', l:'Full address', t:'text', ph:'1403 Fulton Street, Brooklyn, NY'},
      {k:'zip', l:'ZIP code', t:'text', half:true, ph:'11216'},
      {k:'block_lot', l:'Block / lot or BIN', t:'text', half:true},
      {k:'dhcr_id', l:'DHCR registration number', t:'text', help:'Kept here so you never hunt for it at registration time.'},
      {k:'notes', l:'Notes', t:'textarea', ph:'Boiler serviced by…, super’s phone…'}
    ],
    danger: b ? {label:'Delete building', fn:()=>del('buildings','buildings',b.id)} : null,
    onSubmit: async v => { await put('buildings','buildings', {
      name:v.name, address:v.address, zip:v.zip, block_lot:v.block_lot, dhcr_id:v.dhcr_id, notes:v.notes
    }, b && b.id); toast('Building saved'); }
  });
}

function fUnit(u, presetB) {
  openForm({
    title: u ? 'Edit unit' : 'Add a unit',
    values: u || {building_id: presetB || '', unit_type:'apartment', is_stabilized:true},
    note: 'A “unit” is one apartment or one store front. Enter every one, including vacant ones.',
    fields: [
      {k:'building_id', l:'Building', t:'select', opts:buildingOpts(), req:true},
      {k:'label', l:'Unit number', t:'text', req:true, half:true, ph:'2R   ·   Store 1'},
      {k:'unit_type', l:'Type', t:'select', half:true, opts:[{v:'apartment',l:'Apartment'},{v:'commercial',l:'Commercial / store'}]},
      {k:'is_stabilized', l:'Rent stabilized', t:'checkbox', help:'Drives the renewal-window and DHCR reminders.'},
      {k:'legal_rent', l:'Legal regulated rent', t:'number', half:true, ph:'0.00'},
      {k:'notes', l:'Notes', t:'text', half:true}
    ],
    danger: u ? {label:'Delete unit', fn:()=>del('units','units',u.id)} : null,
    onSubmit: async v => { await put('units','units', {
      building_id:v.building_id, label:v.label, unit_type:v.unit_type||'apartment',
      is_stabilized:!!v.is_stabilized, legal_rent:v.legal_rent, notes:v.notes
    }, u && u.id); toast('Unit saved'); }
  });
}

function fLease(l, u) {
  const unitId = u ? u.id : (l && l.unit_id);
  const unit = byId('units', unitId) || {};
  openForm({
    title: (l ? 'Lease — ' : 'Add lease — ') + uFull(unitId),
    values: Object.assign({rent_due_day:1, rider_signed:true}, l || {}),
    fields: [
      {k:'tenant_name', l:'Tenant name', t:'text', req:true, ph:'Full name on the lease'},
      {k:'tenant_phone', l:'Phone', t:'text', half:true, ph:'(718) 555-0134'},
      {k:'tenant_email', l:'Email', t:'text', half:true},
      {k:'_x', l:'Lease terms', t:'hr'},
      {k:'start_date', l:'Lease start', t:'date', req:true, half:true},
      {k:'end_date', l:'Lease end', t:'date', req:true, half:true, help:'Reminders key off this date.'},
      {k:'monthly_rent', l:'Monthly rent', t:'number', req:true, half:true, ph:'0.00'},
      {k:'rent_due_day', l:'Rent due on day', t:'number', half:true, ph:'1', help:'Usually the 1st.'},
      {k:'rider_signed', l:'Rent stabilization rider signed', t:'checkbox'},
      {k:'preferential', l:'Preferential rent in effect', t:'checkbox'},
      {k:'_y', l:'Paperwork', t:'hr'},
      {k:'file', l:'Attach the signed lease', t:'file', help:'PDF or a photo. Files under this apartment.'},
      {k:'share', l:'Let the tenant see this lease in their portal', t:'checkbox'},
      {k:'notes', l:'Notes', t:'textarea', ph:'Preferential rent, SCRIE/DRIE, guarantor…'}
    ],
    danger: l ? {label:'Delete lease', fn:()=>del('leases','leases',l.id)} : null,
    onSubmit: async (v, files) => {
      await put('leases','leases', {
        unit_id:unitId, tenant_name:v.tenant_name, tenant_phone:v.tenant_phone, tenant_email:v.tenant_email,
        start_date:v.start_date, end_date:v.end_date, monthly_rent:v.monthly_rent,
        rent_due_day: v.rent_due_day || 1, rider_signed: !!v.rider_signed,
        preferential: !!v.preferential, notes:v.notes
      }, l && l.id);
      if (files.file) await fileDocument(files.file, {
        building_id: unit.building_id, unit_id: unitId, category:'Lease',
        tenant_visible: !!v.share, note:'Lease '+(v.start_date||'')+' – '+(v.end_date||'')
      });
      toast('Lease saved');
    }
  });
}

/* ----------------------------------------------------------- RENT */
function vRent(v, act) {
  act.appendChild(el('button',{class:'btn', text:'Download this month (CSV)', onclick:exportRent}));

  const f = el('div',{class:'filters'});
  f.appendChild(el('button',{class:'btn sm', text:'‹ Previous', onclick:()=>{S.period=addMonths(S.period,-1); render();}}));
  f.appendChild(el('div',{class:'ff', style:'font-weight:700;font-size:15px;min-width:150px;text-align:center', text:fmtPeriod(S.period)}));
  f.appendChild(el('button',{class:'btn sm', text:'Next ›', onclick:()=>{S.period=addMonths(S.period,1); render();}}));
  if (S.period !== CUR_PERIOD) f.appendChild(el('button',{class:'btn sm', text:'This month', onclick:()=>{S.period=CUR_PERIOD; render();}}));
  v.appendChild(f);

  const rows = [];
  S.units.forEach(u => { const l = leaseFor(u.id, S.period); if (l) rows.push({u,l,r:rentFor(u.id,S.period)}); });
  rows.sort((a,b)=>(bName(a.u.building_id)+a.u.label).localeCompare(bName(b.u.building_id)+b.u.label, undefined, {numeric:true}));

  const due  = rows.reduce((s,x)=>s+Number(x.l.monthly_rent||0),0);
  const paid = rows.reduce((s,x)=>s+(x.r?Number(x.r.amount_paid||0):0),0);
  const kpi = (a,b,cls) => { const k=el('div',{class:'kpi'+(cls?' '+cls:'')});
    k.appendChild(el('div',{class:'v',text:a})); k.appendChild(el('div',{class:'l',text:b})); return k; };
  const kp = el('div',{class:'kpis', style:'margin-bottom:16px'});
  kp.appendChild(kpi(money0(due),'Rent roll'));
  kp.appendChild(kpi(money0(paid),'Collected', (due && paid>=due)?'brand':''));
  kp.appendChild(kpi(money0(Math.max(due-paid,0)),'Outstanding', (due-paid)>0.5?'crit':'brand'));
  kp.appendChild(kpi(rows.filter(x=>x.r && Number(x.r.amount_paid||0) >= Number(x.l.monthly_rent||0)-0.5).length+'/'+rows.length,'Paid in full'));
  v.appendChild(kp);

  const p = el('div',{class:'panel'});
  p.appendChild(el('div',{class:'panel-h'},[el('h2',{text:'Rent ledger — '+fmtPeriod(S.period)})]));
  if (!rows.length) {
    p.appendChild(el('div',{class:'empty'},[el('strong',{text:'No active leases for this month.'}),'Add leases under Buildings and this fills in by itself.']));
  } else {
    const t = el('table',{class:'t'});
    t.appendChild(el('thead',{},[el('tr',{html:'<th>Unit</th><th>Tenant</th><th class="r">Due</th><th class="r">Paid</th><th>Date</th><th>Method</th><th>Proof</th><th>Status</th><th></th>'})]));
    const tb = el('tbody');
    rows.forEach(x => {
      const dueAmt = Number(x.l.monthly_rent||0), paidAmt = x.r ? Number(x.r.amount_paid||0) : 0;
      const dueDate = periodDue(S.period, x.l.rent_due_day||1), n = days(dueDate);
      let pill;
      if (paidAmt >= dueAmt-0.5) pill = el('span',{class:'pill settled', text:'Paid'});
      else if (paidAmt > 0)      pill = el('span',{class:'pill warn', text:'Partial'});
      else if (n < 0)            pill = el('span',{class:'pill crit', text:Math.abs(n)+'d late'});
      else                       pill = el('span',{class:'pill mute', text:'Due '+fmtShort(dueDate)});
      const tr = el('tr');
      tr.appendChild(el('td',{},[ el('div',{style:'font-weight:600',text:x.u.label}), el('div',{class:'sub',text:bName(x.u.building_id)}) ]));
      tr.appendChild(el('td',{text:x.l.tenant_name||'—'}));
      tr.appendChild(el('td',{class:'r mono', text:money(dueAmt)}));
      tr.appendChild(el('td',{class:'r mono', text:x.r?money(paidAmt):'—'}));
      tr.appendChild(el('td',{class:'mono', style:'font-size:12.5px', text:(x.r&&x.r.paid_date)?fmtDate(x.r.paid_date):'—'}));
      tr.appendChild(el('td',{class:'sub', text:(x.r&&x.r.method)||'—'}));
      tr.appendChild(el('td',{},[ fileBtn(x.r && x.r.proof_path) ]));
      tr.appendChild(el('td',{},[pill]));
      tr.appendChild(el('td',{class:'r'},[ el('button',{class:'btn sm pri', text:x.r?'Edit':'Record', onclick:()=>fPayment(x.u,x.l,x.r)}) ]));
      tb.appendChild(tr);
    });
    t.appendChild(tb);
    p.appendChild(el('div',{class:'tblwrap'},[t]));
  }
  v.appendChild(p);
}

function fPayment(u, l, r) {
  openForm({
    title: 'Rent — ' + u.label + ', ' + bName(u.building_id),
    values: Object.assign({amount_paid:l.monthly_rent, paid_date:TODAY_ISO, method:'Check'}, r || {}),
    note: fmtPeriod(S.period) + ' · ' + money(l.monthly_rent) + ' due on the ' + ord(l.rent_due_day||1) + '.',
    fields: [
      {k:'amount_paid', l:'Amount received', t:'number', req:true, half:true, ph:'0.00'},
      {k:'paid_date', l:'Date received', t:'date', req:true, half:true},
      {k:'method', l:'Paid by', t:'select', half:true, opts:['Check','Money order','Cash','Zelle','Bank transfer','Section 8 / HRA','Other']},
      {k:'reference', l:'Check / reference number', t:'text', half:true},
      {k:'file', l:'Proof of payment', t:'file', help:'Photo of the check, money order stub, or bank screenshot.'},
      {k:'note', l:'Note', t:'textarea', ph:'Partial payment — balance promised by the 20th…'}
    ],
    danger: r ? {label:'Delete record', fn:()=>del('rent_payments','rent',r.id)} : null,
    onSubmit: async (v, files) => {
      let proof = r ? r.proof_path : null;
      if (files.file) {
        const d = await fileDocument(files.file, {building_id:u.building_id, unit_id:u.id,
          category:'Rent proof', tenant_visible:true, note:fmtPeriod(S.period)+' rent'});
        if (d) proof = d.storage_path;
      }
      await put('rent_payments','rent', {
        unit_id:u.id, lease_id:l.id, period:S.period,
        amount_due:Number(l.monthly_rent||0), amount_paid:v.amount_paid,
        paid_date:v.paid_date, method:v.method, reference:v.reference,
        note:v.note, proof_path:proof, recorded_by:S.me.id
      }, r && r.id);
      toast('Payment recorded');
    }
  });
}

function exportRent() {
  const rows = [['Building','Unit','Tenant','Period','Rent due','Amount paid','Date paid','Method','Reference','Status']];
  S.units.forEach(u => {
    const l = leaseFor(u.id, S.period); if (!l) return;
    const r = rentFor(u.id, S.period);
    const d = Number(l.monthly_rent||0), p = r ? Number(r.amount_paid||0) : 0;
    rows.push([bName(u.building_id), u.label, l.tenant_name||'', S.period, d.toFixed(2), p.toFixed(2),
      (r&&r.paid_date)||'', (r&&r.method)||'', (r&&r.reference)||'',
      p>=d-0.5?'Paid':p>0?'Partial':'Unpaid']);
  });
  const csv = rows.map(r => r.map(c => /[",\n]/.test(String(c)) ? '"'+String(c).replace(/"/g,'""')+'"' : String(c)).join(',')).join('\n');
  const blob = new Blob([csv], {type:'text/csv;charset=utf-8'});
  const a = el('a',{href:URL.createObjectURL(blob), download:'rent-roll-'+S.period+'.csv'});
  document.body.appendChild(a); a.click(); a.remove();
}

/* ------------------------------------------------------ UTILITIES */
function vUtilities(v, act) {
  const tab = S.tab.util || 'bills';
  act.appendChild(el('button',{class:'btn', text:'Add account', onclick:()=>fUtilAccount()}));
  act.appendChild(el('button',{class:'btn pri', text:'Add bill', onclick:()=>fUtilBill()}));

  const tabs = el('div',{class:'tabs'});
  [['bills','Bills'],['accounts','Accounts & billing dates']].forEach(([k,l]) => {
    const b = el('button',{class:'tab', text:l, onclick:()=>{S.tab.util=k; render();}});
    b.setAttribute('aria-selected', tab===k?'true':'false'); tabs.appendChild(b);
  });
  v.appendChild(tabs);

  if (tab === 'accounts') {
    const p = el('div',{class:'panel'});
    p.appendChild(el('div',{class:'panel-h'},[el('h2',{text:'Utility accounts'}), el('div',{class:'spacer'}),
      el('span',{class:'eyebrow', text:'Billing day drives “bill expected” reminders'})]));
    if (!S.utilAccounts.length) {
      p.appendChild(el('div',{class:'empty'},[el('strong',{text:'No accounts yet.'}),
        'Add one per building per utility, with the day of the month it normally bills. The site then tells you when a bill is expected but missing.']));
    } else {
      const t = el('table',{class:'t'});
      t.appendChild(el('thead',{},[el('tr',{html:'<th>Building</th><th>Utility</th><th>Provider</th><th>Account #</th><th>Bills on</th><th>Cycle</th><th></th>'})]));
      const tb = el('tbody');
      S.utilAccounts.forEach(a => {
        const tr = el('tr');
        tr.appendChild(el('td',{style:'font-weight:600', text:bName(a.building_id)}));
        tr.appendChild(el('td',{text:String(a.utility_type||'').replace(/^./,c=>c.toUpperCase())}));
        tr.appendChild(el('td',{class:'sub', text:a.provider||'—'}));
        tr.appendChild(el('td',{class:'mono', style:'font-size:12.5px', text:a.account_number||'—'}));
        tr.appendChild(el('td',{class:'mono', text:a.due_day?('the '+ord(a.due_day)):'—'}));
        tr.appendChild(el('td',{class:'sub', text:Number(a.cycle_months||1)===1?'Monthly':Number(a.cycle_months)+'-monthly'}));
        tr.appendChild(el('td',{class:'r'},[el('button',{class:'btn sm', text:'Edit', onclick:()=>fUtilAccount(a)})]));
        tb.appendChild(tr);
      });
      t.appendChild(tb);
      p.appendChild(el('div',{class:'tblwrap'},[t]));
    }
    v.appendChild(p); return;
  }

  const bills = S.utilBills.slice().sort((a,b)=>String(b.due_date).localeCompare(String(a.due_date)));
  const openAmt = bills.filter(b=>!b.paid_date).reduce((s,b)=>s+Number(b.amount||0),0);
  const overdue = bills.filter(b=>!b.paid_date && days(b.due_date)<0);
  const yr = String(TODAY.getFullYear());
  const ytd = bills.filter(b=>b.paid_date && String(b.paid_date).slice(0,4)===yr).reduce((s,b)=>s+Number(b.amount||0),0);
  const kpi = (a,b,cls)=>{const k=el('div',{class:'kpi'+(cls?' '+cls:'')});
    k.appendChild(el('div',{class:'v',text:a})); k.appendChild(el('div',{class:'l',text:b})); return k;};
  const kp = el('div',{class:'kpis', style:'margin-bottom:16px'});
  kp.appendChild(kpi(money0(openAmt),'Unpaid', openAmt?'warn':'brand'));
  kp.appendChild(kpi(String(overdue.length),'Past due', overdue.length?'crit':'brand'));
  kp.appendChild(kpi(money0(ytd),'Paid in '+yr));
  v.appendChild(kp);

  const p = el('div',{class:'panel'});
  p.appendChild(el('div',{class:'panel-h'},[el('h2',{text:'Utility bills'})]));
  if (!bills.length) {
    p.appendChild(el('div',{class:'empty'},[el('strong',{text:'No bills entered.'}),
      'Add a bill whenever one arrives — amount, due date, and a photo of the bill.']));
  } else {
    const t = el('table',{class:'t'});
    t.appendChild(el('thead',{},[el('tr',{html:'<th>Where</th><th>Utility</th><th>Period</th><th class="r">Amount</th><th>Due</th><th>Status</th><th>Files</th><th></th>'})]));
    const tb = el('tbody');
    bills.forEach(b => {
      const n = days(b.due_date);
      let pill;
      if (b.paid_date) pill = el('span',{class:'pill settled', text:'Paid '+fmtShort(b.paid_date)});
      else if (n<0)    pill = el('span',{class:'pill crit', text:Math.abs(n)+'d overdue'});
      else if (n<=14)  pill = el('span',{class:'pill warn', text:'Due in '+n+'d'});
      else             pill = el('span',{class:'pill mute', text:'Scheduled'});
      const tr = el('tr');
      const c1 = el('td',{},[el('div',{style:'font-weight:600', text:bName(b.building_id)})]);
      if (b.unit_id) c1.appendChild(el('div',{class:'sub', text:uLabel(b.unit_id)}));
      tr.appendChild(c1);
      const c2 = el('td',{},[el('div',{text:String(b.utility_type||'').replace(/^./,c=>c.toUpperCase())})]);
      if (b.provider) c2.appendChild(el('div',{class:'sub', text:b.provider}));
      tr.appendChild(c2);
      tr.appendChild(el('td',{class:'sub', text:b.period_label||'—'}));
      tr.appendChild(el('td',{class:'r mono', text:money(b.amount)}));
      tr.appendChild(el('td',{class:'mono', style:'font-size:12.5px', text:fmtDate(b.due_date)}));
      tr.appendChild(el('td',{},[pill]));
      const c7 = el('td');
      if (b.bill_path)  c7.appendChild(fileBtn(b.bill_path,'Bill'));
      if (b.proof_path) { if (b.bill_path) c7.appendChild(document.createTextNode(' · ')); c7.appendChild(fileBtn(b.proof_path,'Receipt')); }
      if (!b.bill_path && !b.proof_path) c7.appendChild(el('span',{class:'sub', text:'—'}));
      tr.appendChild(c7);
      tr.appendChild(el('td',{class:'r'},[el('button',{class:'btn sm'+(b.paid_date?'':' pri'), text:b.paid_date?'Edit':'Mark paid', onclick:()=>fUtilBill(b)})]));
      tb.appendChild(tr);
    });
    t.appendChild(tb);
    p.appendChild(el('div',{class:'tblwrap'},[t]));
  }
  v.appendChild(p);
}

const UTIL_OPTS = [{v:'water',l:'Water & sewer (NYC DEP)'},{v:'gas',l:'Gas'},{v:'electric',l:'Electric'},
                   {v:'oil',l:'Heating oil'},{v:'other',l:'Other'}];

function fUtilAccount(a) {
  openForm({
    title: a ? 'Edit utility account' : 'Add a utility account',
    values: a || {cycle_months:1},
    note: 'Tell it the day of the month this utility normally bills. It will warn you when a bill is expected but has not arrived — and when one is due.',
    fields: [
      {k:'building_id', l:'Building', t:'select', opts:buildingOpts(), req:true},
      {k:'utility_type', l:'Utility', t:'select', half:true, req:true, opts:UTIL_OPTS},
      {k:'provider', l:'Provider', t:'text', half:true, ph:'Con Edison · National Grid · NYC DEP'},
      {k:'account_number', l:'Account number', t:'text'},
      {k:'due_day', l:'Normally due on day', t:'number', half:true, ph:'15', help:'1 to 28.'},
      {k:'cycle_months', l:'Bills every', t:'select', half:true, opts:[{v:1,l:'Month'},{v:3,l:'3 months (quarterly)'},{v:6,l:'6 months'}]},
      {k:'notes', l:'Notes', t:'text'}
    ],
    danger: a ? {label:'Delete account', fn:()=>del('utility_accounts','utilAccounts',a.id)} : null,
    onSubmit: async v => { await put('utility_accounts','utilAccounts', {
      building_id:v.building_id, utility_type:v.utility_type, provider:v.provider,
      account_number:v.account_number, due_day:v.due_day, cycle_months:Number(v.cycle_months||1), notes:v.notes
    }, a && a.id); toast('Account saved'); }
  });
}

function fUtilBill(b) {
  openForm({
    title: b ? 'Utility bill' : 'Add a utility bill',
    values: b || {utility_type:'water'},
    fields: [
      {k:'building_id', l:'Building', t:'select', opts:buildingOpts(), req:true},
      {k:'unit_id', l:'Specific unit', t:'select', opts:unitOptsAll(), ph:'Whole building (master meter)',
        help:'Only a bill tied to a unit is visible to that tenant.'},
      {k:'utility_type', l:'Utility', t:'select', half:true, req:true, opts:UTIL_OPTS},
      {k:'provider', l:'Provider', t:'text', half:true, ph:'Con Edison'},
      {k:'period_label', l:'Service period', t:'text', half:true, ph:'Aug 1 – Aug 31'},
      {k:'amount', l:'Amount', t:'number', req:true, half:true, ph:'0.00'},
      {k:'bill_date', l:'Bill date', t:'date', half:true},
      {k:'due_date', l:'Due date', t:'date', req:true, half:true, help:'This is what the reminder counts down to.'},
      {k:'billFile', l:'Photo / PDF of the bill', t:'file'},
      {k:'_p', l:'When you pay it', t:'hr'},
      {k:'paid_date', l:'Date paid', t:'date', half:true, help:'Leave blank until paid.'},
      {k:'method', l:'Paid by', t:'select', half:true, ph:'—', opts:['Check','Bank transfer','Card','Autopay','Cash','Other']},
      {k:'proofFile', l:'Proof of payment', t:'file'},
      {k:'note', l:'Note', t:'textarea'}
    ],
    danger: b ? {label:'Delete bill', fn:()=>del('utility_bills','utilBills',b.id)} : null,
    onSubmit: async (v, files) => {
      let billPath = b ? b.bill_path : null, proofPath = b ? b.proof_path : null;
      const meta = {building_id:v.building_id, unit_id:v.unit_id||null, tenant_visible: !!v.unit_id};
      if (files.billFile)  { const d = await fileDocument(files.billFile,  Object.assign({category:'Utility bill', note:v.utility_type+' '+(v.period_label||'')}, meta)); if (d) billPath = d.storage_path; }
      if (files.proofFile) { const d = await fileDocument(files.proofFile, Object.assign({category:'Utility payment proof', note:v.utility_type+' '+(v.period_label||'')}, meta)); if (d) proofPath = d.storage_path; }
      const acct = S.utilAccounts.find(a => a.building_id === v.building_id && a.utility_type === v.utility_type);
      await put('utility_bills','utilBills', {
        building_id:v.building_id, unit_id:v.unit_id||null, account_id: acct ? acct.id : null,
        utility_type:v.utility_type, provider:v.provider, period_label:v.period_label,
        amount:v.amount, bill_date:v.bill_date, due_date:v.due_date, paid_date:v.paid_date,
        method:v.method, bill_path:billPath, proof_path:proofPath, note:v.note
      }, b && b.id);
      toast('Bill saved');
    }
  });
}

/* ----------------------------------------------------- COMPLAINTS */
const SRC = {tenant:'Tenant', hpd:'HPD', dob:'DOB', '311':'311', internal:'Internal'};
const CATS = ['Heat / hot water','Leak / water damage','Mold','Pests','Electrical','Plumbing',
              'Appliance','Elevator','Lock / security','Noise','Trash / sanitation','Structural','Other'];

function vComplaints(v, act) {
  act.appendChild(el('button',{class:'btn pri', text:'Log a complaint', onclick:()=>fComplaint()}));
  const show = S.filter.cs || 'open';
  const f = el('div',{class:'filters'});
  const s1 = el('select',{id:'flt_cs', onchange:e=>{S.filter.cs=e.target.value; render();}});
  [['open','Open & in progress'],['all','Everything'],['resolved','Resolved']].forEach(([k,l])=>s1.appendChild(el('option',{value:k,text:l})));
  s1.value = show; f.appendChild(s1);
  const s2 = el('select',{id:'flt_cb', onchange:e=>{S.filter.cb=e.target.value; render();}});
  s2.appendChild(el('option',{value:'', text:'All buildings'}));
  S.buildings.forEach(b=>s2.appendChild(el('option',{value:b.id, text:b.name})));
  s2.value = S.filter.cb || ''; f.appendChild(s2);
  v.appendChild(f);

  let cs = S.complaints.slice();
  if (show==='open') cs = cs.filter(c=>c.status!=='resolved');
  if (show==='resolved') cs = cs.filter(c=>c.status==='resolved');
  if (S.filter.cb) cs = cs.filter(c=>c.building_id===S.filter.cb);
  cs.sort((a,b)=>String(b.opened_date).localeCompare(String(a.opened_date)));

  const p = el('div',{class:'panel'});
  p.appendChild(el('div',{class:'panel-h'},[el('h2',{text:'Complaints & violations'}), el('div',{class:'spacer'}),
    el('span',{class:'eyebrow', text:cs.length+' shown'})]));
  if (!cs.length) {
    p.appendChild(el('div',{class:'empty'},[el('strong',{text:'Nothing here.'}),
      'Log every call, text and HPD notice. Each one keeps a dated trail you can show a judge or an inspector.']));
  } else {
    cs.forEach(c => p.appendChild(complaintRow(c, true)));
  }
  v.appendChild(p);
}

function complaintRow(c, staff) {
  const n = Math.abs(days(c.opened_date));
  const row = el('div',{style:'padding:14px 16px;border-top:1px solid var(--line-2)'});
  const head = el('div',{style:'display:flex;gap:9px;align-items:center;flex-wrap:wrap'});
  head.appendChild(el('span',{class:'pill '+(['hpd','dob','311'].indexOf(c.source)>=0?'crit':'info'), text:SRC[c.source]||'Other'}));
  head.appendChild(el('span',{class:'ff', style:'font-weight:700;font-size:14.5px', text:c.title||'Complaint'}));
  head.appendChild(el('span',{class:'pill '+(c.status==='resolved'?'settled':c.status==='in_progress'?'warn':'mute'),
    text:c.status==='resolved'?'Resolved':c.status==='in_progress'?'In progress':'Open'}));
  head.appendChild(el('div',{style:'flex:1'}));
  head.appendChild(el('button',{class:'btn sm', text:'Add update', onclick:()=>fUpdate(c)}));
  if (staff) head.appendChild(el('button',{class:'btn sm', text:'Edit', onclick:()=>fComplaint(c)}));
  row.appendChild(head);
  row.appendChild(el('div',{class:'sub', style:'margin-top:4px',
    text:(c.unit_id?uLabel(c.unit_id)+' · ':'')+bName(c.building_id)+' · opened '+fmtDate(c.opened_date)
      + (c.status==='resolved'&&c.closed_date ? ' · closed '+fmtDate(c.closed_date) : ' · '+n+' day'+(n===1?'':'s')+' open')
      + (c.case_number ? ' · case '+c.case_number : '')}));
  if (c.description) row.appendChild(el('div',{style:'margin-top:7px;font-size:13.5px', text:c.description}));

  const ups = S.cupdates.filter(u=>u.complaint_id===c.id)
    .sort((a,b)=>String(b.update_date).localeCompare(String(a.update_date)));
  if (ups.length) {
    const ul = el('div',{style:'margin-top:10px;border-left:2px solid var(--line);padding-left:12px;display:flex;flex-direction:column;gap:8px'});
    ups.forEach(u => {
      const line = el('div',{style:'font-size:13px'});
      line.appendChild(el('span',{class:'mono', style:'color:var(--ink-3);font-size:12px',
        text:fmtDate(u.update_date)+(u.author_name?' · '+u.author_name:'')+' — '}));
      line.appendChild(el('span',{text:u.note}));
      if (u.file_path) { line.appendChild(document.createTextNode(' ')); line.appendChild(fileBtn(u.file_path,'photo')); }
      ul.appendChild(line);
    });
    row.appendChild(ul);
  }
  return row;
}

function fComplaint(c) {
  openForm({
    title: c ? 'Edit complaint' : 'Log a complaint',
    values: c || {opened_date:TODAY_ISO, status:'open', source:'tenant'},
    note: c ? '' : 'Log it the moment it comes in — a dated record protects you in housing court and at HPD certification.',
    fields: [
      {k:'building_id', l:'Building', t:'select', opts:buildingOpts(), req:true},
      {k:'unit_id', l:'Unit', t:'select', opts:unitOptsAll(), ph:'Whole building / common area'},
      {k:'source', l:'Came from', t:'select', half:true, req:true,
        opts:[{v:'tenant',l:'Tenant directly'},{v:'hpd',l:'HPD'},{v:'dob',l:'DOB'},{v:'311',l:'311'},{v:'internal',l:'Noticed by us'}]},
      {k:'category', l:'Category', t:'select', half:true, ph:'—', opts:CATS},
      {k:'title', l:'One-line summary', t:'text', req:true, ph:'No hot water in bathroom since Tuesday'},
      {k:'description', l:'What happened', t:'textarea'},
      {k:'opened_date', l:'Date received', t:'date', req:true, half:true},
      {k:'status', l:'Status', t:'select', half:true, opts:[{v:'open',l:'Open'},{v:'in_progress',l:'In progress'},{v:'resolved',l:'Resolved'}]},
      {k:'case_number', l:'HPD / DOB case number', t:'text', half:true},
      {k:'closed_date', l:'Date resolved', t:'date', half:true},
      {k:'file', l:'Attach a photo or notice', t:'file'}
    ],
    danger: c ? {label:'Delete complaint', fn:()=>del('complaints','complaints',c.id)} : null,
    onSubmit: async (v, files) => {
      const row = await put('complaints','complaints', {
        building_id:v.building_id, unit_id:v.unit_id||null, source:v.source, category:v.category,
        title:v.title, description:v.description, opened_date:v.opened_date, status:v.status,
        case_number:v.case_number, closed_date: v.status==='resolved' ? (v.closed_date||TODAY_ISO) : null,
        created_by: (c && c.created_by) || S.me.id
      }, c && c.id);
      if (row && files.file) await fileDocument(files.file, {
        building_id:v.building_id, unit_id:v.unit_id||null, category:'Complaint',
        tenant_visible: !!v.unit_id, note:v.title });
      toast('Complaint saved');
    }
  });
}

function fUpdate(c) {
  const asTenant = !isStaff();
  openForm({
    title: 'Add update — ' + (c.title || 'complaint'),
    values: {update_date:TODAY_ISO, status:c.status},
    note: 'Every update is stamped with its date, so the history reads as a timeline.',
    fields: [
      {k:'update_date', l:'Date', t:'date', req:true, half: !asTenant},
      {k:'status', l:'Set status to', t:'select', half:true, staffOnly:true,
        opts:[{v:'open',l:'Open'},{v:'in_progress',l:'In progress'},{v:'resolved',l:'Resolved'}]},
      {k:'note', l:'What happened', t:'textarea', req:true,
        ph: asTenant ? 'Still no hot water this morning.' : 'Plumber replaced the mixing valve; tenant confirmed hot water restored.'},
      {k:'file', l:'Attach a photo', t:'file'}
    ].filter(f => !(f.staffOnly && asTenant)),
    onSubmit: async (v, files) => {
      let path = null;
      if (files.file) {
        const d = await fileDocument(files.file, {
          building_id:c.building_id, unit_id:c.unit_id, category:'Complaint',
          asTenant, tenant_visible:true, note:String(v.note).slice(0,60) });
        if (d) path = d.storage_path;
      }
      const ins = await S.sb.from('complaint_updates').insert({
        complaint_id:c.id, update_date:v.update_date, note:v.note, file_path:path,
        author_id:S.me.id, author_name:S.me.full_name || S.me.email
      }).select().single();
      if (ins.error) throw new Error(friendlyDbError(ins.error));
      S.cupdates.push(ins.data);
      if (!asTenant && v.status && v.status !== c.status) {
        await put('complaints','complaints', {
          status:v.status, closed_date: v.status==='resolved' ? (c.closed_date||v.update_date) : null
        }, c.id);
      }
      toast('Update added');
    }
  });
}

/* ------------------------------------------------------ DOCUMENTS */
const DOC_CATS = ['Lease','Rider','Rent proof','Utility bill','Utility payment proof','Complaint',
                  'DHCR','Insurance','Registration','Other'];

function vDocuments(v, act) {
  act.appendChild(el('button',{class:'btn pri', text:'Upload a document', onclick:()=>fDocument()}));
  const f = el('div',{class:'filters'});
  const b = el('select',{id:'flt_db', onchange:e=>{S.filter.db=e.target.value; S.filter.du=''; render();}});
  b.appendChild(el('option',{value:'', text:'All buildings'}));
  S.buildings.forEach(x=>b.appendChild(el('option',{value:x.id, text:x.name})));
  b.value = S.filter.db || ''; f.appendChild(b);
  if (S.filter.db) {
    const u = el('select',{id:'flt_du', onchange:e=>{S.filter.du=e.target.value; render();}});
    u.appendChild(el('option',{value:'', text:'All units'}));
    unitsOf(S.filter.db).forEach(x=>u.appendChild(el('option',{value:x.id, text:x.label})));
    u.value = S.filter.du || ''; f.appendChild(u);
  }
  const c = el('select',{id:'flt_dc', onchange:e=>{S.filter.dc=e.target.value; render();}});
  c.appendChild(el('option',{value:'', text:'All categories'}));
  DOC_CATS.forEach(x=>c.appendChild(el('option',{value:x, text:x})));
  c.value = S.filter.dc || ''; f.appendChild(c);
  v.appendChild(f);

  let docs = S.documents.slice();
  if (S.filter.db) docs = docs.filter(d=>d.building_id===S.filter.db);
  if (S.filter.du) docs = docs.filter(d=>d.unit_id===S.filter.du);
  if (S.filter.dc) docs = docs.filter(d=>d.category===S.filter.dc);
  docs.sort((a,b)=>String(b.uploaded_at).localeCompare(String(a.uploaded_at)));

  const p = el('div',{class:'panel'});
  p.appendChild(el('div',{class:'panel-h'},[el('h2',{text:'File room'}), el('div',{class:'spacer'}),
    el('span',{class:'eyebrow', text:docs.length+' file'+(docs.length===1?'':'s')})]));
  if (!docs.length) {
    p.appendChild(el('div',{class:'empty'},[el('strong',{text:'No documents here yet.'}),
      'Anything you attach anywhere on this site also lands here, filed under its apartment.']));
  } else {
    const t = el('table',{class:'t'});
    t.appendChild(el('thead',{},[el('tr',{html:'<th>Document</th><th>Category</th><th>Filed under</th><th>Tenant can see</th><th>Added</th><th class="r">Size</th><th></th>'})]));
    const tb = el('tbody');
    docs.forEach(d => {
      const tr = el('tr');
      const c1 = el('td',{},[ el('button',{class:'doclink', style:'font-weight:600;font-size:13.5px',
        type:'button', text:d.name||'Document', onclick:()=>openFile(d.storage_path)}) ]);
      if (d.note) c1.appendChild(el('div',{class:'sub', text:d.note}));
      tr.appendChild(c1);
      tr.appendChild(el('td',{},[el('span',{class:'pill mute', text:d.category||'Other'})]));
      tr.appendChild(el('td',{class:'sub', text:(d.unit_id?uLabel(d.unit_id)+' · ':'')+bName(d.building_id)}));
      tr.appendChild(el('td',{},[ d.tenant_visible
        ? el('span',{class:'pill brand', text:'Shared'})
        : el('span',{class:'pill settled', text:'Private'}) ]));
      tr.appendChild(el('td',{class:'mono', style:'font-size:12.5px', text:fmtDate(d.uploaded_at)}));
      tr.appendChild(el('td',{class:'r mono', style:'font-size:12.5px',
        text: d.size_bytes ? (d.size_bytes/1048576).toFixed(1)+' MB' : '—'}));
      tr.appendChild(el('td',{class:'r'},[el('button',{class:'btn sm', text:'Edit', onclick:()=>fDocMeta(d)})]));
      tb.appendChild(tr);
    });
    t.appendChild(tb);
    p.appendChild(el('div',{class:'tblwrap'},[t]));
  }
  v.appendChild(p);
}

function fDocument() {
  openForm({
    title:'Upload a document',
    values:{},
    note:'PDF or photo, up to 20 MB. Pick the building and unit so it files itself in the right place.',
    fields:[
      {k:'building_id', l:'Building', t:'select', opts:buildingOpts(), req:true},
      {k:'unit_id', l:'Unit', t:'select', opts:unitOptsAll(), ph:'Whole building'},
      {k:'category', l:'What is it', t:'select', req:true, opts:DOC_CATS},
      {k:'note', l:'Short description', t:'text', ph:'2026 renewal lease, signed'},
      {k:'tenant_visible', l:'Let this unit’s tenant see it in their portal', t:'checkbox',
        help:'Only works when a unit is chosen above.'},
      {k:'file', l:'Choose the file', t:'file', req:true}
    ],
    onSubmit: async (v, files) => {
      if (!files.file) throw new Error('Pick a file first.');
      const d = await fileDocument(files.file, {
        building_id:v.building_id, unit_id:v.unit_id||null, category:v.category,
        note:v.note, tenant_visible: !!(v.tenant_visible && v.unit_id) });
      if (d) toast('Document filed');
    }
  });
}

function fDocMeta(d) {
  openForm({
    title:'Edit document details',
    values:d,
    note: d.tenant_visible ? '' : 'Note: a file saved privately stays private. To share it with the tenant, upload it again with the sharing box ticked.',
    fields:[
      {k:'name', l:'Name', t:'text', req:true},
      {k:'building_id', l:'Building', t:'select', opts:buildingOpts(), req:true},
      {k:'unit_id', l:'Unit', t:'select', opts:unitOptsAll(), ph:'Whole building'},
      {k:'category', l:'Category', t:'select', opts:DOC_CATS},
      {k:'note', l:'Description', t:'text'}
    ],
    danger:{label:'Delete document', fn: async()=>{
      await S.sb.storage.from('docs').remove([d.storage_path]);
      await del('documents','documents',d.id);
    }},
    onSubmit: async v => { await put('documents','documents', {
      name:v.name, building_id:v.building_id, unit_id:v.unit_id||null, category:v.category, note:v.note
    }, d.id); toast('Updated'); }
  });
}

/* --------------------------------------------------------- PEOPLE */
function vPeople(v, act) {
  const tab = S.tab.people || 'invites';
  act.appendChild(el('button',{class:'btn pri', text:'Create invite code', onclick:()=>fInvite()}));

  const tabs = el('div',{class:'tabs'});
  [['invites','Invite codes'],['accounts','Accounts']].forEach(([k,l])=>{
    const b = el('button',{class:'tab', text:l, onclick:()=>{S.tab.people=k; render();}});
    b.setAttribute('aria-selected', tab===k?'true':'false'); tabs.appendChild(b);
  });
  v.appendChild(tabs);

  if (tab === 'invites') {
    const p = el('div',{class:'panel'});
    p.appendChild(el('div',{class:'panel-h'},[el('h2',{text:'Tenant invite codes'}), el('div',{class:'spacer'}),
      el('span',{class:'eyebrow', text:'One code per apartment, used once'})]));
    p.appendChild(el('div',{style:'padding:13px 16px;border-bottom:1px solid var(--line-2)'},[
      el('div',{class:'note', text:'Print or write the code on a slip with the web address and hand it to the tenant. They use it once to create their own password. A used code cannot be reused.'})
    ]));
    if (!S.invites.length) {
      p.appendChild(el('div',{class:'empty'},[el('strong',{text:'No codes yet.'}),'Create one for each apartment whose tenant you want online.']));
    } else {
      const t = el('table',{class:'t'});
      t.appendChild(el('thead',{},[el('tr',{html:'<th>Code</th><th>Apartment</th><th>Status</th><th>Created</th><th></th>'})]));
      const tb = el('tbody');
      S.invites.slice().sort((a,b)=>String(b.created_at).localeCompare(String(a.created_at))).forEach(iv=>{
        const used = !!iv.used_by;
        const tr = el('tr');
        tr.appendChild(el('td',{class:'mono', style:'font-weight:600;font-size:14px', text:iv.code}));
        tr.appendChild(el('td',{text: uFull(iv.unit_id)}));
        tr.appendChild(el('td',{},[ used ? el('span',{class:'pill settled', text:'Used '+fmtShort(iv.used_at)})
                                        : el('span',{class:'pill brand', text:'Ready to hand out'}) ]));
        tr.appendChild(el('td',{class:'mono', style:'font-size:12.5px', text:fmtDate(iv.created_at)}));
        const c5 = el('td',{class:'r'});
        if (!used) c5.appendChild(el('button',{class:'btn sm', text:'Copy slip', onclick:()=>copySlip(iv)}));
        if (isOwner()) c5.appendChild(el('button',{class:'btn sm danger', text:'Delete', style:'margin-left:6px',
          onclick:async()=>{ if(confirm('Delete this code?')){ await del('unit_invites','invites', iv.code, 'code'); render(); } }}));
        tr.appendChild(c5);
        tb.appendChild(tr);
      });
      t.appendChild(tb);
      p.appendChild(el('div',{class:'tblwrap'},[t]));
    }
    v.appendChild(p); return;
  }

  const p = el('div',{class:'panel'});
  p.appendChild(el('div',{class:'panel-h'},[el('h2',{text:'Everyone with an account'})]));
  const t = el('table',{class:'t'});
  t.appendChild(el('thead',{},[el('tr',{html:'<th>Name</th><th>Email</th><th>Phone</th><th>Role</th><th>Apartment</th><th></th>'})]));
  const tb = el('tbody');
  S.profiles.slice().sort((a,b)=>String(a.full_name||a.email).localeCompare(String(b.full_name||b.email))).forEach(pr=>{
    const units = S.tenancies.filter(x=>x.profile_id===pr.id).map(x=>uFull(x.unit_id)).join(', ');
    const tr = el('tr');
    tr.appendChild(el('td',{style:'font-weight:600', text:pr.full_name||'—'}));
    tr.appendChild(el('td',{class:'sub', text:pr.email||'—'}));
    tr.appendChild(el('td',{class:'sub', text:pr.phone||'—'}));
    tr.appendChild(el('td',{},[el('span',{class:'pill '+(pr.role==='owner'?'brand':pr.role==='manager'?'info':'mute'),
      text: pr.role==='owner'?'Owner':pr.role==='manager'?'Manager':'Tenant'})]));
    tr.appendChild(el('td',{class:'sub', text:units||'—'}));
    const c6 = el('td',{class:'r'});
    if (isOwner() && pr.id !== S.me.id) c6.appendChild(el('button',{class:'btn sm', text:'Change role', onclick:()=>fRole(pr)}));
    tr.appendChild(c6);
    tb.appendChild(tr);
  });
  t.appendChild(tb);
  p.appendChild(el('div',{class:'tblwrap'},[t]));
  v.appendChild(p);
}

function makeCode(unitId) {
  const u = byId('units', unitId) || {};
  const b = byId('buildings', u.building_id) || {};
  const word = String(b.name||'GL').replace(/[^A-Za-z]/g,'').slice(0,5).toUpperCase() || 'GL';
  const lab  = String(u.label||'X').replace(/[^A-Za-z0-9]/g,'').toUpperCase();
  const rnd  = Math.random().toString(36).replace(/[^a-z0-9]/g,'').slice(0,3).toUpperCase();
  return word + '-' + lab + '-' + rnd;
}

function fInvite() {
  openForm({
    title:'Create a tenant invite code',
    values:{},
    note:'Pick the apartment. The code below is what you hand to that tenant — it works once.',
    fields:[
      {k:'unit_id', l:'Apartment', t:'select', opts:unitOptsAll(), req:true},
      {k:'expires_at', l:'Expires on', t:'date', help:'Optional. Leave blank for no expiry.'}
    ],
    onSubmit: async v => {
      const code = makeCode(v.unit_id);
      const { data, error } = await S.sb.from('unit_invites').insert({
        code, unit_id:v.unit_id, label:uFull(v.unit_id), expires_at:v.expires_at, created_by:S.me.id
      }).select().single();
      if (error) throw new Error(friendlyDbError(error));
      S.invites.push(data);
      setTimeout(() => copySlip(data), 60);   // after this modal closes
    }
  });
}

function copySlip(iv) {
  const url = location.origin + location.pathname;
  const text = CO + '\n\nYour apartment: ' + uFull(iv.unit_id)
    + '\n\n1. Go to: ' + url
    + '\n2. Tap "Resident", then "Set up your account with an invite code"'
    + '\n3. Your invite code: ' + iv.code
    + '\n4. Choose your own password.\n\nYou will be able to see your lease, your rent, and report repairs.';
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(text).then(()=>toast('Slip copied — paste it into a text or a document to print.'),
                                             ()=>showSlip(text));
  } else showSlip(text);
}
function showSlip(text) {
  openForm({ title:'Tenant slip', values:{slip:text}, submit:'Done',
    fields:[{k:'slip', l:'Copy this and give it to the tenant', t:'textarea'}],
    onSubmit: async()=>{} });
}

function fRole(pr) {
  openForm({
    title:'Change role — ' + (pr.full_name || pr.email),
    values:{role:pr.role},
    note:'Owner can do everything including deleting. Property manager can do everything except delete records. Tenant sees only their own apartment.',
    fields:[{k:'role', l:'Role', t:'select', req:true,
      opts:[{v:'owner',l:'Owner'},{v:'manager',l:'Property manager'},{v:'tenant',l:'Tenant'}]}],
    onSubmit: async v => { await put('profiles','profiles', {role:v.role}, pr.id); toast('Role updated'); }
  });
}

/* ====================================================================
   TENANT PORTAL
   ==================================================================== */
const TNAV = [['home','My home'],['rent','Rent'],['bills','Utility bills'],['repairs','Repairs'],['docs','Documents']];

function renderTenant() {
  const root = $('#root'); root.innerHTML = '';
  const unitId = myUnitIds()[0];
  const unit   = byId('units', unitId) || {};
  const bld    = byId('buildings', unit.building_id) || {};
  const lease  = activeLease(unitId);
  const route  = S.route && TNAV.some(t=>t[0]===S.route) ? S.route : 'home';

  let owed = 0;
  [addMonths(CUR_PERIOD,-1), CUR_PERIOD].forEach(p => {
    const l = leaseFor(unitId, p); if (!l) return;
    const r = rentFor(unitId, p);
    owed += Math.max(Number(l.monthly_rent||0) - (r?Number(r.amount_paid||0):0), 0);
  });

  const hero = el('div',{class:'tphero'});
  hero.appendChild(el('div',{class:'co', text:CO}));
  hero.appendChild(el('h1',{text: unit.label ? ('Apartment ' + unit.label) : 'Your home'}));
  hero.appendChild(el('div',{class:'addr', text: bld.address || bld.name || ''}));
  const bal = el('div',{class:'tpbal'});
  bal.appendChild(el('div',{class:'amt', text: money0(owed)}));
  bal.appendChild(el('div',{class:'lbl', text: owed > 0.5
    ? 'owed as of today' + (lease ? ' · rent is due on the ' + ord(lease.rent_due_day||1) + ' of each month' : '')
    : 'You are all paid up. Thank you.'}));
  hero.appendChild(bal);
  root.appendChild(hero);

  const nav = el('div',{class:'tpnav'});
  TNAV.forEach(([k,l]) => {
    const b = el('button',{text:l, onclick:()=>{S.route=k; window.scrollTo(0,0); render();}});
    b.setAttribute('aria-current', route===k ? 'true':'false');
    nav.appendChild(b);
  });
  root.appendChild(nav);

  const tp = el('div',{class:'tp'});
  ({home:tHome, rent:tRent, bills:tBills, repairs:tRepairs, docs:tDocs}[route])(tp, unitId, unit, lease);
  tp.appendChild(el('div',{style:'margin-top:22px;text-align:center'},[
    el('button',{class:'btn', text:'Sign out', onclick:signOut})
  ]));
  root.appendChild(tp);
}

function tHome(tp, unitId, unit, lease) {
  const stack = el('div',{class:'stack'});

  if (lease) {
    const p = el('div',{class:'panel'});
    p.appendChild(el('div',{class:'panel-h'},[el('h2',{text:'Your lease'})]));
    const n = days(lease.end_date);
    const rows = [
      ['Monthly rent', money(lease.monthly_rent)],
      ['Rent due', 'The ' + ord(lease.rent_due_day||1) + ' of each month'],
      ['Lease started', fmtDate(lease.start_date)],
      ['Lease ends', fmtDate(lease.end_date) + (n>=0 ? ' · ' + n + ' days from now' : ' · expired')],
      ['Apartment', (unit.label||'—') + (unit.is_stabilized ? ' · rent stabilized' : '')]
    ];
    rows.forEach(([a,b]) => {
      const r = el('div',{class:'tprow'});
      r.appendChild(el('div',{class:'g'},[el('div',{class:'t', text:a})]));
      r.appendChild(el('div',{class:'amt', text:b}));
      p.appendChild(r);
    });
    if (n >= 0 && n <= RENEW_OPEN) {
      p.appendChild(el('div',{style:'padding:13px 16px;border-top:1px solid var(--line-2)'},[
        el('div',{class:'note', text:'Your lease ends in ' + n + ' days. Your landlord is required to offer you a renewal between 90 and 150 days before it ends. If you have not received one, contact the office.'})
      ]));
    }
    stack.appendChild(p);
  } else {
    stack.appendChild(el('div',{class:'panel'},[el('div',{class:'empty'},[
      el('strong',{text:'No lease on file yet.'}),'Your landlord has not entered your lease details. Contact the office.'])]));
  }

  const open = S.complaints.filter(c=>c.status!=='resolved');
  const p2 = el('div',{class:'panel'});
  p2.appendChild(el('div',{class:'panel-h'},[el('h2',{text:'Your open repair requests'}), el('div',{class:'spacer'}),
    el('span',{class:'eyebrow', text:open.length+' open'})]));
  if (!open.length) p2.appendChild(el('div',{class:'empty'},[el('strong',{text:'Nothing open.'}),'Everything you reported has been marked resolved.']));
  else open.slice(0,4).forEach(c => {
    const n = Math.abs(days(c.opened_date));
    const r = el('div',{class:'tprow'});
    r.appendChild(el('div',{class:'g'},[
      el('div',{class:'t', text:c.title}),
      el('div',{class:'d', text:'Reported '+fmtDate(c.opened_date)+' · '+n+' day'+(n===1?'':'s')+' ago'})
    ]));
    r.appendChild(el('span',{class:'pill '+(c.status==='in_progress'?'warn':'mute'),
      text:c.status==='in_progress'?'In progress':'Open'}));
    p2.appendChild(r);
  });
  stack.appendChild(p2);

  if (CFG.EMERGENCY_PHONE || CFG.OFFICE_EMAIL) {
    const p3 = el('div',{class:'panel'});
    p3.appendChild(el('div',{class:'panel-h'},[el('h2',{text:'Contact'})]));
    if (CFG.EMERGENCY_PHONE) p3.appendChild(el('div',{class:'tprow'},[
      el('div',{class:'g'},[el('div',{class:'t', text:'Emergency (no heat, flood, no water)'}),
        el('div',{class:'d', text:'Call — do not wait for the website'})]),
      el('a',{class:'btn sm pri', href:'tel:'+String(CFG.EMERGENCY_PHONE).replace(/[^0-9+]/g,''), text:CFG.EMERGENCY_PHONE})]));
    if (CFG.OFFICE_EMAIL) p3.appendChild(el('div',{class:'tprow'},[
      el('div',{class:'g'},[el('div',{class:'t', text:'Office'})]),
      el('a',{class:'doclink', href:'mailto:'+CFG.OFFICE_EMAIL, text:CFG.OFFICE_EMAIL})]));
    stack.appendChild(p3);
  }

  tp.appendChild(stack);
  tp.appendChild(el('div',{class:'tpcta'},[
    el('button',{class:'btn pri big', text:'Report a repair', onclick:()=>tFileComplaint(unitId)})
  ]));
}

function tRent(tp, unitId) {
  const p = el('div',{class:'panel'});
  p.appendChild(el('div',{class:'panel-h'},[el('h2',{text:'Your rent record'})]));
  const periods = [];
  for (let k=0;k>=-13;k--) periods.push(addMonths(CUR_PERIOD,k));
  let any = false;
  periods.forEach(per => {
    const l = leaseFor(unitId, per); if (!l) return;
    any = true;
    const r = rentFor(unitId, per);
    const due = Number(l.monthly_rent||0), paid = r?Number(r.amount_paid||0):0;
    const row = el('div',{class:'tprow'});
    const g = el('div',{class:'g'});
    g.appendChild(el('div',{class:'t', text:fmtPeriod(per)}));
    g.appendChild(el('div',{class:'d', text: paid>=due-0.5
      ? ('Paid in full' + (r&&r.paid_date ? ' on '+fmtDate(r.paid_date) : '') + (r&&r.method ? ' · '+r.method : ''))
      : paid>0 ? (money(paid)+' received of '+money(due)+' — '+money(due-paid)+' outstanding')
               : ('Nothing recorded · '+money(due)+' due')}));
    row.appendChild(g);
    if (r && r.proof_path) row.appendChild(fileBtn(r.proof_path,'Receipt'));
    row.appendChild(el('span',{class:'pill '+(paid>=due-0.5?'settled':paid>0?'warn':'crit'),
      text: paid>=due-0.5?'Paid':paid>0?'Partial':'Due'}));
    p.appendChild(row);
  });
  if (!any) p.appendChild(el('div',{class:'empty'},[el('strong',{text:'Nothing recorded yet.'}),'Payments appear here as soon as your landlord records them.']));
  tp.appendChild(p);
  tp.appendChild(el('div',{class:'note', style:'margin-top:14px',
    text:'This is a record of what your landlord has entered. It is not a way to pay — keep paying the way you do now, and ask for a receipt if a month looks wrong.'}));
}

function tBills(tp, unitId) {
  const bills = S.utilBills.filter(b=>b.unit_id===unitId)
    .sort((a,b)=>String(b.due_date).localeCompare(String(a.due_date)));
  const p = el('div',{class:'panel'});
  p.appendChild(el('div',{class:'panel-h'},[el('h2',{text:'Utility bills for your apartment'})]));
  if (!bills.length) {
    p.appendChild(el('div',{class:'empty'},[el('strong',{text:'No bills here.'}),
      'Only bills metered to your apartment appear here. Building-wide bills are not shown.']));
  } else bills.forEach(b => {
    const n = days(b.due_date);
    const row = el('div',{class:'tprow'});
    const g = el('div',{class:'g'});
    g.appendChild(el('div',{class:'t', text:String(b.utility_type||'').replace(/^./,c=>c.toUpperCase())+(b.provider?' · '+b.provider:'')}));
    g.appendChild(el('div',{class:'d', text:(b.period_label?b.period_label+' · ':'')+'Due '+fmtDate(b.due_date)}));
    row.appendChild(g);
    if (b.bill_path) row.appendChild(fileBtn(b.bill_path,'Bill'));
    row.appendChild(el('div',{class:'amt', text:money(b.amount)}));
    row.appendChild(el('span',{class:'pill '+(b.paid_date?'settled':n<0?'crit':'warn'),
      text: b.paid_date?'Paid':n<0?'Overdue':'Due in '+n+'d'}));
    p.appendChild(row);
  });
  tp.appendChild(p);
}

function tRepairs(tp, unitId) {
  const cs = S.complaints.slice().sort((a,b)=>String(b.opened_date).localeCompare(String(a.opened_date)));
  const p = el('div',{class:'panel'});
  p.appendChild(el('div',{class:'panel-h'},[el('h2',{text:'Repairs you have reported'}), el('div',{class:'spacer'}),
    el('span',{class:'eyebrow', text:cs.length+' total'})]));
  if (!cs.length) {
    p.appendChild(el('div',{class:'empty'},[el('strong',{text:'You have not reported anything.'}),
      'Use the button below. Everything you report is dated and kept — including what your landlord does about it.']));
  } else cs.forEach(c => p.appendChild(complaintRow(c, false)));
  tp.appendChild(p);
  tp.appendChild(el('div',{class:'tpcta'},[
    el('button',{class:'btn pri big', text:'Report a repair', onclick:()=>tFileComplaint(unitId)})
  ]));
}

function tFileComplaint(unitId) {
  const unit = byId('units', unitId) || {};
  openForm({
    title:'Report a repair',
    values:{opened_date:TODAY_ISO, category:'Heat / hot water'},
    note:'Your landlord sees this straight away. It is dated and kept permanently, so you have a record.',
    fields:[
      {k:'category', l:'What is the problem', t:'select', req:true, opts:CATS},
      {k:'title', l:'In one line', t:'text', req:true, ph:'No hot water in the bathroom since Tuesday'},
      {k:'description', l:'Tell us more', t:'textarea', ph:'When it started, which room, anything you have already tried.'},
      {k:'file', l:'Add a photo (optional)', t:'file', accept:'image/*'}
    ],
    onSubmit: async (v, files) => {
      const ins = await S.sb.from('complaints').insert({
        building_id: unit.building_id, unit_id: unitId, source:'tenant',
        category:v.category, title:v.title, description:v.description,
        opened_date:TODAY_ISO, status:'open', created_by:S.me.id
      }).select().single();
      if (ins.error) throw new Error(friendlyDbError(ins.error));
      S.complaints.push(ins.data);
      if (files.file) await fileDocument(files.file, {
        building_id: unit.building_id, unit_id: unitId, category:'Complaint',
        asTenant:true, note:v.title });
      toast('Reported. Your landlord can see it now.');
    }
  });
}

function tDocs(tp, unitId) {
  const docs = S.documents.filter(d=>d.unit_id===unitId)
    .sort((a,b)=>String(b.uploaded_at).localeCompare(String(a.uploaded_at)));
  const p = el('div',{class:'panel'});
  p.appendChild(el('div',{class:'panel-h'},[el('h2',{text:'Your documents'})]));
  if (!docs.length) {
    p.appendChild(el('div',{class:'empty'},[el('strong',{text:'Nothing shared yet.'}),
      'Your lease and receipts appear here when your landlord shares them.']));
  } else docs.forEach(d => {
    const row = el('div',{class:'tprow'});
    row.appendChild(el('div',{class:'g'},[
      el('div',{class:'t', text:d.name}),
      el('div',{class:'d', text:(d.category||'Document')+' · added '+fmtDate(d.uploaded_at)})
    ]));
    row.appendChild(el('button',{class:'btn sm', text:'Open', onclick:()=>openFile(d.storage_path)}));
    p.appendChild(row);
  });
  tp.appendChild(p);
}

/* ====================================================================
   ROUTER
   ==================================================================== */
function render() {
  if (S.loading) { $('#root').innerHTML = '<div class="loading">Loading your records…</div>'; return; }
  if (!S.session) { renderAuth(); return; }
  if (isStaff()) { renderStaffShell(); return; }
  if (!myUnitIds().length) { renderClaim(); return; }
  renderTenant();
}

async function start() {
  const problem = configProblem();
  if (problem) { showSetupError(problem); return; }

  S.sb = window.supabase.createClient(CFG.SUPABASE_URL.replace(/\/$/,''), CFG.SUPABASE_ANON_KEY, {
    auth:{ persistSession:true, autoRefreshToken:true, detectSessionInUrl:true }
  });

  const { data:{ session } } = await S.sb.auth.getSession();
  S.session = session;

  S.sb.auth.onAuthStateChange((evt, sess) => {
    const had = !!S.session;
    S.session = sess;
    if (evt === 'SIGNED_OUT') { location.reload(); return; }
    if (!had && sess) location.reload();
  });

  if (!S.session) { S.loading = false; render(); return; }

  try {
    await loadMe();
    await loadAll();
  } catch (e) {
    console.error(e);
    S.loading = false;
    toast('Could not load your records. Check your internet and refresh.', true);
  }
  S.loading = false;
  render();
}

start();
})();
