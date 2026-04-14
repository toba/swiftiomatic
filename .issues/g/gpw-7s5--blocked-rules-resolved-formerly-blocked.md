---
# gpw-7s5
title: 'Blocked rules: resolved (formerly blocked)'
status: completed
type: task
priority: normal
created_at: 2026-04-14T18:36:18Z
updated_at: 2026-04-14T18:36:18Z
parent: c7r-77o
sync:
    github:
        issue_number: "302"
        synced_at: "2026-04-14T18:45:54Z"
---

Rules that were initially blocked but have been unblocked and converted to format rules.

- [x] `redundantObjc` — Attribute removal via `AttributeListSyntax+Convenience`
- [x] `redundantViewBuilder` — Attribute removal via `AttributeListSyntax+Convenience`
- [x] `redundantSendable` — Inheritance clause removal via `InheritanceClauseSyntax+Convenience`
- [x] `redundantExtensionACL` — Member modifier removal (stateful rewriting pattern)
- [x] `redundantPublic` — Member modifier removal (`DeclGroupSyntax` pattern)
- [x] `redundantBreak` — Statement removal from `CodeBlockItemListSyntax`
- [x] `redundantAsync` — Effect specifier removal
- [x] `redundantThrows` — Effect specifier removal
- [x] `redundantTypedThrows` — Effect specifier simplify/removal
- [x] `andOperator` — Visit `ConditionElementListSyntax`, flatten `&&` chains
- [x] `preferCountWhere` — Visit `MemberAccessExprSyntax`, replace chain with `.count(where:)`
- [x] `hoistTry` — Visit `FunctionCallExprSyntax`, strip `TryExprSyntax` from arguments, wrap call
- [x] `hoistAwait` — Same pattern as `hoistTry` with `AwaitExprSyntax`
- [x] `preferKeyPath` — Visit `FunctionCallExprSyntax`, replace closure with `KeyPathExprSyntax`
- [x] `simplifyGenericConstraints` — Generic helper with key paths, modify params + where clause
- [x] `genericExtensions` — Visit `ExtensionDeclSyntax`, modify extended type + where clause
- [x] `isEmpty` — Visit `InfixOperatorExprSyntax`, return restructured expression
