---
# 81p-a0m
title: Rules unlikely to be implemented
status: draft
type: task
priority: normal
created_at: 2026-04-14T22:41:28Z
updated_at: 2026-05-07T16:12:02Z
parent: c7r-77o
sync:
    github:
        issue_number: "312"
        synced_at: "2026-05-07T16:13:56Z"
---

Rules from the SwiftFormat port that are unlikely to be implemented due to fundamental limitations or poor cost/benefit ratio.

- `unusedPrivateDeclarations` — Requires whole-file analysis to track all references to private symbols. High false-positive risk (protocol witnesses, KVC, @objc, dynamic dispatch). The cost of a lightweight scope resolver doesn't justify the limited benefit given that Xcode and swift-lint already surface unused warnings with full type information.


- `headerFileName` — Ensure header file name matches actual file. Requires file path context that isn't available in the AST-only rule model. Low value since Xcode already warns on mismatched file names.


- `propertyTypes` — Bidirectional conversion between inferred (`let foo = Foo()`) and explicit (`let foo: Foo = .init()`) property types. Requires 3 config options and 325 lines of edge-case handling (optionals, `any`/`some`, if/switch expressions, arrays, dictionaries, sets). No performance benefit either way — purely stylistic preference. High config complexity for low value.


- `organizeDeclarations` — Organize type members by category (properties, initializers, methods, etc.). 600+ lines, the largest rule in SwiftFormat. Purely stylistic preference with no perf benefit. High complexity for opinionated ordering that varies by team.


- `markTypes` — Add `// MARK: -` comments before type declarations. 400+ lines. Purely stylistic with no perf benefit. Opinionated formatting that many teams disable. Modern IDEs already provide type navigation without MARK comments.



- `unused_imports` (SwiftLint) — Detect imports whose exported symbols are never referenced in the file. Fundamentally requires a hard-coded module-symbol catalog (SwiftLint maintains one for stdlib/Foundation/etc.) that is incomplete and wrong for third-party modules. Worse: when wrong, it produces silent link-time breakage in **downstream** modules rather than local compile errors — conformance-only modules (`RegexBuilder` providing `String: RegexComponent`), macro-only modules (`Observation`, `SwiftData`), and `@_implementationOnly` / access-level-modified imports all look unused textually but are load-bearing. Near-miss documented in `gf3-hxe` (scrapped May 2): swiftiomatic was blamed for a `public import RegexBuilder` → `import RegexBuilder` rewrite that broke linking across BibTeX/CSL/ThesisApp targets; triage found Xcode's compiler-fix-it was the actual culprit, but the analysis applies — Swiftiomatic operates per-file via swift-syntax with no dependency graph, so it cannot see downstream consumers. Surfaced again 2026-05-07 via `/cite review` (SwiftLint #6631 added access-level support); we never explicitly took a position when porting, so adding it here. If revisited, hard requirements would be: lint-only (no rewrite), opinionated allowlist of conformance/macro/regex-builder modules, honor access-level modifiers + `@_implementationOnly` from day one, and an escape-hatch directive.
