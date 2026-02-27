---
# 797-849
title: Create bridge layer and lint subcommand
status: scrapped
type: task
priority: normal
created_at: 2026-02-27T22:59:25Z
updated_at: 2026-02-27T23:33:06Z
parent: 5nn-red
blocked_by:
    - bpt-2qz
---

Bridge SwiftLint violations into Swiftiomatic's Finding model and add CLI subcommand.

- [ ] Create Bridge/LintBridge.swift: StyleViolation → Finding mapping
- [ ] Map SwiftLint severity (.warning/.error) → Swiftiomatic Severity
- [ ] Add lint Category or subcategories
- [ ] Create LintCommand.swift with path, format, rule enable/disable options
- [ ] Register Lint.self in swiftiomatic.swift subcommands
- [ ] Extend .swiftiomatic.yaml config with lint section
- [ ] swiftiomatic lint Sources/ produces findings
