# Backup & Provenance Log

A running record of where this project's contents came from, so nothing is ever "lost in a chat."

## Source of truth = Git

This repository **is** the backup. The cloud session that assembled AetherForge is ephemeral and
keeps no other persistent files. The rule going forward:

> If it isn't committed and pushed, it doesn't exist. Commit early, commit often.

## Migration record

| Date | What | From → To |
|---|---|---|
| 2026-06-25 | Original feasibility analysis | repo root `nintendo-clone-feasibility.md` → `public/docs/archive-original-feasibility.md` (now viewable in-app under **Archive**) |
| 2026-06-25 | Planning note | Claude plan file `what-top-3-games-*.md` (session-local, non-persistent) → folded into **Game Design Doc** + **Legal Clean-Room** |
| 2026-06-25 | New scaffolding | created Tauri 2 + Vite app, 8 hub documents, setup script |

> Note: Claude "plan files" live in the assistant's session workspace, not your repo — they don't
> persist. That's exactly why their content was copied into committed docs here.

## Recommended backup hygiene

- **Primary:** this Git repo (GitHub). Branch in use: `claude/nintendo-clone-feasibility-7i3usp`.
- **Game assets** (art, audio, `.blend`, DAW projects) get large — use **Git LFS**
  (<https://git-lfs.com>) or keep a synced `/assets-master` in iCloud/Dropbox/Backblaze and
  reference exports in-repo.
- **Releases:** tag milestones (`git tag v0.1-slice`) so you can always return to a known-good build.
- **3-2-1 rule:** 3 copies, 2 media, 1 offsite. GitHub + local + a cloud drive covers it.
