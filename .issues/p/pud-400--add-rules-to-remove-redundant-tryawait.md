---
# pud-400
title: Research adding DropRedundantTry / DropRedundantAwait rules
status: draft
type: task
priority: low
created_at: 2026-05-01T21:25:06Z
updated_at: 2026-05-01T21:32:55Z
sync:
    github:
        issue_number: "612"
        synced_at: "2026-05-01T21:40:14Z"
---

Xcode flags `try` (and `await`) on call sites that don't actually throw (or suspend) — e.g. `fields = try ReferenceFields(from: json, with: configuration)` produces "No calls to throwing functions occur within 'try' expression." These are common after refactors and are tedious to clean up by hand.

## Background

Swiftiomatic has adapted rules from both **Nick Lockwood's SwiftFormat** and **SwiftLint**, and the `Sources/SwiftiomaticKit/Rules/Redundancies/` directory already contains many sibling rules: `DropRedundantThrows`, `DropRedundantAsync`, `DropRedundantTypedThrows`, `DropRedundantSendable`, `DropRedundantEscaping`, etc. The two missing companions are `DropRedundantTry` and `DropRedundantAwait` — Nick's SwiftFormat has both as `redundantTry` / `redundantAwait`.

## Why this might be a big refactor (not a quick adopt)

The sibling rules in `Redundancies/` mostly work by looking at *declarations* — e.g. `DropRedundantThrows` removes `throws` from a function whose body provably never throws, which is computable from the AST by walking the function body for `try`, `throw`, throwing calls. Symmetric.

`DropRedundantTry` is the *opposite* direction and is much harder syntactically:

- For `try expr`, we need to know whether `expr` (often a function call or initializer) is declared `throws`. That's a **lookup question**, not a syntactic one. Apple swift-syntax has no symbol resolution.
- Nick Lockwood's SwiftFormat sidesteps this by maintaining its own lightweight type/scope tracker over the file (`Formatter` + `declaredType` / `isThrowing` heuristics across the whole file), looking at all `func ... throws` decls in scope and matching call sites against them. It's heuristic and acknowledges false positives — it errs on the side of leaving `try` in when uncertain.
- We'd need either: (a) port that file-scoped heuristic tracker (substantial — Nick's tracker is one of the larger pieces of his project), (b) integrate SourceKit / swift-syntax `LookupResult` for real symbol resolution (cleaner but adds a build dep on the toolchain at lint time), or (c) ship a very narrow version that only handles obviously non-throwing forms (literals, plain identifiers, etc.) — limited utility.

`DropRedundantAwait` has the same problem for `async` calls.

## Action

Research task — not a fix. Decide:

1. Read Nick's `RedundantTry.swift` / `RedundantAwait.swift` to gauge the size of the heuristic tracker.
2. Look at our existing `Redundancies/` rules to see if any of them already do file-scoped declaration scanning we could reuse.
3. Evaluate the SourceKit / `swift-syntax` `Lookup` route as an alternative.
4. Write up findings; decide whether to ship narrow / heuristic / SourceKit version, or close.

## References

- Nick Lockwood SwiftFormat `redundantTry`: https://github.com/nicklockwood/SwiftFormat/blob/main/Sources/Rules/RedundantTry.swift
- Nick Lockwood SwiftFormat `redundantAwait`: https://github.com/nicklockwood/SwiftFormat/blob/main/Sources/Rules/RedundantAwait.swift
- Compiler warning: "No calls to throwing functions occur within 'try' expression"



## Research findings

### Nick's SwiftFormat — does NOT have these rules

Reviewed `~/Developer/swiftiomatic-ref/SwiftFormat/Sources/Rules/`. Nick has:

- `RedundantThrows.swift` — removes `throws` from a **function declaration** whose body never `throw`s or `try`s. Same direction (and same scope) as our existing `DropRedundantThrows`.
- `RedundantAsync.swift` — same for `async`. We have `DropRedundantAsync`.
- `HoistTry.swift` / `HoistAwait.swift` — moves `try`/`await` to outer expression. Different rule, not redundancy removal.

