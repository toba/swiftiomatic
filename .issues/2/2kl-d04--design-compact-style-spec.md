---
# 2kl-d04
title: Design `compact` style spec
status: completed
type: task
priority: high
created_at: 2026-04-28T01:40:43Z
updated_at: 2026-04-28T02:10:14Z
parent: iv7-r5g
blocked_by:
    - kl0-8b8
sync:
    github:
        issue_number: "486"
        synced_at: "2026-04-28T02:40:02Z"
---

## Goal

Produce the exhaustive specification for the `compact` style — the only style `iv7-r5g` ships.

## Contents

- Every syntactic normalization the style performs (drawn from the node-local + structural buckets in the inventory).
- Every layout parameter value: `lineLength`, indentation, tab width, break-precedence preferences, blank-line policy, semicolon policy, etc.
- How today's per-rule sub-configs (`orderedImports`, `fileScopedDeclarationPrivacy`, `noPlaygroundLiterals`, etc.) collapse: style-internal constants vs. universal parameters exposed at the top level.
- Examples: input → `compact` output snippets for the trickier cases (member-access wraps, guard/if conditions, switch `where` indentation).

Blocks: spike, configuration redesign, cutover.


## Specification

### 1. Layout parameters

Universal — exposed as top-level config keys, applicable to every style:

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `lineLength` | Int | 100 | Hard wrap target. Pretty printer breaks before exceeding. |
| `indentation` | `.spaces(N)` \| `.tabs(N)` | `.spaces(4)` | Single unit. |
| `tabWidth` | Int | 8 | Tab→space width for column accounting only. |
| `respectsExistingLineBreaks` | Bool | true | Honour discretionary `\n` from input. |
| `lineEnding` | `.lf` \| `.crlf` | `.lf` | File EOL. |
| `maximumBlankLines` | Int | 1 | Cap on consecutive blank lines. |

`compact`-internal — fixed by the style, not exposed:

| Parameter | Value | Rationale |
|---|---|---|
| break-precedence order | `&&`/`||` > `.` > inner-op > `=` / keyword | See CLAUDE.md "Break Precedence". |
| trailing-comma behaviour | `keptAsWritten` | Author intent wins; printer doesn't churn commas. |
| blank-line-between-scopes | exactly 1 | Single blank between top-level decls/types. |
| blank-line-after-imports | 1 | One blank then code. |
| blank-line-after-guard | 1 when followed by stmt | Visual separation. |
| switch case spacing | uniform across switch | Majority-vote consistency. |
| switch-case `where` indent | indent past `case` keyword (per `7bp-yok`). |
| `else`/`catch` placement | same line as `}` | One-line `} else {`. |
| keep-function-output-together | true | `-> R` stays with signature. |
| indent conditional compilation blocks | true | `#if` body indents. |
| indent blank lines | false | Empty lines have zero columns. |
| spaces around range operators | false | `0..<n` not `0 ..< n`. |
| spaces before EOL comments | 2 | `code  // comment`. |

### 2. Syntactic normalizations

Applied in stage 1 (single combined `SyntaxRewriter` walk) — all 122 node-local rules from `kl0-8b8`. Style decides which fire, parameters become style-internal constants.

Applied in stage 2 (separate ordered passes) — 13 structural rules:

1. `SortImports` — group-and-sort imports.
2. `BlankLinesAfterImports` — blank line policy after import block.
3. `FileScopedDeclarationPrivacy` — file-scope `private`/`fileprivate` choice. `compact` uses `private`.
4. `ExtensionAccessLevel` — hoist common ACL onto `extension`; remove redundant per-member ACL.
5. `PreferFinalClasses` — needs file-wide subclass detection.
6. `ConvertRegularCommentToDocC` — needs decl-vs-statement context.
7. `BlankLinesBetweenScopes` — runs after scope additions/removals settle.
8. `ConsistentSwitchCaseSpacing` — majority vote per switch.
9. `SortDeclarations` — sort within `// MARK:`-bracketed regions.
10. `SortSwitchCases` — sort within a switch.
11. `SortTypeAliases` — sort adjacent typealias decls.
12. `FileHeader` — file-level comment normalization.
13. `ReflowComments` — coupled to layout column, runs after structural settles.

Order matters: import sort → import blanks → file-scope ACL → extension ACL → others → blank-line policies → comment reflow.

### 3. Today's per-rule sub-configs — disposition

