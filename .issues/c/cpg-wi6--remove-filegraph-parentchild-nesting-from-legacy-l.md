---
# cpg-wi6
title: Remove FileGraph parent/child nesting from legacy lint path
status: completed
type: task
priority: normal
created_at: 2026-02-28T18:03:18Z
updated_at: 2026-02-28T19:58:42Z
---

The `FileGraph` parent/child nesting is still used by the legacy lint path (`Configuration(configurationFiles:)`), which is still used by `Configuration+Merging.swift` for nested directory config discovery. This is part of the lint engine infrastructure that's still active.

## Context

Identified during dead-code cleanup — the FileGraph nesting logic couldn't be removed because it's wired into the configuration merging system.

## TODO

- [x] Audit `Configuration(configurationFiles:)` and `Configuration+Merging.swift` to understand the dependency on FileGraph parent/child nesting
- [x] Determine if nested directory config discovery can use a simpler mechanism
- [x] Refactor or remove FileGraph nesting in favor of the replacement
- [x] Remove any dead code exposed by the refactor

## Summary of Changes

Replaced the complex FileGraph graph data structure (Vertex/Edge/EdgeType with cycle detection, DFS validation, parent/child config chain discovery) with a simple struct holding `rootDirectory` and `loadedConfigFiles: Set<String>`.

**Files changed:**
- `Configuration+FileGraph.swift` — rewrote from ~280 lines of graph logic to ~90 lines with a simple struct and a static `resultingConfiguration` method that merges configs left-to-right
- `Configuration+FileGraphSubtypes.swift` — deleted (Vertex, FilePath, Edge, EdgeType no longer needed)
- `Configuration.swift` — removed `ignoreParentAndChildConfigs` parameter from `Configuration(configurationFiles:)`, updated to call new static API
- `Configuration+Merging.swift` — removed `ignoreParentAndChildConfigs: true` from nested config creation
- `Configuration+Parsing.swift` — removed `Key.childConfig` and `Key.parentConfig` enum cases

**What was removed:**
- `parent_config` / `child_config` YAML key support (legacy SwiftLint feature for chaining config files via in-file references)
- Graph traversal with cycle detection and ambiguity validation
- `Vertex` class, `Edge` struct, `EdgeType` enum, `FilePath` enum

**What was preserved:**
- `includesFile(atPath:)` — now backed by a simple `Set<String>` lookup instead of iterating vertices
- Multiple `--config` file support — configs are still merged left-to-right
- Nested directory config discovery in `Configuration+Merging.swift` — unchanged, still checks `fileGraph.includesFile`