**Nick has no `RedundantTry` or `RedundantAwait` rule.** My initial assumption was wrong.

### SwiftLint — also does NOT have one

Reviewed `~/Developer/swiftiomatic-ref/SwiftLint/Source/SwiftLintBuiltInRules/Rules/`. Has `UnneededThrowsRule` (declaration-level, same direction as ours), `AsyncWithoutAwaitRule`, `ForceTryRule`. None removes `try`/`await` at the call site.

### Why nobody has done it

Removing a redundant `try` at a call site needs to know whether the **callee** throws. That's a symbol-resolution + signature-inspection question. swift-syntax alone can't answer it. The Swift compiler handles it trivially because it has a type-checked AST; pure-syntax tools don't.

Nick's `RedundantThrows` is easy because it's declaration-local — walk the function's own body for `try`/`throw`. ~60 LOC. Our rule is ~61 LOC. Symmetric.

A call-site rule would need cross-decl analysis. Three real paths:

**A. Narrow syntactic-only.** Only handle obvious cases: `try` on a literal, on a non-call expression, etc. ~50 LOC, tiny utility — users wouldn't trust a rule that removes `try` keywords without strong evidence.

**B. `SwiftLexicalLookup`-based heuristic.** swift-syntax ships a `SwiftLexicalLookup` module (we don't currently depend on it; would need to add the product). It does lexical name resolution within a file: "what decls named `foo` are in scope at this position?" Could resolve each `try` expression's callee, find the matching decl(s), inspect for `throws` clause. Heuristic — no type-based overload resolution, no info on imported symbols — but would handle the common in-file / in-module case. Estimated: small new infrastructure (maybe 200-400 LOC) to thread lookup results into a rule, plus the rule itself.

**C. SourceKit-backed.** Shell out to `sourcekitd` for typed AST, consume its diagnostic. Most accurate. Major architectural change — requires toolchain at lint time, async, sandboxing concerns.

**D. Skip it.** Xcode's compiler-emitted warning + fixit already does this with full type info. A less-accurate Swiftiomatic version that deletes valid `try` keywords is *worse* than not having it.

### Recommendation

**D for now**, with **B** as a reasonable follow-up if demand surfaces. Reasoning:

1. The compiler warning the user saw in Xcode is the authoritative source — Xcode can apply the fixit directly.
2. swift-syntax-only correctness is genuinely hard here and the failure mode (silently deleting a needed `try`) is a correctness regression in user code, not a style nit.
3. Adding `SwiftLexicalLookup` is reasonable once we have a second rule that needs it — adopting it just for one heuristic rule is poor leverage.

If we do (B) someday, we should also use it to extend `DropRedundantThrows` (today it only inspects the function's own body — with lookup we could also see whether `try` calls inside the body actually call throwing functions, eliminating false negatives there).



## Decision: D — skip

Research complete. We are deliberately **not** implementing `DropRedundantTry` / `DropRedundantAwait` at this time:

- The Swift compiler already emits the warning ("No calls to throwing functions occur within 'try' expression") with full type info, and Xcode applies the fixit on demand. Users have a working solution today.
- A swift-syntax-only implementation would be heuristic and could silently delete a needed `try` keyword — a correctness regression in user code, strictly worse than no rule.
- Adding `SwiftLexicalLookup` infrastructure for one heuristic rule is poor leverage. Revisit only if a second rule independently needs lookup, at which point we should also use it to strengthen `DropRedundantThrows` (which today only inspects the declared function's own body).

Issue kept as a **draft** so the research stays discoverable if the question comes up again. Reopen if compiler-diagnostic-consumption (option C) becomes practical, or if a second SwiftLexicalLookup-using rule is proposed (option B becomes cheap).
