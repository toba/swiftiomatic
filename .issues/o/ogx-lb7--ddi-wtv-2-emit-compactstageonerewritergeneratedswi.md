---
# ogx-lb7
title: 'ddi-wtv-2: emit CompactStageOneRewriter+Generated.swift'
status: completed
type: task
priority: high
created_at: 2026-04-28T02:42:28Z
updated_at: 2026-04-28T02:54:54Z
parent: ddi-wtv
blocked_by:
    - q4d-ya9
sync:
    github:
        issue_number: "492"
        synced_at: "2026-04-28T02:56:07Z"
---

Extend `Sources/GeneratorKit/PipelineGenerator.swift` to emit a new generated file `CompactStageOneRewriter+Generated.swift` defining `CompactStageOneRewriter: SyntaxRewriter` with one `visit(_:)` per node type, chaining each adopting rule's static `transform(_:context:)`.

## Tasks

- [x] Added `nodeLocalTransforms` to `RuleCollector`; populated for rules with `static func transform(_:context:)`
- [x] New `CompactStageOneRewriterGenerator` (separate from `PipelineGenerator` for clarity); emits `CompactStageOneRewriter` with one `visit(_:)` per node type chaining each rule's `transform`
- [x] Wired into `Sources/Generator/main.swift` and `Plugins/GeneratePlugin/plugin.swift`
- [x] With zero adopters the generated rewriter is just an empty subclass; build green

## Summary of Changes

- `Sources/GeneratorKit/RuleCollector+DetectedRule.swift`: add `transformedNodes` field on `DetectedSyntaxRule`.
- `Sources/GeneratorKit/RuleCollector.swift`: detect `static func transform(_:context:)` overloads; populate `nodeLocalTransforms`.
- `Sources/GeneratorKit/CompactStageOneRewriterGenerator.swift`: new file generator for `CompactStageOneRewriter+Generated.swift`; emits per-node `visit(_:)` overrides that chain rule transforms in alphabetical order.
- `Sources/GeneratorKit/GeneratePaths.swift`: add `compactStageOneRewriterFile`.
- `Sources/Generator/main.swift`: invoke `CompactStageOneRewriterGenerator` after the pipeline generator.
- `Plugins/GeneratePlugin/plugin.swift`: add the new file to `outputFiles`.

The return-type table for `SyntaxRewriter.visit(_:)` (decl/expr/stmt → erased; concrete otherwise) is built into the generator so emitted overrides match upstream signatures.

## Done when

The build plugin emits the file even with zero `transform` adopters; package compiles.
