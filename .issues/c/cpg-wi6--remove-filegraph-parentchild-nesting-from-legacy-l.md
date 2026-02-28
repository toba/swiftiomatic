---
# cpg-wi6
title: Remove FileGraph parent/child nesting from legacy lint path
status: ready
type: task
created_at: 2026-02-28T18:03:18Z
updated_at: 2026-02-28T18:03:18Z
---

The `FileGraph` parent/child nesting is still used by the legacy lint path (`Configuration(configurationFiles:)`), which is still used by `Configuration+Merging.swift` for nested directory config discovery. This is part of the lint engine infrastructure that's still active.

## Context

Identified during dead-code cleanup — the FileGraph nesting logic couldn't be removed because it's wired into the configuration merging system.

## TODO

- [ ] Audit `Configuration(configurationFiles:)` and `Configuration+Merging.swift` to understand the dependency on FileGraph parent/child nesting
- [ ] Determine if nested directory config discovery can use a simpler mechanism
- [ ] Refactor or remove FileGraph nesting in favor of the replacement
- [ ] Remove any dead code exposed by the refactor
