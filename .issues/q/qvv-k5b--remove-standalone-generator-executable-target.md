---
# qvv-k5b
title: Remove standalone Generator executable target
status: ready
type: task
created_at: 2026-04-19T17:32:03Z
updated_at: 2026-04-19T17:32:03Z
parent: rcc-z52
---

Once the build tool plugin is working, clean up the old manual generator.

- [ ] Remove or repurpose `Generator` executable target from Package.swift
- [ ] Remove `Sources/Generator/main.swift` (or keep as thin wrapper)
- [ ] Update CLAUDE.md build instructions
- [ ] Verify full build cycle: clean build, incremental build, add new rule, rename rule
