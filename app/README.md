# WANDR — your personal travel intelligence

An "epic" trip-idea generator UI with a per-user **learning agent**. You sign in,
WANDR spins up a private sub-agent (a memory **compartment** unique to your
account), and it learns how *you* like to travel through a short, sharp
interview — then generates ranked trip ideas and helps you narrow each one down
with recommendations scored to your profile.

## Run it

It's a zero-build static app. Either:

```bash
# option A — just open the file
open app/index.html          # macOS  (xdg-open on Linux)

# option B — serve it (recommended; any static server works)
cd app && python3 -m http.server 8000
# then visit http://localhost:8000
```

No install, no API keys. Everything runs in the browser.

## The experience (the flow you asked for)

1. **Sign in → your agent is born.** Each email gets an isolated compartment in
   `localStorage`, and a stable, named sub-agent (Atlas, Vega, …). Sign back in
   later and it remembers you.
2. **Basics, with smart defaults.** Trip length defaults to **2 weeks**, plus
   budget, who's going, when, and optional first instincts. Change anything.
3. **The interview.** Instead of a giant form, the agent asks the *most
   informative* next question (an information-gain pick over the traits it's
   least sure about) — "best researched questions, at first and at crucial
   points." Each answer trains the **Shadow Profile**.
4. **Idea generation.** Destinations are ranked by cosine fit between your
   profile and each place's trait vector (confidence-weighted), nudged by season
   and budget. Every card explains *why it fits you*.
5. **Narrow it down.** Pick a trip and refine segments — stay, experiences,
   food, pace — each option re-scored to you, with searches/recommendations.
   On entering refine (a **crucial point**) the agent asks one more pointed
   question and *re-ranks live*.
6. **Shadow Profile drawer.** Open it any time to see the trained preference
   vector, per-trait confidence, and the plain-language things the agent has
   inferred — "training the shadow side," made visible and yours alone.

## How it's built

| File | Role |
|------|------|
| `index.html` | Shell, top bar, aurora background, Shadow drawer |
| `styles.css` | The whole design system (dark/glassmorphism/aurora) |
| `data.js`    | Destinations, the adaptive question bank, segment recs, trait model |
| `agent.js`   | The per-user sub-agent: compartments, learning, scoring, question selection |
| `app.js`     | Screen flow + all UI rendering and interactions |

### Where a real LLM plugs in

This prototype is fully self-contained so it runs offline, but it's architected
around the seams you'd swap for production:

- **`Agent.nextQuestion()`** — replace the information-gain heuristic with an LLM
  that *writes* the next best question from the user's history.
- **`Agent.rankDestinations()` / `rankSegment()`** — swap the local catalog for
  live search + retrieval (flights, stays, activities) re-ranked by the profile.
- **`deriveInsight()`** — let the model narrate what it learned.
- **`localStorage` compartments** — back with real auth + a per-user vector store.

The trait vector + confidence model in `agent.js` is exactly the kind of
durable user memory you'd persist server-side per account.
