---
# shb-etk
title: 'Missing swift-format rules: 6 genuinely unimplemented checks'
status: in-progress
type: feature
priority: normal
created_at: 2026-04-12T23:56:03Z
updated_at: 2026-04-13T00:00:00Z
sync:
    github:
        issue_number: "240"
        synced_at: "2026-04-13T00:25:18Z"
---

Comparison of swift-format rules (reference at `~/Developer/swiftiomatic-ref/`) against Swiftiomatic's 330 rules found **6 genuinely missing** checks. These are NOT covered by existing rules under different names or configurations.

## Missing Rules

- [ ] **UseEarlyExits** — prefer `guard` for early exits instead of nested `if/else` when the else branch is a simple exit (`return`, `throw`, `break`, `continue`). `redundant_else` handles a related but different case (removing else after an if that already exits). This rule would suggest converting `if condition { long block } else { return }` → `guard condition else { return }; long block`.
- [ ] **FullyIndirectEnum** — when all cases of an enum are marked `indirect`, consolidate to `indirect enum` on the declaration itself. Simple redundancy removal.
- [ ] **ValidateDocumentationComments** — validate doc comment *structure*: param names match the function signature, `- Returns:` clause is present for non-Void functions, one-line summary at start. `missing_docs` only checks *presence*, not correctness.
- [ ] **OneCasePerLine** — enum cases with associated values or raw values should each have their own `case` declaration (e.g., `case a(Int), b(String)` → separate `case` lines). Plain cases without payloads are fine grouped.
- [ ] **DontRepeatTypeInStaticProperties** — static properties returning their enclosing type shouldn't include the type name (e.g., `UIColor.blueColor` → `.blue`). `naming_heuristics` covers factory method prefixes and Bool naming but not this pattern.
- [ ] **NoLabelsInCasePatterns** — remove redundant labels in case patterns where the label matches the bound variable name (e.g., `case .foo(bar: bar)` → `case .foo(bar)`). `empty_enum_arguments` handles `case .foo(_)` → `case .foo` but not this.

## Excluded from This List

The following swift-format rules were evaluated and excluded because they're effectively handled:

| swift-format Rule | Handled By | Notes |
|---|---|---|
| AllPublicDeclarationsHaveDocumentation | `missing_docs` | |
| AlwaysUseLiteralForEmptyCollectionInit | `empty_collection_literal` | |
| AlwaysUseLowerCamelCase | `identifier_name` | |
| DoNotUseSemicolons | `trailing_semicolon` | |
| FileScopedDeclarationPrivacy | `private_over_fileprivate` | |
| GroupNumericLiterals | `number_separator` | |
| NeverForceUnwrap | `force_unwrap` | |
| NeverUseForceTry | `force_try` | |
| NeverUseImplicitlyUnwrappedOptionals | `implicitly_unwrapped_optional` | |
| NoAccessLevelOnExtensionDeclaration | `no_extension_access_modifier` | |
| NoBlockComments | `block_comments` | |
| NoCasesWithOnlyFallthrough | `no_fallthrough_only` | |
| NoEmptyLinesOpeningClosingBraces | `vertical_whitespace_opening_braces` + `vertical_whitespace_closing_braces` | |
| NoEmptyTrailingClosureParentheses | `trailing_closure_empty_parens` | |
| NoParensAroundConditions | `control_statement_parens` | |
| NoPlaygroundLiterals | `discouraged_object_literal` | Covers #colorLiteral, #imageLiteral |
| NoVoidReturnOnFunctionSignature | `redundant_void_return` | |
| OmitExplicitReturns | `implicit_return` | |
| OneVariableDeclarationPerLine | `single_property_per_line` | |
| OnlyOneTrailingClosureArgument | `multiple_trailing_closures` | |
| OrderedImports | `sort_imports` | |
| ReplaceForEachWithForLoop | `prefer_for_loop` | |
| ReturnVoidInsteadOfEmptyTuple | `void_return` | |
| TypeNamesShouldBeCapitalized | `type_name` | |
| UseExplicitNilCheckInConditions | `unused_optional_binding` | |
| UseLetInEveryBoundCaseVariable | `pattern_matching_keywords` | Opposite style, but same concern |
| UseShorthandTypeNames | `syntactic_sugar` | |
| UseSingleLinePropertyGetter | `redundant_get` | |
| UseSynthesizedInitializer | `redundant_synthesized_initializer` | |
| UseTripleSlashForDocumentationComments | `block_comments` + `doc_comments` | |
| UseWhereClausesInForLoops | `for_where` | |

Also excluded as borderline:

- **AvoidRetroactiveConformances** — compiler already enforces `@retroactive` via SE-0364; forbidding them entirely is an API policy choice
- **AmbiguousTrailingClosureOverload** — very niche API design concern about overload disambiguation
- **NoAssignmentInExpressions** — Swift's type system (`=` returns Void) prevents most misuse scenarios
- **IdentifiersMustBeASCII** — partially covered by `identifier_name` configuration
- **NoLeadingUnderscores** — partially covered by `identifier_name` configuration
