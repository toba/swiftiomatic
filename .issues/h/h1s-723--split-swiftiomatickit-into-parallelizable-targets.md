---
# h1s-723
title: Split SwiftiomaticKit into parallelizable targets
status: in-progress
type: task
priority: normal
created_at: 2026-04-30T18:28:56Z
updated_at: 2026-04-30T18:29:30Z
---

Split the monolithic `SwiftiomaticKit` target (297 files / ~52k LOC, 306 object files, ~114s cold compile) into smaller targets so SPM can parallelize compilation and incremental edits don't retype the whole module.

## Benchmark baseline (cold debug build)

| Scenario | Time |
|---|---|
| Full clean build | 148–152 s |
| SwiftiomaticKit-only rebuild (deps cached) | 114 s |
| Deps-only cold (swift-syntax + everything else) | ~36 s |

SwiftiomaticKit is ~75% of clean-build wall time. swift-syntax is not the bottleneck.

## Target shape

```
ConfigurationKit  (already separate)
       v
SmCore        Configuration/, Findings/, Extensions/, Support/   (~4.4k LOC)
       v
SmLayout      Layout/                                            (~7.8k LOC)
       v
SmSyntax      Syntax/  (rule base classes, pipelines, rewriter)  (~4.1k LOC)
       v
SmRules       Rules/   (all 219 rule files)                      (~31k LOC)
       v
SwiftiomaticKit  (umbrella) — Generated/, public facade, hosts
                  GenerateCode build plugin                       (~5k LOC)
```

Public API of `SwiftiomaticKit` stays identical so `Swiftiomatic` exec and tests don't need import changes (umbrella re-exports).

## Why

- Layout/Syntax/Rules currently rebuild together on any rule edit. After split, a rule edit only retypes SmRules.
- SmLayout and parts of SmSyntax share no symbols with most rules, so SPM compiles them in parallel with SmRules.
- Rules stays the biggest target — future follow-up could subdivide by category, but not in this issue.

## Steps

- [ ] **Step 1: Inventory cross-references.** Grep Layout/Syntax/Rules for symbol usage; produce a list of types/funcs that must become `public` and any accidental couplings (e.g. a rule reaching into a Layout internal).
- [ ] **Step 2: Carve out `SmCore`.** Configuration/, Findings/, Extensions/, Support/. No internal deps on other groups. Land + verify build + tests pass before next step.
- [ ] **Step 3: Carve out `SmLayout`.** Depends on SmCore. Land separately.
- [ ] **Step 4: Carve out `SmSyntax`.** Houses SyntaxRule, LintSyntaxRule, StaticFormatRule, StructuralFormatRule, CompactSyntaxRewriter, LintPipeline base type. Generated dispatcher files (`Pipelines+Generated.swift`, `TokenStream+Generated.swift`) stay in umbrella because they reference SmRules / SmLayout symbols.
- [ ] **Step 5: Carve out `SmRules`.** 219 files move. Expect heavy `internal` -> `public` audit on Context, Configuration accessors, Layout/Syntax helpers.
- [ ] **Step 6: Reduce `SwiftiomaticKit` to umbrella.** Re-exports + Generated/ only. Build plugin (`GenerateCode`) stays attached here. Self-host lint plugin (`SwiftiomaticBuildToolPlugin`) stays on umbrella + Swiftiomatic exec only — don't attach to sub-targets (avoids 5x lint passes).
- [ ] **Step 7: Re-benchmark.** Cold build after split. Target: under ~110 s (saving ~40 s via parallelism).

## Validation per step

- `xc-swift build_swift_package` cold; record wall time.
- Full test suite passes between every step. Each split lands green or doesn't land.

## Risks / gotchas

- **Generated code coupling** — `Pipelines+Generated.swift` references rule types; `TokenStream+Generated.swift` references Layout types; `ConfigurationRegistry+Generated.swift` references all rule types. Keep all generated files in umbrella to sidestep cross-target visibility issues.
- **`internal` -> `public` audit** in step 5 is tedious; no automated path, visibility errors guide it.
- **Build plugins**: `GenerateCode` only on umbrella; `swiftiomatic-plugins` self-host lint only on umbrella + Swiftiomatic exec.

## Out of scope

- Splitting SmRules by category (premature; do after four-way split proves out).
- Binary target for swift-syntax (~20 s win, toolchain-version brittleness, defer).
- Touching Generator / GeneratorKit (already separate, already fast).

## Estimate

~1 day focused work. Step 5 is ~60% of effort.
