async function load() {
  const r = await fetch('/api/data');
  const d = await r.json();
  renderPlan(d.plan);
  renderMatches(d.matches);
  document.getElementById('profile').value = JSON.stringify(d.profile, null, 2);
  const sel = document.getElementById('d-settlement');
  sel.innerHTML = d.settlements.map(s => `<option value="${s.id}">${s.title}</option>`).join('');
}

function renderPlan(plan) {
  if (!plan || !plan.tasks.length) { document.getElementById('plan').textContent = 'No actions yet — load a profile.'; return; }
  const [lo, hi] = plan.estimated_total_recovery_usd;
  let h = `<p><b>${plan.task_count}</b> actions · est. recovery <b>$${lo}–$${hi}</b></p>`;
  for (const t of plan.tasks) {
    h += `<div class="task"><b>${t.title}</b> <span class="urg">${t.urgency}</span><br>`;
    h += `<a href="${t.official_url}" target="_blank" rel="noopener">official site ↗</a>`;
    h += `<ul>` + t.steps.map(s => `<li>${s}</li>`).join('') + `</ul></div>`;
  }
  document.getElementById('plan').innerHTML = h;
}

function renderMatches(matches) {
  if (!matches.length) { document.getElementById('matches').textContent = 'No matches — load a profile below.'; return; }
  document.getElementById('matches').innerHTML = matches.map(m => {
    const reasons = m.matched_reasons.map(r => `<div class="reason">✓ ${r}</div>`).join('');
    const miss = m.missing_info.map(r => `<div class="miss">? ${r}</div>`).join('');
    return `<div class="match ${m.status}"><span class="badge ${m.status}">${m.status}</span>
      <b> ${m.title}</b> <small>score ${m.score}</small>${reasons}${miss}</div>`;
  }).join('');
}

document.getElementById('save').onclick = async () => {
  let profile;
  try { profile = JSON.parse(document.getElementById('profile').value); }
  catch (e) { document.getElementById('saved').textContent = 'Invalid JSON: ' + e.message; return; }
  await fetch('/api/profile', { method: 'POST', body: JSON.stringify(profile) });
  document.getElementById('saved').textContent = 'Saved ✓';
  load();
};

document.getElementById('d-go').onclick = async () => {
  const body = JSON.stringify({
    settlement_id: document.getElementById('d-settlement').value,
    kind: document.getElementById('d-kind').value,
    channel: document.getElementById('d-channel').value,
  });
  const r = await fetch('/api/draft', { method: 'POST', body });
  const d = await r.json();
  document.getElementById('draft').textContent = `Subject: ${d.subject}\n\n${d.body}`;
};

load();
