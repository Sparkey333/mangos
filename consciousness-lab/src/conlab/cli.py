"""Command-line interface for Consciousness Lab.

Run ``python -m conlab --help``. Designed to be obvious and offline-safe:
every command works without network or hardware except the ones that
explicitly reach out (``docs fetch``).
"""

from __future__ import annotations

import argparse
import sys

from . import __version__
from .analysis import tags as taglib
from .biometrics.session import record_session
from .db import Storage
from .documents import collector, sources


def _print_kv(d: dict) -> None:
    for k, v in d.items():
        print(f"  {k:<16} {v}")


def cmd_init(args, store: Storage) -> int:
    counts = store.counts()
    print(f"Consciousness Lab v{__version__}")
    print(f"Database: {store.path}")
    print("Tables:")
    _print_kv(counts)
    return 0


def cmd_status(args, store: Storage) -> int:
    _print_kv(store.counts())
    return 0


def cmd_docs_seed(args, store: Storage) -> int:
    ids = collector.seed(store)
    print(f"Seeded {len(ids)} verified anchor document(s).")
    for row in store.list_documents():
        flag = "✓" if row["verified"] else " "
        print(f"  [{flag}] {row['agency']:<5} {row['year'] or '----'}  {row['title']}")
    return 0


def cmd_docs_search(args, store: Storage) -> int:
    query = " ".join(args.query)
    print(f"Search links for: {query!r}\n")
    for name, url in collector.search_links(query).items():
        print(f"  {name}\n    {url}\n")
    print("Open a link, find a document, then record it with:")
    print('  conlab docs add "<url>" --title "..." --agency CIA --year 1983')
    return 0


def cmd_docs_add(args, store: Storage) -> int:
    if args.no_download:
        doc_id = store.add_document(
            source=args.source, title=args.title or args.url, url=args.url,
            agency=args.agency, year=args.year,
        )
        print(f"Recorded metadata only (id={doc_id}).")
        return 0
    doc_id, path, status = collector.fetch_url(
        store, args.url, title=args.title, agency=args.agency,
        year=args.year, source=args.source,
    )
    print(f"id={doc_id}  status={status}")
    if path:
        print(f"saved: {path}")
    return 0


def cmd_docs_list(args, store: Storage) -> int:
    rows = store.list_documents(agency=args.agency or "")
    for row in rows:
        flag = "✓" if row["verified"] else " "
        tg = ", ".join(t["tag"] for t in store.tags_for("document", row["id"]))
        print(f"[{flag}] #{row['id']} {row['agency']:<5} {row['year'] or '----'}  "
              f"{row['title']}" + (f"   ({tg})" if tg else ""))
    if not rows:
        print("(no documents yet — try `conlab docs seed`)")
    return 0


def cmd_record(args, store: Storage) -> int:
    result = record_session(
        store, subject=args.subject, seconds=args.seconds,
        device=args.device, protocol=args.protocol, notes=args.notes,
    )
    print(f"Session #{result.session_id} recorded "
          f"({result.samples} samples, device={args.device}).")
    print("Average band power / metrics:")
    _print_kv({k: round(v, 3) for k, v in result.summary.items()})
    return 0


def cmd_journal(args, store: Storage) -> int:
    body = " ".join(args.text)
    jid = store.add_journal(body=body, title=args.title, subject=args.subject)
    for t in taglib.suggest_themes(body):
        store.tag("journal", jid, t, kind="theme")
    suggested = taglib.suggest_themes(body)
    print(f"Journal #{jid} saved." +
          (f" Auto-tags: {', '.join(suggested)}" if suggested else ""))
    return 0


def cmd_centers(args, store: Storage) -> int:
    print("Hypothesized centers and their TESTABLE physiological correlates")
    print("(these are hypotheses to validate against your own data, not facts):\n")
    for c in taglib.CENTERS:
        print(f"  {c.name:<10} {c.traditional:<12} → {c.correlate}")
        print(f"             {c.rationale}\n")
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="conlab",
        description="Consciousness Lab — declassified-document + biometric research toolkit.",
    )
    p.add_argument("--db", help="path to SQLite db (default: ~/.conlab/conlab.sqlite3)")
    sub = p.add_subparsers(dest="command", required=True)

    sp = sub.add_parser("init", help="initialize / show the database")
    sp.set_defaults(func=cmd_init)

    sp = sub.add_parser("status", help="show row counts")
    sp.set_defaults(func=cmd_status)

    docs = sub.add_parser("docs", help="declassified-document tools").add_subparsers(
        dest="docs_cmd", required=True
    )

    sp = docs.add_parser("seed", help="load verified anchor documents (offline)")
    sp.set_defaults(func=cmd_docs_seed)

    sp = docs.add_parser("search", help="print search links for the public archives")
    sp.add_argument("query", nargs="+")
    sp.set_defaults(func=cmd_docs_search)

    sp = docs.add_parser("add", help="download/record a document by URL")
    sp.add_argument("url")
    sp.add_argument("--title", default="")
    sp.add_argument("--agency", default="")
    sp.add_argument("--year", type=int)
    sp.add_argument("--source", default="manual")
    sp.add_argument("--no-download", action="store_true",
                    help="record metadata only, do not fetch the file")
    sp.set_defaults(func=cmd_docs_add)

    sp = docs.add_parser("list", help="list stored documents")
    sp.add_argument("--agency", default="")
    sp.set_defaults(func=cmd_docs_list)

    sp = sub.add_parser("record", help="record a biometric session")
    sp.add_argument("--subject", required=True)
    sp.add_argument("--seconds", type=int, default=30)
    sp.add_argument("--device", default="sim", help="sim | muse_2 | muse_s")
    sp.add_argument("--protocol", default="")
    sp.add_argument("--notes", default="")
    sp.set_defaults(func=cmd_record)

    sp = sub.add_parser("journal", help="add a journal note")
    sp.add_argument("text", nargs="+")
    sp.add_argument("--title", default="")
    sp.add_argument("--subject", default="")
    sp.set_defaults(func=cmd_journal)

    sp = sub.add_parser("centers", help="show the testable 'centers' hypothesis table")
    sp.set_defaults(func=cmd_centers)

    return p


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    store = Storage(args.db) if args.db else Storage()
    try:
        return args.func(args, store)
    finally:
        store.close()


if __name__ == "__main__":
    sys.exit(main())
