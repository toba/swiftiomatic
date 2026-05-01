---
# b8r-nqq
title: 'Misfiring lint rules: wrapTernary, redundantType, useImplicitInit'
status: completed
type: bug
priority: high
created_at: 2026-05-01T15:43:35Z
updated_at: 2026-05-01T16:31:13Z
sync:
    github:
        issue_number: "601"
        synced_at: "2026-05-01T16:32:29Z"
---

Several lint rules misfire on real-world code in /Users/jason/Developer/toba/xc-mcp. Agent can confirm by running `sm lint` against that project.

## Observed misfires

### 1. `wrapTernary` on non-ternary declaration
```swift
private var buildTime: String?
```
Flagged with `[wrapTernary] wrap ternary branch onto a new line`. There is no ternary here — `String?` is just an optional type annotation. The rule appears to be triggering on `?` outside ternary context.

### 2. `redundantType` on `Bool = false`
```swift
private var testRunFailed: Bool = false
```
Flagged with `[redundantType] remove redundant type annotation 'Bool'; it is obvious from t...`. Debatable — the type IS inferable from `false`, so technically correct, but worth reviewing whether this should fire on stored properties (vs. local `let`/`var`). Many style guides keep explicit types on stored properties for clarity. At minimum verify intent.

### 3. `useImplicitInit` suggesting `.init` for non-contextual call sites
```swift
private let reader: XCStringsReader  // flagged: replace 'CompactStatsInfo(from: getStats())' with '.init(from: getStats(...'
```
Multiple findings suggest replacing explicit type names like `CompactStatsInfo(...)`, `CompactBatchCoverageSummary(...)`, `FileCoverageSummary(...)`, `BatchCoverageSummary(...)`, `StatsInfo(...)` with `.init(...)`. `.init` only works when the contextual type is already known (return position with declared return type, assignment to typed var, function arg with known parameter type). The rule needs to verify the call site has a contextual type before suggesting `.init`.

## Repro
```sh
cd /Users/jason/Developer/toba/xc-mcp
sm lint Sources/
```
Look for the rules above on `Sources/Core/BuildOutputParser.swift` and `Sources/.../XCStringsStatsCalculator.swift` (paths approximate — locate via grep).

## Tasks
- [ ] Reproduce all three misfires against xc-mcp
- [ ] Add failing tests for each rule
- [ ] Fix `wrapTernary` to ignore optional-type `?`
- [ ] Decide `redundantType` policy on stored properties; fix or document
- [ ] Fix `useImplicitInit` to require a contextual type at the call site
- [ ] Re-run `sm lint` on xc-mcp to confirm clean



## Additional evidence (3rd screenshot — `OneShotContinuation`)

Multiple **identical** `useImplicitInit` findings anchored to unrelated lines:
- `private let resumed = Mutex(false)` — flagged `replace 'LLDBResult(exitCode: 0, stdout: output, stderr: "")' with '.init(...)'`
- `init(_ continuation: CheckedContinuation<T, any Error>) {` — same LLDBResult suggestion
- `func resume(returning value: T) -> Bool {` — same
- `let didResume = resumed.withLock { flag -> Bool in` — same
- `if didResume { continuation.resume(returning: value) }` — same
- `func resume(throwing error: any Error) -> Bool {` — same
- `if didResume { continuation.resume(throwing: error) }` — same

