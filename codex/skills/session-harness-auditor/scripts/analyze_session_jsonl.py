#!/usr/bin/env python3
import argparse
import json
import re
from collections import Counter
from pathlib import Path
from typing import Any


ERROR_PATTERNS = [
    re.compile(r"process exited with code (?!0\b)-?\d+", re.I),
    re.compile(r"\b(error|failed|failure|exception|traceback|assert fail|aborted)\b", re.I),
]

SIGNAL_KEYWORDS = [
    "commit",
    "push",
    "review",
    "スクショ",
    "見た目",
    "画像",
    "文字化け",
    "余白",
    "再生成",
    "AGENTS.md",
    "skill",
    "hook",
    "smoke",
    "test",
    "browser",
]

OUTPUT_TOKEN_PATTERN = re.compile(r"Original token count:\s*([0-9]+)", re.I)
OUTPUT_LINE_PATTERN = re.compile(r"Total output lines:\s*([0-9]+)", re.I)
OVERSIZED_TOKEN_THRESHOLD = 100_000
OVERSIZED_LINE_THRESHOLD = 10_000


def walk_strings(value: Any):
    if isinstance(value, str):
        yield value
    elif isinstance(value, list):
        for item in value:
            yield from walk_strings(item)
    elif isinstance(value, dict):
        for item in value.values():
            yield from walk_strings(item)


def compact(text: str, limit: int = 220) -> str:
    text = re.sub(r"\s+", " ", text).strip()
    return text if len(text) <= limit else text[: limit - 1] + "…"


def load_events(path: Path):
    with path.open("r", encoding="utf-8") as fh:
        for line_no, line in enumerate(fh, 1):
            if not line.strip():
                continue
            try:
                yield line_no, json.loads(line)
            except json.JSONDecodeError:
                yield line_no, {"type": "decode_error", "payload": {"line": line[:200]}}


def main() -> int:
    parser = argparse.ArgumentParser(description="Summarize a Codex session JSONL for retrospective analysis.")
    parser.add_argument("session_jsonl")
    parser.add_argument("--max-items", type=int, default=20)
    args = parser.parse_args()

    path = Path(args.session_jsonl).expanduser()
    meta = {}
    type_counts = Counter()
    user_messages = []
    assistant_messages = 0
    toolish = []
    errors = []
    oversized_outputs = []
    keyword_hits = Counter()

    for line_no, event in load_events(path):
        event_type = event.get("type", "unknown")
        payload = event.get("payload", {})
        type_counts[event_type] += 1
        if event_type == "session_meta":
            meta = payload

        strings = list(walk_strings(payload))
        joined = "\n".join(strings)
        for keyword in SIGNAL_KEYWORDS:
            if keyword.lower() in joined.lower():
                keyword_hits[keyword] += 1

        if event_type == "response_item" and isinstance(payload, dict):
            if payload.get("type") == "message" and payload.get("role") == "user":
                text = " ".join(walk_strings(payload.get("content", [])))
                user_messages.append({"line": line_no, "text": compact(text)})
            elif payload.get("type") == "message" and payload.get("role") == "assistant":
                assistant_messages += 1
            elif payload.get("type") in {"function_call", "tool_call"}:
                toolish.append({"line": line_no, "type": payload.get("type"), "name": payload.get("name")})

        if event_type in {"response_item", "turn_context"}:
            for pattern in ERROR_PATTERNS:
                if pattern.search(joined):
                    errors.append({"line": line_no, "text": compact(joined)})
                    break

        if event_type == "response_item" and isinstance(payload, dict):
            if payload.get("type") in {"function_call_output", "tool_call_output"}:
                token_match = OUTPUT_TOKEN_PATTERN.search(joined)
                line_match = OUTPUT_LINE_PATTERN.search(joined)
                token_count = int(token_match.group(1)) if token_match else 0
                output_lines = int(line_match.group(1)) if line_match else 0
                if token_count > OVERSIZED_TOKEN_THRESHOLD or output_lines > OVERSIZED_LINE_THRESHOLD:
                    oversized_outputs.append(
                        {"line": line_no, "tokens": token_count, "lines": output_lines}
                    )

    print("# Session Harness Audit Summary")
    print()
    print(f"- Path: `{path}`")
    if meta:
        print(f"- Session id: `{meta.get('id', '')}`")
        print(f"- Timestamp: `{meta.get('timestamp', '')}`")
        print(f"- CWD: `{meta.get('cwd', '')}`")
        print(f"- Originator: `{meta.get('originator', '')}`")
    print()
    print("## Event Counts")
    for key, count in type_counts.most_common():
        print(f"- {key}: {count}")
    print()
    print("## User Requests")
    for item in user_messages[: args.max_items]:
        print(f"- line {item['line']}: {item['text']}")
    if len(user_messages) > args.max_items:
        print(f"- ... {len(user_messages) - args.max_items} more")
    print()
    print("## Error / Friction Signals")
    if errors:
        for item in errors[: args.max_items]:
            print(f"- line {item['line']}: {item['text']}")
        if len(errors) > args.max_items:
            print(f"- ... {len(errors) - args.max_items} more")
    else:
        print("- No obvious error/friction strings detected.")
    print()
    print("## Oversized Tool Outputs")
    if oversized_outputs:
        for item in oversized_outputs[: args.max_items]:
            print(
                f"- line {item['line']}: original_tokens={item['tokens']}, "
                f"output_lines={item['lines']}"
            )
        if len(oversized_outputs) > args.max_items:
            print(f"- ... {len(oversized_outputs) - args.max_items} more")
    else:
        print("- No oversized tool outputs detected.")
    print()
    print("## Keyword Signals")
    for key, count in keyword_hits.most_common():
        print(f"- {key}: {count}")
    print()
    print("## Retrospective Prompts")
    print("- Which user corrections repeated?")
    print("- Which failures could a project AGENTS.md rule, skill, hook, or harness have prevented?")
    print("- Which improvements are project-specific, and which are reusable globally?")
    print("- Which proposed changes have enough evidence to implement rather than only suggest?")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
