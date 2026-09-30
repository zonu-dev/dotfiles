---
name: slack-mrkdwn
description: Prepare natural Slack-ready text using Slack mrkdwn. Use when drafting, reviewing, or converting messages for Slack posts, Slack manual paste, Slack drafts, channel updates, thread replies, or any outbound Slack content where formatting must render correctly and avoid AI-generated phrasing.
---

# Slack Mrkdwn

Use Slack mrkdwn, not GitHub-flavored Markdown, before finalizing Slack-ready text. Also remove generic AI-generated phrasing before returning the message.

## Checks

- Bold text: use `*text*`, not double-asterisk Markdown.
- Inline code: put ASCII spaces before and after each backtick-delimited fragment when it touches Japanese text, ASCII words, paths, or punctuation; for example, write `foo `bar` baz`, not `foo`bar`baz`.
- Links: keep the label and URL together in one inline link; do not write a label-only line followed by a bare URL on the next line. For manual Slack mrkdwn use `<https://example.com|label>`; when a Slack tool explicitly asks for standard markdown or `markdown_text`, use `[label](https://example.com)`.
- Code fences: use plain triple backticks only; do not add language tags after the opening fence.
- Tables: avoid Markdown tables; use bullets or short lines.
- Lists: prefer `-` bullets.
- Channels: keep channel names as plain text unless a real Slack channel ID is known.
- Mentions: do not add `@here`, `@channel`, user mentions, or user-group mentions unless explicitly requested and resolved.
- Manual paste: output only the Slack-ready body, with no surrounding wrapper fence.

## Anti-AI Style Pass

- Replace session-local labels like "the rtk init thing" with self-contained nouns that make sense to readers who did not see the conversation.
- Remove filler openers such as "以下が", "まとめると", and "この記事では" unless they add meaning.
- Avoid over-claiming importance with words like "重要", "画期的", "示唆", "浮き彫り", and "注目されます" when plain facts are enough.
- Remove AI transition padding such as "さらに", "加えて", "一方で", and "なお" when the order is already clear.
- Prefer direct verbs over roundabout phrases like "位置づけられます", "役割を果たします", and "〜することが可能です".
- Do not force three-part lists, parallel bullet sets, or a "conclusion" section when the content does not need one.
- Avoid stock endings like "今後の展開が注目されます" and "〜していくことが重要です".
- Avoid em dashes and long dash punctuation; use commas, parentheses, or a new sentence.
- Avoid vague sourcing like "多くの専門家" or "一般的に言われています" without a link or concrete source.
- Reduce hedging such as "かもしれません", "可能性があります", and "と思われます" unless uncertainty matters.
- Do not use mechanical bold labels in every bullet; only emphasize text when it helps scanning.
- Avoid inline-header bullets like `- Speed: ...` or `- 速度: ...` when normal prose reads better.
- Remove chatbot residue such as "もちろんです", "承知しました", "ご参考になれば幸いです", and "お気軽に".
- Avoid praise or agreement padding; state the correction or result directly.
- Add concrete friction, judgment, or context when useful; a small specific observation beats a polished generic sentence.
- Vary rhythm: mix short and medium sentences, and do not make every bullet the same shape.
- For casual Slack posts, avoid overly formal punctuation at the final punchline unless the surrounding text is formal.
- For casual Japanese Slack posts, omit Japanese full stops (`。`) at paragraph and bullet endings unless the message is intentionally formal or the punctuation prevents ambiguity.
- Before finalizing, scan the opening, headings, bullets, and final sentence for AI-ish patterns and rewrite only the suspicious parts.
