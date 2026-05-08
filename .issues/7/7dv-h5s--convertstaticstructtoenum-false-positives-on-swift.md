---
# 7dv-h5s
title: '`convertStaticStructToEnum` false-positives on swift-testing `@Test` suites'
status: completed
type: bug
priority: high
created_at: 2026-05-08T18:52:53Z
updated_at: 2026-05-08T19:12:29Z
sync:
    github:
        issue_number: "665"
        synced_at: "2026-05-08T19:20:43Z"
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
