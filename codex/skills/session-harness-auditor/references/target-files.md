# Target Files

Common paths for session-derived improvements.

## Global Scope

- Global Codex instructions: `~/.codex/AGENTS.md` when present.
- Global skills: `~/.codex/skills/<skill-name>/SKILL.md`.
- Global skill metadata: `~/.codex/skills/<skill-name>/agents/openai.yaml`.
- Global hooks/settings: inspect the user's Codex configuration before proposing exact paths.

Use global scope for reusable behavior across repositories.

## Project Scope

- Project instructions: `<repo>/AGENTS.md`.
- Project skills: `<repo>/.codex/skills/<skill-name>/SKILL.md`.
- Project skill metadata: `<repo>/.codex/skills/<skill-name>/agents/openai.yaml`.
- Project hooks/settings: inspect `<repo>/.codex/` or repository-specific automation files before proposing exact paths.
- Project harnesses/tests: paths depend on the stack, such as `tests/`, `scripts/`, `tools/`, `Makefile`, package scripts, or engine-specific smoke tests.

Use project scope for repository-specific commands, generated assets, game/app workflows, and local QA conventions.

## Path Rules

- Present absolute paths in proposals.
- If a target file does not exist, say whether to create it.
- Do not create or edit target files until the user approves the proposal.
