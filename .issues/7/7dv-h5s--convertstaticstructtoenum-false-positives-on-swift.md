---
# 7dv-h5s
title: '`convertStaticStructToEnum` false-positives on swift-testing `@Test` suites'
status: completed
type: bug
priority: high
created_at: 2026-05-08T18:52:53Z
updated_at: 2026-05-08T20:11:59Z
sync:
    github:
        issue_number: "665"
        synced_at: "2026-05-08T20:13:58Z"
---

\`convertStaticStructToEnum\` flags swift-testing suite structs as having only static members, but \`@Test\`-attributed functions are **instance** methods on the suite (swift-testing creates an instance per test). The struct must not be converted to an enum.

## Repro

\`\`\`swift
// thesis/Core/Tests/CustomDump/DiffTests.swift:5
import Testing
import Foundation
@testable import TestSupport

struct DiffTests {
    @Test func any() {
        #expect(diff((1, 2) as Any, (1, 2)) == nil)
        // ... uses self
    }

    @Test func someOther() {
        // instance method
    }
}
\`\`\`

\`sm lint\`:

\`\`\`
Core/Tests/CustomDump/DiffTests.swift:2:3: warning: [convertStaticStructToEnum] use 'enum' instead of 'struct' or 'class' for types with only static members
Core/Tests/CustomDump/DiffTests.swift:2:2: warning: [convertStaticStructToEnum] use 'enum' instead of 'struct' or 'class' for types with only static members
\`\`\`

(Also note: same finding emitted twice at adjacent columns — probably a separate dedup bug, but worth fixing in this rule's path.)

## Expected

Skip \`convertStaticStructToEnum\` when:
- Any member is annotated with \`@Test\`, \`@Suite\` (swift-testing), or
- Conformance to \`XCTestCase\` / Apple Testing protocols, or
- (Broader) any member has an attribute the analyzer doesn't recognise — defaulting to "this might be an instance method exposed via macro/attribute" is safer than rewriting suite types into enums (which would break compilation).

## Impact

Currently silenceable with \`// sm:ignore convertStaticStructToEnum - …\` at the top of every test file, which is noisy and easy to forget when adding new suites.

## Where the finding location is reported

\`line 2 col 2\` / \`line 2 col 3\` — line 2 in the file is \`import Foundation\`. The rule should report at the type declaration (\`struct DiffTests\` on line 5), not at an unrelated import. The current location makes the warning hard to interpret without running sm again with full context.



## Summary of Changes

Root cause was twofold:

1. **Location bug** — `transform` diagnosed on `visited.name`, but `visited` is the post-rewrite struct/class which gets detached from the source tree once any child has been rewritten by upstream rules in the same pipeline pass. Its `startLocation` then resolved against the wrong offsets, producing nonsense locations like `line 2 col 2/3` (pointing at unrelated `import` statements).

2. **The actual flagged structs were not `DiffTests` itself.** `DiffTests` correctly skipped because all its `@Test func` members are instance methods (no `static` modifier). The rule was firing on **local nested-type-only structs inside @Test func bodies** (e.g. `struct Parent { struct State: Equatable { ... } }` in `DiffTests.swift:1008,1011`). The bogus line 2 location made it look like the suite itself was being flagged.

### Fix

`Sources/SwiftiomaticKit/Rules/Declarations/ConvertStaticStructToEnum.swift`:
- Diagnose against `original.name` (pre-rewrite, attached to source tree) so source locations resolve correctly. The struct/class transforms now bind `original` instead of using `_`.
- Treat any **member-level attribute** as disqualifying for namespace conversion (`@Test`, `@Observable`-synthesized peers, custom macros, etc.) — a member attribute could be a macro that synthesizes instance behavior on the host type.

### Tests

`Tests/SwiftiomaticTests/Rules/ConvertStaticStructToEnumTests.swift`:
- `swiftTestingSuiteWithTestFuncsNotConverted` — regression: `struct DiffTests { @Test func any() {} }` must not convert.
- `swiftTestingSuiteAttributedStructNotConverted` — regression: `@Suite struct MyTests { @Test func one() {} }` must not convert.
- `memberWithUnknownAttributeNotConverted` — `struct Container { @SomeMacro static let value = 0 }` must not convert (conservative: macro attribute on member could synthesize peers).

### Verification

Full suite: 3278 passed, 0 failed.

After fix on the original repro file:
```
/tmp/big.swift:1008:16: warning: [convertStaticStructToEnum] ...
/tmp/big.swift:1011:16: warning: [convertStaticStructToEnum] ...
```
Locations now correctly point at the offending nested-type-only structs (`Child` and `Parent`), not bogus offsets in the imports.

Note: `useFinalClasses` exhibits the same `visited.name` location bug per the related open issue `rs5-13i`. Not fixed here — separate issue.


## Reopened — still firing in sm 3.5.4

After the fix shipped in 3.5.4, both `convertStaticStructToEnum` warnings still fire on the same files. I think the original report mis-identified the cause; the actual problem is the rule's **location reporting**, not the @Test detection.

### What sm 3.5.4 actually reports

```
$ sm lint Core/Tests/CustomDump/DiffTests.swift
Core/Tests/CustomDump/DiffTests.swift:2:3: warning: [convertStaticStructToEnum] use 'enum' instead of 'struct' or 'class' for types with only static members
Core/Tests/CustomDump/DiffTests.swift:2:2: warning: [convertStaticStructToEnum] use 'enum' instead of 'struct' or 'class' for types with only static members
```

### What's actually on those lines

```swift
// DiffTests.swift
1: import Testing
2: import Foundation       ← warnings reported here at col 2 and col 3
3: @testable import TestSupport
4:
5: struct DiffTests {       ← NOT reported, has @Test instance methods (correct: skipped)
6:     @Test func any() { … }
```

### Where the rule is *probably* detecting offenders (and reporting wrong)

```swift
// DumpTests.swift line 11
        struct Feature {
            struct State {}   ← empty nested struct, deep inside @Test method
        }

// line 508
        struct Inline {}      ← empty nested fixture struct

// line 756, 784
        struct ObservationRegistrar {}
```

These ARE struct-with-no-members and could syntactically be enums. So the rule's detection is reasonable — but:

1. **Location is wrong.** Reported at file's `import Foundation` (line 2 col 2/3) instead of the actual nested struct definitions (lines 11, 508, 756, 784).
2. **Duplicate emission at adjacent columns** (col 2 AND col 3) for what appears to be the same finding.
3. **These are intentional test fixtures** — they exist specifically to exercise dump/diff output for empty struct types. Converting them to enum would change the test semantics. So even with correct location reporting, this should be ignorable per-line; without correct location it's not actionable.

### Repro

Minimal:

```swift
// repro.swift
import Testing
import Foundation

struct Suite {
    @Test func test() {
        struct EmptyFixture {}  // ← rule should target this if anything
        _ = EmptyFixture.self
    }
}
```

Expected: warning at the `struct EmptyFixture {}` line (or no warning, if the rule excludes types nested inside @Test method bodies).
Actual: warning at `import Foundation` line, col 2 and col 3.

### Suggested fixes

1. Fix location reporting so the warning points at the actual offending struct definition.
2. Skip detection for types nested inside `@Test` / `@Suite` method bodies (they're test fixtures by intent).
3. Deduplicate warnings emitted for the same SyntaxNode.



## Re-investigation 2026-05-08

Locations on installed sm 3.5.4 are now correct (DiffTests.swift:1008:16 and 1011:16, pointing at the actual nested-type-only `struct Child` and `struct Parent`). The location bug from the first reopen is resolved.

The remaining real complaint is **the rule shouldn't fire on local type fixtures inside method bodies at all**. `struct Child { struct State {} }` inside a `@Test func` body is a fixture, not a namespace — converting to enum changes test semantics.

### Plan

Skip `convertStaticStructToEnum` for any struct/class declaration whose ancestor chain contains a `CodeBlockSyntax` (i.e., it's a local declaration inside a function/closure/accessor body). This is broader than just @Test — local types inside method bodies are essentially never namespaces, and skipping them avoids the false positive class entirely.

- [x] Add regression test `localFixtureStructInsideTestMethodNotConverted`
- [x] Add regression test `localStructInsideTopLevelFunctionNotConverted`
- [x] Implement `isLocalDeclaration` ancestor check in `ConvertStaticStructToEnum`
- [x] Full suite green (3287/3287)

## Summary of Changes (round 2)

`Sources/SwiftiomaticKit/Rules/Declarations/ConvertStaticStructToEnum.swift`:
- Added `isLocalDeclaration(_:)` helper that walks the ancestor chain of `original` looking for any `CodeBlockSyntax`. Returns true when the struct/class is declared inside a function, closure, or accessor body.
- Both `transform(StructDeclSyntax …)` and `transform(ClassDeclSyntax …)` now early-return when `isLocalDeclaration(original)` is true. Local types are essentially never namespaces — they're one-off fixtures (e.g. the empty `struct State`s inside swift-testing `@Test` method bodies that exercise dump/diff output). Rewriting them to `enum` would change test semantics.

This subsumes the @Test/@Suite-specific carveout the issue suggested: every `@Test func` body sits inside a `CodeBlockSyntax`, so any nested type-only `struct` inside such a body is now skipped, regardless of attributes on the enclosing function.

Top-level structs and member-nested structs are unaffected — their ancestor chain doesn't pass through a `CodeBlockSyntax`. Existing `localStructInsideStaticFunc` and `outerNamespaceWithNonNamespaceNested` tests still pass because they assert on the *outer* (non-local) namespace conversion.

`Tests/SwiftiomaticTests/Rules/ConvertStaticStructToEnumTests.swift`:
- `localFixtureStructInsideTestMethodNotConverted` — exact DiffTests.swift pattern: `struct DiffTests { @Test func … { struct Child { struct State {} }; struct Parent { struct State { … } } } }`. None of these convert.
- `localStructInsideTopLevelFunctionNotConverted` — `func doStuff() { struct LocalNamespace { static let foo = 1 } }`. Local namespace-only struct is not flagged.

### Verification

Full suite: 3287 passed, 0 failed.

The earlier location-bug fix (using `original.name` rather than `visited.name`) also remains correct — locations on the thesis repo file resolved to the right lines (1008:16, 1011:16) even before this round, so the user's "line 2 col 2/3" report from the reopen was likely against a stale binary. After this fix those findings are gone entirely because the local fixtures are skipped.



## Reopen root cause — argv[0]-dependent cache fingerprint

Same symptom and same fix as rs5-13i. The persistent `:2:2` / `:2:3` findings on `import` lines in sm 3.5.4 were caused by stale entries in the lint cache, not by remaining location-anchor bugs in this rule.

`Sources/SwiftiomaticKit/Support/LintCache.swift:120` derived the rule-set fingerprint from `CommandLine.arguments.first` (= argv[0]). Bare `sm lint …` invocations have argv[0] = "sm", so `attributesOfItem(atPath: "sm")` fails when cwd has no `sm` file, the size/mtime mix-in is skipped, and the fingerprint stays stable across rebuilds — so cached findings from the pre-fix binary keep being returned.

### Fix

Resolve the executable via `Bundle.main.executablePath` (with `CommandLine.arguments.first` as a fallback) so size/mtime always contribute to the digest and rebuilds invalidate the cache regardless of how `sm` is invoked.
