---
# qjw-hor
title: Add AsyncEnrichableRule protocol
status: completed
type: task
priority: normal
created_at: 2026-02-28T17:05:21Z
updated_at: 2026-02-28T17:21:38Z
parent: dz8-axs
---

Add a new protocol to the Rule hierarchy for rules that can be enriched with async SourceKit type resolution after their synchronous validation pass.

```swift
protocol AsyncEnrichableRule: Rule {
    func enrichAsync(file: SwiftLintFile, typeResolver: any TypeResolver) async -> [StyleViolation]
}
```

## Steps

- [ ] Define `AsyncEnrichableRule` protocol (in `Core/Protocols/` or alongside `Rule.swift`)
- [ ] Verify it compiles with no conformers yet

## Key files
- `Sources/Swiftiomatic/Core/Protocols/` — protocol definitions
- `Sources/Swiftiomatic/SourceKitService/TypeResolver.swift` — TypeResolver protocol
