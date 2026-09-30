#!/usr/bin/env python3
"""Two-line statusline with minimal dots indicator."""

import json
import re
import subprocess
import sys
import time
from pathlib import Path
from urllib.parse import quote

R = '\033[0m'
BOLD = '\033[1m'
GRAY = '\033[90m'
UNDERLINE = '\033[4m'
YELLOW = '\033[38;2;218;165;32m'  # PR link style color (goldenrod)

MODEL_ICON = '󰚩'
FOLDER_ICON = '\uf413'
UNITY_ICON = '\ue721'
RIDER_ICON = '\ue88f'
BRANCH_ICON = '\ue725'
ISSUE_ICON = '\uf41b'
OPEN_UNITY_SCRIPT = Path('~/.agent/scripts/open-unity-project.sh').expanduser()
UNITY_SEARCH_PATHS = (
    Path('unity_client/ProjectSettings/ProjectVersion.txt'),
    Path('unity_server/ProjectSettings/ProjectVersion.txt'),
    Path('ProjectSettings/ProjectVersion.txt'),
)


def run_command(args, timeout=2):
    try:
        result = subprocess.run(
            args,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except Exception:
        return None

    output = result.stdout.strip()
    return output or None


def gradient(pct):
    if pct < 50:
        r = int(pct * 5.1)
        return f'\033[38;2;{r};200;80m'

    g = int(200 - (pct - 50) * 4)
    return f'\033[38;2;255;{max(g, 0)};60m'


def dot(pct):
    if pct is None:
        return f'{GRAY}● --%{R}'

    p = round(pct)
    return f'{gradient(pct)}●{R} {BOLD}{p}%{R}'


def make_link(url, text):
    """Create OSC 8 clickable link with underline and color styling."""
    return f'\033]8;;{url}\033\\{YELLOW}{UNDERLINE}{text}{R}\033]8;;\033\\'


def file_url(path):
    return Path(path).expanduser().resolve().as_uri()


def extract_repo_path(remote):
    patterns = (
        r'git@github\.com:(.+?)(?:\.git)?$',
        r'https://github\.com/(.+?)(?:\.git)?$',
        r'ssh://git@[^/]+/(.+?)(?:\.git)?$',
        r'git@[^:]+:(.+?)(?:\.git)?$',
    )

    for pattern in patterns:
        match = re.match(pattern, remote)
        if match:
            return match.group(1)

    return None


def get_repo_url():
    """Get GitHub repository URL from git remote."""
    remote = run_command(['git', 'remote', 'get-url', 'origin'])
    if not remote:
        return None

    repo_path = extract_repo_path(remote)
    if not repo_path:
        return None

    return f'https://github.com/{repo_path}'


def find_unity_project_path(base_path):
    if not base_path:
        return None

    base_dir = Path(base_path)
    for relative_path in UNITY_SEARCH_PATHS:
        version_file = base_dir / relative_path
        if version_file.exists():
            return version_file.parent.parent

    return None


def write_if_changed(path, content, mode=None):
    if path.exists():
        try:
            if path.read_text() == content:
                if mode is not None:
                    path.chmod(mode)
                return
        except Exception:
            pass

    path.write_text(content)
    if mode is not None:
        path.chmod(mode)


def ensure_unity_launcher(project_path, project_name):
    """Create a tiny .app wrapper so clicking opens Unity without a terminal."""
    if not OPEN_UNITY_SCRIPT.exists():
        return None

    app_dir = Path('/tmp') / f'OpenUnity_{project_name}.app'
    contents_dir = app_dir / 'Contents'
    macos_dir = contents_dir / 'MacOS'
    plist_path = contents_dir / 'Info.plist'
    launcher_path = macos_dir / 'launcher'

    plist_content = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>launcher</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSUIElement</key><true/>
</dict></plist>
"""
    launcher_content = f'#!/bin/bash\n"{OPEN_UNITY_SCRIPT}" "{project_path}"\n'

    try:
        macos_dir.mkdir(parents=True, exist_ok=True)
        write_if_changed(plist_path, plist_content)
        write_if_changed(launcher_path, launcher_content, mode=0o755)
        return app_dir
    except Exception:
        return None


def ensure_rider_launcher(project_path, project_name):
    """Create a tiny .app wrapper so clicking opens Rider without a terminal."""
    app_dir = Path('/tmp') / f'OpenRider_{project_name}.app'
    contents_dir = app_dir / 'Contents'
    macos_dir = contents_dir / 'MacOS'
    plist_path = contents_dir / 'Info.plist'
    launcher_path = macos_dir / 'launcher'

    plist_content = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>launcher</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSUIElement</key><true/>
</dict></plist>
"""
    launcher_content = f'#!/bin/bash\nopen -a "Rider" "{project_path}"\n'

    try:
        macos_dir.mkdir(parents=True, exist_ok=True)
        write_if_changed(plist_path, plist_content)
        write_if_changed(launcher_path, launcher_content, mode=0o755)
        return app_dir
    except Exception:
        return None


def get_branch_name():
    branch = run_command(['git', 'branch', '--show-current'])
    if branch:
        return branch

    head = run_command(['git', 'rev-parse', '--short', 'HEAD'])
    if head:
        return f'HEAD ({head})'

    return ''


def fmt_remaining(resets_at):
    if resets_at is None:
        return ''

    secs = max(0, int(resets_at - time.time()))
    d = secs // 86400
    h = secs % 86400 // 3600
    m = secs % 3600 // 60

    if d >= 1:
        return f'{d}d'
    if h >= 1:
        return f'{h}h'
    return f'{m}m'


def build_line1(data):
    model = data.get('model', {}).get('display_name', 'Claude')
    parts = [f'{BOLD}{MODEL_ICON} {model}{R}']

    ctx_pct = data.get('context_window', {}).get('used_percentage')
    parts.append(f'ctx {dot(ctx_pct)}')

    five = data.get('rate_limits', {}).get('five_hour', {})
    five_remain = fmt_remaining(five.get('resets_at'))
    five_suffix = f' {GRAY}{five_remain}{R}' if five_remain else ''
    parts.append(f'5h {dot(five.get("used_percentage"))}{five_suffix}')

    week = data.get('rate_limits', {}).get('seven_day', {})
    week_remain = fmt_remaining(week.get('resets_at'))
    week_suffix = f' {GRAY}{week_remain}{R}' if week_remain else ''
    parts.append(f'7d {dot(week.get("used_percentage"))}{week_suffix}')

    return ' | '.join(parts)


def build_folder_part(folder_path):
    if not folder_path:
        return ''

    folder_dir = Path(folder_path)
    folder_name = folder_dir.name or str(folder_dir)
    unity_project_path = find_unity_project_path(folder_path)

    if unity_project_path:
        folder_link = make_link(file_url(folder_dir), folder_name)

        unity_launcher = ensure_unity_launcher(unity_project_path, folder_name)
        unity_target = unity_launcher or unity_project_path
        unity_link = make_link(file_url(unity_target), 'Unity')

        rider_launcher = ensure_rider_launcher(unity_project_path, folder_name)
        rider_target = rider_launcher or unity_project_path
        rider_link = make_link(file_url(rider_target), 'Rider')

        return f'{UNITY_ICON} {folder_link} {unity_link} {rider_link}'

    return f'{FOLDER_ICON} {make_link(file_url(folder_dir), folder_name)}'


def extract_issue_number(branch):
    match = re.match(r'^(?:feature|fix|bugfix|hotfix)/(\d+)-', branch)
    return match.group(1) if match else None


def build_branch_part(branch):
    if not branch:
        return ''

    repo_url = get_repo_url()
    if repo_url and not branch.startswith('HEAD'):
        branch_url = f'{repo_url}/tree/{quote(branch, safe="")}'
        result = f'{BRANCH_ICON} {make_link(branch_url, branch)}'

        issue_num = extract_issue_number(branch)
        if issue_num:
            issue_url = f'{repo_url}/issues/{issue_num}'
            result += f' | {ISSUE_ICON} {make_link(issue_url, f"#{issue_num}")}'

        return result

    return f'{BRANCH_ICON} {branch}'


def build_line2(data):
    folder_path = data.get('workspace', {}).get('current_dir', '')
    parts = [part for part in (
        build_folder_part(folder_path),
        build_branch_part(get_branch_name()),
    ) if part]
    return ' | '.join(parts)


def main():
    data = json.load(sys.stdin)
    line1 = build_line1(data)
    line2 = build_line2(data)
    print(f'{line1}\n{line2}', end='')


if __name__ == '__main__':
    main()
