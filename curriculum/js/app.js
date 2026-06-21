/* =====================================================================
   AWAKENING ARCADE — app logic (vanilla JS, no build step)
   All user data lives in localStorage on THIS device only. Nothing is
   uploaded anywhere. Use Backup/Restore to move it between machines.
   ===================================================================== */
(function () {
  "use strict";

  var NS = "awakening.v1.";
  var store = {
    get: function (k, d) {
      try { var v = localStorage.getItem(NS + k); return v === null ? d : JSON.parse(v); }
      catch (e) { return d; }
    },
    set: function (k, v) { try { localStorage.setItem(NS + k, JSON.stringify(v)); } catch (e) {} },
    del: function (k) { try { localStorage.removeItem(NS + k); } catch (e) {} },
    keys: function () {
      var out = [];
      for (var i = 0; i < localStorage.length; i++) {
        var key = localStorage.key(i);
        if (key && key.indexOf(NS) === 0) out.push(key.slice(NS.length));
      }
      return out;
    }
  };

  /* ---------- progress state ---------- */
  var done = store.get("done", {}); // { taskId: true }
  function saveDone() { store.set("done", done); }

  function esc(s) {
    return String(s == null ? "" : s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }
  function el(html) { var d = document.createElement("div"); d.innerHTML = html.trim(); return d.firstChild; }

  /* ---------- task id helpers ---------- */
  function taskId(t, s, sub, i) { return t.id + "/" + s.id + "/" + sub.id + "/" + i; }
  function trackTaskIds(track) {
    var ids = [];
    track.sections.forEach(function (s) {
      s.sub.forEach(function (sub) {
        (sub.tasks || []).forEach(function (_, i) { ids.push(taskId(track, s, sub, i)); });
      });
    });
    return ids;
  }
  function sectionTaskIds(track, s) {
    var ids = [];
    s.sub.forEach(function (sub) { (sub.tasks || []).forEach(function (_, i) { ids.push(taskId(track, s, sub, i)); }); });
    return ids;
  }
  function pct(ids) {
    if (!ids.length) return 0;
    var n = 0; ids.forEach(function (id) { if (done[id]) n++; });
    return Math.round((n / ids.length) * 100);
  }
  function countDone(ids) { var n = 0; ids.forEach(function (id) { if (done[id]) n++; }); return n; }

  /* ---------- render a track view ---------- */
  function pillarBlock(cls, label, items) {
    var lis = (items || []).map(function (x) { return "<li>" + esc(x) + "</li>"; }).join("");
    return '<div class="pillar ' + cls + '"><h4>' + label + "</h4><ul>" + lis + "</ul></div>";
  }
  function reinforceItem(s) {
    var m = /^([A-Z\-]+):\s*/.exec(s), lbl = "", txt = s;
    if (m) {
      var key = m[1].toLowerCase();
      var cls = key.indexOf("cross") === 0 ? "cross" : key.indexOf("earlier") === 0 ? "earlier" : "this";
      lbl = '<span class="lbl ' + cls + '">' + esc(m[1]) + "</span>";
      txt = s.slice(m[0].length);
    }
    return "<li>" + lbl + esc(txt) + "</li>";
  }
  function resItem(r) {
    var free = /free/i.test(r.cost || "");
    return '<li class="res"><a href="' + esc(r.url) + '" target="_blank" rel="noopener">' + esc(r.label) + "</a>" +
      '<span class="tag">' + esc(r.tag || "") + "</span>" +
      '<span class="cost' + (free ? " free" : "") + '">' + esc(r.cost || "") + "</span></li>";
  }

  function renderSub(track, s, sub) {
    var pillars =
      '<div class="pillars">' +
      pillarBlock("course", "📚 COURSEWORK", sub.pillars.coursework) +
      pillarBlock("career", "💼 CAREER", sub.pillars.career) +
      pillarBlock("side", "⚡ SIDEGIGZ", sub.pillars.sidegigz) +
      "</div>";

    var tasks = (sub.tasks || []).map(function (t, i) {
      var id = taskId(track, s, sub, i);
      var isDone = !!done[id];
      return '<label class="task' + (isDone ? " done" : "") + '" data-id="' + id + '">' +
        '<input type="checkbox" ' + (isDone ? "checked" : "") + '><span>' + esc(t) + "</span></label>";
    }).join("");

    var reinforce = (sub.reinforce || []).map(reinforceItem).join("");
    var resources = (sub.resources || []).map(resItem).join("");

    return '<div class="sub">' +
      '<div class="sub-head"><h3>' + esc(sub.title) + "</h3></div>" +
      '<div class="objective">🎯 ' + esc(sub.objective) + "</div>" +
      pillars +
      '<div class="tasks"><h4>TASKS / SUBTASKS</h4>' + tasks + "</div>" +
      (reinforce ? '<div class="reinforce"><h4>🔁 REINFORCEMENT (loops back on this & earlier)</h4><ul>' + reinforce + "</ul></div>" : "") +
      (resources ? '<div class="resources"><h4>🔗 RESOURCES / COURSES / LINKS</h4><ul>' + resources + "</ul></div>" +
        '<div class="row" style="margin-top:10px"><button class="btn sm jobs-btn" data-q="' + esc(sub.title) + '">🔎 Find related jobs on Indeed</button>' +
        '<button class="btn sm tobook-btn" data-t="' + esc(track.title) + " — " + esc(sub.title) + '">📖 Send to Book as a chapter prompt</button></div>' : "") +
      "</div>";
  }

  function renderSection(track, s, openId) {
    var ids = sectionTaskIds(track, s);
    var subs = s.sub.map(function (sub) { return renderSub(track, s, sub); }).join("");
    var open = openId === s.id;
    return '<div class="section' + (open ? " open" : "") + '" data-sec="' + s.id + '">' +
      '<div class="sec-head"><span class="era-badge">' + esc(s.era) + "</span>" +
      "<h2>" + esc(s.title) + "</h2>" +
      '<span class="secpct">' + pct(ids) + "%</span>" +
      '<span class="chev">' + (open ? "▼" : "▶") + "</span></div>" +
      '<div class="sec-body"><div class="sec-summary">' + esc(s.summary) + "</div>" + subs + "</div></div>";
  }

  function renderTrack(track) {
    var ids = trackTaskIds(track);
    var p = pct(ids);
    var hero = '<div class="hero" style="--accent:' + track.accent + '">' +
      "<h1>" + esc(track.title) + "</h1>" +
      '<div class="tagline">' + esc(track.tagline) + "</div>" +
      "<p>" + esc(track.intro) + "</p>" +
      '<div class="progress-wrap"><div class="progress-track"><div class="progress-fill" style="width:' + p + '%"></div></div>' +
      '<div class="progress-label">TRACK PROGRESS: ' + countDone(ids) + " / " + ids.length + " tasks · " + p + "%</div></div></div>";
    var sections = track.sections.map(function (s) { return renderSection(track, s, null); }).join("");
    return hero + sections;
  }

  /* ---------- DASHBOARD ---------- */
  function renderDashboard() {
    var totalIds = [], perTrack = [];
    TRACKS.forEach(function (t) { var ids = trackTaskIds(t); totalIds = totalIds.concat(ids); perTrack.push({ t: t, ids: ids }); });
    var book = store.get("book", []);
    var journal = store.get("journal", []);
    var assets = store.get("assets", []);
    var words = book.reduce(function (a, c) { return a + ((c.body || "").trim() ? c.body.trim().split(/\s+/).length : 0); }, 0);

    var stats =
      '<div class="dash-grid">' +
      '<div class="stat"><div class="n">' + pct(totalIds) + '%</div><div class="k">Overall Curriculum</div></div>' +
      '<div class="stat"><div class="n">' + countDone(totalIds) + "/" + totalIds.length + '</div><div class="k">Tasks Completed</div></div>' +
      '<div class="stat"><div class="n">' + journal.length + '</div><div class="k">Journal Entries</div></div>' +
      '<div class="stat"><div class="n">' + words.toLocaleString() + '</div><div class="k">Words in Your Book</div></div>' +
      '<div class="stat"><div class="n">' + assets.length + '</div><div class="k">Assets Logged</div></div>' +
      "</div>";

    var trackBars = perTrack.map(function (o) {
      return '<div style="margin:14px 0"><div style="display:flex;justify-content:space-between;margin-bottom:6px">' +
        '<strong style="color:' + o.t.accent + '">' + esc(o.t.title) + "</strong><span class=note>" + pct(o.ids) + "%</span></div>" +
        '<div class="progress-track"><div class="progress-fill" style="width:' + pct(o.ids) + '%"></div></div></div>';
    }).join("");

    var legend = '<div class="callout"><strong>The 3 Pillars of Career Evolution:</strong> ' +
      '<span style="color:var(--pillar-course)">📚 Coursework</span> (learn it) · ' +
      '<span style="color:var(--pillar-career)">💼 Career</span> (get hired for it) · ' +
      '<span style="color:var(--pillar-side)">⚡ Sidegigz</span> (ship small &amp; earn now). ' +
      'Every subsection carries all three, plus 🔁 <em>Reinforcement</em> that loops back on what you just learned and earlier sections — rarely on what comes next.</div>';

    return '<h2 class="viewtitle">▚ MISSION CONTROL</h2>' + stats + legend +
      '<h3 class="pixel" style="font-size:11px;color:var(--gold)">TRACK PROGRESS</h3>' + trackBars +
      '<div class="callout" style="margin-top:18px">🔒 <strong>Your data is private.</strong> Everything here is saved only in this browser on this device. ' +
      'Use <em>Backup</em> (top-right) to export a file, and <em>Restore</em> to load it on another machine. Clearing browser data erases it — back up first.</div>';
  }

  /* ---------- BOOK (self-help, write-along) ---------- */
  var SEED_BOOK = [
    { title: "Preface — Why I'm Awakening", body: "" },
    { title: "Chapter 1 — The No-Sleep Nostalgia (the feeling I'm building toward)", body: "" },
    { title: "Chapter 2 — Coursework: What I'm Learning & Why", body: "" },
    { title: "Chapter 3 — Career: Turning Skills Into a Living", body: "" },
    { title: "Chapter 4 — Sidegigz: Earning While I Learn", body: "" },
    { title: "Chapter 5 — The Third Place I Want to Build", body: "" }
  ];
  var curChapter = 0;
  function getBook() { var b = store.get("book", null); if (!b) { b = SEED_BOOK.slice(); store.set("book", b); } return b; }

  function renderBook() {
    var book = getBook();
    if (curChapter >= book.length) curChapter = 0;
    var list = book.map(function (c, i) {
      return '<div class="ci' + (i === curChapter ? " on" : "") + '" data-i="' + i + '">' + esc(c.title || "Untitled") + "</div>";
    }).join("");
    var ch = book[curChapter] || { title: "", body: "" };
    return '<h2 class="viewtitle">📖 MY SELF-HELP BOOK <span class="note">— write it alongside the journey</span></h2>' +
      '<div class="row" style="margin-bottom:12px">' +
      '<button class="btn sm" id="book-add">+ New Chapter</button>' +
      '<button class="btn sm" id="book-del">🗑 Delete Chapter</button>' +
      '<button class="btn sm" id="book-export">⬇ Export Book (.md)</button>' +
      "</div>" +
      '<div class="editor-grid">' +
      '<div class="chapter-list">' + list + "</div>" +
      '<div class="editor-pane">' +
      '<input class="title-in" id="book-title" value="' + esc(ch.title) + '">' +
      '<textarea id="book-body" placeholder="Start writing. Anything you type autosaves to this device only.">' + esc(ch.body) + "</textarea>" +
      '<div class="savestate" id="book-save">Autosaves as you type · ' + (ch.body || "").trim().split(/\s+/).filter(Boolean).length + " words</div>" +
      "</div></div>";
  }

  /* ---------- JOURNAL (awakening log) ---------- */
  function renderJournal() {
    var entries = store.get("journal", []);
    var form =
      '<div class="section open" style="margin-bottom:18px"><div class="sec-body" style="display:block">' +
      '<div class="row">' +
      '<div class="field" style="flex:1;min-width:240px"><label>What awakened / what did I learn or feel today?</label>' +
      '<textarea class="tin" id="j-body" rows="3" placeholder="A win, a realization, a struggle, a connection between sections..."></textarea></div>' +
      '<div class="field"><label>Mood</label><select class="tin" id="j-mood">' +
      ["⚡ Fired up", "🧠 Focused", "😴 Tired but proud", "🌀 Confused", "🔥 Breakthrough", "🌱 Growing"].map(function (m) { return "<option>" + m + "</option>"; }).join("") +
      "</select></div>" +
      '<div class="field"><label>&nbsp;</label><button class="btn" id="j-add">+ Save Entry</button></div>' +
      "</div></div></div>";
    var list = entries.length ? entries.map(function (e, i) {
      return '<div class="journal-entry"><div class="when">' + esc(e.when) + ' <span class="mood">' + esc(e.mood) + "</span></div>" +
        '<div class="body">' + esc(e.body) + "</div>" +
        '<button class="btn sm jdel" data-i="' + i + '" style="margin-top:8px">delete</button></div>';
    }).join("") : '<div class="empty">No entries yet. Record your first awakening above.</div>';
    return '<h2 class="viewtitle">🌌 AWAKENING JOURNAL</h2>' + form + list;
  }

  /* ---------- ASSETS (coursework, images, clips for Udemy/YouTube) ---------- */
  function renderAssets() {
    var assets = store.get("assets", []);
    var types = ["Coursework note", "Image", "Video clip", "Course idea (Udemy/YT)", "Project file", "Certificate", "Link"];
    var form = '<div class="section open" style="margin-bottom:18px"><div class="sec-body" style="display:block"><div class="row">' +
      '<div class="field"><label>Type</label><select class="tin" id="a-type">' + types.map(function (t) { return "<option>" + t + "</option>"; }).join("") + "</select></div>" +
      '<div class="field" style="flex:1;min-width:200px"><label>Title / description</label><input class="tin" id="a-title" placeholder="e.g. Pong post-mortem clip"></div>' +
      '<div class="field" style="flex:1;min-width:200px"><label>Link or location (optional)</label><input class="tin" id="a-link" placeholder="URL or file path on your computer"></div>' +
      '<div class="field"><label>&nbsp;</label><button class="btn" id="a-add">+ Log Asset</button></div>' +
      "</div></div></div>";
    var list = assets.length ? assets.map(function (a, i) {
      var link = a.link ? '<a href="' + esc(a.link) + '" target="_blank" rel="noopener">open ↗</a>' : '<span class="note">no link</span>';
      return '<div class="asset-row"><div><span class="a-type">' + esc(a.type) + "</span><br>" + esc(a.title) + "</div>" +
        "<div>" + link + "</div>" +
        '<button class="btn sm adel" data-i="' + i + '">✕</button></div>';
    }).join("") : '<div class="empty">No assets logged. Track every clip, image, and course idea you generate so you can repurpose them into Udemy/YouTube later.</div>';
    return '<h2 class="viewtitle">🎬 ASSET &amp; CONTENT VAULT <span class="note">— raw material for courses, videos, books</span></h2>' + form + list;
  }

  /* ---------- ABOUT ---------- */
  function renderAbout() {
    return '<h2 class="viewtitle">ℹ ABOUT THIS APP</h2>' +
      '<div class="hero" style="--accent:#9b59ff"><h1>Awakening Arcade</h1>' +
      '<p>A personal learning OS organized around two passions — <strong>making retro-era games</strong> and ' +
      '<strong>mastering electrical (theory → licensed trade)</strong> — built on the three pillars of ' +
      '<em>Coursework · Career · Sidegigz</em>. Sections break into subsections and checkable subtasks, with spaced ' +
      'reinforcement that loops backward, not forward.</p></div>' +
      '<div class="callout"><strong>Privacy:</strong> 100% local. Your progress, book, journal, and assets are stored ' +
      'in this browser only and never leave your device. Back up regularly.</div>' +
      '<div class="callout"><strong>Disclaimer:</strong> Career timelines, wage ranges, course costs, and licensing ' +
      'rules are ballpark guidance gathered to point you in the right direction — always verify current numbers and ' +
      'requirements with the official sources linked (CO DORA, ABET, schools, NEC). Never perform live electrical work ' +
      'untrained or unlicensed.</div>' +
      '<h3 class="pixel" style="font-size:11px;color:var(--gold)">HOW TO GROW THIS</h3>' +
      '<p class="note">Curriculum lives in <code>js/data/gamedev.js</code> and <code>js/data/electrical.js</code> as plain ' +
      'data — add sections, subsections, tasks, resources, and reinforcement there and they appear automatically. ' +
      'Future expansions (certification directories, course catalogs, career-fit profiling, location-aware course finder) ' +
      'plug into the same model.</p>';
  }

  /* ---------- view router ---------- */
  var views = {};
  function buildViews() {
    views = {
      dashboard: renderDashboard,
      book: renderBook,
      journal: renderJournal,
      assets: renderAssets,
      about: renderAbout
    };
    TRACKS.forEach(function (t) { views["track:" + t.id] = function () { return renderTrack(t); }; });
  }

  var content = document.getElementById("content");
  var current = store.get("currentView", "dashboard");

  function setView(v) {
    current = v; store.set("currentView", v);
    if (!views[v]) v = "dashboard";
    content.innerHTML = "<div class='view active'>" + views[v]() + "</div>";
    document.querySelectorAll(".tab").forEach(function (b) { b.classList.toggle("active", b.dataset.view === v); });
    document.querySelectorAll(".side .navitem").forEach(function (b) { b.classList.toggle("on", b.dataset.view === v); });
    wireView(v);
    content.parentElement.scrollTop = 0;
    window.scrollTo(0, 0);
  }

  /* ---------- per-view wiring ---------- */
  function wireView(v) {
    // task checkboxes (track views)
    content.querySelectorAll(".task").forEach(function (lab) {
      lab.addEventListener("click", function (e) {
        if (e.target.tagName !== "INPUT") { /* allow label click toggles native */ }
      });
      var cb = lab.querySelector("input");
      cb.addEventListener("change", function () {
        var id = lab.dataset.id;
        if (cb.checked) done[id] = true; else delete done[id];
        saveDone();
        lab.classList.toggle("done", cb.checked);
        // update section + track percentages live
        var trackId = id.split("/")[0];
        var track = TRACKS.filter(function (t) { return t.id === trackId; })[0];
        if (track) {
          var secEl = lab.closest(".section");
          if (secEl) {
            var sec = track.sections.filter(function (s) { return s.id === secEl.dataset.sec; })[0];
            if (sec) { var sp = secEl.querySelector(".secpct"); if (sp) sp.textContent = pct(sectionTaskIds(track, sec)) + "%"; }
          }
          var fill = content.querySelector(".hero .progress-fill");
          var lbl = content.querySelector(".hero .progress-label");
          if (fill) { var ids = trackTaskIds(track); fill.style.width = pct(ids) + "%"; if (lbl) lbl.textContent = "TRACK PROGRESS: " + countDone(ids) + " / " + ids.length + " tasks · " + pct(ids) + "%"; }
        }
      });
    });
    // collapse/expand sections
    content.querySelectorAll(".sec-head").forEach(function (h) {
      h.addEventListener("click", function () {
        var sec = h.closest(".section"); sec.classList.toggle("open");
        var chev = h.querySelector(".chev"); if (chev) chev.textContent = sec.classList.contains("open") ? "▼" : "▶";
      });
    });
    // jobs button
    content.querySelectorAll(".jobs-btn").forEach(function (b) {
      b.addEventListener("click", function () {
        var q = encodeURIComponent(b.dataset.q);
        window.open("https://www.indeed.com/jobs?q=" + q, "_blank", "noopener");
      });
    });
    // send subsection to book as a prompt
    content.querySelectorAll(".tobook-btn").forEach(function (b) {
      b.addEventListener("click", function () {
        var book = getBook();
        book.push({ title: "Idea: " + b.dataset.t, body: "What did I learn here? How will I teach/use it?\n\n" });
        store.set("book", book);
        b.textContent = "✓ Added to Book";
      });
    });

    if (v === "book") wireBook();
    if (v === "journal") wireJournal();
    if (v === "assets") wireAssets();
  }

  function wireBook() {
    content.querySelectorAll(".chapter-list .ci").forEach(function (ci) {
      ci.addEventListener("click", function () { curChapter = +ci.dataset.i; setView("book"); });
    });
    var titleIn = document.getElementById("book-title");
    var bodyIn = document.getElementById("book-body");
    var saveLbl = document.getElementById("book-save");
    function persist() {
      var book = getBook();
      if (!book[curChapter]) book[curChapter] = { title: "", body: "" };
      book[curChapter].title = titleIn.value;
      book[curChapter].body = bodyIn.value;
      store.set("book", book);
      var w = bodyIn.value.trim() ? bodyIn.value.trim().split(/\s+/).length : 0;
      saveLbl.textContent = "Saved ✓ · " + w + " words";
    }
    var t;
    function debounced() { saveLbl.textContent = "Saving…"; clearTimeout(t); t = setTimeout(persist, 350); }
    titleIn.addEventListener("input", function () { debounced(); refreshChapterTitle(); });
    bodyIn.addEventListener("input", debounced);
    function refreshChapterTitle() {
      var on = content.querySelector(".chapter-list .ci.on"); if (on) on.textContent = titleIn.value || "Untitled";
    }
    document.getElementById("book-add").addEventListener("click", function () {
      var book = getBook(); book.push({ title: "New Chapter", body: "" }); store.set("book", book); curChapter = book.length - 1; setView("book");
    });
    document.getElementById("book-del").addEventListener("click", function () {
      var book = getBook(); if (book.length <= 1) { alert("Keep at least one chapter."); return; }
      if (!confirm("Delete this chapter? This cannot be undone.")) return;
      book.splice(curChapter, 1); store.set("book", book); curChapter = 0; setView("book");
    });
    document.getElementById("book-export").addEventListener("click", function () {
      var book = getBook();
      var md = book.map(function (c) { return "# " + (c.title || "Untitled") + "\n\n" + (c.body || "") + "\n"; }).join("\n---\n\n");
      download("my-self-help-book.md", md);
    });
  }

  function wireJournal() {
    var add = document.getElementById("j-add");
    if (add) add.addEventListener("click", function () {
      var body = document.getElementById("j-body").value.trim();
      if (!body) return;
      var mood = document.getElementById("j-mood").value;
      var entries = store.get("journal", []);
      entries.unshift({ when: new Date().toLocaleString(), mood: mood, body: body });
      store.set("journal", entries); setView("journal");
    });
    content.querySelectorAll(".jdel").forEach(function (b) {
      b.addEventListener("click", function () {
        var entries = store.get("journal", []); entries.splice(+b.dataset.i, 1); store.set("journal", entries); setView("journal");
      });
    });
  }

  function wireAssets() {
    var add = document.getElementById("a-add");
    if (add) add.addEventListener("click", function () {
      var title = document.getElementById("a-title").value.trim();
      if (!title) return;
      var a = { type: document.getElementById("a-type").value, title: title, link: document.getElementById("a-link").value.trim() };
      var assets = store.get("assets", []); assets.unshift(a); store.set("assets", assets); setView("assets");
    });
    content.querySelectorAll(".adel").forEach(function (b) {
      b.addEventListener("click", function () {
        var assets = store.get("assets", []); assets.splice(+b.dataset.i, 1); store.set("assets", assets); setView("assets");
      });
    });
  }

  /* ---------- backup / restore ---------- */
  function download(name, text) {
    var blob = new Blob([text], { type: "text/plain;charset=utf-8" });
    var a = document.createElement("a"); a.href = URL.createObjectURL(blob); a.download = name;
    document.body.appendChild(a); a.click(); setTimeout(function () { URL.revokeObjectURL(a.href); a.remove(); }, 100);
  }
  function backup() {
    var data = {};
    store.keys().forEach(function (k) { data[k] = store.get(k, null); });
    download("awakening-backup-" + new Date().toISOString().slice(0, 10) + ".json", JSON.stringify(data, null, 2));
  }
  function restore() {
    var inp = document.createElement("input"); inp.type = "file"; inp.accept = "application/json,.json";
    inp.addEventListener("change", function () {
      var f = inp.files[0]; if (!f) return;
      var r = new FileReader();
      r.onload = function () {
        try {
          var data = JSON.parse(r.result);
          if (!confirm("Restore will overwrite current data on this device. Continue?")) return;
          Object.keys(data).forEach(function (k) { store.set(k, data[k]); });
          done = store.get("done", {});
          alert("Restored ✓");
          location.reload();
        } catch (e) { alert("Could not read that file."); }
      };
      r.readAsText(f);
    });
    inp.click();
  }

  /* ---------- build chrome (tabs + sidebar) ---------- */
  function buildChrome() {
    var tabs = document.getElementById("tabs");
    var sidebar = document.getElementById("sidebar");
    var tabDefs = [{ v: "dashboard", t: "🏠 Home" }];
    TRACKS.forEach(function (tr) { tabDefs.push({ v: "track:" + tr.id, t: (tr.id === "gamedev" ? "🕹 Games" : "⚡ Electrical") }); });
    tabDefs.push({ v: "book", t: "📖 Book" }, { v: "journal", t: "🌌 Journal" }, { v: "assets", t: "🎬 Assets" }, { v: "about", t: "ℹ About" });
    tabs.innerHTML = tabDefs.map(function (d) { return '<button class="tab" data-view="' + d.v + '">' + d.t + "</button>"; }).join("");
    tabs.querySelectorAll(".tab").forEach(function (b) { b.addEventListener("click", function () { setView(b.dataset.view); }); });

    // sidebar = jump-to-section nav for each track
    var html = '<div class="navitem" data-view="dashboard">🏠 Mission Control</div>';
    TRACKS.forEach(function (tr) {
      html += '<h3 style="color:' + tr.accent + '">' + (tr.id === "gamedev" ? "🕹 " : "⚡ ") + esc(tr.title) + "</h3>";
      tr.sections.forEach(function (s) {
        html += '<div class="navitem" data-view="track:' + tr.id + '" data-sec="' + s.id + '">' +
          '<span class="mini">' + esc(s.era) + "</span><br>" + esc(s.title) + "</div>";
      });
    });
    html += '<h3>Tools</h3>' +
      '<div class="navitem" data-view="book">📖 My Book</div>' +
      '<div class="navitem" data-view="journal">🌌 Journal</div>' +
      '<div class="navitem" data-view="assets">🎬 Assets</div>';
    sidebar.innerHTML = html;
    sidebar.querySelectorAll(".navitem").forEach(function (b) {
      b.addEventListener("click", function () {
        setView(b.dataset.view);
        if (b.dataset.sec) {
          // open + scroll to the section
          setTimeout(function () {
            var secEl = content.querySelector('.section[data-sec="' + b.dataset.sec + '"]');
            if (secEl) { secEl.classList.add("open"); var c = secEl.querySelector(".chev"); if (c) c.textContent = "▼"; secEl.scrollIntoView({ behavior: "smooth", block: "start" }); }
          }, 40);
        }
      });
    });

    document.getElementById("btn-backup").addEventListener("click", backup);
    document.getElementById("btn-restore").addEventListener("click", restore);
  }

  /* ---------- boot ---------- */
  function boot() {
    if (!window.TRACKS || !TRACKS.length) { content.innerHTML = "<p class=empty>No curriculum data loaded.</p>"; return; }
    buildViews(); buildChrome(); setView(views[current] ? current : "dashboard");
  }
  document.addEventListener("DOMContentLoaded", boot);
})();
