---
# 7y3-bfa
title: sm format ignores '// sm:ignore:next <rule>' directives, applies destructive transforms anyway
status: completed
type: bug
priority: high
created_at: 2026-05-08T22:08:34Z
updated_at: 2026-05-08T22:20:44Z
sync:
    github:
        issue_number: "673"
        synced_at: "2026-05-08T22:24:57Z"
---

## Summary

`sm format` removes `throws` (or `async throws`) from function declarations whose body it considers non-throwing, even when:
1. Callers invoke the function with `try` — silently breaks compilation downstream
2. The line above carries an explicit `// sm:ignore:next dropRedundantThrows` directive — the directive is ignored

## Examples

### Strips `throws` from `setUp` despite the ignore directive

`DOM/Tests/Performance/PipelineIndexerPerformanceTests.swift`:
```diff
     @MainActor
     // sm:ignore:next dropRedundantThrows
-    override func setUp() async throws {
+    override func setUp() async {
```

Downstream error:
> overriding a throwing '@objc' method with a non-throwing method is not supported

The `// sm:ignore:next dropRedundantThrows` comment was placed precisely to prevent this. The formatter ignored it and made the change anyway. (And the lint warning was a false positive in the first place: `XCTestCase.setUp() async throws` is the framework signature; overriding with a non-throwing form is an error.)

### Strips `throws` from a function called via `try`

`Integrations/RIS/Tests/Support/RISTestSuite.swift`:
```diff
-    func data(from fileName: String) async throws -> [RIS.FileRow]? {
+    func data(from fileName: String) async -> [RIS.FileRow]? {
```

Body uses `guard let url = … else { throw … }` somewhere down the chain (or a caller does), so `try` at call sites now fails to compile:
> errors thrown from here are not handled

## Severity

High. Combined with the strip-Sendable bug, a single `sm format` run on the Thesis tree introduced dozens of compile errors. The directive-ignored case is particularly bad because users rely on `sm:ignore` to suppress known-incorrect warnings; if the formatter applies the change anyway, the directive is functionally dead.

## Related

This is adjacent to bug `ugi-3p0` (`sm format` corrupting code inside multi-line `\"\"\"` literals) — both stem from `sm format` making semantically-significant changes that it classifies as cosmetic.

## Suggested fix

1. Honor `// sm:ignore:next <rule>` (and file-level `// sm:ignore <rule>`) in the formatter's modification path, not just in the lint reporter.
2. For `dropRedundantThrows` specifically: a function that overrides a throwing requirement (protocol or `@objc` superclass) cannot drop `throws`. The formatter needs the override / requirement context before rewriting; if context is unavailable, it should not rewrite.
3. More broadly: stripping `throws` from a public/internal function is a source-breaking change for callers in other files. The formatter should either resolve cross-file usage or refuse to strip `throws` from non-`private`/`fileprivate` functions.


## Update — second confirmed rule that ignores the directive

`dropUnusedArguments` also fires through the directive. In `Core/Tests/Storage/DatabaseFunctionTests.swift`:

\`\`\`swift
@SQLFunction
// sm:ignore:next dropUnusedArguments
func dateTime(_ format: String? = nil) -> Date? { Date(timeIntervalSince1970: 0) }
\`\`\`

After \`sm format\`:

\`\`\`swift
@SQLFunction
// sm:ignore:next dropUnusedArguments
private func dateTime(_: String? = nil) -> Date? { Date(timeIntervalSince1970: 0) }
\`\`\`

The internal parameter name was dropped (\`_ format:\` → \`_:\`). Same in \`Core/Tests/Storage/CompileTimeQueriesTests.swift\` for the \`representableArguments\` function.

This breaks the \`@SQLFunction\` macro, which reads parameter names to generate identifier bindings. The macro then emits \`if let _ = …\` and \`let _ = …\` pattern uses where \`_\` is treated as an identifier — producing 14+ compile errors per affected file.

So `sm:ignore:next` is being ignored by at least three rules so far: `dropRedundantThrows`, `dropUnusedArguments`, and (I suspect) others. This points to a single root cause in the formatter's rewrite path rather than per-rule oversight.



## Summary of Changes

Two fixes for the bug where `sm format` strips `throws` and ignores `// sm:ignore:next dropRedundantThrows` directives.

### 1. `DropRedundantThrows` is now restricted to syntax-provably-safe cases

`Sources/SwiftiomaticKit/Rules/Redundancies/DropRedundantThrows.swift`:
- Skip functions with the `override` modifier — they may satisfy a throwing super requirement (`@objc` or otherwise).
- Skip functions that aren't explicitly `private` or `fileprivate` — internal/public/package functions can be called from other files where callers wrap them in `try`. Without type/cross-file info we can't prove the rewrite is safe.

This trades reach for soundness in line with the issue's suggested fix.

### 2. `// sm:ignore:next` directives between attributes and modifiers are now honored

`Sources/SwiftiomaticKit/Syntax/RuleMask.swift`:
- `applyDirectives` previously only scanned lone-line comments in the *first* token's leading trivia. A directive placed on its own line between, e.g., `@MainActor` and `override func setUp() async throws` lives in the leading trivia of an *interior* token (`override`) and was silently ignored.
- The scanner now walks lone-line comments in the leading trivia of every direct (non-descendant) token of the visited `CodeBlockItem` / `MemberBlockItem`.
- A `:next` directive (or any bare `// sm:ignore` *inside* the node's trivia) is scoped to the current node. A bare directive in the *first* token's leading trivia continues to extend to EOF, matching prior behavior.

### Tests

- `DropRedundantThrowsTests`: added `internalFunctionNotFlagged`, `publicFunctionNotFlagged`, `overrideFunctionNotFlagged`. Updated existing `throwsWithoutThrow`, `nestedClosureThrowNotCounted`, `typedThrowsWithoutThrow` to use `private` (the rule now requires it).
- `RuleMaskTests`: added `ignoreNextBetweenAttributeAndModifierAppliesToNode`.

Full test suite: 3282 passed, 0 failed.
