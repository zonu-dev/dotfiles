# Harness Rubric

Use this rubric to convert session failures into the smallest durable harness that would have caught or shortened the failure.

## Failure Classes

- Prompt-only rule: the session relied on instructions that a deterministic check could enforce.
- Missing reproducible command: the agent could not name or run one command that verifies the change.
- Missing smoke test: a user-facing behavior, launch path, CLI path, or artifact had no minimal executable check.
- Missing artifact validation: screenshots, generated files, APKs, PDFs, docs, or JSON outputs were not machine-checked.
- Repeated command failure: the agent reran failing commands without a preflight, wrapper, or clearer error.
- Structure drift: files, names, templates, imports, or project layout moved away from project conventions.
- State loss: handoff, resume, or context compaction lost task state that should be stored in git, JSON, issue comments, or docs.
- Non-SMAV completion: done criteria were not Specific, Measurable, Atomic, and Verifiable.

## Target Priority

Prefer the first target that can solve the observed failure.

1. Existing test, lint, typecheck, formatter, script, or build command.
2. One small repo-local smoke test or check script.
3. Artifact validator for generated output.
4. Precommit, CI, Makefile, or package script wiring.
5. Codex hook or user config.
6. AGENTS.md, skill, docs, or checklist text.

Do not propose a new framework when a shell command, existing test runner, or existing dependency is enough.

## Scope Rules

- `global`: reusable across repositories, such as a global skill or general Codex behavior.
- `project`: repository-specific instructions or policy, especially project scope `AGENTS.md`.
- `skill-local`: files inside the skill, such as rubrics, scripts, references, or metadata.
- `repo-local`: executable checks in the active repo, such as tests, scripts, CI, or Makefile targets.
- `user-config`: Codex settings, permissions, and hooks. Treat as proposal-only unless approved.

Prefer `repo-local` for stack-specific checks. Prefer `project` for human workflow policy. Prefer `skill-local` when improving this auditor.

Manual-only checks are not reliable harnesses for must-not-miss failures. For those, prefer repo settings, CI, required status checks, hooks, scheduled workflows, or mandatory AI workflow steps. Only propose manual or AI-invoked checks when best-effort coverage is acceptable, and say so explicitly.

