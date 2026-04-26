---
# j5a-lnn
title: '@DeclVisitor macro: infrastructure + Pattern A prototype'
status: scrapped
type: task
priority: high
created_at: 2026-04-26T17:48:11Z
updated_at: 2026-04-26T19:06:24Z
parent: lhe-lqu
sync:
    github:
        issue_number: "453"
        synced_at: "2026-04-26T19:46:00Z"
---

Phase 1 of `lhe-lqu`. Land the macro infrastructure end-to-end on a single rule before scaling.

## Scope

- New SPM targets in root `Package.swift`:
  - `.macro(name: "SwiftiomaticMacroPlugin")` depending on `SwiftSyntax`, `SwiftSyntaxMacros`, `SwiftDiagnostics`, `SwiftCompilerPlugin`. Pin swift-syntax to a single major matching the toolchain (e.g. `600.0.0..<604.0.0`).
  - `.target(name: "SwiftiomaticMacros")` — thin re-export library exposing the macro declarations via `#externalMacro`.
  - `.testTarget(name: "SwiftiomaticMacroTests")` depending on `SwiftiomaticMacroPlugin` + `MacroTesting`.
  - Add `SwiftiomaticMacros` as a dep of `SwiftiomaticKit`.
- Plugin entry point `Plugin.swift` mirroring Thesis (`/Users/jason/Developer/toba/thesis/Core/Macros/Sources/ThesisMacroPlugin/Plugin.swift`): `@main struct Plugin: CompilerPlugin { let providingMacros: [Macro.Type] = [DeclVisitorMacro.self] }`.
- `DeclVisitor.NodeKind` enum covering all 17 declaration syntax types currently visited by rules.
- `DeclVisitorMacro: MemberMacro` — Pattern A only (simple dispatch). Generates one `override func visit(_ node: <Kind>Syntax) -> DeclSyntax { processDecl(node) }` per kind for `RewriteSyntaxRule`, no-return form for `LintSyntaxRule`. Default helper name `processDecl`; `helper:` argument overrides.
- Diagnostics for: empty kind list, unknown kind, rule type not inheriting from a known base class, invalid `helper:` identifier.
- Snapshot tests with `MacroTesting`'s `assertMacro { ... } expansion: { ... }` for each diagnostic and one expansion per supported base class.
- `RuleCollector` change at `Sources/GeneratorKit/RuleCollector.swift:154-162`: walk class `attributes`, find `DeclVisitor`, parse `LabeledExprListSyntax` for `.kindName` member-access expressions, map to `*Syntax` type names. Keep the existing member-walk path as a fallback so unmigrated rules still work.
- Prototype migration: pick one rule with pure Pattern A (`TripleSlashDocComments` — 11 overrides — is a good candidate). Replace its visit overrides with `@DeclVisitor(...)`. Verify via xc-swift build/test that all tests pass and finding output is unchanged.

## Done when

- xc-swift package test passes (full suite + new macro tests).
- Prototype rule fires identically before/after migration on a corpus diff.
- Generated `Pipelines+Generated.swift` includes the prototype rule's full visit set (proves `RuleCollector` reads the attribute correctly).

## References

- Thesis macros package layout: `/Users/jason/Developer/toba/thesis/Core/Macros/Package.swift`
- MemberMacro example: `/Users/jason/Developer/toba/thesis/Core/Macros/Sources/ThesisMacroPlugin/TableMacro+MemberMacro.swift`
- Snapshot test style: `/Users/jason/Developer/toba/thesis/Core/Macros/Tests/ThesisMacroTests/Support/SnapshotTests.swift`
- Macro reference: `~/.claude/skills/swift/references/swift-macros.md`
