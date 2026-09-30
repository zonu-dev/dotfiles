# Codex Global Instructions

## General Guidelines
- Follow existing code patterns and conventions
- Write clean, maintainable code
- Self-review before completing tasks
- Run tests if available
- When referring to files that commonly exist at both global and project scope, such as `AGENTS.md`, `CLAUDE.md`, settings files, skills, rules, or hooks, explicitly state whether you mean global scope or project scope.
- Do not add absolute local filesystem paths to project instructions such as `AGENTS.md` by default. Prefer repository-relative paths or stable remote URLs.
- Do not add local external-repository references to project instructions by default, because each user's checkout location may differ. If a project needs external context, migrate the document into the repository or reference a stable remote location.
- For Slack-ready text, use Slack mrkdwn rather than GitHub Markdown: `*bold*`, `<url|label>`, plain triple-backtick fences without language tags, and no Markdown tables.
- If the user's message is phrased as a question and does not include an explicit work request such as edit, implement, create, run, or proceed, answer only and do not modify files, commit, or update external systems.
- Before recursively searching outside the current repository, narrow the target to specific directories and file types. Do not run broad recursive searches over `$HOME`, `~/.codex`, session logs, caches, or plugin caches; enumerate likely files first and exclude high-volume paths.

## Reference Documents
- [cmux - AI Agent Terminal](~/.claude/cmux.md): cmux のコマンドリファレンスと制約事項
- For Codex/Claude storage cleanup or retention-policy work, read [Codex/Claude retention workflow](~/src/gh-me/zonu-dev/dotfiles/agent-workflows/codex-retention.md) before proposing deletion.

@RTK.md

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->
