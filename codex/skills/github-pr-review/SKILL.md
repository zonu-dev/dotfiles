---
name: github-pr-review
description: Review a GitHub pull request and choose the correct posting action, especially avoiding self-approval failures. Use when submitting or recording a GitHub PR review, approval, request-changes review, or review summary.
---

# GitHub PR Review

Use this skill before posting a GitHub PR review result.

## Workflow

1. Identify the repository and PR number.
2. Check whether the current GitHub user is the PR author.
   ```bash
   me="$(gh api user --jq .login)"
   author="$(gh pr view <pr> --json author --jq .author.login)"
   ```
3. If `me` equals `author`, do not approve the PR. Post the review result as a PR comment instead.
   ```bash
   gh pr comment <pr> --body-file <file>
   ```
4. If `me` is not the author, use the normal review action.
   ```bash
   gh pr review <pr> --approve --body-file <file>
   ```
   Use `--comment` or `--request-changes` when that matches the review result.

## Output

- State whether the review was submitted as a GitHub review or as a PR comment.
- If self-approval was avoided, mention that GitHub does not allow approving your own PR.

