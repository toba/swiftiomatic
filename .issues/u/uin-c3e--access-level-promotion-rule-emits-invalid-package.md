---
# uin-c3e
title: Access-level promotion rule emits invalid 'package' on protocol-conformance extension
status: completed
type: bug
priority: high
created_at: 2026-04-27T20:24:59Z
updated_at: 2026-04-30T02:24:34Z
sync:
    github:
        issue_number: "468"
        synced_at: "2026-04-30T03:34:38Z"
---

The access-level promotion rule rewrote a protocol-conformance extension as `package extension JSONValue: Codable`, which Swift rejects:

- 'package' modifier cannot be used with extensions that declare protocol conformances
- Initializer 'init(from:)' must be as accessible as its enclosing type
- Method 'encode(to:)' must be as accessible as its enclosing type

Repro file: `Sources/ConfigurationKit/JSONValue.swift` (extension JSONValue: Codable around line 25).

Expected: when an extension declares protocol conformance, the rule must NOT add an access modifier to the extension itself. Per Swift rules, access modifiers are disallowed on conformance-declaring extensions; members inherit from the enclosing type's access level (or the protocol's requirements).

Fix direction:
- In the access-level promotion rule, skip extensions whose `inheritanceClause` contains any inherited type (protocol conformance).
- Add a test case asserting no modifier is added to `extension Foo: SomeProtocol { ... }`.

Test first: add a failing test under the rule's tests reproducing the JSONValue.swift case, then implement the guard, then verify.



## Summary of Changes

- Sources/SwiftiomaticKit/Rules/Access/ExtensionAccessLevel.swift: in visitOnExtension, added a guard to skip extensions whose inheritanceClause is non-nil. This prevents hoisting a common access modifier onto a protocol-conformance extension, which Swift rejects.
- Tests/SwiftiomaticTests/Rules/ExtensionAccessLevelTests.swift: added protocolConformanceExtensionNotHoisted covering the JSONValue.swift repro (extension JSONValue: Codable with package members stays unchanged, no findings).

## Verification

Tests could not be run in this session due to a pre-existing generator bug in TokenStream+Generated.swift emitting visit(_ _: ArrayElementSyntax) (3 sites) that fails to compile. Unrelated to this fix. Once resolved, run the ExtensionAccessLevelTests suite via xc-swift, then rebuild sm and confirm Sources/ConfigurationKit/JSONValue.swift is no longer rewritten with package extension.
