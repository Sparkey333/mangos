/* ============================================================================
 * game.js — screens, roster, and the turn-based battle engine.
 *
 * THE LOOP (MVP / vertical slice):
 *   Title  ->  Choose your Hunter  ->  Codex (lore + the unified-theory map)
 *          ->  Ascend the 7 layers of the pyramid, one guardian per layer.
 * Beat all seven layers and the spectrum closes into white = you win.
 *
 * Everything is data-driven from THE_SEVEN, so this same engine grows straight
 * into the bigger party game later.
 * ========================================================================== */

(() => {
  const $ = (sel) => document.querySelector(sel);
  const screens = {};
  let player = null;       // chosen hunter (battle copy)
  let enemy = null;        // current guardian (battle copy)
  let layer = 0;           // which pyramid layer we're climbing (0..6)
  let busy = false;        // lock input during animations
  let frame = 0;

  // ---- battle canvas ----
  const canvas = $("#scene");
  const ctx = canvas.getContext("2d");

  function fitCanvas() {
    const wrap = canvas.parentElement;
    const w = wrap.clientWidth;
    const h = Math.round(w * 0.62);
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = w * dpr;
    canvas.height = h * dpr;
    canvas.style.height = h + "px";
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.imageSmoothingEnabled = false;
    canvas._w = w; canvas._h = h;
  }
  window.addEventListener("resize", fitCanvas);

  // make a fresh battle copy with current HP
  function spawn(def) {
    return JSON.parse(JSON.stringify({ ...def, hp: def.stats.hp, maxhp: def.stats.hp }));
  }

  /* ---------------------------------------------------------------- screens */
  function show(name) {
    Object.values(screens).forEach((s) => s.classList.remove("active"));
    screens[name].classList.add("active");
    if (name === "battle") { fitCanvas(); }
  }

  function buildRoster() {
    const grid = $("#roster");
    grid.innerHTML = "";
    THE_SEVEN.forEach((h) => {
      const card = document.createElement("button");
      card.className = "card";
      card.style.setProperty("--c", h.base);
      card.style.setProperty("--c2", h.shade);
      const port = Sprites.hunterPortrait(h, 96);
      port.className = "port";
      card.appendChild(port);
      const nm = document.createElement("div");
      nm.className = "cname";
      nm.textContent = h.name;
      const sub = document.createElement("div");
      sub.className = "csub";
      sub.textContent = h.colorName + " · " + h.toneHz + "Hz";
      card.appendChild(nm); card.appendChild(sub);
      card.addEventListener("click", () => { Audio7.blip(520 + h.id * 40); openCodex(h); });
      grid.appendChild(card);
    });
  }

  /* ------------------------------------------------------------------ codex */
  function openCodex(h) {
    const c = $("#codex-body");
    const port = Sprites.hunterPortrait(h, 128);
    port.className = "codex-port";
    c.innerHTML = "";
    c.appendChild(port);
    const rows = [
      ["Title", h.title],
      ["Color → Light", `${h.colorName} · ~${h.lightTHz} THz`],
      ["Sound (Solfeggio)", `${h.toneHz} Hz · note ${h.note}`],
      ["Chakra", h.chakra],
      ["Stone / Gem", h.stone],
      ["Sacred Geometry", h.geometry],
      ["Pyramid Layer", h.pyramidLayer],
    ];
    const dl = document.createElement("dl");
    dl.className = "codex-grid";
    rows.forEach(([k, v]) => {
      const dt = document.createElement("dt"); dt.textContent = k;
      const dd = document.createElement("dd"); dd.textContent = v;
      dl.appendChild(dt); dl.appendChild(dd);
    });
    const blurb = document.createElement("p");
    blurb.className = "blurb";
    blurb.textContent = h.blurb;
    c.appendChild(dl); c.appendChild(blurb);

    $("#codex-title").textContent = h.name;
    $("#codex-title").style.color = h.base;
    $("#hear-tone").onclick = () => Audio7.tone(h.toneHz, 1.4);
    $("#choose").onclick = () => startRun(h);
    show("codex");
  }

  /* -------------------------------------------------------------- battle run */
  function startRun(h) {
    player = spawn(h);
    layer = 0;
    nextLayer();
  }

  function nextLayer() {
    // the guardian of each layer is the hunter whose color owns that layer,
    // skipping the player's own color (you don't fight yourself — you ARE it).
    let guardianId = layer;
    if (guardianId === player.id) guardianId = (guardianId + 1) % 7;
    const g = spawn(THE_SEVEN[guardianId]);
    // guardians get tougher as you ascend
    const buff = 1 + layer * 0.035;
    g.maxhp = Math.round(g.maxhp * buff);
    g.hp = g.maxhp;
    g.stats = { ...g.stats, atk: Math.round(g.stats.atk * buff) };
    enemy = g;
    player.hp = player.maxhp; // full heal between layers (MVP kindness)
    setupBattle();
  }

  function setupBattle() {
    show("battle");
    $("#layer-tag").textContent =
      `LAYER ${layer + 1}/7 — ${enemy.pyramidLayer.split(" — ")[0]}`;
    log(`A wild ${enemy.name} guards the ${enemy.colorName} layer!`, true);
    buildActions();
    updateBars();
  }

  function buildActions() {
    const box = $("#actions");
    box.innerHTML = "";
    player.moves.forEach((m, i) => {
      const b = document.createElement("button");
      b.className = "act";
      b.innerHTML = `<span>${m.name}</span><small>${m.kind === "tone" ? m.power + " · " + player.toneHz + "Hz" : "PWR " + m.power}</small>`;
      b.onclick = () => { if (!busy) playerTurn(i); };
      box.appendChild(b);
    });
    const attune = document.createElement("button");
    attune.className = "act";
    attune.innerHTML = `<span>Attune</span><small>heal + brace · ${player.toneHz}Hz</small>`;
    attune.onclick = () => { if (!busy) playerAttune(); };
    box.appendChild(attune);

    const flee = document.createElement("button");
    flee.className = "act flee";
    flee.innerHTML = "<span>Retreat</span><small>back to roster</small>";
    flee.onclick = () => { if (!busy) { Audio7.blip(200); show("select"); } };
    box.appendChild(flee);
  }

  /* ----------------------------------------------------------- damage model */
  function damage(attacker, defender, move) {
    const eff = effectiveness(attacker.id, defender.id);
    const atk = attacker.stats.atk;
    const def = defender.stats.def;
    let base = (move.power * (atk / 22)) * (1 - def / (def + 70)) * eff;
    if (defender === player) base *= 0.80;          // hero takes a little less
    if (defender.guarding) { base *= 0.5; defender.guarding = false; } // braced
    const variance = 0.85 + Math.random() * 0.3;
    const dmg = Math.max(1, Math.round(base * variance));
    return { dmg, eff };
  }

  function playerTurn(moveIndex) {
    busy = true;
    const move = player.moves[moveIndex];
    sound(player, move);
    flash(move.kind === "tone" ? player.base : "#fff", "enemy");
    const { dmg, eff } = damage(player, enemy, move);
    enemy.hp = Math.max(0, enemy.hp - dmg);
    log(`${player.name} used ${move.name} — ${move.text}.`);
    log(effLine(eff, dmg));
    updateBars();

    setTimeout(() => {
      if (enemy.hp <= 0) return onEnemyDown();
      enemyTurn();
    }, 850);
  }

  function playerAttune() {
    busy = true;
    const healed = Math.round(player.maxhp * 0.30);
    player.hp = Math.min(player.maxhp, player.hp + healed);
    player.guarding = true; // halves the next hit taken
    Audio7.tone(player.toneHz, 1.2);
    flash(player.light, "player");
    log(`${player.name} attunes to ${player.toneHz}Hz — recovers ${healed} HP and braces.`);
    updateBars();
    setTimeout(() => {
      if (player.hp <= 0) return onPlayerDown();
      enemyTurn();
    }, 850);
  }

  function enemyTurn() {
    // simple AI: prefer the signature tone move when it would be effective
    const eff = effectiveness(enemy.id, player.id);
    const move = eff >= 1 ? enemy.moves[1] : enemy.moves[Math.floor(Math.random() * 2)];
    sound(enemy, move);
    flash(move.kind === "tone" ? enemy.base : "#fff", "player");
    const r = damage(enemy, player, move);
    player.hp = Math.max(0, player.hp - r.dmg);
    log(`${enemy.name} used ${move.name}!`);
    log(effLine(r.eff, r.dmg));
    updateBars();

    setTimeout(() => {
      if (player.hp <= 0) return onPlayerDown();
      busy = false;
    }, 850);
  }

  function onEnemyDown() {
    Audio7.spectrum([enemy.toneHz, enemy.toneHz * 1.25]);
    log(`${enemy.name} fades back into the stone.`, true);
    layer++;
    setTimeout(() => {
      if (layer >= 7) return onVictory();
      log(`You ascend to layer ${layer + 1}…`);
      setTimeout(() => { busy = false; nextLayer(); }, 700);
    }, 700);
  }

  function onVictory() {
    Audio7.spectrum(THE_SEVEN.map((h) => h.toneHz));
    const unity = THE_HIDDEN.find((h) => h.key === "unity");
    const ninth = THE_HIDDEN.find((h) => h.key === "ouroboros");
    const voidT = THE_HIDDEN.find((h) => h.key === "void");
    $("#end-title").textContent = "THE SPECTRUM CLOSES";
    $("#end-title").style.color = "#fff";
    $("#end-msg").textContent =
      `${player.name} carried all seven rays to the capstone. The seven tones ring as one — and for a moment they are not seven but ${unity.name}, the Eighth: a single living light.`;
    // a whisper of what waits beyond the seven
    $("#end-whisper").textContent =
      `…beneath it the ${ninth.name} stirs — the tail-eater, the dark cycle that must be ridden. ` +
      `And further out, past light and dark alike, ${voidT.name} forgets. ` +
      `One grain, named and remembered, holds it all open.`;
    show("end");
    busy = false;
  }

  function onPlayerDown() {
    $("#end-title").textContent = "THE CLIMB ENDS";
    $("#end-msg").textContent =
      `${player.name} fell at layer ${layer + 1}. The pyramid keeps its secret… for now.`;
    show("end");
    busy = false;
  }

  /* --------------------------------------------------------------- helpers */
  function effLine(eff, dmg) {
    let tag = "";
    if (eff > 1) tag = " It resonates — super effective!";
    else if (eff < 1) tag = " It's dissonant — not very effective.";
    return `…${dmg} damage.${tag}`;
  }

  function sound(who, move) {
    if (move.kind === "tone") Audio7.tone(who.toneHz, 1.0);
    else Audio7.hit(160 + who.id * 20);
  }

  let flashFx = null;
  function flash(color, target) { flashFx = { color, target, t: 12 }; }

  function log(text, clear) {
    const el = $("#log");
    if (clear) el.innerHTML = "";
    const p = document.createElement("p");
    p.textContent = text;
    el.appendChild(p);
    el.scrollTop = el.scrollHeight;
  }

  function bar(el, cur, max) {
    const pct = Math.max(0, (cur / max) * 100);
    el.style.width = pct + "%";
    el.style.background = pct > 50 ? "#4fd06a" : pct > 22 ? "#f2cf1b" : "#e23b2e";
  }

  function updateBars() {
    $("#p-name").textContent = player.name;
    $("#e-name").textContent = enemy.name;
    $("#p-hp-text").textContent = `${player.hp}/${player.maxhp}`;
    $("#e-hp-text").textContent = `${enemy.hp}/${enemy.maxhp}`;
    bar($("#p-hp"), player.hp, player.maxhp);
    bar($("#e-hp"), enemy.hp, enemy.maxhp);
  }

  /* ----------------------------------------------------------- render loop */
  function render() {
    frame++;
    if (screens.battle.classList.contains("active") && enemy && player) {
      const w = canvas._w, h = canvas._h;
      // backdrop: gradient tinted toward the current layer's color
      const g = ctx.createLinearGradient(0, 0, 0, h);
      g.addColorStop(0, Sprites.shade(enemy.shade, -0.25));
      g.addColorStop(1, "#0a0712");
      ctx.fillStyle = g; ctx.fillRect(0, 0, w, h);
      drawPyramidBands(w, h);

      const size = Math.min(w * 0.34, 150);
      // enemy upper-right, player lower-left
      Sprites.drawHunter(ctx, enemy, w - size - w * 0.06, h * 0.10, size, frame, -1);
      Sprites.drawHunter(ctx, player, w * 0.06, h - size - h * 0.06, size, frame + 30, 1);

      if (flashFx && flashFx.t > 0) {
        ctx.fillStyle = flashFx.color;
        ctx.globalAlpha = flashFx.t / 24;
        const s = Math.min(w * 0.34, 150);
        if (flashFx.target === "enemy") ctx.fillRect(w - s - w * 0.06, h * 0.10, s, s);
        else ctx.fillRect(w * 0.06, h - s - h * 0.06, s, s);
        ctx.globalAlpha = 1;
        flashFx.t--;
      }
    }
    requestAnimationFrame(render);
  }

  // faint horizontal bands evoking the seven stacked stone layers
  function drawPyramidBands(w, h) {
    for (let i = 0; i < 7; i++) {
      ctx.fillStyle = THE_SEVEN[i].base;
      ctx.globalAlpha = 0.05;
      ctx.fillRect(0, (h / 7) * i, w, h / 7 - 1);
    }
    ctx.globalAlpha = 1;
  }

  /* -------------------------------------------------------------- bootstrap */
  function init() {
    ["title", "select", "codex", "battle", "end"].forEach(
      (n) => (screens[n] = $("#screen-" + n))
    );
    buildRoster();

    $("#start").onclick = () => { Audio7.unlock(); Audio7.blip(700); show("select"); };
    $("#codex-back").onclick = () => { Audio7.blip(300); show("select"); };
    $("#again").onclick = () => { Audio7.blip(600); show("select"); };
    $("#mute").onclick = (e) => {
      const on = Audio7.toggle();
      e.currentTarget.textContent = on ? "♪ ON" : "♪ OFF";
    };

    fitCanvas();
    show("title");
    render();
  }

  if (document.readyState === "loading")
    document.addEventListener("DOMContentLoaded", init);
  else init();
})();
