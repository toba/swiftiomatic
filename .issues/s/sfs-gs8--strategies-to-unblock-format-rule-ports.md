---
# sfs-gs8
title: Strategies to unblock format rule ports
status: in-progress
type: feature
priority: normal
created_at: 2026-04-14T05:26:49Z
updated_at: 2026-04-14T17:13:49Z
parent: c7r-77o
sync:
    github:
        issue_number: "294"
        synced_at: "2026-04-14T06:15:35Z"
---

Design and implement abstractions, helpers, and architectural patterns that unblock the 30 rules listed in c7r-77o, enabling their conversion from lint-only to auto-fixing format rules.

## Analysis

Investigation of the swift-syntax source at `~/Developer/apple/swift-syntax` and the existing rule patterns in Swiftiomatic reveals that the 30 blocked rules cluster into **7 distinct blocker categories**, each requiring a different strategy. Several rules originally thought to be architecturally blocked are actually **not blocked at all** — their blockers were based on incorrect assumptions about swift-syntax's AST representation.

### Revised Blocker Categories

| Category | Rules | Actual Difficulty |
|----------|-------|-------------------|
| A. Not actually blocked | 3 | Ready to implement |
| B. Attribute removal boilerplate | 3 | Needs `AttributeListSyntax+Convenience` |
| C. Modifier removal boilerplate | 5 | Pattern exists (RedundantInternal); boilerplate only |
| D. Inheritance clause modification | 2 | Needs `InheritanceClauseSyntax+Convenience` |
| E. Expression restructuring | 5 | Architecturally supported; needs patterns |
| F. Cross-statement/declaration merging | 4 | Pattern exists (UseEarlyExits); moderate |
| G. Condition/list splitting | 3 | Pattern exists (DoNotUseSemicolons); moderate |
| H. Scope analysis | 1 | Genuinely hard; needs design |
| I. Rule extension | 2 | Just feature work |

### Category A: Not Actually Blocked (3 rules)

**`redundantPattern`** — Original blocker: "swift-syntax does not produce `ValueBindingPatternSyntax` for inner case patterns." **This is incorrect.** The swift-syntax source confirms that `case .bar(let _)` produces:

```
ExpressionPatternSyntax
  └─ FunctionCallExprSyntax
     └─ LabeledExprSyntax
        └─ PatternExprSyntax
           └─ ValueBindingPatternSyntax   ← IT EXISTS
              ├─ bindingSpecifier: "let"
              └─ WildcardPatternSyntax
```

The `ValueBindingPatternSyntax` IS produced — it's nested inside `PatternExprSyntax` inside `LabeledExprSyntax`. The lint rule visitor needs to visit `PatternExprSyntax` or `ValueBindingPatternSyntax` directly, not look for it at the `SwitchCaseItemSyntax` level.

**`strongifiedSelf` / `redundantBackticks`** — Original blocker: "backtick token positioning doesn't align with MarkedText." **Investigation shows this is solvable.** swift-syntax stores backticks as part of the token text (`.identifier("` `` `self` `` `")`), and `TokenSyntax.startLocation` points to the opening backtick. Additionally, `SyntaxRewriter` has `visit(_ token: TokenSyntax) -> TokenSyntax` which intercepts ALL tokens — perfect for backtick rules. The `Identifier.name` property strips backticks automatically. The pipeline output divergence for `strongifiedSelf` (noted as a secondary blocker) needs investigation but is likely a trivia transfer issue, not architectural.

**Action**: Implement these three rules directly. No new abstractions needed.

### Category B: Attribute Removal (3 rules)

**Rules**: `redundantObjc`, `redundantViewBuilder`, plus future attribute-removal rules

**Problem**: No `AttributeListSyntax+Convenience` exists. `ModifierListSyntax` has `remove(anyOf:)` and `removing(anyOf:)` but attributes have no equivalent. Each rule must manually iterate `AttributeListSyntax`, find the target, rebuild the list, and fix trivia (leading trivia of removed attribute → next attribute or declaration keyword).

**Solution**: Create `AttributeListSyntax+Convenience.swift`:

```swift
extension AttributeListSyntax {
    /// Returns the first attribute matching the given name.
    func attribute(named name: String) -> AttributeSyntax?

    /// Returns a copy with the named attribute removed, with trivia cleanup.
    func removing(named name: String) -> AttributeListSyntax

    /// Mutating removal with trivia cleanup.
    mutating func remove(named name: String)
}
```

Then converting `RedundantObjc` from lint to format follows the RedundantInternal pattern exactly, but calling `attributes.remove(named: "objc")` instead of `modifiers.remove(anyOf:)`.

### Category C: Modifier Removal (5 rules)

**Rules**: `redundantExtensionACL`, `redundantPublic`, `redundantLet`, `redundantBreak`, `redundantAsync`, `redundantThrows`, `redundantTypedThrows`

