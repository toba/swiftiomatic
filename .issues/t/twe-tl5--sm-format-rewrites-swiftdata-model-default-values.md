---
# twe-tl5
title: sm format rewrites SwiftData @Model default values to leading-dot shorthand, breaking the build
status: completed
type: bug
priority: high
created_at: 2026-08-02T17:43:51Z
updated_at: 2026-08-02T17:47:55Z
sync:
    github:
        issue_number: "761"
        synced_at: "2026-08-02T17:49:08Z"
---

## Problem

`sm format -i` rewrites fully-qualified default-value expressions on SwiftData `@Model` stored properties into leading-dot shorthand. The SwiftData `@Model` macro **rejects** the shorthand form, so a previously-compiling model tree stops building after a format pass.

Compiler error emitted for each affected property:

```
error: A default value requires a fully qualified domain named value (from macro 'Model')
```

## Reproduction

Given a compiling model:

```swift
@Model
public final class Issue {
    public var id: UUID = UUID()
    public var status: MessageStatus = MessageStatus.open
    public var priority: Priority = Priority.normal
    public var createdAt: Date = Date.now
}
```

`sm format -i` rewrites the defaults to:

```swift
@Model
public final class Issue {
    public var id: UUID = .init()
    public var status: MessageStatus = .open
    public var priority: Priority = .normal
    public var createdAt: Date = .now
}
```

Every one of these now fails to compile under the `@Model` macro.

## Affected transformations observed

- `UUID()` → `.init()`
- `Date.now` → `.now`
- `SomeEnum.someCase` → `.someCase` (e.g. `MessageStatus.open` → `.open`, `Priority.normal` → `.normal`, `LinkType.url` → `.url`, `TaskStatus.ready` → `.ready`, `RelationType.relatesTo` → `.relatesTo`)

Observed in the `toba/todo` project (a SwiftData port): a single `sm format -i -r Sources` broke all 10 `@Model` files. Every stored-property default with an initializer expression was affected; had to hand-revert each to the fully-qualified form to restore the build.

## Why it happens

The `@Model` macro expands stored-property defaults into `Schema.PropertyMetadata(..., defaultValue: <expr>, ...)` where `<expr>` is lifted out of the property's declared-type context. Leading-dot member syntax relies on that type context to resolve; once lifted into the metadata call the base type is `Any?`, so `.open` / `.normal` / `.init()` no longer resolve. Fully-qualified values (`MessageStatus.open`, `UUID()`, `Date.now`) survive the lift.

## Suggested fix

The dot-shorthand / redundant-type-name simplification rule must **not** fire on default-value expressions of stored properties inside a type annotated with `@Model` (and likely other macro-attached types that lift initializer expressions — worth checking `@Observable` / peer macros too).

Options:
1. Detect the `@Model` attribute on the enclosing class and skip the shorthand rewrite for its stored-property initializers.
2. More conservatively, never rewrite a `Type = Type.member` / `Type = Type()` initializer to leading-dot when the property has an explicit type annotation and the enclosing decl carries any attached macro attribute.

## Impact

High for any SwiftData project using swiftiomatic: `sm format` produces a non-compiling tree, and the failure is silent until the next build. Anyone wiring `sm format` into a pre-commit hook or the `/swift` review skill (which runs `sm format -i` as step 1) will hit it.

## Summary of Changes

**Root cause:** `UseImplicitInit` (`Sources/SwiftiomaticKit/Rules/Redundancies/UseImplicitInit.swift`) rewrote stored-property default-value initializers to leading-dot shorthand regardless of the enclosing type. Inside a SwiftData `@Model` class the macro lifts those defaults into a `Schema.PropertyMetadata(defaultValue:)` call where the declared-type context is lost, so `.open` / `.init()` / `.now` no longer resolve and the model stops compiling.

**Fix:** Guarded **Case 1** (stored property with type annotation + initializer) with a new `isInModelType(parent:)` check. It walks the captured pre-recursion parent chain to the nearest enclosing type declaration (class/struct/actor/enum/extension) and returns `true` only if that type carries `@Model`. When it does, the initializer is left fully qualified.

Scope is deliberately narrow (Option 1 from the issue):
- Only stored-property initializers are skipped — the contexts the `@Model` macro actually lifts.
- Computed-property bodies and default parameter values inside a `@Model` class are **not** lifted by the macro, so they still get shorthand (covered by a regression test).
- Non-`@Model` types are entirely unaffected.

**Tests** (`Tests/SwiftiomaticTests/Rules/UseImplicitInitTests.swift`):
- `modelStoredPropertyDefaultsPreserved` — the exact repro (`UUID()`, `MessageStatus.open`, `Priority.normal`, `Date.now`) left untouched.
- `modelNonLiftedContextsStillRewritten` — computed body + default param inside `@Model` still shortened.
- `nonModelStoredPropertyStillRewritten` — plain class still shortened.

**Verification:** filtered suite 26/26; full suite 3506/3506, no regressions.
