---
# uih-8nz
title: Prefer implicit member expression over explicit type in known-type context
status: completed
type: feature
priority: normal
created_at: 2026-04-24T18:36:48Z
updated_at: 2026-04-24T19:00:22Z
sync:
    github:
        issue_number: "375"
        synced_at: "2026-04-24T20:43:40Z"
---

When the return type is known from context (explicit type annotation, function return type, default parameter value, etc.), prefer implicit member syntax over repeating the type name.

## Examples

```swift
// static property with type annotation
static var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .no) }
// becomes
static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

// variable with type annotation
let value: Color = Color.red
// becomes
let value: Color = .red

// function return
func make() -> Config { return Config(debug: true) }
// becomes
func make() -> Config { return .init(debug: true) }

// default parameter value
func run(mode: Mode = Mode.fast) { }
// becomes
func run(mode: Mode = .fast) { }
```

## Scope

The rule should fire when:
- A variable/property has an explicit type annotation and the initializer repeats that type
- A computed property or function has a known return type and the body repeats it
- A default parameter value repeats the parameter type
- A static factory method (e.g. `Color.red`) repeats the type in context

The rule should NOT fire when:
- The type is not explicitly declared (inference needed)
- The expression is a nested subexpression where the type isn't contextually known
- Removing the type name would reduce clarity (e.g. long chains)

## Related rules

- `RedundantType` — removes redundant type *annotations* (`let x: Foo = Foo()` → `let x = Foo()`); this is the inverse: keeps the annotation, shortens the expression
- `RedundantInit` — removes `.init` from explicit type calls (`Foo.init()` → `Foo()`); this adds `.init` when dropping the type

These rules don't conflict — they target mutually exclusive cases. `RedundantType` fires on removable annotations (stored properties with obvious initializers). `PreferImplicitMember` fires where the annotation must stay (computed properties, return types, parameter defaults).

## Tasks

- [x] Create `UseImplicitInit` rule as `RewriteSyntaxRule<BasicRuleValue>`
- [x] Handle constructor calls: `Type(args)` → `.init(args)` when type matches context
- [x] Handle static member access: `Type.member` → `.member` when type matches context
- [x] Handle function return types, computed properties, default parameters
- [x] Add tests (19 tests)


## Summary of Changes

Created `UseImplicitInit` rule (`RewriteSyntaxRule<BasicRuleValue>`) in the redundancies group. Handles:
- Computed property getters with type annotation
- Stored properties with type annotation and initializer
- Function/method return types (single expression and explicit return)
- Subscript return types
- Default parameter values (via parent FunctionDecl/InitializerDecl visits)
- Static member access (`Type.member` → `.member`)
- Static factory calls (`Type.factory(args)` → `.factory(args)`)
- Generic type constructors (`Array<Int>()` → `.init()`)

Note: `SyntaxRewriter.visit(_ node: FunctionParameterSyntax)` was never dispatched by the rewriter, so default parameter handling is done from within the parent `FunctionDeclSyntax` and `InitializerDeclSyntax` visits.
