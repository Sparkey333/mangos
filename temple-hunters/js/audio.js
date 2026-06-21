/* ============================================================================
 * audio.js — tiny WebAudio engine.
 *
 * The whole point of the "frequency/color/sound" theory is that you can HEAR
 * it. So a Hunter's signature ("tone") move actually plays its solfeggio
 * frequency. Basic moves get a short blippy hit. No audio files — it's all
 * synthesized, and it stays silent until the player taps once (iOS rule).
 * ========================================================================== */

const Audio7 = (() => {
  let ctx = null;
  let enabled = true;

  function ensure() {
    if (!ctx) {
      const AC = window.AudioContext || window.webkitAudioContext;
      if (AC) ctx = new AC();
    }
    if (ctx && ctx.state === "suspended") ctx.resume();
    return ctx;
  }

  // a sustained, gentle pad at `freq` Hz — used for signature "tone" moves
  function tone(freq, dur = 1.1) {
    if (!enabled) return;
    const ac = ensure(); if (!ac) return;
    const now = ac.currentTime;
    const gain = ac.createGain();
    gain.gain.setValueAtTime(0, now);
    gain.gain.linearRampToValueAtTime(0.18, now + 0.06);
    gain.gain.exponentialRampToValueAtTime(0.0008, now + dur);
    gain.connect(ac.destination);

    // a sine carrier plus a soft fifth for body
    [ [freq, "sine", 1], [freq * 1.5, "sine", 0.35], [freq * 2, "triangle", 0.15] ]
      .forEach(([f, type, amp]) => {
        const o = ac.createOscillator();
        const g = ac.createGain();
        o.type = type; o.frequency.value = f; g.gain.value = amp;
        o.connect(g); g.connect(gain);
        o.start(now); o.stop(now + dur);
      });
  }

  // a short percussive hit — used for physical moves
  function hit(base = 220) {
    if (!enabled) return;
    const ac = ensure(); if (!ac) return;
    const now = ac.currentTime;
    const o = ac.createOscillator();
    const g = ac.createGain();
    o.type = "square";
    o.frequency.setValueAtTime(base, now);
    o.frequency.exponentialRampToValueAtTime(base * 0.5, now + 0.12);
    g.gain.setValueAtTime(0.16, now);
    g.gain.exponentialRampToValueAtTime(0.001, now + 0.16);
    o.connect(g); g.connect(ac.destination);
    o.start(now); o.stop(now + 0.18);
  }

  // a tiny UI click
  function blip(freq = 660) {
    if (!enabled) return;
    const ac = ensure(); if (!ac) return;
    const now = ac.currentTime;
    const o = ac.createOscillator();
    const g = ac.createGain();
    o.type = "square"; o.frequency.value = freq;
    g.gain.setValueAtTime(0.08, now);
    g.gain.exponentialRampToValueAtTime(0.001, now + 0.08);
    o.connect(g); g.connect(ac.destination);
    o.start(now); o.stop(now + 0.09);
  }

  // ascending arpeggio of all seven tones — victory sting
  function spectrum(freqs) {
    if (!enabled) return;
    freqs.forEach((f, i) => setTimeout(() => tone(f, 0.5), i * 130));
  }

  return {
    unlock: ensure,
    tone, hit, blip, spectrum,
    toggle() { enabled = !enabled; return enabled; },
    get enabled() { return enabled; }
  };
})();

if (typeof window !== "undefined") window.Audio7 = Audio7;
