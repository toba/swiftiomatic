---
# kf3-9c0
title: Break generator ↔ Swiftiomatic circular dependency
status: in-progress
type: task
created_at: 2026-04-18T02:18:33Z
updated_at: 2026-04-18T02:18:33Z
---

Replace runtime reflection with AST parsing in RuleCollector. Create SwiftiomaticCore shared target for ConfigGroup.

- [ ] Create Sources/SwiftiomaticCore/ConfigGroup.swift
- [ ] Update Sources/Swiftiomatic/API/ConfigGroup.swift to re-export
- [ ] Update Package.swift (new target, rename _GenerateSwiftiomatic → Generators)
- [ ] Copy DocumentationCommentText into Generators
- [ ] Rewrite RuleCollector.swift — remove _typeByName reflection
- [ ] Update remaining Generator imports
- [ ] Update test import
- [ ] Verify build and generated output
