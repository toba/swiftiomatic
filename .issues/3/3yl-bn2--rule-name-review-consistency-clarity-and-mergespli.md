---
# 3yl-bn2
title: 'Rule name review: consistency, clarity, and merge/split candidates'
status: completed
type: task
priority: normal
created_at: 2026-04-14T23:01:42Z
updated_at: 2026-04-14T23:57:16Z
sync:
    github:
        issue_number: "309"
        synced_at: "2026-04-15T00:34:43Z"
---

Review of all ~120 rule names for consistency in grammar, clarity of meaning, and whether rules should be merged or split.

## Naming Convention Inconsistencies

### 1. Four different prohibition prefixes

Rules that prohibit something use four different patterns:

| Prefix | Count | Examples |
|--------|-------|---------|
| `No` | 12 | `NoBlockComments`, `NoParensAroundConditions`, `NoLabelsInCasePatterns` |
| `Never` | 3 | `NeverForceUnwrap`, `NeverUseForceTry`, `NeverUseImplicitlyUnwrappedOptionals` |
| `DoNot` | 1 | `DoNotUseSemicolons` |
| `Dont` | 1 | `DontRepeatTypeInStaticProperties` |
| `Avoid` | 1 | `AvoidRetroactiveConformances` |

**Recommendation:** Standardize on `No` — it's the most concise and already the most common.

- [ ] `NeverForceUnwrap` → `NoForceUnwrap`
- [ ] `NeverUseForceTry` → `NoForceTry`
- [ ] `NeverUseImplicitlyUnwrappedOptionals` → `NoImplicitlyUnwrappedOptionals`
- [ ] `DoNotUseSemicolons` → `NoSemicolons`
- [ ] `DontRepeatTypeInStaticProperties` → `NoTypeRepetitionInStaticProperties`
- [ ] `AvoidRetroactiveConformances` → `NoRetroactiveConformances`

### 2. `Use` vs `Prefer` overlap

Both prefixes mean "do this instead of that" with no clear semantic boundary:

| Prefix | Count | Examples |
|--------|-------|---------|
| `Use` | 8 | `UseEarlyExits`, `UseShorthandTypeNames`, `UseTripleSlashForDocumentationComments` |
| `Prefer` | 5 | `PreferCountWhere`, `PreferFinalClasses`, `PreferKeyPath`, `PreferSwiftTesting` |

**Recommendation:** Pick one. `Prefer` works for soft suggestions; `Use` for strict enforcement. Or just use `Prefer` everywhere — rules are always preferences, never law.

### 3. Redundant `Always` prefix

- `AlwaysUseLiteralForEmptyCollectionInit`
- `AlwaysUseLowerCamelCase`

The "Always" is implied — every rule always applies. Drop it.

### 4. `Sort` vs `Ordered`

- `SortDeclarations`, `SortSwitchCases`, `SortTypealiases` (imperative verb)
- `OrderedImports` (past-participle adjective)

**Recommendation:** Standardize on one form. `SortImports` or `OrderedDeclarations`.

### 5. Singular vs plural `BlankLine(s)`

- Singular: `BlankLineAfterImports`, `BlankLineAfterSwitchCase`
- Plural: `BlankLinesAfterGuardStatements`, `BlankLinesAroundMark`, `BlankLinesBetweenScopes`, etc.

**Recommendation:** Use plural consistently — some rules manage multiple blank lines.

## Ambiguous or Unclear Names

Names that don't convey what the rule does without reading the source:

| Rule | Problem | What it actually does | Suggestion |
|------|---------|----------------------|------------|
| `AssertionFailures` | Sounds like it detects failures | Replaces `assert(false)` with `assertionFailure()` | `PreferAssertionFailure` |
| `Acronyms` | Too vague | Capitalizes acronyms (URL, JSON, etc.) when context is uppercase | `CapitalizeAcronyms` |
| `IsEmpty` | Sounds like an emptiness check | Enforces `.isEmpty` over `.count == 0` | `PreferIsEmpty` |
| `Todos` | Sounds like it manages TODOs | Formats `TODO:`/`MARK:`/`FIXME:` comment syntax | `FormatSpecialComments` |
| `StrongifiedSelf` | Jargon | Removes backticks from `self` in optional binding | `NoBacktickedSelf` |
| `ApplicationMain` | What about it? | Replaces `@UIApplicationMain`/`@NSApplicationMain` with `@main` | `PreferMainAttribute` |
| `EnvironmentEntry` | What about it? | Replaces `EnvironmentKey` boilerplate with `@Entry` | `PreferEnvironmentEntry` |
| `FileMacro` | What about it? | Standardizes `#file` → `#fileID` | `PreferFileID` |
| `ConditionalAssignment` | Vague | Uses if/switch expression assignment (SE-0380) | `PreferConditionalExpression` |
| `AndOperator` | What about `&&`? | Replaces `&&` with comma in condition lists | `PreferCommaConditions` |
| `AnyObjectProtocol` | What about it? | Replaces `class` constraint with `AnyObject` | `PreferAnyObject` |
| `GenericExtensions` | Vague | Uses angle-bracket syntax for generic extensions | `PreferAngleBracketExtensions` |
| `TrailingClosures` | Does what? | Converts eligible closure args to trailing position | `PreferTrailingClosures` |
| `LeadingDelimiters` | Unclear | Moves `.`, `?`, `!` to the beginning of wrapped lines | `LeadingDotOperators` |
| `YodaConditions` | Named after the anti-pattern; ambiguous if it enforces or bans | Bans yoda conditions (`0 == x` → `x == 0`) | `NoYodaConditions` |

