#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tomllib
from pathlib import Path


DEFAULT_REPO = Path(__file__).resolve().parents[4]


def run(args: list[str], cwd: Path | None = None) -> tuple[int, str, str]:
    proc = subprocess.run(
        args,
        cwd=str(cwd) if cwd else None,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def lines_from(cmd: list[str]) -> list[str]:
    code, out, _ = run(cmd)
    if code != 0 or not out:
        return []
    return [line.strip() for line in out.splitlines() if line.strip()]


def parse_brewfile(path: Path) -> tuple[set[str], set[str]]:
    formulas: set[str] = set()
    casks: set[str] = set()
    if not path.exists():
        return formulas, casks

    brew_re = re.compile(r'^\s*brew\s+["\']([^"\']+)["\']')
    cask_re = re.compile(r'^\s*cask\s+["\']([^"\']+)["\']')
    for line in path.read_text().splitlines():
        if match := brew_re.match(line):
            formulas.add(match.group(1))
        elif match := cask_re.match(line):
            casks.add(match.group(1))
    return formulas, casks


def parse_mise_config(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    with path.open("rb") as f:
        data = tomllib.load(f)
    tools = data.get("tools", {})
    result: dict[str, str] = {}
    for name, value in tools.items():
        if isinstance(value, str):
            result[name] = value
        elif isinstance(value, list):
            result[name] = ", ".join(str(item) for item in value)
        else:
            result[name] = str(value)
    return result


def parse_global_gems(path: Path) -> dict[str, str]:
    gems: dict[str, str] = {}
    if not path.exists():
        return gems
    for line in path.read_text().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        parts = stripped.split()
        if len(parts) >= 2:
            gems[parts[0]] = parts[1]
    return gems


def mise_installed() -> dict[str, list[str]]:
    code, out, _ = run(["mise", "ls", "--installed", "--json"])
    if code != 0 or not out:
        return {}
    try:
        data = json.loads(out)
    except json.JSONDecodeError:
        return {}
    result: dict[str, list[str]] = {}
    for name, entries in data.items():
        versions: list[str] = []
        if isinstance(entries, list):
            for entry in entries:
                version = entry.get("version") if isinstance(entry, dict) else None
                if version:
                    versions.append(str(version))
        if versions:
            result[name] = sorted(set(versions))
    return result


def npm_globals() -> list[str]:
    code, out, _ = run(["zsh", "-lic", "npm list -g --depth=0 --json"])
    if code != 0 or not out:
        code, out, _ = run(["npm", "list", "-g", "--depth=0", "--json"])
    if code != 0 or not out:
        return []
    try:
        data = json.loads(out)
    except json.JSONDecodeError:
        return []
    deps = data.get("dependencies", {})
    result = []
    for name, meta in deps.items():
        version = meta.get("version") if isinstance(meta, dict) else None
        result.append(f"{name}@{version}" if version else name)
    return sorted(result)


def pipx_globals() -> list[str]:
    code, out, _ = run(["pipx", "list", "--json"])
    if code != 0 or not out:
        return []
    try:
        data = json.loads(out)
    except json.JSONDecodeError:
        return []
    venvs = data.get("venvs", {})
    result = []
    for name, meta in venvs.items():
        package = meta.get("metadata", {}).get("main_package", {}) if isinstance(meta, dict) else {}
        version = package.get("package_version") if isinstance(package, dict) else None
        result.append(f"{name}@{version}" if version else name)
    return sorted(result)


def gem_globals() -> list[str]:
    output = lines_from(["gem", "list", "--local"])
    result = []
    for line in output:
        match = re.match(r"^(\S+)\s+\(([^)]+)\)", line)
        if match:
            result.append(f"{match.group(1)} {match.group(2)}")
    return sorted(result)


def gem_versions() -> dict[str, list[str]]:
    versions: dict[str, list[str]] = {}
    for line in lines_from(["gem", "list", "--local"]):
        match = re.match(r"^(\S+)\s+\(([^)]+)\)", line)
        if not match:
            continue
        name = match.group(1)
        raw_versions = match.group(2)
        parsed = []
        for value in raw_versions.split(","):
            version = value.strip().replace("default: ", "")
            if version:
                parsed.append(version)
        versions[name] = parsed
    return versions


def section(title: str, rows: list[str]) -> None:
    print(f"## {title}\n")
    if rows:
        for row in rows:
            print(f"- {row}")
    else:
        print("- None")
    print()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dotfiles-repo", default=os.environ.get("DOTFILES_REPO", str(DEFAULT_REPO)))
    args = parser.parse_args()

    repo = Path(args.dotfiles_repo).expanduser()
    brewfile = repo / "Brewfile"
    mise_config = repo / "mise/.config/mise/config.toml"
    global_gems_file = repo / "ruby/global-gems.txt"

    repo_formulas, repo_casks = parse_brewfile(brewfile)
    repo_mise = parse_mise_config(mise_config)
    repo_gems = parse_global_gems(global_gems_file)

    brew_all = set(lines_from(["brew", "list", "--formula", "-1"]))
    brew_top = set(lines_from(["brew", "leaves", "--installed-on-request"]))
    if not brew_top:
        brew_top = brew_all
    casks = set(lines_from(["brew", "list", "--cask", "-1"]))

    installed_mise = mise_installed()
    installed_mise_pairs = {f"{name}@{version}" for name, versions in installed_mise.items() for version in versions}

    print(f"# Tool Sync Report\n")
    print(f"- Dotfiles repo: `{repo}`")
    print(f"- Brewfile: `{brewfile}`")
    print(f"- mise config: `{mise_config}`\n")

    repo_formula_names = {formula.split("/")[-1] for formula in repo_formulas}
    missing_formulas = sorted(formula for formula in repo_formulas if formula.split("/")[-1] not in brew_all)
    untracked_top_formulas = sorted(formula for formula in brew_top if formula.split("/")[-1] not in repo_formula_names)

    section("Brewfile formulas missing from Homebrew", missing_formulas)
    section("Top-level Homebrew formulas absent from Brewfile", untracked_top_formulas)
    section("Brewfile casks missing locally", sorted(repo_casks - casks))
    section("Installed Homebrew casks absent from Brewfile", sorted(casks - repo_casks))

    mise_missing = []
    for name, version in sorted(repo_mise.items()):
        installed_versions = installed_mise.get(name, [])
        if version not in installed_versions:
            mise_missing.append(f"{name}@{version} (installed: {', '.join(installed_versions) or 'none'})")

    mise_untracked = []
    for pair in sorted(installed_mise_pairs):
        name, version = pair.rsplit("@", 1)
        if name not in repo_mise:
            mise_untracked.append(f"{name}@{version}")

    section("mise tools configured in repo but missing locally", mise_missing)
    section("mise installed tools absent from repo config", mise_untracked)

    installed_gems = gem_versions()
    missing_gems = []
    for name, version in sorted(repo_gems.items()):
        if version not in installed_gems.get(name, []):
            installed = ", ".join(installed_gems.get(name, [])) or "none"
            missing_gems.append(f"{name} {version} (installed: {installed})")

    section("Tracked Ruby global gems missing locally", missing_gems)
    section("npm global packages inventory", npm_globals())
    section("pipx global packages inventory", pipx_globals())
    section("gem local packages inventory", gem_globals())

    return 0


if __name__ == "__main__":
    sys.exit(main())
