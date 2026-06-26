#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import os
import re
import stat
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


def parse_encrypt_mappings(repo: Path) -> list[Mapping]:
    encrypt = repo / "scripts/encrypt-current.sh"
    if not encrypt.exists():
        return []

    pattern = re.compile(r'^encrypt_file\s+"\$HOME/([^"]+)"\s+"([^"]+)"')
    mappings: list[Mapping] = []
    for line in encrypt.read_text().splitlines():
        match = pattern.search(line.strip())
        if not match:
            continue
        live_suffix, encrypted = match.groups()
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


def permission_status(path: Path) -> str:
    mode = stat.S_IMODE(path.stat().st_mode)
    if mode & 0o077:
        return f"permission-too-open ({mode:04o}, expected 0600)"
    return f"permission-ok ({mode:04o})"


def redact_repo_path(repo: Path, show_paths: bool) -> str:
    return str(repo) if show_paths else "<private-overlay>"


def redact_live_path(path: Path, show_paths: bool) -> str:
    if show_paths:
        return str(path)

    try:
        return "$HOME/" + str(path.relative_to(Path.home()))
    except ValueError:
        return "<outside-home>"


def decrypt_hash(path: Path) -> tuple[str | None, str | None]:
    code, out, err = run(["sops", "--decrypt", "--input-type", "binary", "--output-type", "binary", str(path)])
    if code != 0:
        return None, err.decode(errors="replace").strip()
    return sha256_bytes(out), None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--private-repo", default=os.environ.get("DOTFILES_PRIVATE_REPO"))
    parser.add_argument(
        "--show-paths",
        action="store_true",
        help="print exact private overlay and live file paths for local debugging",
    )
    args = parser.parse_args()

    if not args.private_repo:
        print("Set DOTFILES_PRIVATE_REPO or pass --private-repo <path>.", file=sys.stderr)
        return 2

    repo = Path(args.private_repo).expanduser()
    mappings = parse_restore_mappings(repo)
    encrypt_mappings = parse_encrypt_mappings(repo)
    encrypted_paths = {m.encrypted for m in mappings}
    encrypt_paths = {m.encrypted for m in encrypt_mappings}
    all_encrypted = sorted(str(p.relative_to(repo)) for p in (repo / "secrets").rglob("*.enc")) if (repo / "secrets").exists() else []

    print("# Private Secret Inventory\n")
    print(f"- Private repo: `{redact_repo_path(repo, args.show_paths)}`")
    print(f"- Restore mappings: {len(mappings)}")
    print(f"- Encrypt mappings: {len(encrypt_mappings)}")
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
            details: list[str] = []

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
                    details.append("decrypt-error")
                else:
                    live_hash = sha256_file(live)
                    status = "in-sync" if decrypted_hash == live_hash else "differs"
                    details.append(permission_status(live))

            detail = f" ({'; '.join(details)})" if details else ""
            print(f"- `{mapping.encrypted}` -> `{redact_live_path(live, args.show_paths)}`: {status}{detail}")
        print()

    orphaned = [path for path in all_encrypted if path not in encrypted_paths]
    print("## Encrypted Files Not Listed In restore.sh\n")
    if orphaned:
        for path in orphaned:
            print(f"- `{path}`")
    else:
        print("- None")

    print()
    print("## Mapping Mismatches\n")
    restore_only = sorted(encrypted_paths - encrypt_paths)
    encrypt_only = sorted(encrypt_paths - encrypted_paths)
    if not restore_only and not encrypt_only:
        print("- None")
    else:
        for path in restore_only:
            print(f"- restore-only: `{path}`")
        for path in encrypt_only:
            print(f"- encrypt-only: `{path}`")

    return 0


if __name__ == "__main__":
    sys.exit(main())
