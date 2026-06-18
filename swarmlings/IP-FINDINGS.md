# IP-Findings — staying clear of protected material

**Not legal advice.** This is an engineering log of how we keep the game in
"genre, not copy" territory so it can ship on the App Store, Google Play,
Steam, and (eventually) the eShop without takedown risk. When real money is
on the line, have an IP attorney review.

## The one principle

> **Game mechanics, rules, and genres are not protected by copyright.**
> What *is* protected: specific characters, their names and designs, original
> art, music, story text, logos, trademarks, and the source code itself.

So we are free to make a "command-a-swarm-of-helpers, day-timer, carry-and-
fight" game. We are **not** free to reuse the source game's creatures, names,
mascot, music, UI art, or trade dress.

## Substitution table — element → risk → our original choice

| Source-game element | Why it's risky | Our original replacement |
|---|---|---|
| The named plant-creatures | Protected characters + trademark | **Bloomlings** (v2) / **Polyps** (v3) — our own designs/names |
| The spaceman mascot | Protected character + trademark | **Surveyor** (v2) / **Coral-keeper** (v3) |
| The bulb/onion base | Distinctive character design | **Hive-Pod** (v2) / **Spire** (v3) — generic geometric forms |
| Specific enemy designs | Protected art | **Gnashbud** / **Gulper** — original silhouettes |
| Exact color↔ability mapping copied 1:1 | Could read as derivative if identical | We use **fire / water / shock** resist tied to our own colors & themes |
| Sound effects & soundtrack | Protected recordings/compositions | **Procedural WebAudio** generated at runtime — 100% original |
| Fonts, logos, UI chrome | Trademark / trade dress | System fonts + our own minimalist UI |
| Box art / key art / title | Trademark | Original title **SWARMLINGS** + original art (TBD) |
| Source code | Copyright | Written from scratch in this repo |

## Trademark notes (separate from copyright)

- Never use the source game's name (or near-misspellings) in our title,
  store listing, keywords, or marketing. "A game *like* X" is risky as a
  keyword and can trigger storefront rejection.
- Pick a distinctive mark, run a knockout search before committing, and
  avoid suggestive mascots/logos that evoke the original's trade dress.

## Safe-harbor checklist before any public build

- [ ] No source-game names anywhere in code, assets, or metadata.
- [ ] All art original or properly licensed (keep receipts/licenses).
- [ ] All audio original/procedural or licensed.
- [ ] No ripped sprites, models, fonts, or sounds — ever.
- [ ] Title + logo cleared by a trademark knockout search.
- [ ] Store description sells *our* world, not "the X clone."
- [ ] (If commercial) attorney review of art + marks.

## "How close is too close?"

The safe line: **clone the verb, not the noun.** Reproduce the *feeling* of
making smart routing decisions under a timer (verb). Never reproduce the
specific creatures, mascot, music, or look (nouns). v2 lives right at that
line on purpose and documents each swap; v3 steps well back from it by
changing the world entirely.
