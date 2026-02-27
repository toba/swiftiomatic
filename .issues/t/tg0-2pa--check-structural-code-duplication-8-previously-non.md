---
# tg0-2pa
title: 'Check: Structural code duplication (§8 — previously non-greppable)'
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:36:12Z
updated_at: 2026-02-27T21:55:08Z
parent: 52u-0w0
blocked_by:
    - w7e-hbx
---

SyntaxVisitor that detects structural code duplication — the #1 gap grep cannot address.

## Why this was impossible with grep
Structural duplication means function bodies that are near-identical but with different variable names, types, or string literals. Grep can match identical text but cannot normalize variable names or compare structural similarity.

Example the grep scanner misses:
```swift
// These are structurally identical — same AST shape, different names
func loadUsers() throws {
    do {
        let data = try store.fetch("users")
        self.users = try decode(data)
    } catch {
        logger.error("Failed to load users: \(error)")
        throw LoadError.users(error)
    }
}

func loadPosts() throws {
    do {
        let data = try store.fetch("posts")
        self.posts = try decode(data)
    } catch {
        logger.error("Failed to load posts: \(error)")
        throw LoadError.posts(error)
    }
}
```

## Implementation approach

### AST fingerprinting
- [ ] For each function body, compute a structural fingerprint by walking the AST and recording node types in sequence, ignoring:
  - Identifier names (variable names, function names)
  - String literal values
  - Numeric literal values
  - Comments and trivia
- [ ] The fingerprint captures the *shape*: "VarDecl, TryExpr, FunctionCall, AssignExpr, CatchClause, FunctionCall, ThrowStmt"
- [ ] Functions with identical fingerprints → structural duplicates

### Similarity scoring
- [ ] Exact fingerprint match → confidence high
- [ ] Fingerprints differing by ≤ 2 nodes → confidence medium (near-duplicate)
- [ ] Use Levenshtein distance on fingerprint sequences for fuzzy matching
- [ ] Minimum function body size: 5 AST nodes (skip trivial getters/setters)

### Pattern detection (specific patterns from swift-review skill)
- [ ] **Repeated `do/catch` with same shape** — 3+ do/catch blocks with identical catch clause structure
- [ ] **Start/succeed/fail state machine** — functions containing `.pending`/`.inProgress`/`.completed`/`.failed` state transitions with identical flow
- [ ] **CRUD operations** — `func create/read/update/delete` with identical body shapes

### Cross-file analysis
- [ ] Collect fingerprints from all files in pass 1
- [ ] Compare fingerprints in pass 2 — flag groups of 3+ matches
- [ ] Report: "Functions X, Y, Z in files A, B, C have identical structure — consider extracting a generic helper"

## AST nodes to visit
- `FunctionDeclSyntax` — collect body for fingerprinting
- All child nodes — recorded as fingerprint tokens (type only, no values)
- `DoStmtSyntax` / `CatchClauseSyntax` — specific pattern detection

## Confidence levels
- 3+ functions with identical fingerprint → high
- 2 functions with identical fingerprint → medium
- Near-identical (Levenshtein ≤ 2) → medium
- Similar do/catch structure → medium

## Summary of Changes
- StructuralDuplicationCheck with AST fingerprinting
- FingerprintVisitor records structural node types, ignoring names/literals
- Cross-file comparison finds 2+ functions with identical structure
