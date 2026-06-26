# Tool Sync Workflow

Use this workflow to align globally installed developer tools with this public dotfiles repository.

## Goal

Identify drift between the current Mac and the reproducible configuration, then update the repo only for tools the user confirms should be part of the baseline.

## Sources

- Homebrew baseline: `Brewfile`
- mise baseline: `mise/.config/mise/config.toml`
- Ruby baseline: `rbenv/.rbenv/version` and `ruby/global-gems.txt`
- Read-only audit script: `codex/skills/dotfiles-tool-sync/scripts/collect_tool_diff.py`

## Workflow

1. Generate the audit report.

   ```sh
   python3 codex/skills/dotfiles-tool-sync/scripts/collect_tool_diff.py
   ```

2. Summarize the report for the user. Group findings as:

   - repo tools missing from the local machine
   - local top-level Homebrew formulas absent from `Brewfile`
   - local Homebrew casks absent from `Brewfile`
   - mise tools installed locally but absent from repo config
   - repo-configured mise tools missing locally
   - tracked Ruby global gems missing locally
   - npm, pipx, and gem global inventories that need human judgment

3. Ask which local-only tools should become part of the reproducible baseline. Do not add every local tool automatically.

4. Apply only approved changes.

   - Add Homebrew CLI tools and apps to `Brewfile`.
   - Add versioned language runtimes and toolchains to `mise/.config/mise/config.toml`.
   - Add selected global Ruby CLIs to `ruby/global-gems.txt`.
   - Leave project dependencies in their project repos, not global dotfiles.
   - Avoid adding transitive Homebrew dependencies unless the user directly uses them.

5. Validate.

   ```sh
   git diff --check
   brew bundle check --file Brewfile --no-upgrade
   ```

   If `brew bundle check` fails because of pre-existing missing or outdated tools, report that separately from the current change.

6. Commit and push only after the user has approved the repo changes.

## Guardrails

- Do not add secrets, tokens, auth files, private keys, or local recovery paths.
- Do not turn one-off experiments into baseline tools without confirmation.
- Prefer the repo's existing grouping and ordering.
