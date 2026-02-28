---
# l02-83z
title: Unify rule definitions under Sources/Swiftiomatic/Rules/
status: completed
type: feature
priority: normal
created_at: 2026-02-28T02:44:32Z
updated_at: 2026-02-28T17:59:56Z
---

Move all rule definitions into Rules/, create unified Diagnostic output type, enhance RuleCatalog, wire commands to Diagnostic output.

## Tasks
- [x] Phase 1: Create Diagnostic type and adapters
- [x] Phase 2: Move suggest check files into Rules/Suggest/
- [x] Phase 3: Move format rule files into Rules/Format/
- [x] Phase 4: Enhance RuleCatalog
- [x] Phase 5: Wire commands to Diagnostic output
- [x] Verify: build, test, all commands work

## Summary of Changes

Unified all rule definitions under Sources/Swiftiomatic/Rules/. Created Diagnostic type (Support/Models/Diagnostic.swift) as the unified output across all engines. Enhanced RuleCatalog as a unified facade querying suggest, lint, and format registries. Format rules moved to Rules/Format/ (138 files). Suggest rules landed in themed directories (AccessControl, Modernization, Frameworks, etc.) instead of Rules/Suggest/ — superseded by the 13-themed-directory rebalance (2ys-iip). Old Check abstraction files deleted.
