# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

## Meta Commands (always use rtk directly)

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk discover          # Analyze Claude Code history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```

## Installation Verification

```bash
rtk --version         # Should show: rtk X.Y.Z
rtk gain              # Should work (not "command not found")
which rtk             # Verify correct binary
```

⚠️ **Name collision**: If `rtk gain` fails, you may have reachingforthejack/rtk (Rust Type Kit) installed instead.

## Hook-Based Usage

All other commands are automatically rewritten by the Claude Code hook.
Example: `git status` → `rtk git status` (transparent, 0 tokens overhead)

Refer to CLAUDE.md for full command reference.

## Accuracy Guardrails

RTK output is optimized for context size, not for authoritative file metadata.
Do not infer that a file is empty from compact `rtk ls` output alone.
When exact size, ownership, permissions, timestamps, or file contents matter:

- Use `stat` for exact metadata.
- Use `Read` for exact file contents.
- Use `/bin/ls` or `RTK_DISABLED=1 ls` when raw `ls` formatting itself matters.
