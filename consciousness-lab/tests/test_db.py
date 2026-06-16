import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from conlab.db import Storage
from conlab.documents import collector
from conlab.biometrics.muse import SimSource
from conlab.biometrics.session import record_session


def make_store(tmp_path):
    return Storage(tmp_path / "test.sqlite3")


def test_schema_and_counts(tmp_path):
    store = make_store(tmp_path)
    counts = store.counts()
    assert set(counts) == {
        "documents", "subjects", "sessions",
        "session_metrics", "journal", "tags",
    }
    assert all(v == 0 for v in counts.values())
    store.close()


def test_seed_documents_are_verified(tmp_path):
    store = make_store(tmp_path)
    ids = collector.seed(store)
    assert len(ids) >= 3
    docs = store.list_documents()
    titles = [d["title"] for d in docs]
    assert any("Gateway Process" in t for t in titles)
    # seeded docs are marked verified and carry theme tags
    gw = next(d for d in docs if "Gateway Process" in d["title"])
    assert gw["verified"] == 1
    tag_names = {t["tag"] for t in store.tags_for("document", gw["id"])}
    assert "gateway" in tag_names
    store.close()


def test_seed_is_idempotent(tmp_path):
    store = make_store(tmp_path)
    collector.seed(store)
    n1 = store.counts()["documents"]
    collector.seed(store)
    n2 = store.counts()["documents"]
    assert n1 == n2
    store.close()


def test_record_session_with_sim(tmp_path):
    store = make_store(tmp_path)
    result = record_session(
        store, subject="brandon", seconds=10, device="sim",
        source=SimSource(seed=1),
    )
    assert result.samples == 10
    # 5 bands + hr each second = 6 metrics * 10 = 60 rows
    assert store.counts()["session_metrics"] == 60
    assert "alpha" in result.summary and "hr_bpm" in result.summary
    store.close()


def test_journal_and_tags(tmp_path):
    store = make_store(tmp_path)
    jid = store.add_journal(body="Tried a gateway hemi-sync meditation today")
    assert jid > 0
    store.tag("journal", jid, "gateway")
    assert any(t["tag"] == "gateway" for t in store.tags_for("journal", jid))
    store.close()


def test_fetch_url_offline_records_metadata(tmp_path):
    store = make_store(tmp_path)
    # An unroutable URL: must NOT raise, must record metadata-only.
    doc_id, path, status = collector.fetch_url(
        store, "http://127.0.0.1:9/nope.pdf", title="x", timeout=1.0
    )
    assert doc_id > 0
    assert path is None
    assert "metadata-only" in status
    store.close()