| Sub-config | Disposition under `compact` |
|---|---|
| `orderedImports.groupByKind` | Style-internal: `true`. Imports group by kind (testable, _exported, regular). |
| `orderedImports.priorityList` | Style-internal: empty (alphabetical within kind). |
| `fileScopedDeclarationPrivacy.accessLevel` | Style-internal: `.private`. |
| `noPlaygroundLiterals.UIColor` | Folded — rule is deletable for `compact` (not part of style). |
| `multilineTrailingCommaBehavior` | Style-internal: `.keptAsWritten`. |
| `lineBreakAroundMultilineExpressionChainComponents` | Style-internal: `true` (matches today's break precedence). |
| `lineBreakBeforeEachArgument` | Style-internal: `false` (compact prefers single-line args when fitting). |
| `lineBreakBeforeEachGenericRequirement` | Style-internal: `false`. |
| `lineBreakBeforeControlFlowKeywords` | Style-internal: `false` (`} else {`, `} catch {`). |
| `prioritizeKeepingFunctionOutputTogether` | Style-internal: `true`. |
| `indentConditionalCompilationBlocks` | Style-internal: `true`. |
| `respectsExistingLineBreaks` | **Universal** parameter (exposed). |
| `lineLength` | **Universal** parameter (exposed). |
| `indentation` / `tabWidth` | **Universal** parameter (exposed). |
| `maximumBlankLines` | **Universal** parameter (exposed). |
| Metrics rules' thresholds (`fileLength`, `nestingDepth`, etc.) | Lint-only — keep as today's per-rule values; tri-state severity. |

Rule of thumb: a knob that authors might genuinely want to vary (line length, indentation, line endings) stays universal. A knob that defines what "compact" *means* becomes style-internal — choosing it differently is choosing a different style.

### 4. Lint configuration shape

Lints stay discrete — `LintPipeline` already does single-walk. Replace today's `rules: [String: Bool]` with a lint-only map keyed by group:

```jsonc
{
  "$schema": "...",
  "version": 7,
  "style": "compact",
  "lineLength": 100,
  "indentation": { "spaces": 4 },
  "tabWidth": 8,
  "respectsExistingLineBreaks": true,
  "maximumBlankLines": 1,
  "lints": {
    "naming": { "AlwaysUseLowerCamelCase": "error", "AvoidNoneName": "warn" },
    "redundancies": { "RedundantSelf": "off" },
    "metrics": {
      "FileLength": { "severity": "warn", "max": 400 },
      "NestingDepth": { "severity": "warn", "max": 5 }
    }
  }
}
```

Severity is tri-state `off | warn | error` (folds the old `enabled: Bool` and severity into one knob). The bare-string form is preferred; the nested `{ severity, ... }` form supports rules with extra config (metrics thresholds, etc.).

### 5. Migration of existing `swiftiomatic.json`

- Detect old-shape config (presence of top-level `rules: { ... }` or per-rule sub-config groups for format rules). Emit a one-time deprecation warning identifying the unsupported keys.
- Map the old config onto `style: compact` plus the universal parameters (preserving `lineLength`, `indentation`, etc., where present).
- Drop format-rule toggles silently (they no longer exist as a configuration surface).
- Lint-rule toggles in old `rules: { ... }` migrate to the new `lints` shape; unknown keys produce a warning, not an error.
- Bump configuration `version` from 6 → 7. `version < 7` triggers the migration path; `version >= 7` requires the new shape.

### 6. CLI surface

Additive only — preserves swift-format contract per CLAUDE.md.

```
sm format --style compact <files>
sm lint --style compact <files>
sm analyze --style compact <files>
sm dump-configuration              # emits new shape
sm dump-configuration --style compact
```

`--style` defaults to `compact`. `--style roomy` → not-yet-implemented error (per `0ev-1u9`).

### 7. Examples

#### 7.1 Function output kept together

**Input:**
```swift
func transform(_ value: SomeReallyLongInputType, with options: ConfigurationOptions) -> SomeReallyLongResultType { ... }
```

**`compact` output (lineLength 100):**
```swift
func transform(_ value: SomeReallyLongInputType, with options: ConfigurationOptions)
    -> SomeReallyLongResultType
{
    ...
}
```

The `-> R` clause prefers to wrap as a unit; the open brace moves to its own line only when the signature itself wraps.

#### 7.2 Member-access chain (break precedence)

**Input:**
```swift
let result = collection.filter { $0.isValid }.map(transform).reduce(into: [:]) { acc, x in acc[x.key] = x }
```

**`compact` output:**
```swift
let result =
    collection
        .filter { $0.isValid }
        .map(transform)
        .reduce(into: [:]) { acc, x in acc[x.key] = x }
```

The contextual `.` breaks fire before the `=` break — assignment yields to chain segmentation.

#### 7.3 Guard with multiple conditions

**Input:**
```swift
guard let user = try? loadUser(), user.isActive, user.permissions.contains(.read) else { return }
```

**`compact` output:**
```swift
guard
    let user = try? loadUser(),
    user.isActive,
    user.permissions.contains(.read)
else { return }
```

`BeforeGuardConditions` keyword break is *last resort* — fires only when the guard exceeds `lineLength`. Single-condition guards stay inline.

#### 7.4 Switch case `where` indent

**Input:**
```swift
switch x {
case .foo where condition: ...
}
```

**`compact` output:**
```swift
switch x {
case .foo
        where condition:
    ...
}
```

`where` indents past `case` (per fix `7bp-yok`) when the case wraps.

#### 7.5 Else on same line

**Input:**
```swift
if condition {
    a()
}
else {
    b()
}
```

**`compact` output:**
```swift
if condition {
    a()
} else {
    b()
}
```

### 8. Open Questions Resolved

- **`compact` defined as data or code?** Code. Per-node logic is non-uniform; a struct of flags would either be a constants file or balloon to a DSL. A dedicated `CompactStyleRewriter` type is honest about that.
- **Daemon mode / lint reorganization** — out of scope, deferred.
- **`list-rules`** → `list-findings` (lint catalog only). Format rules are no longer publicly enumerable.

## Summary of Changes

- Specified `compact` style: 6 universal parameters, 14+ style-internal constants, 122 node-local normalizations (stage 1), 13 structural passes (stage 2 ordered).
- Defined lint config shape with tri-state severity grouped by rule directory.
- Defined migration path from configuration version 6 → 7.
- Captured 5 trickier-case examples (function output, member chains, guards, switch where, else placement).
- Decided `compact` lives as code (`CompactStyleRewriter`), not as data.
