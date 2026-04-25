---
# 6rg-85v
title: PreferStaticOverClassFunc + formatTypePrefix break the rule's own source file
status: review
type: bug
priority: normal
created_at: 2026-04-25T19:39:11Z
updated_at: 2026-04-25T20:18:49Z
sync:
    github:
        issue_number: "411"
        synced_at: "2026-04-25T20:19:37Z"
---

## Repro

`sm format` (v0.33.0, project's swiftiomatic.json) on `Sources/SwiftiomaticKit/Rules/Idioms/PreferStaticOverClassFunc.swift` produces:

```diff
-    override class var group: ConfigurationGroup? { .idioms }
-    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }
+    override static var group: ConfigurationGroup? { .idioms }
+    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }
...
-        return DeclSyntax(result)
+        return .init(result)
```

Two rules are firing on this file:

### 1. PreferStaticOverClassFunc rewriting itself
The rule converts `class var`/`class func` → `static var`/`static func` on members of `final` classes. `PreferStaticOverClassFunc` is itself a `final class` with `override class var group` / `override class var defaultValue` overriding base-class declarations on `RewriteSyntaxRule`. The rule rewrites its own overrides.

This is likely incorrect: the parent declares these as `class var` so other rule subclasses can override them. Changing this subclass to `override static var` is technically valid (final class can use `override static`), but the rule should probably skip overrides in general — overriding members participate in the parent's override chain and the parent author chose `class` deliberately.

### 2. formatTypePrefix rewriting `DeclSyntax(result)` → `.init(result)`
Line 30:
```swift
override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    ...
    return DeclSyntax(result)   // becomes: return .init(result)
}
```
Where `result` is `ClassDeclSyntax` and the return type is `DeclSyntax`. The formatTypePrefix rule rewrites `Type(arg)` → `.init(arg)` when the type is inferable from context.

This may or may not compile (DeclSyntax has a generic init taking `some DeclSyntaxProtocol`; `.init(result)` should resolve via return-type context). Even if it compiles, the rewrite makes the code less clear: `DeclSyntax(result)` explicitly signals a wrap of a typed node into the type-erased DeclSyntax — `.init(result)` obscures that intent. The rule probably shouldn't fire when the wrapped value is a different type than the surrounding context (here: ClassDeclSyntax → DeclSyntax). It should only fire when the call is a true self-init like `MyType(field: x)` returning `MyType`.

## Repro steps

```sh
cp Sources/SwiftiomaticKit/Rules/Idioms/PreferStaticOverClassFunc.swift /tmp/
sm format /tmp/PreferStaticOverClassFunc.swift --in-place
diff Sources/SwiftiomaticKit/Rules/Idioms/PreferStaticOverClassFunc.swift /tmp/PreferStaticOverClassFunc.swift
```

## TODO

- [x] Decide: should PreferStaticOverClassFunc skip `override` modifiers? (Likely yes.)
- [x] Decide: skip single-unlabeled-positional-arg calls in UseImplicitInit (was misnamed formatTypePrefix in original report)
- [x] Add tests for both edge cases
- [x] Verify the formatted output actually compiles



## Compile errors observed

Per user screenshot, after running `sm format` the file fails to compile with errors on UNCHANGED lines:

```
result.memberBlock.members = MemberBlockItemListSyntax(result.memberBlock.members.map { ... })
                             ^ No exact matches in call to instance method 'map' (or similar)

result.modifiers = DeclModifierListSyntax(node.modifiers.map { ... })
                   ^ No exact matches in call to instance method 'map'
```

These are cascade failures — the closures can't type-check because something upstream is broken. The two changes the format made are the only candidates:

1. `override class var` → `override static var` on `group` and `defaultValue`. The parent (`RewriteSyntaxRule<V>`) declares these as `class var defaultValue: V` (generic). Overriding with `static var defaultValue: BasicRuleValue` may be rejected when V is the concrete type parameter — needs to be confirmed.
2. `return DeclSyntax(result)` → `return .init(result)` where `result: ClassDeclSyntax` and the return type is `DeclSyntax`. `.init(result)` should resolve via return-type context to `DeclSyntax(_ node: some DeclSyntaxProtocol)`, but if it doesn't, the function body fails to type-check and errors cascade.

Either change being rejected by the compiler causes the closures inside `replaceClassWithStatic` and `visit` to fail inference, producing the visible "No exact matches in call to 'map'" errors.

Bisect: try applying each change in isolation to determine which one (or both) breaks compilation.



## Update: confirmed second rule is `UseImplicitInit`

## Related bug: closures stripped from trailing-closure call sites

A separate but possibly related rule is eating multi-line trailing closures entirely. In `Sources/SwiftiomaticKit/Rules/EmptyExtensions.swift`:

```swift
// Before:
if removedFirst, var first = newItems.first {
    first.leadingTrivia = Trivia(
        pieces: first.leadingTrivia.drop {
            switch $0 {
            case .newlines, .carriageReturns, .carriageReturnLineFeeds, .spaces, .tabs:
                true
            default:
                false
            }
        }
    )
    newItems[0] = first
}

// After `sm format`:
if removedFirst, var first = newItems.first {
    first.leadingTrivia = Trivia(pieces: first.leadingTrivia.drop())
    newItems[0] = first
}
```

The entire `drop { ... }` trailing-closure body is dropped, leaving `.drop()` with empty parens. This is a SEVERE correctness bug — actual code is being deleted, not just rewritten.

Likely a layout/wrap rule that collapses multi-line calls to a single line is mis-handling trailing closures: it folds the call but loses the closure body when serializing the collapsed form. Candidates: `NestedCallLayout`, `WrapSingleLineBodies`, or another rule under `Rules/Wrap/`. (Note: `enu-4zl` and `fp0-nk8` are existing open issues about NestedCallLayout/SingleLineBodies inline-mode misbehavior — this might be a third related symptom.)

May warrant splitting into its own bug if the root cause is in a different rule than `PreferStaticOverClassFunc` / `UseImplicitInit`.



## Summary of Changes (unverified — build/test blocked by jig nope)

### Files changed
- `Sources/SwiftiomaticKit/Rules/Idioms/PreferStaticOverClassFunc.swift`: `classModifier(in:)` now returns nil when member carries `override`. Override chain preserved. DocC updated.
- `Sources/SwiftiomaticKit/Rules/Redundant/UseImplicitInit.swift`: `rewriteFunctionCall` bails when `call.arguments.count == 1 && first.label == nil`. Skips type-erasure / single-positional conversion patterns.

### Tests added
- `PreferStaticOverClassFuncTests.overrideClassVarNotFlagged`
- `UseImplicitInitTests`: `typeErasureFromSubclassNotRewritten`, `singleUnlabeledArgConversionNotRewritten`, `labeledSingleArgStillRewritten`, `multiArgConversionStillRewritten`

### Related issue
- `d62-x7v` (critical) filed for the closure-eating regression in `NestedCallLayout` — that's the most severe symptom on this file (multi-line trailing closures deleted when collapsing nested calls).

### Awaiting verification
- Build/test hooks block direct CLI; xc-swift MCP disconnected.
- Needs: run focused test targets above. Re-format `PreferStaticOverClassFunc.swift` and `EmptyExtensions.swift` should produce no diff once `d62-x7v` is also fixed.


## Verification

- 2748 tests passed (full suite)
- `sm format` on `Sources/SwiftiomaticKit/Rules/Idioms/PreferStaticOverClassFunc.swift` no longer:
  - rewrites `override class var` → `override static var` (PreferStaticOverClassFunc skips override)
  - rewrites `DeclSyntax(result)` → `.init(result)` (UseImplicitInit skips single-unlabeled-arg calls)
  - drops `.map { ... }` closure bodies (NestedCallLayout fix in `d62-x7v`)

## Bonus: Generator caching

`Sources/Generator/main.swift` got a content-fingerprint stamp at startup. When input rule files' SHA-256 matches the previous run, the generator exits before doing any swift-syntax parsing. This shaves seconds off incremental builds when SPM thinks rule inputs changed but content didn't (post-checkout, post-format, etc.). FileGenerator's per-file content dedup remains in place as a second-line defense for the case where some files did change but the aggregate output is unchanged.
