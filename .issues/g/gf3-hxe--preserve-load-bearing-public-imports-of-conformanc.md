---
# gf3-hxe
title: Preserve load-bearing public imports of conformance-only modules
status: scrapped
type: bug
priority: normal
tags:
    - enhancement
created_at: 2026-05-02T18:19:52Z
updated_at: 2026-05-02T18:29:43Z
sync:
    github:
        issue_number: "637"
        synced_at: "2026-05-02T18:52:15Z"
---

## Problem

The lint rule that downgrades `public import X` to `import X` when `X` isn't referenced in any public/inlinable declarations is unsafe for modules that exist solely to provide protocol conformances (notably `RegexBuilder`, which provides `String: RegexComponent`).

When module A has `public import RegexBuilder` and module B (depending on A) uses regex literals like `/foo/` or `String.matches(of:)`, B inherits the `String: RegexComponent` conformance descriptor at link time via A's re-export. Downgrading to plain `import` doesn't break A's compile (the conformance isn't named in A's public API signatures, so the rule's heuristic fires), but it breaks linking of every downstream module that relied on the transitive re-export.

Real-world hit in Thesis: swiftiomatic rewrote `Core/Sources/Extensions/String+replacing.swift` from `public import RegexBuilder` → `import RegexBuilder`. Build then failed with:

```
Undefined symbol 'protocol conformance descriptor for Swift.String : _StringProcessing.RegexComponent in RegexBuilder' (arm64) referenced from RegexBuilder in DecodeContext.o
```

…across BibTeX, CSL, and ThesisApp targets. The compiler's own warning ("Public import of 'RegexBuilder' was not used in public declarations or inlinable code") is the same heuristic — and Swift itself is wrong here for the same reason.

## Options

1. **Skip known conformance-only modules.** Maintain a small allowlist (`RegexBuilder`, possibly others like `_StringProcessing`) that are never downgraded.
2. **Add explicit imports downstream first.** Before downgrading `public import X` in module A, scan all modules that depend on A. For each downstream file using a feature provided by X (regex literals, `matches(of:)`, etc.), insert `import X` if missing. Only downgrade A once downstream is self-sufficient. This is the principled fix but requires cross-module awareness.
3. **Escape hatch.** Honor a `// sm:disable public-import` (or equivalent) trailing comment on the import line so users can pin a load-bearing public import.

## Recommendation

Ship #1 + #3 immediately (cheap, safe). #2 is the right long-term answer but needs a dependency graph.

## Reproduction

- Module A: `public import RegexBuilder`, no use of `Regex` in public/inlinable API.
- Module B (depends on A): file with `/pattern/` regex literal and `.matches(of:)`, no `import RegexBuilder`.
- Run swiftiomatic lint on A → import is downgraded.
- Build fails at link time on B.



## Reasons for Scrapping

1. **No such rule exists in Swiftiomatic.** A grep across `Sources/` for `public import` / `PublicImport` / `publicImport` finds no rule that downgrades `public import X` → `import X`. The Thesis rewrite that motivated this issue almost certainly came from Xcode applying the Swift compiler's own fix-it for its `public-import-not-used-in-api` warning, not from `sm`. There is nothing to fix on our side.

2. **Detection isn't feasible from a single-file AST.** Whether a `public import X` is load-bearing depends on what downstream modules pull through the re-export (e.g. conformance descriptors). Swiftiomatic operates per-file via swift-syntax with no build/dependency graph — it cannot see downstream consumers. The mitigations proposed (allowlist of conformance-only modules, `// sm:ignore` escape hatch) aren't detection; they're opt-outs, and they're only relevant if we ship the offending rule, which we haven't.

If a rule like this is ever proposed, this issue's analysis should inform its design — but until then there's no work to do.
