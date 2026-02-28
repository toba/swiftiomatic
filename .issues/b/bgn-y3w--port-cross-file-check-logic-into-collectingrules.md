---
# bgn-y3w
title: Port cross-file Check logic into CollectingRules
status: completed
type: task
priority: normal
created_at: 2026-02-28T17:05:56Z
updated_at: 2026-02-28T17:25:11Z
parent: dz8-axs
---

Two cross-file Checks use custom two-pass architecture. Port their superior logic into the existing CollectingRule implementations.

## DeadSymbolsRule

The Check's `SymbolTable` + `DeclarationCollector` + USR-based matching is strictly superior to the Rule's simpler name-only matching.

- [ ] Port `SymbolTable` and `DeclarationCollector` from `DeadSymbolsCheck` into `DeadSymbolsRule`
- [ ] Add USR-based matching to the Rule's collect/validate phases
- [ ] Delete `Rules/Suggest/DeadSymbolsCheck.swift`

## StructuralDuplicationRule

Already mirrors the Check's logic closely via `FingerprintCollector`.

- [ ] Verify Rule produces equivalent results to Check
- [ ] Delete `Rules/Suggest/StructuralDuplicationCheck.swift`

## Key files
- `Rules/Suggest/DeadSymbolsCheck.swift` — source (SymbolTable, DeclarationCollector, USR matching)
- `Rules/Suggest/DeadSymbolsRule.swift` — target
- `Rules/Suggest/StructuralDuplicationCheck.swift` — source
- `Rules/Suggest/StructuralDuplicationRule.swift` — target
