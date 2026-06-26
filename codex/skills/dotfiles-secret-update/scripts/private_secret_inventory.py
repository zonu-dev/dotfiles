#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Mapping:
    encrypted: str
    live: Path


def run(args: list[str], cwd: Path | None = None) -> tuple[int, bytes, bytes]:
    proc = subprocess.run(
        args,
        cwd=str(cwd) if cwd else None,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return proc.returncode, proc.stdout, proc.stderr


def parse_restore_mappings(repo: Path) -> list[Mapping]:
    restore = repo / "scripts/restore.sh"
    if not restore.exists():
        return []

    pattern = re.compile(r'^restore_file\s+"([^"]+)"\s+"\$HOME/([^"]+)"')
    mappings: list[Mapping] = []
    for line in restore.read_text().splitlines():
        match = pattern.search(line.strip())
        if not match:
            continue
        encrypted, live_suffix = match.groups()
        mappings.append(Mapping(encrypted=encrypted, live=Path.home() / live_suffix))
    return mappings


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def decrypt_hash(path: Path) -> tuple[str | None, str | None]:
    code, out, err = run(["sops", "--decrypt", "--input-type", "binary", "--output-type", "binary", str(path)])
    if code != 0:
        return None, err.decode(errors="replace").strip()
    return sha256_bytes(out), None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--private-repo", default=os.environ.get("DOTFILES_PRIVATE_REPO"))
    args = parser.parse_args()

    if not args.private_repo:
        print("Set DOTFILES_PRIVATE_REPO or pass --private-repo <path>.", file=sys.stderr)
        return 2

    repo = Path(args.private_repo).expanduser()
    mappings = parse_restore_mappings(repo)
    encrypted_paths = {m.encrypted for m in mappings}
    all_encrypted = sorted(str(p.relative_to(repo)) for p in (repo / "secrets").rglob("*.enc")) if (repo / "secrets").exists() else []

    print("# Private Secret Inventory\n")
    print(f"- Private repo: `{repo}`")
    print(f"- Managed mappings: {len(mappings)}")
    print()

    if not mappings:
        print("No mappings found in `scripts/restore.sh`.")
    else:
        print("## Managed Files\n")
        for mapping in mappings:
            encrypted = repo / mapping.encrypted
            live = mapping.live

            encrypted_exists = encrypted.exists()
            live_exists = live.exists()
            status: str
            detail = ""

            if not encrypted_exists and not live_exists:
                status = "missing-both"
            elif not encrypted_exists:
                status = "encrypted-missing"
            elif not live_exists:
                status = "live-missing"
            else:
                decrypted_hash, error = decrypt_hash(encrypted)
                if error:
                    status = "decrypt-failed"
                    detail = f" ({error.splitlines()[0]})" if error else ""
                else:
                    live_hash = sha256_file(live)
                    status = "in-sync" if decrypted_hash == live_hash else "differs"

            print(f"- `{mapping.encrypted}` -> `{live}`: {status}{detail}")
        print()

    orphaned = [path for path in all_encrypted if path not in encrypted_paths]
    print("## Encrypted Files Not Listed In restore.sh\n")
    if orphaned:
        for path in orphaned:
            print(f"- `{path}`")
    else:
        print("- None")

    return 0


if __name__ == "__main__":
    sys.exit(main())
