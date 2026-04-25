---
# 6rg-85v
title: PreferStaticOverClassFunc + formatTypePrefix break the rule's own source file
status: ready
type: bug
priority: normal
created_at: 2026-04-25T19:39:11Z
updated_at: 2026-04-25T19:44:35Z
sync:
    github:
        issue_number: "411"
        synced_at: "2026-04-25T19:53:35Z"
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

- [ ] Decide: should PreferStaticOverClassFunc skip `override` modifiers? (Likely yes.)
- [ ] Decide: should formatTypePrefix only fire when the constructed type matches the declared/inferred context type? (Likely yes — the current rule fires for type-erasure conversions which loses information.)
- [ ] Add tests for both edge cases
- [ ] Verify the formatted output actually compiles



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
