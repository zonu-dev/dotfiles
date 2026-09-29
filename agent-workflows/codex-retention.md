# Codex/Claude Retention Workflow

Use this workflow when auditing or cleaning Codex, Claude Code, Claude Desktop, or related agent work areas.

## Goal

Protect session history while separating reproducible caches, temporary worktrees, and generated artifacts from long-lived project files.

## Trigger

Read this workflow only for storage cleanup, retention policy, or Codex/Claude work-area organization tasks. Do not load it for ordinary coding tasks.

## Areas

| Area | Default | Notes |
| --- | --- | --- |
| `~/.codex/sessions` | Preserve | Codex session history. Do not delete unless the user explicitly asks. |
| `~/.codex/archived_sessions` | Preserve | Archived Codex session history. |
| `~/.claude/projects` | Preserve | Claude Code project/session history. |
| `~/.codex/worktrees` | Review | Generated worktrees. Delete only after confirming no active session depends on them. |
| `~/.codex/automations` | Review | Automation definitions and work copies. Keep active automations. |
| `~/Documents/Codex` | Review | Codex app work directories. Treat as session workspace, not permanent project storage. |
| `~/.codex/generated_images` | Review | Generated image outputs. Move wanted artifacts before deleting. |
| `~/.codex/.tmp`, `~/.codex/tmp` | Delete candidate | Temporary files. Prefer deleting after Codex exits. |
| `~/.codex/conflict-calc-*` | Delete candidate | Old generated work copies unless a current session references them. |
| `~/Library/Application Support/Claude/vm_bundles` | Delete candidate | Claude Desktop VM bundle. Close Claude first; it may be recreated by local execution features. |

## Workflow

1. Measure the relevant areas.

   ```sh
   du -xhd 1 ~/.codex ~/.claude ~/Documents/Codex 2>/dev/null | sort -h
   ```

2. Check active processes before touching work directories.

   ```sh
   ps -axo pid,lstart,command | rg -i 'Codex|Claude|claude|codex'
   ```

3. Classify each candidate as `preserve`, `review`, or `delete candidate`.

4. For worktrees and work directories, inspect Git state before deletion.

   ```sh
   git -C /path/to/workdir status --short
   ```

5. Ask the user before deletion. Do not delete session history by default.

6. After cleanup, report what was removed and what remains intentionally preserved.

## Rules

- Never delete active session work directories.
- Never treat `Documents/Codex` as a source repository root unless the user explicitly made it one.
- Move durable outputs to the user's artifact/archive location before deleting session work areas.
- Prefer deleting reproducible caches and stale work copies over session history.
