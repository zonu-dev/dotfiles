---
name: session-harness-auditor
description: Analyze explicit Codex session audits, session logs, or past-session learning and propose evidence-based Minimum Viable Harness improvements across tests, scripts, hooks, AGENTS.md, Codex skills, permissions, and workflow rules. Use only when the user explicitly asks to inspect or learn from a Codex session, session ID, or session log; do not use for general recurrence-prevention, harness, or improvement requests without session analysis.
---

# Session Harness Auditor

Use this skill to turn Codex session logs into scoped, concrete Minimum Viable Harness improvements.

## Trigger Boundary

Apply this skill only when the user explicitly requests a session audit, session-log analysis, or learning from a current or past Codex session. Do not locate recent sessions or apply this skill solely because a request mentions recurrence prevention, harnesses, guardrails, mistakes, or improvements.

## Inputs

- Prefer an explicit `session_id` or session log path from the user.
- If no `session_id` is provided, analyze the session that started this skill. First use any current session id exposed by the Codex harness or runtime metadata. If that cannot be identified directly, use `scripts/find_recent_sessions.py` to find recent candidates for the current working directory and choose the best current-session candidate; ask only if ambiguous.
- Optional scope: global, project, skill-local, repo-local, user-config, or any combination. If omitted, propose the scope per finding.

## Workflow

1. Locate the session log.
   - If the user provides a path, use it directly.
   - If the user provides a session id, run:
     ```bash
     python3 <skill>/scripts/find_recent_sessions.py --session-id <id>
     ```
   - If no id is provided, run:
     ```bash
     python3 <skill>/scripts/find_recent_sessions.py --cwd "$PWD" --limit 8
     ```
     Prefer the session that matches the active harness metadata. Otherwise pick the newest same-cwd current-session candidate when clear.

2. Summarize the log.
   ```bash
   python3 <skill>/scripts/analyze_session_jsonl.py <session-jsonl>
   ```
   Use the output as evidence, not as the final answer. Inspect relevant log excerpts when a recommendation needs confirmation.
   Avoid broad `rg` searches directly over raw JSONL session logs because single-line JSON records can produce huge truncated outputs. Do not recursively search `$HOME`, `~/.codex`, session roots, logs, or plugin caches. Enumerate likely files first, constrain directories and file types, then use the analyzer output; when excerpts are needed, use:
   ```bash
   python3 <skill>/scripts/extract_session_excerpts.py <session-jsonl> --keyword <text> --limit 20
   ```

3. Classify improvement opportunities.
   - Repeated user corrections.
   - Failed or repeated commands.
   - Review loops that used the wrong criteria.
   - Missing verification gates.
   - Tool/skill misuse.
   - Excessive ambiguity or unnecessary user prompts.
   - Workflows that should become scripts, hooks, tests, or skills.
   - Missing executable harnesses for maintenance, structure, or behavior checks.
   - Completion criteria that are not Specific, Measurable, Atomic, and Verifiable.
   - Prompt-only rules that should become deterministic checks.

4. Propose improvements before editing.
   Write the final proposal output in Japanese.
   Every proposal must include:
   - Priority: `P0`, `P1`, `P2`, or `P3`.
   - Evidence from the session.
   - Failure class.
   - Target artifact type: `AGENTS.md`, skill, hook, harness/test, settings, script, or docs.
   - Scope: `global`, `project`, `skill-local`, `repo-local`, or `user-config`.
   - Exact target path.
   - Reason the scope is appropriate.
   - The minimal intended harness or change.
   - The execution trigger for every proposed harness: repo setting, CI, required status check, hook, scheduled workflow, or mandatory AI workflow step.
   - Risk and validation method.

5. Apply changes only after explicit user approval.
   - Keep edits minimal and local to approved items.
   - Do not revert unrelated changes.
   - For new or updated skills, follow the system `skill-creator` workflow and run its validator.
   - For hooks or permission changes, prefer proposal-only unless the user explicitly asks to implement.

6. Verify and report.
   - Show changed files.
   - Run relevant validators or checks.
   - Summarize which session findings were addressed and which were left as proposals.

## Scope Selection

Read `references/improvement-rubric.md` when deciding where to place improvements.
Read `references/harness-rubric.md` when deciding whether the improvement should be a test, script, hook, skill change, or instruction change.

Use `project` when a finding is tied to a specific repository, stack, game, test command, local asset workflow, or project convention.

Use `global` when the finding applies across repositories, such as response style, generic commit hygiene, common review discipline, or reusable session analysis workflows.

Use `skill-local` for this skill's own scripts, rubrics, and references.

Use `repo-local` for executable checks inside the active repository, such as tests, smoke scripts, CI, Makefile targets, or artifact validators.

Use `user-config` for Codex settings, permissions, and hooks. Prefer proposal-only unless the user explicitly approves editing config.

When unsure, propose project-level first. Global instructions are harder to remove and can cause unrelated tasks to overfit to one session.

Prefer executable harnesses over instruction text. Consider targets in this order: existing test/lint/script command, one small repo-local smoke test, artifact validation script, precommit or CI, Codex hook or user config, then AGENTS.md or skill instructions.

Do not present manual-only checks as reliable harnesses. If a check must not be missed, propose an automatic or mandatory trigger. If the smallest viable option is still manual or AI-invoked, label it as best-effort and state what can still be missed.

## Output Format For Proposals

```markdown
## 改善提案

1. [P0|P1|P2|P3] <短いタイトル>
   - 証拠: <セッション内の根拠>
   - 失敗分類: <何が壊れた、または壊れかけたか>
   - 対象: <AGENTS.md|skill|hook|harness/test|settings|script|docs>
   - スコープ: <global|project|skill-local|repo-local|user-config>
   - パス: <絶対パス>
   - スコープ理由: <なぜこのスコープが適切か>
   - 最小ハーネス: <最小の実行可能チェックまたはルール。非ハーネス対象は「変更」と書く>
   - トリガー: <いつ実行されるか。「best-effort manual/AI-invoked」は許容できる場合だけ使う>
   - 検証: <確認方法>
   - リスク: <起こり得る問題>
```

## Resources

- `scripts/find_recent_sessions.py`: locate session logs by id, cwd, or recency.
- `scripts/analyze_session_jsonl.py`: summarize a Codex JSONL session and highlight retrospective signals.
- `scripts/extract_session_excerpts.py`: print bounded selected-field excerpts from JSONL logs.
- `references/improvement-rubric.md`: proposal categories, scope-selection rules, and approval gates.
- `references/harness-rubric.md`: MVH failure classes, target priority, and scope rules.
- `references/target-files.md`: common global/project paths for AGENTS.md, skills, hooks, and harnesses.
