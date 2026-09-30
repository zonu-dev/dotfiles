#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def sessions_root() -> Path:
    return Path.home() / ".codex" / "sessions"


def iter_session_files(root: Path):
    if not root.exists():
        return []
    return sorted(root.rglob("*.jsonl"), key=lambda p: p.stat().st_mtime, reverse=True)


def read_meta(path: Path) -> dict:
    try:
        with path.open("r", encoding="utf-8") as fh:
            for line in fh:
                if not line.strip():
                    continue
                obj = json.loads(line)
                if obj.get("type") == "session_meta":
                    return obj.get("payload", {})
                return {}
    except Exception as exc:
        return {"error": str(exc)}
    return {}


def main() -> int:
    parser = argparse.ArgumentParser(description="Find Codex session JSONL files.")
    parser.add_argument("--session-id", help="Full or partial Codex session id")
    parser.add_argument("--cwd", help="Filter sessions by working directory")
    parser.add_argument("--root", default=str(sessions_root()), help="Session root directory")
    parser.add_argument("--limit", type=int, default=10)
    args = parser.parse_args()

    root = Path(args.root).expanduser()
    rows = []
    for path in iter_session_files(root):
        meta = read_meta(path)
        session_id = str(meta.get("id", ""))
        cwd = str(meta.get("cwd", ""))
        if args.session_id and args.session_id not in session_id and args.session_id not in path.name:
            continue
        if args.cwd and (not cwd or Path(args.cwd).resolve() != Path(cwd).expanduser().resolve()):
            continue
        rows.append(
            {
                "path": str(path),
                "id": session_id,
                "timestamp": meta.get("timestamp"),
                "cwd": cwd,
                "originator": meta.get("originator"),
                "model": meta.get("model_provider"),
            }
        )
        if len(rows) >= args.limit:
            break

    print(json.dumps(rows, ensure_ascii=False, indent=2))
    return 0 if rows else 1


if __name__ == "__main__":
    raise SystemExit(main())
