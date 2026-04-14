---
# zbx-pz6
title: 'Phase 8: PrettyPrinter wrapping rules'
status: ready
type: task
priority: normal
created_at: 2026-04-14T18:37:37Z
updated_at: 2026-04-14T18:37:37Z
parent: c7r-77o
sync:
    github:
        issue_number: "296"
        synced_at: "2026-04-14T18:45:53Z"
---

Wrapping rules that require PrettyPrinter enhancements rather than SyntaxFormatRule. From xuy-4wl.

- [ ] `wrapMultilineStatementBraces` — Move `{` to its own line when statement signature spans multiple lines. Requires modifying the token preceding `{` (outside the code block node), handling 10+ statement types, and coordinating with indent. Parent: xuy-4wl.
- [ ] `wrapMultilineFunctionChains` — All-or-nothing chain wrapping. 150+ lines of bidirectional chain traversal in SwiftFormat; fundamentally token-stream-based, awkward with AST nodes. Parent: xuy-4wl.
- [ ] `wrapMultilineConditionalAssignment` — Wrap after `=` for multiline if/switch expressions. Requires re-indenting the entire RHS expression (SwiftFormat pairs this with its `indent` rule). Parent: xuy-4wl.
- [ ] `wrapSingleLineComments` — Word-wrap `//` comments exceeding max line width. Column-based word splitting in comment trivia. Parent: xuy-4wl.
