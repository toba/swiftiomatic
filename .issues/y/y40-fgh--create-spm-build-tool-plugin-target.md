---
# y40-fgh
title: Create SPM build tool plugin target
status: ready
type: task
created_at: 2026-04-19T17:32:03Z
updated_at: 2026-04-19T17:32:03Z
parent: rcc-z52
blocked_by:
    - su3-lef
    - ugx-hol
---

Add a `.plugin` target to Package.swift that runs the generator automatically before each build.

- [ ] Add `.plugin(name: "GeneratePlugin", capability: .prebuildCommand(...))` to Package.swift
- [ ] Create plugin Swift file that invokes the generator executable with paths from plugin context
- [ ] Declare input directories and output files for correct invalidation
- [ ] Apply plugin to `SwiftiomaticKit` target
- [ ] Verify generated files are produced on clean build