## Overly Verbose Names

Sentence-like names that could be shortened:

| Current | Suggested |
|---------|-----------|
| `AllPublicDeclarationsHaveDocumentation` | `DocumentPublicDeclarations` |
| `BeginDocumentationCommentWithOneLineSummary` | `DocCommentSummary` |
| `TypeNamesShouldBeCapitalized` | `CapitalizedTypeNames` |
| `IdentifiersMustBeASCII` | `ASCIIIdentifiers` |
| `AlwaysUseLiteralForEmptyCollectionInit` | `EmptyCollectionLiteral` |
| `NoAccessLevelOnExtensionDeclaration` | `NoExtensionAccessLevel` |
| `UseExplicitNilCheckInConditions` | `ExplicitNilCheck` |
| `UseTripleSlashForDocumentationComments` | `TripleSlashDocComments` |
| `UseLetInEveryBoundCaseVariable` | `PatternLetPlacement` |
| `ReturnVoidInsteadOfEmptyTuple` | `PreferVoidReturn` |
| `NoEmptyTrailingClosureParentheses` | `NoTrailingClosureParens` |
| `NoCasesWithOnlyFallthrough` | `NoFallthroughOnlyCases` |
| `OneVariableDeclarationPerLine` | `OneVariablePerLine` |
| `WrapMultilineConditionalAssignment` | `WrapConditionalAssignment` |

## File/Class Name Mismatch

`NoEmptyLineOpeningClosingBraces.swift` contains class `NoEmptyLinesOpeningClosingBraces` — file says singular "Line", class says plural "Lines". These must match.

## Merge Candidates

### Force unwrap/try rules (2 pairs → 2 rules)

- `NeverForceUnwrap` + `NoForceUnwrapInTests` — same concept (force unwraps are bad), different contexts. The production rule is lint-only; the test rule auto-fixes. A single rule could lint in production and fix in tests.
- `NeverUseForceTry` + `NoForceTryInTests` — identical pattern.

### Access control redundancy (4 → 1)

- `RedundantInternal` + `RedundantPublic` + `RedundantExtensionACL` + `RedundantFileprivate`
- All remove redundant access control modifiers. Could be `RedundantAccessControl`.

### Wrap body rules (4 → 1)

- `WrapConditionalBodies` + `WrapFunctionBodies` + `WrapLoopBodies` + `WrapPropertyBodies`
- All do the same thing (enforce braces on new lines) for different construct types. Could be `WrapBodies`.

### Import blank line rules (2 → 1)

- `BlankLineAfterImports` + `BlankLinesBetweenImports`
- Both manage whitespace around imports. Could be `ImportBlankLines`.

### Doc comment validation (2 → 1)

- `ValidateDocumentationComments` + `BeginDocumentationCommentWithOneLineSummary`
- The summary check is a subset of comment validation.

### One-per-line rules (2 → 1)

- `OneCasePerLine` + `OneVariableDeclarationPerLine`
- Same concept for different constructs. Could be `OneDeclarationPerLine`.

## Split Candidates

No rules currently have configuration complex enough to warrant splitting. All config-aware rules (7 total) use simple toggles or small value lists that don't change fundamental behavior.

## Notes

- Renaming changes the JSON config key in `.swiftiomatic.json` — needs a migration path or alias support
- Total rules: ~120
- Many names are inherited from swift-format / SwiftLint origins and were never harmonized


## Summary of Changes

### Naming Consistency (42 renames)
- **Prohibition prefix → `No`**: 6 rules (`Never*`, `DoNot*`, `Dont*`, `Avoid*` → `No*`)
- **`Use` → `Prefer`**: 5 rules
- **Drop `Always`**: 2 rules
- **`Ordered` → `Sort`**: `OrderedImports` → `SortImports`
- **Singular → plural**: `BlankLineAfter*` → `BlankLinesAfter*`
- **Verbose → concise**: 8 sentence-like names shortened
- **Ambiguous → clear**: 15 bare-noun names given descriptive prefixes
- **File/class mismatch**: `NoEmptyLineOpeningClosingBraces.swift` → `NoEmptyLinesOpeningClosingBraces.swift`

### Merges (5 rule groups → 5 single rules)
- `NeverForceUnwrap` + `NoForceUnwrapInTests` → **`NoForceUnwrap`** (diagnoses in non-test, fixes in test)
- `NeverUseForceTry` + `NoForceTryInTests` → **`NoForceTry`**
- `RedundantInternal` + `RedundantPublic` + `RedundantExtensionACL` + `RedundantFileprivate` → **`RedundantAccessControl`**
- `WrapConditionalBodies` + `WrapFunctionBodies` + `WrapLoopBodies` + `WrapPropertyBodies` → **`WrapBodies`**
- `OneCasePerLine` + `OneVariableDeclarationPerLine` → **`OneDeclarationPerLine`**

### Config
- `orderedImports` → `sortImports` (config property + struct name)
- Generated pipelines, registry, and name cache regenerated

### Split Candidates
None warranted — all config-aware rules have simple toggles.

### Stats
- 135 files changed, 3137 insertions, 7256 deletions
- 2318 tests pass (FileHeader handled separately)
