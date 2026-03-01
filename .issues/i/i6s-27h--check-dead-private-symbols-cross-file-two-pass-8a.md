---
# i6s-27h
title: 'Check: Dead private symbols — cross-file two-pass (§8a)'
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:35:28Z
updated_at: 2026-02-27T21:55:08Z
parent: 52u-0w0
blocked_by:
    - w7e-hbx
sync:
    github:
        issue_number: "100"
        synced_at: "2026-03-01T01:41:12Z"
---

Two-pass SyntaxVisitor that definitively identifies dead private symbols.

## Why AST is essential here
The grep scanner has ~15% false positive rate because it can't distinguish:
- A declaration from a reference (grep counts both as "matches")
- Protocol witnesses (private func that satisfies a protocol requirement)
- @objc exposed methods (called from Obj-C runtime, never referenced in Swift)
- KVC/KVO key paths (referenced dynamically)

## Pass 1: Collect declarations (`DeclarationCollector`)
- [ ] Visit all `private func`, `private static func`, `private var`, `private let`, `private class/struct/enum`
- [ ] Record: name, file, line, kind (func/var/type), containing type (for scoping)
- [ ] Exclude: `@objc` annotated, `override` methods, `init`/`deinit`, names containing "test"
- [ ] Store in a cross-file symbol table keyed by name

## Pass 2: Collect references (`ReferenceCollector`)
- [ ] Visit all `DeclReferenceExprSyntax` (identifier references)
- [ ] Visit all `MemberAccessExprSyntax` (dot-accessed members)
- [ ] Visit `StringLiteralExprSyntax` containing `#keyPath` or `#selector` (KVC/Obj-C references)
- [ ] For each reference, look up in the symbol table and increment reference count

## Final analysis
- [ ] Symbols with reference count = 0 (only the declaration) → dead code, confidence: high
- [ ] Symbols with reference count = 1 but the reference is in a default argument → likely dead, confidence: medium
- [ ] Exclude symbols matching common false positive patterns: generic names < 4 chars, protocol conformance witnesses (private func matching a protocol method name)

## Performance
- Must handle modules with 500+ private symbols efficiently
- Symbol table should be a dictionary, not a linear scan
- The grep scanner caps at 50 names; AST version should handle all symbols

## Confidence levels
- Zero references outside declaration → high
- Only referenced in default arguments → medium
- Referenced but private to file and never called → high

## Summary of Changes
- Two-pass dead symbol detection: DeclarationCollector (pass 1) + DeadSymbolsCheck (pass 2)
- Thread-safe SymbolTable using Mutex
- Excludes @objc, override, init/deinit, test methods, short names
- Fixed false positive where same-file references were being skipped
