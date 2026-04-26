---
# 4eg-bfj
title: 'Cat 9: Accessor & Declaration Patterns (3 rules)'
status: completed
type: feature
priority: normal
created_at: 2026-04-15T00:27:58Z
updated_at: 2026-04-26T00:03:12Z
parent: qlt-10c
sync:
    github:
        issue_number: "315"
        synced_at: "2026-04-26T00:18:53Z"
---

| SwiftLint Rule | Swiftiomatic Name | Scope | Description |
|---|---|---|---|
| `computed_accessors_order` | AccessorOrder | `.lint` | Consistent get/set ordering in computed properties |
| `protocol_property_accessors_order` | ProtocolAccessorOrder | `.format` | `{ get set }` order in protocol requirements |
| `lower_acl_than_parent` | ACLConsistency | `.lint` | Child ACL shouldn't exceed parent's effective ACL |



## Tasks

- [x] Write AccessorOrderTests.swift
- [x] Write ProtocolAccessorOrderTests.swift
- [x] Write ACLConsistencyTests.swift
- [x] Implement AccessorOrder (lint, .declarations group)
- [x] Implement ProtocolAccessorOrder (rewrite, .declarations group)
- [x] Implement ACLConsistency (rewrite, .access group)
- [x] Build clean, run tests
- [x] Regenerate schema.json


## Summary of Changes

Added three Cat 9 rules ported from SwiftLint:

- **AccessorOrder** (`Sources/SwiftiomaticKit/Rules/Declarations/AccessorOrder.swift`) — lint-only, group `.declarations`. Visits `AccessorBlockSyntax`; emits a finding when computed properties or subscripts declare get/set in the wrong order. Configurable via `accessorOrder.order` (`get_set` default | `set_get`).
- **ProtocolAccessorOrder** (`Sources/SwiftiomaticKit/Rules/Declarations/ProtocolAccessorOrder.swift`) — rewrite, group `.declarations`. Visits `AccessorBlockSyntax` inside `ProtocolDeclSyntax`; reorders `set get` to `get set` for protocol property requirements.
- **ACLConsistency** (`Sources/SwiftiomaticKit/Rules/Access/ACLConsistency.swift`) — rewrite, group `.access`. Visits `DeclModifierSyntax`; flags ACL modifiers higher than the enclosing nominal/extension parent's effective ACL. `open` → `public`; otherwise the modifier is removed.

Test files: `Tests/SwiftiomaticTests/Rules/{AccessorOrder,ProtocolAccessorOrder,ACLConsistency}Tests.swift` — 26 new test cases, all passing.

Regenerated `schema.json`, `ConfigurationRegistry+Generated.swift`, `Pipelines+Generated.swift` via `swift run Generator`. Full suite: 2940 / 0.
