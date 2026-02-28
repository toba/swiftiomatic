---
# 676-4o7
title: Remove dead notifyRuleDisabledOnce protocol requirement and implementations
status: ready
type: task
created_at: 2026-02-28T18:18:12Z
updated_at: 2026-02-28T18:18:12Z
---

The `notifyRuleDisabledOnce()` protocol requirement on `Rule` and all its implementations are now dead code after the `disableSourceKit` infrastructure was removed from `Request+SwiftLint.swift`.

The only call site was in `Linter.swift`'s `shouldRun(onFile:)` method, inside the `Request.disableSourceKit` guard that was removed.

## Locations to clean up

- `Sources/Swiftiomatic/Support/Protocols/Rule.swift:105` — protocol requirement declaration
- `Sources/Swiftiomatic/Support/Protocols/Rule.swift:168` — default empty implementation
- `Sources/Swiftiomatic/Rules/Multiline/MultilineFunctionChainsRule.swift:288`
- `Sources/Swiftiomatic/Rules/Multiline/LiteralExpressionEndIndentationRule.swift:319`
- `Sources/Swiftiomatic/Rules/Multiline/MultilineParametersBracketsRule.swift:245`
- `Sources/Swiftiomatic/Rules/Whitespace/StatementPositionRule.swift:244`
- `Sources/Swiftiomatic/Rules/Ordering/FileTypesOrderRule.swift:204`
- `Sources/Swiftiomatic/Rules/Whitespace/IndentationWidthRule.swift:232`
- `Sources/Swiftiomatic/Rules/Whitespace/VerticalWhitespaceClosingBracesRule.swift:82`
- `Sources/Swiftiomatic/Rules/Whitespace/VerticalWhitespaceOpeningBracesRule.swift:246`
- `Sources/Swiftiomatic/Rules/DeadCode/UnusedImportRule.swift:362`

## Todo

- [ ] Remove `notifyRuleDisabledOnce()` from the `Rule` protocol
- [ ] Remove the default implementation in `Rule` extension
- [ ] Remove all 8 rule-specific implementations
- [ ] Build and test