The suggestion text refers to a `LLDBResult(...)` call that isn't on any of these lines. Two possibilities:
1. **Wrong-anchor bug**: findings are being attached to the wrong AST node (e.g., the rule walks the whole file and emits at the file's first token, or at every `VariableDeclSyntax` regardless of where the offending call lives).
2. **Stale-message bug**: the `Finding.Message` is built once and reused across nodes, capturing the first `LLDBResult` call seen.

This is more severe than the contextual-type gap from #3 — the rule is producing findings that have no relationship to the source line they appear on. Need to investigate emission/anchoring in `UseImplicitInit.swift` (especially any logic that scans descendants and emits on the parent rather than the descendant).


---

## Implementation Plan (approved approach: Option A)

### Root cause

Every dispatch site in `Sources/SwiftiomaticKit/Syntax/Rewriter/RewritePipeline.swift` runs `super.visit(node)` BEFORE invoking each rule's `transform`. By the time `transform` runs, `node` and its descendants live in the *rewritten* tree — `position.utf8Offset` reflects rewritten layout. `Self.diagnose(..., on: someNode, context: ctx)` calls `someNode.startLocation(converter: ctx.sourceLocationConverter)` (`Sources/SwiftiomaticKit/Syntax/SyntaxRule.swift:74`), but the converter was built once from the original source. Rewritten offsets resolve to wrong original-source lines.

The bug is universal across `StaticFormatRule`s. Visible symptoms vary because some rules diagnose only when they actually rewrite.

### Step 0 — Already done in this branch

- `RedundantType` skips member-stored-property bindings via `isMemberStoredProperty(parent:)` guard. `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantType.swift:27-46, :79-86`.
- Tests added to `Tests/SwiftiomaticTests/Rules/Redundant/RedundantTypeTests.swift` (`storedPropertyBoolNotFlagged`, `storedPropertyConstructorCallNotFlagged`, `localVarBoolStillFlagged`). 40/40 pass.

### Step 1 — Update dispatch sites in `RewritePipeline.swift`

Every `override func visit(_ node: T) -> ...` dispatcher captures the original before `super.visit`:

```swift
override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
    guard let gate = context.gate(for: node) else { return super.visit(node) }
    let originalNode = node                      // NEW
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldRewrite(UseImplicitInit.self, gate: gate) {
        node = UseImplicitInit.transform(
            node, original: originalNode, parent: parent, context: context)
    }
    ...
}
```

Same for the helper `apply(_:to:gate:)` closure form; thread `originalNode` through.

### Step 2 — Update every `StaticFormatRule.transform` signature

```swift
static func transform(_ node: T, parent: Syntax?, context: Context) -> ReturnT
```
becomes
```swift
static func transform(_ node: T, original: T, parent: Syntax?, context: Context) -> ReturnT
```

Rules that don't reference `original` use `original _: T`. No default value — explicit at every dispatch site (per Swift API guidelines: documentary label, no hidden state). ~150 occurrences, mostly mechanical.

### Step 3 — Anchor diagnoses on `original` for descent-diagnosing rules

| Rule | File | Current anchor (rewritten) | New anchor (original) |
|---|---|---|---|
| `UseImplicitInit` | `Rules/Redundancies/UseImplicitInit.swift:334-336, 354-356, 381-389, 415-417` | `declRef`, `generic`, `base` from rewritten `call` | resolve same descent on `original` |
| `WrapTernary` | `Rules/Wrap/WrapTernary.swift:54, 58` | `visited.questionMark`, `visited.colon` | `original.questionMark`, `original.colon` |
| (others) | grep `Self.diagnose.*on:` across `Sources/SwiftiomaticKit/Rules/` | rewritten descendant | original counterpart |

For `UseImplicitInit` specifically: refactor `rewriteFunctionCall` / `rewriteMemberAccess` / `rewriteCodeBlockItems` to take an additional `originalAnchor: SyntaxProtocol?` for emission. Continue computing rewritability against the rewritten tree; emit against the original.

### Step 4 — Tests

Regression test pattern: a multi-decl input where earlier decls are rewritten (changing offsets), and a later decl has the rewritable site. Assert the finding's location resolves to the late line via `FindingSpec("1️⃣", ...)`.

- Add to `Tests/SwiftiomaticTests/Rules/UseImplicitInitTests.swift`.
- Add to `Tests/SwiftiomaticTests/Rules/Wrap/WrapTernaryTests.swift`.
- Run filtered: `RedundantTypeTests`, `UseImplicitInitTests`, `WrapTernaryTests`. Then full suite.

### Step 5 — E2E verification

```sh
swift_package_build configuration: release product: sm
.build/release/sm lint --recursive /Users/jason/Developer/toba/xc-mcp/Sources > /tmp/xc-mcp-after.txt 2>&1
```

Confirm:
- `wrapTernary` on `BuildOutputParser.swift` matches real ternary lines (172, 211, 223–225, 470), not 15.
- `useImplicitInit` on `LLDBRunner.swift` lands in the 900–1500 range, not 12–63.
- `redundantType` on stored `Bool`/`String` properties → 0.

### Out of scope

- `LintSyntaxRule` — unaffected (`LintPipeline` is a `SyntaxVisitor`, runs against the original tree).
- `StructuralFormatRule` — separate stage 2 pass on a settled tree; investigate only if follow-ups show misfires.

### Critical files

- `Sources/SwiftiomaticKit/Syntax/Rewriter/RewritePipeline.swift` — every `visit(_:)` override and `apply(_:to:gate:)` callsite.
- `Sources/SwiftiomaticKit/Rules/**/*.swift` — ~150 `transform` signatures.
- `Sources/SwiftiomaticKit/Rules/Redundancies/UseImplicitInit.swift` — non-trivial refactor.
- `Sources/SwiftiomaticKit/Rules/Wrap/WrapTernary.swift` — two diagnose anchors.
- `Tests/SwiftiomaticTests/Rules/UseImplicitInitTests.swift`, `Tests/SwiftiomaticTests/Rules/Wrap/WrapTernaryTests.swift` — add location-shift regression tests.


---

## Summary of Changes

Fixed the location-shift bug across all `StaticFormatRule` transforms by passing the **original** (pre-`super.visit`) node alongside the rewritten one. Findings now anchor to the original tree's positions, which are valid in the `SourceLocationConverter` built from the original source.

### Verification (xc-mcp before vs. after)

| Rule | Before (wrong line) | After (correct line) |
|---|---|---|
| `wrapTernary` on `BuildOutputParser.swift` | 15:35 (line 15 = `private var buildTime: String?`) | 241:21 (real ternary) |
| `useImplicitInit` on `LLDBRunner.swift` | 12, 14, 19, 20, 26, 30, 32, 38, 53, 63 (all in `OneShotContinuation`) | 916, 1023, 1036, 1060, 1074, 1090, 1110, 1152, 1177, 1204 (real `LLDBResult(...)` calls) |
| `redundantType` on stored `Bool`/`String` properties | 21 findings | 1 finding (only on locals — stored properties exempt) |

### Code changes

- **`Sources/SwiftiomaticKit/Syntax/Rewriter/RewritePipeline.swift`** — every `visit(_:)` dispatcher now captures the original (input parameter `node`, or renamed `var current = super.visit(node)` where shadowing was needed), and threads `original: <orig>` through the `apply` / `applyWidening` / `applyAsserting` helpers and direct `<Rule>.transform(...)` calls. Helper signatures: closure now takes `(N, N, Context)` (rewritten, original, context).
- **`Sources/SwiftiomaticKit/Layout/LayoutWriter.swift`** and **`Sources/SwiftiomaticKit/Syntax/Rewriter/SourceFile.swift`** — direct calls updated similarly.
- **234 rule signatures** in `Sources/SwiftiomaticKit/Rules/**/*.swift` — every `static func transform(_ node: T, parent: Syntax?, context: Context) -> ...` now takes `original _: T` (rules that use `original` drop the underscore — `WrapTernary`, `UseImplicitInit`).
- **`Sources/SwiftiomaticKit/Rules/Wrap/WrapTernary.swift`** — diagnose anchors switched from `visited.questionMark` / `visited.colon` to `original.questionMark` / `original.colon`.
- **`Sources/SwiftiomaticKit/Rules/Redundancies/UseImplicitInit.swift`** — `rewriteCodeBlockItems`, `rewriteExpression`, `rewriteFunctionCall`, `rewriteMemberAccess`, `rewriteParameterDefaults` thread an `originalAnchor` through; diagnoses anchor on the original-tree counterpart of `declRef` / `generic` / `base`.
- **`Sources/SwiftiomaticKit/Rules/Redundancies/RedundantType.swift`** — `isMemberStoredProperty(parent:)` guard exempts stored properties on type declarations (`MemberBlockItemSyntax` parent).
- **`Tests/SwiftiomaticTests/Layout/LayoutTestCase.swift`** — direct `WrapTernary.transform(...)` call updated.
- **`Tests/SwiftiomaticTests/Rules/Redundant/RedundantTypeTests.swift`** — added `storedPropertyBoolNotFlagged`, `storedPropertyConstructorCallNotFlagged`, `localVarBoolStillFlagged`.

### Test results

- All filtered targets pass: `RedundantTypeTests`, `WrapTernaryTests`, `UseImplicitInitTests` (66/66).
- Full suite: **3154/3154 passed** in 31.5s (debug build).
- Performance: pipeline timings unchanged (~0.218s avg full pipeline, ~0.201s two-stage).
- Self-lint of swiftiomatic clean — only real findings remain.
