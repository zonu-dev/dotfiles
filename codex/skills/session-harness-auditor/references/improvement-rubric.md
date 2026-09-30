# Improvement Rubric

Use this rubric to convert session evidence into durable improvements without overfitting to one bad turn.

## Evidence Strength

- Strong: repeated user corrections, repeated failed commands, explicit user frustration, multiple review loops failing for the same reason, or a final instruction that supersedes earlier workflow assumptions.
- Medium: one costly mistake with clear prevention value, one missed validation gate, or one tool misuse that is likely to recur.
- Weak: one-off preference, exploratory dead end, temporary environment issue, or a failure caused by missing user-provided data.

Prefer implementing strong evidence. For medium evidence, propose before implementing. For weak evidence, record as a note unless the user asks to encode it.

## Priority Scale

- `P0`: Stop immediately. Data loss, secret leakage, destructive operations, direct main-branch accidents, or violation of an explicit user prohibition.
- `P1`: Prevent before the next similar task. Strong user correction, rework already caused in the session, or a project workflow rule was violated.
- `P2`: Fix soon. Review-found inconsistency, avoidable command failure, missing re-check, or likely recurring verification gap with limited blast radius.
- `P3`: Optional improvement. Convenience, future efficiency, or weak one-off signal without clear recurrence.

Default decision rule:

- Strong evidence usually maps to `P1`, or `P0` if safety/data/security is involved.
- Medium evidence usually maps to `P2`.
- Weak evidence usually maps to `P3` or a note, unless the user explicitly asks to encode it.

## Target Artifact Choice

- `AGENTS.md`: repository or global behavior rules, verification commands, response conventions, and project-specific guardrails.
- Skill: reusable multi-step workflow, repeated tool choreography, review loop design, image generation process, release flow, or domain-specific procedure.
- Hook: deterministic preflight/postflight automation that should always run and has low false-positive risk.
- Harness/test: project-specific checks, smoke tests, screenshot capture, fixture validation, or artifact integrity checks.
- Script: repeatable parsing, reporting, artifact validation, or command wrappers.
- Settings/permissions: only when the session shows repeated permission or tool access friction and the change is safe.

Prefer harness/test or script when the finding can be checked mechanically. Use AGENTS.md or skill text when the finding is a human workflow rule, scope decision, or tool choreography that cannot be reliably enforced.

## Scope Selection

Use project-level when:

- The improvement mentions repository paths, stack-specific commands, Godot/Unity/web build details, generated assets, local QA screenshots, or project docs.
- The rule would be confusing or harmful in unrelated repositories.
- The issue came from project-specific user preferences.

Use global-level when:

- The improvement applies to nearly every Codex session.
- It is about generic review discipline, commit hygiene, safe file editing, or session analysis.
- It should be available across repositories as a reusable skill.

If both scopes could work, propose:

- Project-level immediate guardrail.
- Global skill or reference only if the pattern has appeared in multiple repositories or is clearly reusable.

Use skill-local when changing this skill's own rubrics, scripts, references, or metadata.

Use repo-local when adding executable checks in the active repository, including tests, smoke scripts, CI wiring, package scripts, or artifact validators.

Use user-config when the target is Codex settings, permissions, or hooks. Prefer proposal-only unless the user explicitly approves editing config.

## Approval Gates

Always ask before:

- Editing global AGENTS.md.
- Creating or modifying global skills.
- Adding hooks.
- Changing permissions/settings.
- Encoding subjective user preferences as global behavior.

Project-level AGENTS.md, tests, and scripts may still require approval unless the user explicitly requested implementation.

## Proposal Quality Checklist

Each proposal should include:

- Priority: `P0`, `P1`, `P2`, or `P3`.
- Concrete evidence from the log.
- Scope and path.
- Why that scope is appropriate.
- Minimal change.
- Execution trigger for proposed harnesses.
- Validation command or manual check.
- Risk of overfitting.
