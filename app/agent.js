/* ============================================================
   WANDR — Agent engine
   Each signed-in user gets their own isolated "sub-agent" with a
   private, persisted memory compartment (localStorage, namespaced by
   user). The agent maintains a Shadow Profile (a trait vector + a
   confidence estimate per trait), chooses the most informative next
   question, and scores destinations / recommendations against the
   profile. This is the seam where a real LLM + tools would plug in.
   ============================================================ */

const STORAGE_PREFIX = "wandr:v1:";
const AGENT_NAMES = ["Atlas","Sol","Vega","Juno","Cass","Orion","Lyra","Echo","Rune","Nova","Indigo","Wren"];

const Agent = (() => {
  let state = null; // active user's compartment

  // ---- compartment persistence (one private store per user) ----
  function keyFor(email) { return STORAGE_PREFIX + email.trim().toLowerCase(); }

  function freshProfile() {
    // start each trait at neutral 0.5 with zero confidence — the agent
    // genuinely knows nothing until it observes you.
    const profile = {}, confidence = {};
    TRAITS.forEach(t => { profile[t.key] = 0.5; confidence[t.key] = 0; });
    return { profile, confidence };
  }

  function spawnAgentName(email) {
    // deterministic per user so "your agent" is stable across sessions
    let h = 0;
    for (let i = 0; i < email.length; i++) h = (h * 31 + email.charCodeAt(i)) >>> 0;
    return AGENT_NAMES[h % AGENT_NAMES.length];
  }

  function load(email) {
    const raw = localStorage.getItem(keyFor(email));
    if (raw) {
      try { state = JSON.parse(raw); state.email = email; return state; } catch (e) {}
    }
    state = {
      email,
      agentName: spawnAgentName(email),
      createdAt: Date.now(),
      ...freshProfile(),
      params: null,           // intake parameters
      answered: {},           // questionId -> chosen option index
      insights: [],           // human-readable things the agent inferred
      askedCrucial: [],       // crucial question ids already surfaced
      chosenTrip: null,
      picks: {},              // segmentKey -> option id
    };
    persist();
    return state;
  }

  function persist() { if (state) localStorage.setItem(keyFor(state.email), JSON.stringify(state)); }
  function get() { return state; }
  function signOut() { state = null; }

  // ---- learning: fold an answer's weights into the Shadow Profile ----
  function observe(question, optionIndex) {
    const opt = question.options[optionIndex];
    state.answered[question.id] = optionIndex;

    // Each observation nudges the relevant traits toward the option's
    // signal and raises our confidence in those traits.
    Object.entries(opt.w).forEach(([trait, signal]) => {
      const c = state.confidence[trait];
      const lr = 0.55 * (1 - c * 0.5);           // learn fast early, settle later
      state.profile[trait] = clamp(state.profile[trait] + (signal - 0.5) * lr * 2);
      state.confidence[trait] = clamp(c + 0.22);
    });

    deriveInsight(question, opt);
    persist();
  }

  // Turn fresh signal into a plain-language insight ("training the shadow side").
  function deriveInsight(question, opt) {
    const top = strongestTraits(2);
    const phrasing = {
      adventure: `leans into adventure — you'll get bolder options, not safer ones`,
      comfort:   `values comfort and low friction — I'll protect your downtime`,
      culture:   `is here for culture — history and local life move to the top`,
      nature:    `is pulled by nature — wild landscapes over crowded sights`,
      social:    `wants people around — livelier neighborhoods and tables`,
      spontaneity:`prefers loose plans — I'll leave deliberate slack in the days`,
      luxury:    `will trade up for quality — fewer, better things`,
      foodie:    `eats first — food is a headline, not a footnote`,
    };
    const t = top[0];
    const text = `Noted "${opt.label}". Your profile ${phrasing[t.key] || "is taking shape"}.`;
    state.insights.unshift({ text, emoji: opt.emoji || "🧠", at: Date.now() });
    state.insights = state.insights.slice(0, 8);
  }

  // ---- choosing what to ask next (information-gain heuristic) ----
  function nextQuestion(phase) {
    const pool = QUESTION_BANK.filter(q => q.phase === phase && state.answered[q.id] === undefined);
    if (!pool.length) return null;
    // prefer the question that reads the traits we're least sure about.
    let best = null, bestScore = -1;
    pool.forEach(q => {
      const uncertainty = q.reads.reduce((s, tr) => s + (1 - state.confidence[tr]), 0) / q.reads.length;
      if (uncertainty > bestScore) { bestScore = uncertainty; best = q; }
    });
    return best;
  }

  function nextCrucialQuestion() {
    const q = nextQuestion("crucial");
    if (q && !state.askedCrucial.includes(q.id)) return q;
    return null;
  }
  function markCrucialAsked(id) { state.askedCrucial.push(id); persist(); }

  function intakeRemaining() {
    return QUESTION_BANK.filter(q => q.phase === "intake" && state.answered[q.id] === undefined).length;
  }
  function intakeTotal() { return QUESTION_BANK.filter(q => q.phase === "intake").length; }

  // ---- scoring ----
  function cosineFit(vec) {
    // weight each trait by our confidence so unknowns don't dominate.
    let dot = 0, ua = 0, ub = 0;
    TRAITS.forEach(t => {
      const w = 0.4 + 0.6 * state.confidence[t.key];
      const a = state.profile[t.key] * w;
      const b = (vec[t.key] ?? 0.5) * w;
      dot += a * b; ua += a * a; ub += b * b;
    });
    if (!ua || !ub) return 0.5;
    return dot / (Math.sqrt(ua) * Math.sqrt(ub));
  }

  function rankDestinations(params) {
    const monthOk = (d) => params && params.month ? d.bestMonths.includes(params.month) : true;
    return DESTINATIONS.map(d => {
      let score = cosineFit(d.vec);
      if (monthOk(d)) score += 0.06;                       // in-season nudge
      if (params && params.budget) {
        const fit = 1 - Math.min(1, Math.abs(d.dayCost - params.budget) / params.budget);
        score = score * 0.85 + fit * 0.15;                 // budget alignment
      }
      return { dest: d, score: clamp(score), inSeason: monthOk(d), whyFit: whyDestination(d) };
    }).sort((a, b) => b.score - a.score);
  }

  function whyDestination(d) {
    const top = strongestTraits(3).map(t => t.key);
    const overlap = top.filter(k => (d.vec[k] ?? 0) >= 0.7);
    const names = { adventure:"your appetite for adventure", culture:"your pull toward culture",
      nature:"how much you want real nature", social:"your social side", foodie:"that you eat first",
      luxury:"your taste for the finer version", comfort:"your need for genuine rest", spontaneity:"your loose, wandering pace" };
    if (!overlap.length) return `A well-rounded fit for a ${labelFor(d)} trip.`;
    return `Matches ${overlap.slice(0,2).map(k => names[k]).join(" and ")}.`;
  }

  function rankSegment(seg) {
    return seg.options
      .map(o => ({ opt: o, score: clamp(cosineFit(o.vec)), why: whyRec(o) }))
      .sort((a, b) => b.score - a.score);
  }

  function whyRec(o) {
    const top = strongestTraits(2);
    for (const t of top) if ((o.vec[t.key] ?? 0) >= 0.7) {
      const m = { adventure:"built for your adventurous streak", comfort:"keeps things easy, like you want",
        culture:"feeds your curiosity", nature:"leans into the outdoors", social:"matches your social energy",
        spontaneity:"leaves room to wander", luxury:"the quality you'll trade up for", foodie:"a food-first pick" };
      return m[t.key];
    }
    return "a solid, safe pick for your profile";
  }

  // ---- helpers exposed to the UI ----
  function strongestTraits(n) {
    return [...TRAITS]
      .map(t => ({ ...t, value: state.profile[t.key], conf: state.confidence[t.key] }))
      .sort((a, b) => (b.value * (0.5 + b.conf) ) - (a.value * (0.5 + a.conf)))
      .slice(0, n);
  }
  function profileSummary() {
    return TRAITS.map(t => ({ ...t, value: state.profile[t.key], conf: state.confidence[t.key] }));
  }
  function overallConfidence() {
    return TRAITS.reduce((s, t) => s + state.confidence[t.key], 0) / TRAITS.length;
  }
  function labelFor(d) { return (d.tags && d.tags[0]) || "great"; }
  function setParams(p) { state.params = p; persist(); }
  function setChosenTrip(id) { state.chosenTrip = id; persist(); }
  function pick(segKey, optId) { state.picks[segKey] = optId; persist(); }
  function clamp(v) { return Math.max(0, Math.min(1, v)); }

  return {
    load, get, persist, signOut, observe, nextQuestion, nextCrucialQuestion, markCrucialAsked,
    intakeRemaining, intakeTotal, rankDestinations, rankSegment, strongestTraits, profileSummary,
    overallConfidence, setParams, setChosenTrip, pick,
  };
})();
