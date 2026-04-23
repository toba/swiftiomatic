---
# j1c-0x2
title: Generate TokenStreamCreator forwarding stubs
status: completed
type: task
priority: normal
created_at: 2026-04-19T17:13:08Z
updated_at: 2026-04-19T17:24:54Z
sync:
    github:
        issue_number: "345"
        synced_at: "2026-04-23T05:30:25Z"
---

Eliminate hand-maintained forwarding stubs in TokenStreamCreator by generating them.

- [x] Rename class to TokenStreamCreatorCore, delete stubs section
- [x] Create TokenStreamStubCollector (scan TSC+*.swift for visit methods)
- [x] Create TokenStreamStubGenerator (emit TokenStreamCreator+Generated.swift)
- [x] Wire up GeneratePaths and main.swift
- [x] Run generator and verify output
- [x] Build and test


## Summary of Changes

Eliminated ~200 hand-maintained forwarding stubs in TokenStreamCreator by:
- Renaming the class to `TokenStreamCreatorCore` (base)
- Generating a thin `TokenStreamCreator` subclass with override stubs via `TokenStreamStubCollector` + `TokenStreamStubGenerator`
- Moving `makeStream`/`verbatimToken` to a `TokenStreamCreator` extension (they call extension-defined helpers)
- Also fixed `LayoutDescriptor` → `LayoutRule` rename in GeneratorKit and `import SwiftOperators` in Syntax+something.swift
