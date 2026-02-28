---
# a3s-831
title: Remove compiler plugin macros
status: in-progress
type: task
created_at: 2026-02-28T01:28:58Z
updated_at: 2026-02-28T01:28:58Z
---

Replace all macro usages (@AcceptableByConfigurationElement, @DisabledWithoutSourceKit, @AutoConfigParser, @SwiftSyntaxRule) with their expanded forms, then delete macro infrastructure.

## Phases
- [ ] Phase 1: @AcceptableByConfigurationElement (18 files) — protocol extension
- [ ] Phase 2: @DisabledWithoutSourceKit (10 files) — inline expansion
- [ ] Phase 3: @AutoConfigParser (76 files) — generate apply() methods
- [ ] Phase 4: @SwiftSyntaxRule (227 files) — explicit conformances + methods
- [ ] Phase 5: Delete macro infrastructure (Package.swift, Macros.swift, Sources/Lint/Macros/)
- [ ] Phase 6: Remove unused swift-syntax products
