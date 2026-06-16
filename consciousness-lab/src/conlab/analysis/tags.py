"""Vocabularies and a lightweight auto-tagger for the interpretation layer.

This gives structure to the "symbolic parallels with demons/spirits",
"chakras / centers", and "unified theory" threads from the project brief —
without dressing them up as established science. Three tag *kinds*:

* ``theme``    — neutral subject keywords (e.g. 'gateway', 'remote-viewing').
* ``symbolic`` — cross-tradition symbolic parallels you choose to note.
* ``center``   — a hypothesized body/energy "center" (chakra-style), each
                 with the conventional EEG/physiology correlate people
                 associate with it. The correlate is a *hypothesis to test*
                 against your own recorded data, never a claim.

The auto-tagger only suggests ``theme`` tags from text by keyword match.
Symbolic and center tags are always applied by you, deliberately.
"""

from __future__ import annotations

from dataclasses import dataclass

# -- theme vocabulary: keyword -> canonical tag --------------------------
THEME_KEYWORDS: dict[str, str] = {
    "gateway": "gateway",
    "hemi-sync": "hemi-sync",
    "hemisync": "hemi-sync",
    "monroe": "monroe-institute",
    "binaural": "binaural-beats",
    "remote viewing": "remote-viewing",
    "remote-viewing": "remote-viewing",
    "star gate": "star-gate",
    "stargate": "star-gate",
    "mkultra": "mkultra",
    "out-of-body": "obe",
    "out of body": "obe",
    "astral": "obe",
    "consciousness": "consciousness",
    "meditation": "meditation",
    "psi": "psi",
    "psychoenergetic": "psi",
}


@dataclass(frozen=True)
class Center:
    """A hypothesized 'center' with a testable physiological correlate."""
    name: str
    traditional: str          # common chakra / tradition name
    correlate: str            # the physiological signal you'd watch
    rationale: str            # why people associate them (clearly a hypothesis)


# A starting, explicitly-hypothetical mapping. The value of this table is
# that each row names a *measurable* correlate you can actually log and
# correlate against subjective reports — turning vibes into experiments.
CENTERS: list[Center] = [
    Center("root", "Muladhara", "hr_bpm / HRV",
           "Grounding/safety states track autonomic (heart-rate) regulation."),
    Center("heart", "Anahata", "hrv + alpha",
           "'Heart' states often co-occur with calm alpha EEG and high HRV."),
    Center("throat", "Vishuddha", "beta",
           "Expression/speech planning associates with frontal beta activity."),
    Center("third-eye", "Ajna", "theta + alpha (frontal-midline)",
           "Focused-attention/imagery states show frontal-midline theta."),
    Center("crown", "Sahasrara", "gamma",
           "Reports of 'unity' states are sometimes linked to gamma; weak, "
           "contested evidence — treat as the headline hypothesis to test."),
]


def suggest_themes(text: str) -> list[str]:
    """Return canonical theme tags whose keywords appear in ``text``."""
    if not text:
        return []
    low = text.lower()
    found: list[str] = []
    for kw, canon in THEME_KEYWORDS.items():
        if kw in low and canon not in found:
            found.append(canon)
    return found


def center_for_band(band: str) -> list[str]:
    """Which hypothesized centers reference a given EEG band/metric."""
    return [c.name for c in CENTERS if band in c.correlate]
