---
# 5ic-5rd
title: 'Comment reflow: rewrap regular and DocC comments to fit print width'
status: completed
type: feature
priority: normal
created_at: 2026-04-26T19:16:45Z
updated_at: 2026-04-26T19:45:50Z
sync:
    github:
        issue_number: "457"
        synced_at: "2026-04-26T19:45:58Z"
---

New rule: rewrap line, block, and DocC documentation comments to fit `lineLength` (e.g. 100), reflowing prose across lines like a paragraph formatter.

## Example

Before (lineLength = 100):
```
/// Wraps any `CloudDatabase` in a concrete class so it can be stored in
/// non-generic contexts (e.g. dictionaries keyed by database scope).
/// Identity-based equality: two wrappers are equal iff they wrap the same object.
```

After:
```
/// Wraps any `CloudDatabase` in a concrete class so it can be stored in non-generic contexts (e.g.
/// dictionaries keyed by database scope). Identity-based equality: two wrappers are equal iff they
/// wrap the same object.
```

## Caveats

- **URLs must never be broken across lines.** Keep a URL on one line even if it pushes past `lineLength`. Apply the same to other unbreakable atoms (Markdown links `[text](url)`, fenced code, inline code spans `` `like this` ` should not split mid-token).
- **`- Parameters:` / `- Parameter foo:` blocks must align continuation lines under the parameter description.** Continuation indent = column where the description begins (after `- name: `).

  ```
  /// - Parameters:
  ///   - view: Name of view to create
  ///   - columns: Optionally specify columns. If not given then the columns are equal to
  ///     whatever is selected.
  ///   - sql: SQL content of the view
  ```

- Preserve other DocC structure: `- Returns:`, `- Throws:`, `- Note:`, `- Warning:`, code fences (```` ``` ````), bullet lists, numbered lists, blank `///` separator lines between paragraphs.
- Preserve leading indentation of the comment block (comment may be indented inside a type).
- Apply to `///`, `//`, `/** */`, `/* */`. Treat each contiguous comment block as one unit.
- Don't reflow inside fenced code blocks.

## Tasks

- [ ] Add rule scaffold (Layout or Rule, decide). Likely a layout rewrite since it interacts with `lineLength`.
- [ ] Tokenize comment block: split into paragraphs, lists, parameter blocks, code fences.
- [ ] Reflow prose paragraphs to fit `lineLength - prefixWidth` (where prefix = indentation + `/// `).
- [ ] Implement URL/inline-code atomicity (no break inside).
- [ ] Implement DocC parameter continuation indent.
- [ ] Tests:
  - basic single-paragraph reflow
  - multi-paragraph with blank `///` separators
  - URL longer than remaining width — keep on its own line, may exceed lineLength
  - `- Parameters:` block with wrapping descriptions
  - mixed `- Parameter foo:` standalone form
  - code fence preservation
  - indented comment inside nested type
  - `//` line comments
  - `/** */` block comments
- [ ] Opt-in vs default-on decision.
- [ ] Config: probably `lineLength` (existing) + per-rule toggle.



## Caveat: Markdown block quotes

DocC block quotes (Markdown `>` quotes) need special handling when reflowed:

- Continuation lines align with the block quote indentation.
- Blank lines inside a multi-paragraph block quote keep the `>` marker so the quote stays contiguous.

Example 1 — single-paragraph quote (lazy continuation; the wrapped line indents to the content column without a leading `>`):

Before:
```
> Note: some very long line that has to wrap
```

After:
```
> Note: some very long
  line that has to wrap
```

Example 2 — multi-paragraph quote (blank separator line keeps the `>`):

Before:
```
> Tip: another very long line
>
> second paragraph of the tip
```

After:
```
> Tip: another very long
  line
>
> second paragraph of the
  tip
```

Canonical style: continuation lines use lazy indentation (no leading `>`, aligned to the content column). Blank separator lines between paragraphs keep the `>` marker so the quote stays contiguous.



## Summary of Changes

Implemented comment reflow as opt-in rewriter rule.

**Files added:**
- \`Sources/SwiftiomaticKit/Rules/Comments/CommentReflowEngine.swift\` — pure-function engine: tokenizes prose into atoms (words + URLs + inline code + Markdown links + autolinks), parses comment bodies into Markdown-aware blocks (paragraph, list, parameter list, block quote, code fence, blank), greedy-fills each block to fit \`availableWidth\`. URLs / inline code / Markdown links never split mid-token; oversized atoms occupy their own line and overflow allowed.
- \`Sources/SwiftiomaticKit/Rules/Comments/ReflowComments.swift\` — \`RewriteSyntaxRule\<BasicRuleValue\>\` visiting \`TokenSyntax\`. Walks leading trivia, finds contiguous \`///\` and \`//\` runs, computes available width = \`lineLength - indentColumn - prefixLen - 1\`, calls engine, rebuilds trivia pieces with the comment prefix on each output line. Skips MARK / TODO / FIXME / sm:ignore / swiftlint / sourcery directives. Default: \`lint: .no\` (opt-in).
- \`Tests/SwiftiomaticTests/Rules/ReflowCommentsTests.swift\` — 18 tests (rule + engine), all passing.

**Behavior covered:**
- Multi-line \`///\` paragraph reflow (the \`CloudDatabase\` example).
- \`//\` line-comment runs.
- Idempotence (no finding when output equals input).
- URL atomicity (kept on its own line if it overflows).
- Inline code spans \`\` \`...\` \`\` and Markdown links \`[text](url)\` atomic.
- Code fences passed through verbatim.
- Block quotes — first-line gets \`> \`, continuations use lazy indent (\`  \`), blank separator lines keep \`>\`.
- Bullet/ordered list items with continuation aligned under content column.
- Comments indented inside nested types — prefix width tracks nesting.
- MARK / TODO / FIXME / sm:ignore directives left untouched.

**Status: review** — implementation done; needs human spot-check on real codebase output before setting completed. Run with:
\`\`\`
sm format --configuration <enable reflowComments>
\`\`\`

**Deferred (out of v1):**
- \`/* */\` and \`/** */\` block comments — current rule only handles \`///\` and \`//\`. The engine is reusable; rule can be extended later.
- File-level comments before \`SourceFileSyntax\` (covered incidentally if attached to first decl token, but no special handling).
- Auto-detected continuation column for \`- Parameters:\` blocks (Markdown parser treats them as a regular bullet list — works correctly because list-item continuation already uses content-column indent, but the special "parameters" detection in the engine is not yet acted on).
