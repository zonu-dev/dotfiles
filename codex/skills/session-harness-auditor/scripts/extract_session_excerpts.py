#!/usr/bin/env python3
import argparse
import json
from collections.abc import Iterable


FIELDS = ("text", "message", "output", "input", "content", "cmd", "body")


def strings(value):
    if isinstance(value, dict):
        for key in FIELDS:
            item = value.get(key)
            if isinstance(item, str):
                yield item
        for item in value.values():
            yield from strings(item)
    elif isinstance(value, list):
        for item in value:
            yield from strings(item)


def compact(parts: Iterable[str], max_chars: int) -> str:
    text = " | ".join(part.replace("\n", " ").strip() for part in parts if part.strip())
    return text[:max_chars]


def main() -> int:
    parser = argparse.ArgumentParser(description="Print bounded excerpts from Codex session JSONL logs.")
    parser.add_argument("jsonl")
    parser.add_argument("--keyword", action="append", default=[], help="Only include records containing this text. Can be repeated.")
    parser.add_argument("--start", type=int, default=1, help="First 1-based line number to inspect.")
    parser.add_argument("--end", type=int, help="Last 1-based line number to inspect.")
    parser.add_argument("--limit", type=int, default=40, help="Maximum matching records to print.")
    parser.add_argument("--max-chars", type=int, default=900, help="Maximum excerpt characters per record.")
    args = parser.parse_args()

    printed = 0
    with open(args.jsonl, encoding="utf-8") as fh:
        for line_no, line in enumerate(fh, 1):
            if line_no < args.start:
                continue
            if args.end is not None and line_no > args.end:
                break
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue

            parts = list(strings(record))
            haystack = "\n".join(parts)
            if args.keyword and not any(keyword in haystack for keyword in args.keyword):
                continue

            excerpt = compact(parts, args.max_chars)
            if not excerpt:
                continue
            print(f"--- line {line_no}")
            print(excerpt)
            printed += 1
            if printed >= args.limit:
                break

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
