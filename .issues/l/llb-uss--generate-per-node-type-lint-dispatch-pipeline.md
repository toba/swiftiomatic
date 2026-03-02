---
# llb-uss
title: Generate per-node-type lint dispatch pipeline
status: completed
type: feature
priority: high
created_at: 2026-03-02T21:40:56Z
updated_at: 2026-03-02T22:14:06Z
parent: a2a-2wk
sync:
    github:
        issue_number: "139"
        synced_at: "2026-03-02T23:47:36Z"
---

Write a build plugin or script that generates a single-walk LintPipeline with per-node-type dispatch, matching swift-format's approach.

## Current State
- Each of ~300 lint rules creates its own `ViolationCollectingVisitor` and walks the entire syntax tree
- For a file with N nodes and R rules: O(N × R) work
- No knowledge of which rules care about which node types

## Target State
- A generator scans rule source files for `visitPost(_:)` / `visit(_:)` overrides
- Generates a `LintPipeline` that is a single `SyntaxVisitor` with `visit()`/`visitPost()` for each node type any rule handles
- Each generated method calls only the rules that handle that specific node type
- Single tree walk: O(N) with per-node dispatch to relevant rules
- CollectingRules still run their own collect pass but validate through the pipeline

## Tasks
- [x] Study swift-format's `generate-swift-format` and `RuleCollector` approach
- [x] Write generator that parses rule Swift files and extracts visitor method overrides
- [x] Generate `LintPipeline.generated.swift` with per-node-type dispatch
- [x] Add skip depth tracking for `skippableDeclarations` and `visit()` return values
- [x] Integrate as `GeneratePipeline` executable target in Package.swift
- [x] Update `Linter` to use generated pipeline instead of per-rule visitor creation
- [x] Handle `CollectingRule` two-pass: collect phase unchanged, fallback path for validate
- [ ] Benchmark before/after on a large Swift project
- [ ] Update CI to run generator and verify generated code is up-to-date

## Summary of Changes

Implemented a generated per-node-type lint dispatch pipeline that walks the syntax tree once and routes each node to only the rules that care about it, reducing linting from O(N × R) to O(N) with per-node routing.

### Components

1. **ViolationCollectingVisitorProtocol** — protocol enabling the pipeline to read violations from type-erased visitors
2. **makePipelineVisitor()** — type-erased visitor factory on SwiftSyntaxRule
3. **GeneratePipeline executable** — scans rule source files for visitor overrides and emits generated code:
   - `RuleCollector`: parses rule files, extracts visit/visitPost overrides, determines pipeline eligibility
   - `PipelineEmitter`: generates `LintPipeline.generated.swift` with per-node-type dispatch arrays
4. **LintPipeline.generated.swift** — single SyntaxVisitor with dispatch arrays routing 278 eligible rules
5. **Linter integration** — partitions rules into pipeline-eligible and fallback, single walk for pipeline rules

### Pipeline Eligibility (278 of 289 rules)

Rules are eligible if they conform to SwiftSyntaxRule and do NOT: override preprocess(), conform to CollectingRule, or require SourceKit/compiler arguments.

### Key Design Decisions

- **visit() return value handling**: uses a stack to track visitors that returned `.skipChildren`, decrementing skip depth in the corresponding visitPost()
- **skippableDeclarations**: per-visitor skip sets queried at init, managed via skip depth counters
- **Region filtering**: reuses existing Rule.filterViolations() for disable commands, superfluous disable detection, shebang handling
- **Benchmark timing**: pipeline time divided equally among pipeline rules (approximate per-rule timing)