**Problem**: Converting these lint rules to format rules requires overriding `visit()` for every declaration type (Actor, Class, Enum, Function, Initializer, Protocol, Struct, Subscript, TypeAlias, Variable — up to 10 overrides per rule), each doing nearly identical work.

**Solution**: The pattern is already proven by `RedundantInternal`:

```swift
private func removeRedundantX<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
    from decl: Decl,
    keywordKeyPath: WritableKeyPath<Decl, TokenSyntax>
) -> Decl
```

Each rule calls this helper from thin visit overrides. The boilerplate (10 visit methods per rule) is unavoidable due to `SyntaxRewriter`'s concrete-type dispatch, but it's mechanical — each override is a one-liner calling the generic helper.

**Alternative — `visitAny` dispatch**: `SyntaxRewriter.visitAny(_ node: Syntax) -> Syntax?` could intercept all declaration nodes and do protocol-based dispatch via `node.asProtocol(WithModifiersSyntax.self)`. However, this fights the type system (need to reconstruct the specific `DeclSyntax` wrapper) and bypasses the pipeline's generated dispatch. Not recommended.

**Alternative — Code generation**: Extend `generate-swiftiomatic` to auto-generate the visit-method boilerplate for "remove modifier" rules. A rule would declare what it removes and the generator emits the overrides. This eliminates boilerplate at the cost of generator complexity. Consider for later if the pattern recurs enough.

**Recommended**: Use the RedundantInternal pattern directly. The boilerplate is annoying but correct and well-understood.

### Category D: Inheritance Clause Modification (2 rules)

**Rules**: `redundantSendable`, `redundantEquatable`

**Problem**: Removing a conformance from `InheritanceClauseSyntax` requires careful handling of comma separators and the colon. Cases: removing the only item (remove entire clause + colon), removing first item (remove leading comma from new first), removing middle item (remove trailing comma), removing last item (remove preceding comma).

**Solution**: Create `InheritanceClauseSyntax+Convenience.swift`:

```swift
extension InheritanceClauseSyntax {
    /// Returns a copy with the named type removed, or nil if the clause becomes empty.
    func removing(named typeName: String) -> InheritanceClauseSyntax?
}
```

For `redundantEquatable`, the rule also needs to remove the `==` function from the member block — this is a `MemberBlockItemListSyntax` filtering operation (Category F pattern).

For `redundantSendable`, the rule just needs inheritance clause modification.

### Category E: Expression Restructuring (5 rules)

**Rules**: `preferCountWhere`, `hoistTry`, `hoistAwait`, `isEmpty`, `preferKeyPath`

**Problem**: These require transforming one expression shape into a fundamentally different one. The return type covariance (`visit(SomeExprSyntax) -> ExprSyntax`) makes this architecturally possible, but the transformations are complex.

**Strategies per rule**:

- **`isEmpty`**: Visit `InfixOperatorExprSyntax`. When pattern matches `.count == 0` / `.count != 0` / `.count > 0`, return `MemberAccessExprSyntax(.isEmpty)` or prefix with `!`. Expression-level, no parent modification needed.

- **`hoistTry` / `hoistAwait`**: Visit `FunctionCallExprSyntax`. Walk arguments to find `TryExprSyntax`/`AwaitExprSyntax` wrappers, strip them from arguments, wrap the entire call in `TryExprSyntax`/`AwaitExprSyntax`. The key insight: you're modifying children (strip wrappers) AND the parent (add wrapper) — but since you visit the `FunctionCallExprSyntax` and return `ExprSyntax`, you do both in one visit method.

- **`preferCountWhere`**: Visit `MemberAccessExprSyntax` (the `.count` access). Check if base is `.filter(closure)`. Restructure: rename `filter` → `count`, add `where:` label, remove `.count` access. Return the restructured `FunctionCallExprSyntax`.

- **`preferKeyPath`**: Visit `FunctionCallExprSyntax`. Check if trailing closure is `{ $0.property }`. Convert to `\.property` argument. Return modified `FunctionCallExprSyntax`.

**No new abstractions needed** — each rule visits a specific expression type and returns `ExprSyntax`. The complexity is per-rule logic, not missing infrastructure.

### Category F: Cross-Statement/Declaration Merging (4 rules)

**Rules**: `conditionalAssignment`, `redundantProperty`, `redundantClosure`, `environmentEntry`

**Problem**: Need to recognize multi-statement patterns and merge/restructure them. `SyntaxRewriter` visits individual statements, can't easily merge adjacent `CodeBlockItemSyntax` nodes.

**Solution**: Visit `CodeBlockItemListSyntax` (for statements) or `MemberBlockItemListSyntax` (for declarations) and iterate with lookahead. This is the exact pattern used by `UseEarlyExits` and `NoAssignmentInExpressions`.

```swift
public override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
    var newItems = [CodeBlockItemSyntax]()
    let items = Array(node)
    var i = 0
    while i < items.count {
        if i + 1 < items.count, let merged = tryMerge(items[i], items[i + 1]) {
            newItems.append(merged)
            i += 2  // consumed two items
        } else {
            newItems.append(visit(items[i]))
            i += 1
        }
    }
    return CodeBlockItemListSyntax(newItems)
}
```

