/* ============================================================
   WANDR — UI controller
   Screen flow: landing → intake → interview → generating → ideas
   → refine (with crucial-point questions). The Shadow Profile drawer
   is available everywhere once signed in.
   ============================================================ */

const app = document.getElementById("app");
const topbar = document.getElementById("topbar");

const MONTHS = ["","January","February","March","April","May","June","July","August","September","October","November","December"];

// ---------- tiny helpers ----------
const el = (html) => { const t = document.createElement("template"); t.innerHTML = html.trim(); return t.content.firstElementChild; };
const esc = (s) => String(s).replace(/[&<>"]/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[c]));
const pct = (v) => Math.round(v * 100);
const sleep = (ms) => new Promise(r => setTimeout(r, ms));

function toast(msg) {
  let wrap = document.querySelector(".toast-wrap");
  if (!wrap) { wrap = el(`<div class="toast-wrap"></div>`); document.body.appendChild(wrap); }
  const t = el(`<div class="toast"><span class="t-orb"></span><span>${esc(msg)}</span></div>`);
  wrap.appendChild(t);
  setTimeout(() => { t.style.opacity = "0"; t.style.transition = "0.4s"; setTimeout(() => t.remove(), 400); }, 3200);
}

// ============================================================
//  ROUTING
// ============================================================
function render() {
  const u = Agent.get();
  if (!u) { topbar.hidden = true; return renderLanding(); }
  topbar.hidden = false;
  document.getElementById("agentName").textContent = u.agentName;

  if (!u.params)            return renderIntake();
  if (Agent.intakeRemaining() > 0) return renderInterview();
  if (!u.chosenTrip)        return renderIdeas();
  return renderRefine();
}

// ============================================================
//  LANDING + SIGN IN
// ============================================================
function renderLanding() {
  app.innerHTML = "";
  const screen = el(`
    <section class="screen full">
      <div class="hero">
        <div>
          <span class="eyebrow">Personal travel intelligence</span>
          <h1>Stop planning trips.<br><span class="grad">Start being understood.</span></h1>
          <p class="lede">WANDR spins up a private agent that learns how <em>you</em> like to travel — then turns a blank calendar into a trip that feels like it was made for you. Because it was.</p>
          <div class="hero-points">
            <div><span>◭</span> Your own learning sub-agent</div>
            <div><span>◭</span> Smart questions, not endless forms</div>
            <div><span>◭</span> A Shadow Profile only you can see</div>
          </div>
        </div>
        <div class="glass signin-card" id="signinCard"></div>
      </div>
    </section>`);
  app.appendChild(screen);
  mountSignin();
}

function mountSignin() {
  const card = document.getElementById("signinCard");
  card.innerHTML = `
    <h3>Spin up your agent</h3>
    <p class="muted" style="font-size:13px;margin:0">Sign in and I'll create a private compartment just for you.</p>
    <div class="field">
      <label>Email</label>
      <input id="emailInput" type="email" placeholder="you@example.com" autocomplete="email" />
    </div>
    <div class="field">
      <label>Name <span class="muted">(optional — what should I call you?)</span></label>
      <input id="nameInput" type="text" placeholder="First name" />
    </div>
    <div class="spacer-lg" style="height:8px"></div>
    <button class="btn lg" id="signInGo" style="width:100%">Create my agent →</button>
    <p class="fineprint">Demo build: accounts and memory live only in this browser's local storage — nothing leaves your device. Each email gets its own isolated agent compartment.</p>`;

  const go = () => {
    const email = document.getElementById("emailInput").value.trim();
    const name = document.getElementById("nameInput").value.trim();
    if (!email || !email.includes("@")) { toast("Enter a valid email to continue"); return; }
    const u = Agent.load(email);
    if (name) { u.displayName = name; Agent.persist(); }
    const isNew = Object.keys(u.answered).length === 0 && !u.params;
    toast(isNew ? `Agent "${u.agentName}" is now yours. Let's begin.` : `Welcome back — ${u.agentName} remembered you.`);
    render();
  };
  document.getElementById("signInGo").onclick = go;
  document.getElementById("emailInput").addEventListener("keydown", e => { if (e.key === "Enter") go(); });
  document.getElementById("nameInput").addEventListener("keydown", e => { if (e.key === "Enter") go(); });
}

// ============================================================
//  STEP RAIL
// ============================================================
function stepRail(active) {
  const steps = [["1","Basics"],["2","Interview"],["3","Ideas"],["4","Refine"]];
  return `<div class="steps">${steps.map(([n,l],i) => {
    const idx = i + 1;
    const cls = idx < active ? "done" : idx === active ? "active" : "";
    return `<div class="step-pill ${cls}"><b>${idx < active ? "✓" : n}</b> ${l}</div>`;
  }).join("")}</div>`;
}

// ============================================================
//  INTAKE — basic params with smart defaults
// ============================================================
const DEFAULT_PARAMS = { duration: 14, travelers: "couple", budget: 150, month: 9, departure: "", vibe: [] };

function renderIntake() {
  const u = Agent.get();
  const greet = u.displayName ? `, ${esc(u.displayName)}` : "";
  app.innerHTML = "";
  const screen = el(`
    <section class="screen">
      ${stepRail(1)}
      <div class="section-head">
        <span class="eyebrow">Step 1 · The basics</span>
        <h2>Let's set the frame${greet}.</h2>
        <p>I've pre-filled sensible defaults so you can move fast — change anything that doesn't fit. Most people start with about two weeks.</p>
      </div>

      <div class="glass card-pad">
        <div class="intake-grid">
          <div>
            <label class="field" style="margin:0"><span style="font-size:12px;color:var(--ink-dim)">Trip length <span class="default-tag">default · 2 weeks</span></span></label>
            <div class="range-wrap" style="margin-top:14px">
              <input id="durInput" type="range" min="2" max="35" value="${DEFAULT_PARAMS.duration}" />
              <div class="range-val" id="durVal"></div>
            </div>
            <div class="hint">Drag to anything from a long weekend to a slow month.</div>
          </div>

          <div>
            <label class="field" style="margin:0"><span style="font-size:12px;color:var(--ink-dim)">Daily budget per person <span class="default-tag">default · $150</span></span></label>
            <div class="range-wrap" style="margin-top:14px">
              <input id="budInput" type="range" min="40" max="500" step="10" value="${DEFAULT_PARAMS.budget}" />
              <div class="range-val" id="budVal"></div>
            </div>
            <div class="hint">Rough all-in: stays, food, activities, local transit.</div>
          </div>

          <div>
            <label class="field" style="margin:0"><span style="font-size:12px;color:var(--ink-dim)">Who's going</span></label>
            <div class="chip-row" id="travelerChips" style="margin-top:12px"></div>
          </div>

          <div>
            <label class="field" style="margin:0"><span style="font-size:12px;color:var(--ink-dim)">When (roughly)</span></label>
            <select id="monthSelect" class="field" style="margin-top:12px"></select>
          </div>

          <div class="span-2">
            <label class="field" style="margin:0"><span style="font-size:12px;color:var(--ink-dim)">Flying out of <span class="muted">(optional)</span></span></label>
            <input id="depInput" class="field" style="margin-top:12px" placeholder="e.g. New York, London, anywhere" />
          </div>

          <div class="span-2">
            <label class="field" style="margin:0"><span style="font-size:12px;color:var(--ink-dim)">Any first instincts? <span class="muted">Pick what sounds good — totally optional</span></span></label>
            <div class="chip-row" id="vibeChips" style="margin-top:12px"></div>
          </div>
        </div>
        <div class="spacer-lg"></div>
        <div class="row-between">
          <p class="muted" style="font-size:12px;margin:0;max-width:420px">Next I'll ask a short set of sharp questions — these teach your agent more than any form could.</p>
          <button class="btn lg" id="toInterview">Start the interview →</button>
        </div>
      </div>
    </section>`);
  app.appendChild(screen);

  // duration
  const durInput = screen.querySelector("#durInput"), durVal = screen.querySelector("#durVal");
  const setDur = () => {
    const d = +durInput.value;
    const wks = (d / 7);
    durVal.textContent = d >= 7 && d % 7 === 0 ? `${wks} ${wks === 1 ? "week" : "weeks"}` : `${d} days`;
  };
  durInput.oninput = setDur; setDur();

  // budget
  const budInput = screen.querySelector("#budInput"), budVal = screen.querySelector("#budVal");
  const setBud = () => budVal.textContent = `$${budInput.value}/day`;
  budInput.oninput = setBud; setBud();

  // travelers
  const travelers = [["solo","🧍 Solo"],["couple","💑 Couple"],["friends","👯 Friends"],["family","👨‍👩‍👧 Family"]];
  let traveler = DEFAULT_PARAMS.travelers;
  const tWrap = screen.querySelector("#travelerChips");
  travelers.forEach(([v,l]) => {
    const c = el(`<button class="chip ${v===traveler?'selected':''}" data-v="${v}">${l}</button>`);
    c.onclick = () => { traveler = v; tWrap.querySelectorAll(".chip").forEach(x => x.classList.toggle("selected", x.dataset.v === v)); };
    tWrap.appendChild(c);
  });

  // month
  const ms = screen.querySelector("#monthSelect");
  ms.innerHTML = `<option value="0">I'm flexible</option>` + MONTHS.slice(1).map((m,i) => `<option value="${i+1}" ${i+1===DEFAULT_PARAMS.month?"selected":""}>${m}</option>`).join("");

  // vibes
  const vibes = ["Adventure","Beaches","Food scene","History","Nightlife","Nature","Wellness","Off the beaten path","Photography","Romance"];
  const selectedVibes = new Set();
  const vWrap = screen.querySelector("#vibeChips");
  vibes.forEach(v => {
    const c = el(`<button class="chip" data-v="${v}">${v}</button>`);
    c.onclick = () => { c.classList.toggle("selected"); if (selectedVibes.has(v)) selectedVibes.delete(v); else selectedVibes.add(v); };
    vWrap.appendChild(c);
  });

  screen.querySelector("#toInterview").onclick = () => {
    Agent.setParams({
      duration: +durInput.value,
      budget: +budInput.value,
      travelers: traveler,
      month: +ms.value || null,
      departure: screen.querySelector("#depInput").value.trim(),
      vibe: [...selectedVibes],
    });
    // seed the profile lightly from any chosen vibes
    seedFromVibes([...selectedVibes]);
    toast("Frame set. Time to learn about you.");
    render();
  };
}

function seedFromVibes(vibes) {
  const map = { "Adventure":"adventure","Nature":"nature","Food scene":"foodie","History":"culture",
    "Nightlife":"social","Wellness":"comfort","Off the beaten path":"adventure","Romance":"luxury","Beaches":"comfort","Photography":"culture" };
  const u = Agent.get();
  vibes.forEach(v => { const k = map[v]; if (k) { u.profile[k] = Math.min(1, u.profile[k] + 0.12); u.confidence[k] = Math.min(1, u.confidence[k] + 0.08); } });
  Agent.persist();
}

// ============================================================
//  INTERVIEW — adaptive questioning
// ============================================================
function renderInterview() {
  app.innerHTML = "";
  const screen = el(`
    <section class="screen">
      ${stepRail(2)}
      <div class="section-head">
        <span class="eyebrow">Step 2 · The interview</span>
        <h2>A few sharp questions.</h2>
        <p>No multi-page form. Each answer trains your agent's read on you — watch the Shadow Profile fill in as we go.</p>
      </div>
      <div class="interview" id="interviewStage"></div>
    </section>`);
  app.appendChild(screen);
  askNext();
}

async function askNext() {
  const stage = document.getElementById("interviewStage");
  const q = Agent.nextQuestion("intake");
  const total = Agent.intakeTotal(), done = total - Agent.intakeRemaining();

  if (!q) { // done with intake → generate
    toast("That's enough to get started. Generating ideas…");
    return renderGenerating();
  }

  stage.innerHTML = `
    <div class="interview-progress">
      <span class="muted" style="font-size:12px">Question ${done + 1} of ${total}</span>
      <div class="ip-bar"><div class="ip-fill" style="width:${(done/total)*100}%"></div></div>
      <span class="muted" style="font-size:12px">${pct(Agent.overallConfidence())}% read</span>
    </div>`;

  // agent "thinks" before asking — feels like a real sub-agent reasoning
  const bubble = el(`
    <div class="agent-bubble">
      <div class="agent-avatar">◭</div>
      <div class="agent-says"><div class="thinking"><span></span><span></span><span></span></div></div>
    </div>`);
  stage.appendChild(bubble);
  await sleep(700);

  bubble.querySelector(".agent-says").innerHTML = `
    <div class="q">${esc(q.q)}</div>
    <div class="why">💡 ${esc(q.why)}</div>`;

  const opts = el(`<div class="options"></div>`);
  q.options.forEach((o, i) => {
    const card = el(`
      <button class="opt">
        <span class="opt-emoji">${o.emoji || "•"}</span>
        <span class="opt-label">${esc(o.label)}</span>
        ${o.sub ? `<span class="opt-sub">${esc(o.sub)}</span>` : ""}
      </button>`);
    card.onclick = async () => {
      opts.querySelectorAll(".opt").forEach(x => x.disabled = true);
      card.classList.add("picked");
      Agent.observe(q, i);
      refreshShadow();
      await sleep(380);
      askNext();
    };
    opts.appendChild(card);
  });
  stage.appendChild(opts);
}

// ============================================================
//  GENERATING — the agent "researches"
// ============================================================
async function renderGenerating() {
  app.innerHTML = "";
  const u = Agent.get();
  const top = Agent.strongestTraits(2).map(t => t.label.toLowerCase()).join(" + ");
  const screen = el(`
    <section class="screen">
      <div class="loading-stage">
        <div class="big-orb"></div>
        <h2>${esc(u.agentName)} is on it.</h2>
        <p class="muted">Cross-referencing your Shadow Profile against the world.</p>
        <div class="loading-log" id="log"></div>
      </div>
    </section>`);
  app.appendChild(screen);

  const lines = [
    `Reading your profile — strongest signals: <span class="lk">${top}</span>`,
    `Filtering ${DESTINATIONS.length} regions by season and budget…`,
    `Scoring each against how <span class="lk">you</span> travel…`,
    `Drafting the questions I'll ask at the crucial forks…`,
    `Ranking your matches.`,
  ];
  const log = document.getElementById("log");
  for (let i = 0; i < lines.length; i++) {
    const line = el(`<div class="log-line" style="animation-delay:${i*0.05}s"><span class="lk">✓</span> <span>${lines[i]}</span></div>`);
    log.appendChild(line);
    await sleep(520);
  }
  await sleep(400);
  render();
}

// ============================================================
//  IDEAS — generated trip cards
// ============================================================
function renderIdeas() {
  const u = Agent.get();
  const ranked = Agent.rankDestinations(u.params).slice(0, 6);
  app.innerHTML = "";
  const dur = u.params.duration;
  const screen = el(`
    <section class="screen">
      ${stepRail(3)}
      <div class="section-head">
        <span class="eyebrow">Step 3 · Your ideas</span>
        <h2>Six trips, sorted by how much they're <em>you</em>.</h2>
        <p>Built for ${dur} days${u.params.month ? `, around ${MONTHS[u.params.month]}` : ""}. The match score is your agent's confidence this fits your Shadow Profile. Open one to narrow it down.</p>
      </div>
      <div class="ideas-grid" id="ideasGrid"></div>
      <div class="spacer-lg"></div>
      <p class="center muted" style="font-size:13px">Not quite it? <button class="back-link" id="reInterview" style="color:var(--brand)">Answer a couple more questions →</button> and I'll re-rank.</p>
    </section>`);
  app.appendChild(screen);

  const grid = screen.querySelector("#ideasGrid");
  ranked.forEach(({ dest, score, inSeason, whyFit }) => {
    const card = el(`
      <article class="idea-card">
        <div class="idea-cover" style="background:${dest.cover}">
          <div class="match">Match <b>${pct(score)}%</b></div>
          <span class="place-emoji">${dest.emoji}</span>
        </div>
        <div class="idea-body">
          <h3>${esc(dest.name)}</h3>
          <div class="idea-region">${esc(dest.region)} ${inSeason ? "· in season ✦" : ""}</div>
          <div class="idea-tagline">${esc(dest.tagline)}</div>
          <div class="idea-meta">
            <span><b>~$${dest.dayCost}</b>/day</span>
            <span><b>${u.params.duration}</b> days</span>
            <span><b>${MONTHS[dest.bestMonths[0]]}</b>+ best</span>
          </div>
          <div class="why-fit">✦ <span>${esc(whyFit)}</span></div>
          <div class="tag-row">${dest.tags.map(t => `<span class="mini-tag">${esc(t)}</span>`).join("")}</div>
          <div class="spacer-lg" style="height:16px"></div>
          <button class="btn" style="width:100%" data-id="${dest.id}">Narrow this down →</button>
        </div>
      </article>`);
    card.querySelector("button").onclick = () => {
      Agent.setChosenTrip(dest.id);
      toast(`Locking in ${dest.name.split(" ")[0]} — let's tune the details.`);
      render();
    };
    grid.appendChild(card);
  });

  screen.querySelector("#reInterview").onclick = () => {
    // re-open crucial questions as an extra learning round
    const q = Agent.nextCrucialQuestion();
    if (!q) { toast("I've asked everything I have for now — pick a trip and we'll refine live."); return; }
    openCrucialModal(q, () => { toast("Re-ranking with what I just learned…"); render(); });
  };
}

// ============================================================
//  REFINE — narrow segments + crucial-point questions
// ============================================================
function renderRefine() {
  const u = Agent.get();
  const dest = DESTINATIONS.find(d => d.id === u.chosenTrip);
  const segs = segmentRecs(dest);
  app.innerHTML = "";
  const screen = el(`
    <section class="screen">
      ${stepRail(4)}
      <button class="back-link" id="backToIdeas">← Back to ideas</button>
      <div class="refine-cover" style="background:${dest.cover}">
        <span class="cover-emoji">${dest.emoji}</span>
        <span class="eyebrow" style="color:rgba(255,255,255,0.9)">Now narrowing</span>
        <h2>${esc(dest.name)}</h2>
        <p>${esc(dest.tagline)}</p>
      </div>
      <div id="crucialSlot"></div>
      <div id="segments"></div>
      <div class="spacer-lg"></div>
      <div class="glass card-pad row-between">
        <div>
          <h3 style="margin:0 0 4px">Your trip is taking shape</h3>
          <p class="muted" style="margin:0;font-size:13px" id="picksSummary"></p>
        </div>
        <button class="btn lg" id="finalize">Build my itinerary →</button>
      </div>
    </section>`);
  app.appendChild(screen);

  screen.querySelector("#backToIdeas").onclick = () => { Agent.setChosenTrip(null); render(); };

  // Surface a crucial question the first time we enter refine (a "crucial point").
  maybeAskCrucial(screen.querySelector("#crucialSlot"), dest);

  renderSegments(screen.querySelector("#segments"), segs);
  updatePicksSummary();

  screen.querySelector("#finalize").onclick = () => {
    const picks = Agent.get().picks;
    if (Object.keys(picks).length < 2) { toast("Pick at least a place to stay and something to do first."); return; }
    toast(`Itinerary drafted for ${dest.name.split(" ")[0]}. ${Agent.get().agentName} will keep learning as you go. ✈️`);
    openShadow();
  };
}

function renderSegments(host, segs) {
  host.innerHTML = "";
  Object.entries(segs).forEach(([key, seg]) => {
    const ranked = Agent.rankSegment(seg);
    const block = el(`
      <div class="segment">
        <div class="segment-head">
          <span class="seg-icon">${seg.icon}</span>
          <h3>${esc(seg.title)}</h3>
          <span class="search-note">🔎 ${esc(seg.searchNote)}</span>
        </div>
        <div class="rec-row"></div>
      </div>`);
    const row = block.querySelector(".rec-row");
    ranked.forEach(({ opt, score, why }) => {
      const chosen = Agent.get().picks[key] === opt.id;
      const rec = el(`
        <button class="rec ${chosen ? "chosen" : ""}" data-seg="${key}" data-id="${opt.id}">
          <div class="rec-top">
            <h4>${esc(opt.name)}</h4>
            <span class="score-ring">${pct(score)}%</span>
          </div>
          <div class="rec-desc">${esc(opt.desc)}</div>
          <div class="rec-top">
            <span class="price">${esc(opt.price)}</span>
            <span class="fit">✦ ${esc(why)}</span>
          </div>
        </button>`);
      rec.onclick = () => {
        Agent.pick(key, opt.id);
        row.querySelectorAll(".rec").forEach(r => r.classList.toggle("chosen", r.dataset.id === opt.id));
        updatePicksSummary();
      };
      row.appendChild(rec);
    });
    host.appendChild(block);
  });
}

function updatePicksSummary() {
  const u = Agent.get();
  const n = Object.keys(u.picks).length;
  const node = document.getElementById("picksSummary");
  if (node) node.textContent = n === 0 ? "Pick the pieces that feel right — each one teaches me a little more." : `${n} ${n === 1 ? "piece" : "pieces"} chosen. I'm folding each choice back into your profile.`;
}

// ---- crucial-point question (inline banner) ----
function maybeAskCrucial(slot, dest) {
  const u = Agent.get();
  const q = Agent.nextCrucialQuestion();
  if (!q) return;
  Agent.markCrucialAsked(q.id);
  const banner = el(`
    <div class="crucial-banner">
      <div class="ck">Crucial point · ${esc(u.agentName)} wants one read</div>
      <h4>${esc(q.q)}</h4>
      <div class="why" style="color:var(--ink-dim);font-size:12px;margin-bottom:14px">💡 ${esc(q.why)}</div>
      <div class="options"></div>
    </div>`);
  const opts = banner.querySelector(".options");
  q.options.forEach((o, i) => {
    const c = el(`<button class="opt"><span class="opt-emoji">${o.emoji||"•"}</span><span class="opt-label">${esc(o.label)}</span>${o.sub?`<span class="opt-sub">${esc(o.sub)}</span>`:""}</button>`);
    c.onclick = async () => {
      opts.querySelectorAll(".opt").forEach(x => x.disabled = true);
      c.classList.add("picked");
      Agent.observe(q, i);
      refreshShadow();
      await sleep(420);
      toast("Good to know — re-tuning your recommendations.");
      // re-rank the segments live with the new signal
      const segs = segmentRecs(dest);
      renderSegments(document.getElementById("segments"), segs);
      banner.style.transition = "0.4s"; banner.style.opacity = "0"; banner.style.height = "0";
      setTimeout(() => banner.remove(), 400);
    };
    opts.appendChild(c);
  });
  slot.appendChild(banner);
}

// modal version used from the ideas screen
function openCrucialModal(q, onDone) {
  const u = Agent.get();
  const scrim = el(`<div class="drawer-scrim"></div>`);
  const box = el(`
    <div class="glass card-pad" style="position:fixed;z-index:65;top:50%;left:50%;transform:translate(-50%,-50%);max-width:560px;width:92vw">
      <div class="ck" style="font-size:11px;text-transform:uppercase;letter-spacing:.18em;color:var(--brand-2);font-weight:700">${esc(u.agentName)} · one more read</div>
      <h3 style="margin:10px 0">${esc(q.q)}</h3>
      <div class="why" style="color:var(--muted);font-size:12px;margin-bottom:16px">💡 ${esc(q.why)}</div>
      <div class="options"></div>
    </div>`);
  const opts = box.querySelector(".options");
  q.options.forEach((o, i) => {
    const c = el(`<button class="opt"><span class="opt-emoji">${o.emoji||"•"}</span><span class="opt-label">${esc(o.label)}</span>${o.sub?`<span class="opt-sub">${esc(o.sub)}</span>`:""}</button>`);
    c.onclick = () => {
      Agent.observe(q, i); Agent.markCrucialAsked(q.id); refreshShadow();
      scrim.remove(); box.remove(); onDone && onDone();
    };
    opts.appendChild(c);
  });
  scrim.onclick = () => { scrim.remove(); box.remove(); };
  document.body.append(scrim, box);
}

// ============================================================
//  SHADOW PROFILE drawer
// ============================================================
const drawer = document.getElementById("shadowDrawer");
const drawerScrim = document.getElementById("drawerScrim");
function openShadow() { refreshShadow(); drawer.classList.add("open"); drawer.setAttribute("aria-hidden","false"); drawerScrim.hidden = false; }
function closeShadow() { drawer.classList.remove("open"); drawer.setAttribute("aria-hidden","true"); drawerScrim.hidden = true; }

function refreshShadow() {
  const u = Agent.get();
  if (!u) return;
  const body = document.getElementById("shadowBody");
  const conf = Agent.overallConfidence();
  document.getElementById("shadowSubtitle").textContent =
    conf < 0.15 ? "I'm just getting to know you." : conf < 0.5 ? "Building a read on you…" : "I've got a strong read on you.";

  const traits = Agent.profileSummary();
  const insights = u.insights || [];

  body.innerHTML = `
    <div class="conf-meter">
      <span class="muted" style="font-size:12px">Overall confidence</span>
      <div class="ip-bar"><div class="ip-fill" style="width:${pct(conf)}%"></div></div>
      <b style="font-family:'Sora';font-size:13px">${pct(conf)}%</b>
    </div>
    <div class="shadow-section-title">Trained preference vector</div>
    ${traits.map(t => `
      <div class="trait" title="${esc(t.blurb)}">
        <div class="trait-top"><b>${esc(t.label)}</b><span>${t.conf < 0.1 ? "unknown" : pct(t.conf)+"% sure"}</span></div>
        <div class="trait-bar"><div class="trait-fill" style="width:${pct(t.value)}%;opacity:${0.35 + t.conf*0.65}"></div></div>
      </div>`).join("")}
    <div class="shadow-section-title">What I've inferred — the shadow side</div>
    ${insights.length
      ? insights.map(i => `<div class="insight"><span class="i-emoji">${i.emoji}</span><span>${esc(i.text)}</span></div>`).join("")
      : `<div class="empty-shadow">Answer a few questions and your agent's private read on you appears here — the implicit profile behind every recommendation.</div>`}
    <div class="shadow-section-title">Compartment</div>
    <div class="insight"><span class="i-emoji">🔒</span><span>Private to <b>${esc(u.email)}</b>. Agent <b>${esc(u.agentName)}</b>, spawned ${new Date(u.createdAt).toLocaleDateString()}. Memory persists only in this browser.</span></div>`;
}

document.getElementById("shadowToggle").onclick = () => drawer.classList.contains("open") ? closeShadow() : openShadow();
document.getElementById("shadowClose").onclick = closeShadow;
drawerScrim.onclick = closeShadow;
document.getElementById("signOutBtn").onclick = () => { Agent.signOut(); closeShadow(); toast("Signed out. Your agent's memory is safe for next time."); render(); };

// ============================================================
//  BOOT
// ============================================================
render();
