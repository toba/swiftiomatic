---
# xfy-in1
title: 'Phase 5: Scope analysis'
status: completed
type: task
priority: normal
created_at: 2026-04-14T18:37:00Z
updated_at: 2026-04-14T22:00:41Z
parent: c7r-77o
sync:
    github:
        issue_number: "303"
        synced_at: "2026-04-14T18:45:53Z"
---

- [x] `redundantSelf` — Insert/remove explicit `self` (configurable). Requires scope analysis for variable shadowing and closure capture. Most complex rule in nicklockwood/SwiftFormat (~800 lines). Conservative subset (SE-0269 cases) is feasible first step. Parent: nnl-svw.


## Summary of Changes

Implemented `RedundantSelf` as a `SyntaxFormatRule` that removes redundant `self.` prefixes. Conservative first implementation covering:

**Removes `self.` when:**
- Inside type bodies (struct/class/enum/actor/extension) in methods, inits, computed properties, property accessors
- The member name is not shadowed by a local variable, parameter, nested function, for-in variable, or catch binding
- Implicit self is allowed in the current scope

**Closure handling (SE-0269/SE-0365):**
- Value types (struct/enum): closures always allow implicit self
- Reference types (class/actor): only with `[self]` or `[unowned self]` capture
- `[weak self]` closures: conservatively keeps `self.` (guard let self detection deferred)
- Extensions: treated as reference types (conservative)

**Property accessor handling:**
- Shorthand getters (`var foo: Int { return self.bar }`)
- Explicit get/set/willSet/didSet with implicit variable names (newValue/oldValue)
- Property name treated as local in own getter/setter (prevents infinite recursion)

**Edge cases handled:**
- `self.init()` never removed (delegating initializer)
- Lazy var in class: keeps `self.` (closure semantics)
- Lazy var in struct: removes `self.` (value type)
- Nested types maintain independent scopes
- Catch clause implicit `error` variable tracked

48 tests adapted from SwiftFormat reference test suite.
