import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from conlab.analysis import tags as taglib


def test_suggest_themes_matches_keywords():
    out = taglib.suggest_themes("A gateway hemi-sync and remote viewing study")
    assert "gateway" in out
    assert "hemi-sync" in out
    assert "remote-viewing" in out


def test_suggest_themes_empty():
    assert taglib.suggest_themes("") == []
    assert taglib.suggest_themes("nothing relevant here") == []


def test_centers_have_correlates():
    assert taglib.CENTERS
    for c in taglib.CENTERS:
        assert c.correlate
        assert c.name


def test_center_for_band():
    # gamma is referenced by the crown center
    assert "crown" in taglib.center_for_band("gamma")