**`environmentEntry`** is the hardest in this group because it spans TWO top-level declarations (a key struct + an extension). This requires visiting `SourceFileSyntax` (like `OrderedImports` does) and recognizing the pattern across adjacent file-level declarations.

### Category G: Condition/List Splitting (3 rules)

**Rules**: `andOperator`, `simplifyGenericConstraints`, `genericExtensions`

**Problem**: `andOperator` needs to split `a && b` inside a condition into two separate `ConditionElementSyntax` nodes. The original blocker says "SyntaxRewriter doesn't support parent modification during child visits."

**Solution**: Visit `ConditionElementListSyntax` (the parent list), not the child condition. Iterate elements, find those containing `&&`, split them, rebuild the list. This is the exact pattern used by `DoNotUseSemicolons` (splits semicolon-joined statements) and `OneVariableDeclarationPerLine` (splits multi-binding declarations).

**`simplifyGenericConstraints` / `genericExtensions`**: Visit the containing declaration type (FunctionDeclSyntax, etc.) and modify both `genericParameterClause` and `genericWhereClause` in a single visit method. No parent modification needed — both properties belong to the declaration being visited.

### Category H: Scope Analysis (1 rule)

**Rule**: `redundantSelf`

**Problem**: Genuinely hard. Requires knowing whether `self.foo` can be simplified to `foo` without ambiguity (no local variable named `foo` in scope, not inside a closure that captures `self`).

**Alternatives**:

1. **Conservative subset**: Only handle the easy cases — `self.` inside a non-escaping closure where it was required before SE-0269, explicit `self` in methods with no local shadowing (check sibling `let`/`var` bindings in the same code block).

2. **Lightweight scope resolver**: Build a `ScopeStack` that tracks variable bindings as the visitor descends. Push scope on entering code blocks/closures, pop on exit. Check for name collisions before removing `self.`. This is moderate complexity (~200-300 lines) and covers most cases.

3. **Configurable insertion mode**: Instead of removing `self`, support inserting explicit `self` everywhere (the inverse — some codebases prefer explicit self). This is simpler because you don't need scope analysis — just add `self.` to all member accesses inside methods.

4. **Defer**: Leave as lint-only. This is the most complex rule in nicklockwood/SwiftFormat (~800 lines). The ROI of making it auto-fix may not justify the effort yet.

**Recommendation**: Start with alternative 1 (conservative subset) as a format rule, leave the full version for later with alternative 2.

### Category I: Rule Extension (2 rules)

**Rules**: `redundantFileprivate`, `redundantParens`

**Problem**: These need to extend existing rules (FileScopedDeclarationPrivacy, NoParensAroundConditions) rather than be standalone.

**Solution**: Add new visit methods and conditions to the existing rule classes. No architectural issue — just feature work.

## New Abstractions Needed

- [x] `AttributeListSyntax+Convenience` — `attribute(named:)`, `remove(named:)`, `removing(named:)` with trivia cleanup
- [x] `InheritanceClauseSyntax+Convenience` — `removing(named:)` returning nil when empty, handling comma/colon cleanup
- [ ] Consider: `CodeBlockItemListSyntax` windowed-transform helper for pairwise pattern matching (Categories F/G)

## Prioritized Implementation Order

**Phase 1 — Quick wins (unblock 8 rules)**:
1. Implement Category A rules directly (strongifiedSelf, redundantBackticks, redundantPattern)
2. Create `AttributeListSyntax+Convenience`; convert redundantObjc + redundantViewBuilder to format
3. Convert redundantExtensionACL, redundantPublic, redundantBreak to format (modifier removal pattern)

**Phase 2 — Expression rules (unblock 5 rules)**:
4. Implement isEmpty, preferCountWhere, hoistTry/hoistAwait, preferKeyPath as format rules

**Phase 3 — List manipulation (unblock 5 rules)**:
5. Create `InheritanceClauseSyntax+Convenience`; implement redundantSendable
6. Implement andOperator (condition list splitting)
7. Convert simplifyGenericConstraints, genericExtensions to format

**Phase 4 — Cross-statement (unblock 4 rules)**:
8. Implement conditionalAssignment, redundantProperty, redundantClosure
9. Implement environmentEntry (SourceFileSyntax-level pattern)

**Phase 5 — Hard rules (unblock 4 rules)**:
10. Extend existing rules (redundantFileprivate, redundantParens)
11. Implement opaqueGenericParameters
12. Design and implement redundantSelf (conservative subset)

**Phase 6 — Remaining modifier rules (unblock 5 rules)**:
13. Convert redundantLet, redundantAsync, redundantThrows, redundantTypedThrows, redundantType to format
14. Implement redundantEquatable (inheritance + member removal)
15. Implement redundantStaticSelf (node type change: MemberAccessExpr → DeclReferenceExpr)
