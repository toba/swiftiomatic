---
# 4eg-bfj
title: 'Cat 9: Accessor & Declaration Patterns (3 rules)'
status: in-progress
type: feature
priority: normal
created_at: 2026-04-15T00:27:58Z
updated_at: 2026-04-25T23:53:30Z
parent: qlt-10c
sync:
    github:
        issue_number: "315"
        synced_at: "2026-04-25T23:54:50Z"
---

| SwiftLint Rule | Swiftiomatic Name | Scope | Description |
|---|---|---|---|
| `computed_accessors_order` | AccessorOrder | `.lint` | Consistent get/set ordering in computed properties |
| `protocol_property_accessors_order` | ProtocolAccessorOrder | `.format` | `{ get set }` order in protocol requirements |
| `lower_acl_than_parent` | ACLConsistency | `.lint` | Child ACL shouldn't exceed parent's effective ACL |



## Tasks

- [ ] Write AccessorOrderTests.swift
- [ ] Write ProtocolAccessorOrderTests.swift
- [ ] Write ACLConsistencyTests.swift
- [ ] Implement AccessorOrder (lint, .declarations group)
- [ ] Implement ProtocolAccessorOrder (rewrite, .declarations group)
- [ ] Implement ACLConsistency (rewrite, .access group)
- [ ] Build clean, run tests
- [ ] Regenerate schema.json
