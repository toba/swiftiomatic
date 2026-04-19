---
# ugx-hol
title: Refactor GeneratePaths to accept injected base paths
status: ready
type: task
created_at: 2026-04-19T17:31:45Z
updated_at: 2026-04-19T17:31:45Z
parent: rcc-z52
---

`GeneratePaths.swift` uses `#filePath` to locate the source tree. Plugins receive paths via the plugin context API (`context.package.directory`, target source directories). Refactor to accept injected paths.

- [ ] Add initializer/factory that takes a package root URL
- [ ] Derive all input/output paths from the injected root
- [ ] Keep `#filePath`-based paths as convenience for the standalone executable during migration
- [ ] Verify Generator executable still works with refactored paths
