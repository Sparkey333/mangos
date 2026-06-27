# Audio stems — your live guitar + drums go here

The adaptive music system (`scripts/music_manager.gd`) looks for three looping OGG
files. Record/compose them in your DAW (Reaper etc.), export as **same-length,
same-tempo loops**, and drop them here:

| File | Role | Suggested arrangement |
|------|------|-----------------------|
| `ambient.ogg` | exploration bed (always audible) | clean/atmospheric guitar, light or no drums |
| `combat.ogg`  | fades in near enemies | add a guitar lead + driving drums |
| `boss.ogg`    | full theme in boss arenas | the whole thing — distortion, double-time drums |

Tips:
- Keep all three the **same length and BPM** so they stay phase-aligned when layered.
- Export OGG Vorbis. Godot loops them automatically (the manager sets `loop = true`).
- No files yet? The game still runs — the music state machine just stays silent.
- Want true beat-synced layering later? Look at Godot's `AudioStreamSynchronized`
  and interactive-music docs.
