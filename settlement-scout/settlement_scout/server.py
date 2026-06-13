"""Zero-dependency HTTP server: JSON API + static web UI.

Run:  python -m settlement_scout.cli serve
Then open http://localhost:8765
"""
from __future__ import annotations

import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

from . import config, db
from .drafting import generate
from .matching import match_all
from .schedule import build_plan


def _dataset():
    conn = db.connect()
    try:
        settlements = db.all_settlements(conn)
        profile = db.load_profile(conn) or {}
        results = match_all(settlements, profile)
        matches = [r.to_dict() for r in results]
        by_id = {s["id"]: s for s in settlements}
        plan = build_plan(by_id, matches)
        return settlements, profile, matches, plan, by_id
    finally:
        conn.close()


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):  # quiet
        pass

    def _send(self, code, payload, ctype="application/json"):
        body = payload if isinstance(payload, bytes) else json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_json(self):
        length = int(self.headers.get("Content-Length", 0))
        if not length:
            return {}
        return json.loads(self.rfile.read(length) or b"{}")

    def do_GET(self):
        path = urlparse(self.path).path
        if path in ("/", "/index.html"):
            html = (config.WEB_DIR / "templates" / "index.html").read_bytes()
            return self._send(200, html, "text/html; charset=utf-8")
        if path == "/static/app.js":
            return self._send(200, (config.WEB_DIR / "static" / "app.js").read_bytes(),
                              "application/javascript")
        if path == "/static/style.css":
            return self._send(200, (config.WEB_DIR / "static" / "style.css").read_bytes(),
                              "text/css")
        if path == "/api/data":
            settlements, profile, matches, plan, _ = _dataset()
            return self._send(200, {"settlements": settlements, "profile": profile,
                                    "matches": matches, "plan": plan})
        return self._send(404, {"error": "not found"})

    def do_POST(self):
        path = urlparse(self.path).path
        if path == "/api/profile":
            profile = self._read_json()
            conn = db.connect()
            try:
                db.save_profile(conn, profile)
            finally:
                conn.close()
            return self._send(200, {"ok": True})
        if path == "/api/draft":
            req = self._read_json()
            settlements, profile, matches, _, by_id = _dataset()
            s = by_id.get(req.get("settlement_id"))
            if not s:
                return self._send(404, {"error": "unknown settlement"})
            reasons = next((m["matched_reasons"] for m in matches
                            if m["settlement_id"] == s["id"]), [])
            draft = generate(req.get("kind", "claim_inquiry"), s, profile,
                             channel=req.get("channel", "email"), matched_reasons=reasons)
            conn = db.connect()
            try:
                db.save_draft(conn, s["id"], draft["channel"], draft["subject"], draft["body"])
            finally:
                conn.close()
            return self._send(200, draft)
        return self._send(404, {"error": "not found"})


def serve(host: str = "0.0.0.0", port: int = 8765):
    httpd = ThreadingHTTPServer((host, port), Handler)
    print(f"Settlement Scout running at http://localhost:{port}  (Ctrl+C to stop)")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
