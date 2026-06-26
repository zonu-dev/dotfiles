#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tomllib
from collections.abc import Iterable
from pathlib import Path


DEFAULT_REPO = Path(__file__).resolve().parents[4]
NPM_RUNTIME_PACKAGES = {"corepack", "npm"}


def run(args: list[str], cwd: Path | None = None, env: dict[str, str] | None = None) -> tuple[int, str, str]:
    proc = subprocess.run(
        args,
        cwd=str(cwd) if cwd else None,
        env={**os.environ, **env} if env else None,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def lines_from(cmd: list[str], env: dict[str, str] | None = None) -> list[str]:
    code, out, _ = run(cmd, env=env)
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


def parse_package_versions(path: Path) -> dict[str, str]:
    packages: dict[str, str] = {}
    if not path.exists():
        return packages
    for line in path.read_text().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        parts = stripped.split()
        if len(parts) >= 2:
            packages[parts[0]] = parts[1]
    return packages


def read_single_line(path: Path) -> str | None:
    if not path.exists():
        return None
    value = path.read_text().strip()
    return value or None


def mise_installed_entries() -> dict[str, list[dict[str, object]]]:
    code, out, _ = run(["mise", "ls", "--installed", "--json"])
    if code != 0 or not out:
        return {}
    try:
        data = json.loads(out)
    except json.JSONDecodeError:
        return {}
    result: dict[str, list[dict[str, object]]] = {}
    for name, entries in data.items():
        tool_entries: list[dict[str, object]] = []
        if isinstance(entries, list):
            for entry in entries:
                version = entry.get("version") if isinstance(entry, dict) else None
                if version:
                    tool_entries.append(
                        {
                            "version": str(version),
                            "active": bool(entry.get("active")) if isinstance(entry, dict) else False,
                        }
                    )
        if tool_entries:
            result[name] = sorted(tool_entries, key=lambda item: str(item["version"]))
    return result


def mise_versions(entries: dict[str, list[dict[str, object]]]) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    for name, tool_entries in entries.items():
        result[name] = sorted({str(entry["version"]) for entry in tool_entries})
    return result


def npm_global_versions() -> dict[str, str]:
    code, out, _ = run(["zsh", "-lic", "npm list -g --depth=0 --json"])
    if code != 0 or not out:
        code, out, _ = run(["npm", "list", "-g", "--depth=0", "--json"])
    if code != 0 or not out:
        return {}
    try:
        data = json.loads(out)
    except json.JSONDecodeError:
        return {}
    deps = data.get("dependencies", {})
    result: dict[str, str] = {}
    for name, meta in deps.items():
        version = meta.get("version") if isinstance(meta, dict) else None
        result[name] = str(version) if version else ""
    return result


def pipx_global_versions() -> dict[str, str]:
    code, out, _ = run(["pipx", "list", "--json"])
    if code != 0 or not out:
        return {}
    try:
        data = json.loads(out)
    except json.JSONDecodeError:
        return {}
    venvs = data.get("venvs", {})
    result: dict[str, str] = {}
    for name, meta in venvs.items():
        package = meta.get("metadata", {}).get("main_package", {}) if isinstance(meta, dict) else {}
        version = package.get("package_version") if isinstance(package, dict) else None
        result[name] = str(version) if version else ""
    return result


def package_rows(packages: dict[str, str]) -> list[str]:
    return [f"{name}@{version}" if version else name for name, version in sorted(packages.items())]


def missing_tracked_packages(tracked: dict[str, str], installed: dict[str, str]) -> list[str]:
    missing = []
    for name, version in sorted(tracked.items()):
        installed_version = installed.get(name)
        if installed_version != version:
            missing.append(f"{name}@{version} (installed: {installed_version or 'none'})")
    return missing


def untracked_packages(installed: dict[str, str], tracked: dict[str, str], ignore: Iterable[str] = ()) -> list[str]:
    ignored = set(ignore)
    return [
        f"{name}@{version}" if version else name
        for name, version in sorted(installed.items())
        if name not in tracked and name not in ignored
    ]


def gem_list_lines(ruby_version: str | None) -> list[str]:
    if ruby_version and run(["rbenv", "--version"])[0] == 0:
        return lines_from(["rbenv", "exec", "gem", "list", "--local"], env={"RBENV_VERSION": ruby_version})
    return lines_from(["gem", "list", "--local"])


def gem_globals(ruby_version: str | None) -> list[str]:
    output = gem_list_lines(ruby_version)
    result = []
    for line in output:
        match = re.match(r"^(\S+)\s+\(([^)]+)\)", line)
        if match:
            result.append(f"{match.group(1)} {match.group(2)}")
    return sorted(result)


def gem_versions(ruby_version: str | None) -> dict[str, list[str]]:
    versions: dict[str, list[str]] = {}
    for line in gem_list_lines(ruby_version):
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
    ruby_version_file = repo / "rbenv/.rbenv/version"
    global_gems_file = repo / "ruby/global-gems.txt"
    npm_packages_file = repo / "npm/global-packages.txt"
    pipx_packages_file = repo / "pipx/global-packages.txt"

    repo_formulas, repo_casks = parse_brewfile(brewfile)
    repo_mise = parse_mise_config(mise_config)
    ruby_version = read_single_line(ruby_version_file)
    repo_gems = parse_global_gems(global_gems_file)
    repo_npm = parse_package_versions(npm_packages_file)
    repo_pipx = parse_package_versions(pipx_packages_file)

    brew_all = set(lines_from(["brew", "list", "--formula", "-1"]))
    brew_top = set(lines_from(["brew", "leaves", "--installed-on-request"]))
    if not brew_top:
        brew_top = brew_all
    casks = set(lines_from(["brew", "list", "--cask", "-1"]))

    installed_mise_entries = mise_installed_entries()
    installed_mise = mise_versions(installed_mise_entries)
    npm_installed = npm_global_versions()
    pipx_installed = pipx_global_versions()

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

    mise_untracked_active = []
    mise_untracked_inactive = []
    for name, entries in sorted(installed_mise_entries.items()):
        if name in repo_mise:
            continue
        for entry in entries:
            row = f"{name}@{entry['version']}"
            if entry["active"]:
                mise_untracked_active.append(row)
            else:
                mise_untracked_inactive.append(row)

    section("mise tools configured in repo but missing locally", mise_missing)
    section("mise active installed tools absent from repo config", mise_untracked_active)
    section("mise inactive installed tools absent from repo config", mise_untracked_inactive)

    installed_gems = gem_versions(ruby_version)
    missing_gems = []
    for name, version in sorted(repo_gems.items()):
        if version not in installed_gems.get(name, []):
            installed = ", ".join(installed_gems.get(name, [])) or "none"
            missing_gems.append(f"{name} {version} (installed: {installed})")

    section("Tracked Ruby global gems missing locally", missing_gems)
    section("Tracked npm global packages missing locally", missing_tracked_packages(repo_npm, npm_installed))
    section("npm global packages absent from repo baseline", untracked_packages(npm_installed, repo_npm, NPM_RUNTIME_PACKAGES))
    section("npm runtime packages inventory", package_rows({name: version for name, version in npm_installed.items() if name in NPM_RUNTIME_PACKAGES}))
    section("Tracked pipx packages missing locally", missing_tracked_packages(repo_pipx, pipx_installed))
    section("pipx packages absent from repo baseline", untracked_packages(pipx_installed, repo_pipx))
    section("gem local packages inventory", gem_globals(ruby_version))

    return 0


if __name__ == "__main__":
    sys.exit(main())
