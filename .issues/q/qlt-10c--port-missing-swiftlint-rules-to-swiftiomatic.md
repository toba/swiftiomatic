---
# qlt-10c
title: Port missing SwiftLint rules to Swiftiomatic
status: ready
type: epic
priority: normal
created_at: 2026-04-15T00:25:10Z
updated_at: 2026-04-15T00:31:47Z
sync:
    github:
        issue_number: "308"
        synced_at: "2026-04-15T00:34:43Z"
---

## Gap Analysis

Compared Swiftiomatic's 142 rules against SwiftLint's 250 rules (ref at `~/Developer/swiftiomatic-ref/SwiftLint`).

- **Already covered**: ~65 rules have Swiftiomatic equivalents (via direct rules or PrettyPrinter)
- **PrettyPrinter covers**: ~40 rules (spacing, indentation, alignment, brace placement, trailing whitespace/commas)
- **Skip — legacy/niche/framework-specific**: ~45 rules (legacy_*, Quick/Nimble, IBOutlet/IBAction, NSLocalizedString, XCTest lifecycle, SwiftLint-internal)
- **Skip — too opinionated or conflicts**: ~20 rules (explicit_acl, strict_fileprivate, no_magic_numbers, one_declaration_per_file, etc.)
- **Skip — compiler catches**: ~5 rules (return_value_from_void_function, duplicate_enum_cases, dynamic_inline)
- **Missing**: ~65 rules worth implementing

## Architecture Differences

**SwiftLint** originally used SourceKit but now uses **SwiftSyntax** for most rules (via `@SwiftSyntaxRule` macro). Correctable rules implement `SwiftSyntaxCorrectableRule`. SwiftLint's rules are conceptually close to Swiftiomatic's model — both walk syntax trees. The main difference is SwiftLint's `ConfigurationProviderRule` pattern vs Swiftiomatic's `Configuration` struct.

**Mapping**: SwiftLint lint-only rules → Swiftiomatic `SyntaxLintRule`. SwiftLint correctable rules → Swiftiomatic `SyntaxFormatRule` (auto-fix). Non-correctable rules that have simple fixes could also be implemented as `SyntaxFormatRule`.

## Implementation Plan

~65 rules across 9 categories, tracked as child issues. Rule details (SwiftLint mapping, proposed Swiftiomatic name, scope) are in each child.

## Already Covered Mapping

<details>
<summary>65 SwiftLint rules already covered by Swiftiomatic (click to expand)</summary>

| SwiftLint | Swiftiomatic Equivalent |
|---|---|
| `control_statement` | `NoParensAroundConditions` |
| `direct_return` | `RedundantProperty` |
| `empty_enum_arguments` | `NoLabelsInCasePatterns` |
| `empty_parentheses_with_trailing_closure` | `NoTrailingClosureParens` |
| `file_header` | `FileHeader` |
| `identifier_name` | `LowerCamelCase` + `ASCIIIdentifiers` |
| `implicit_getter` | `PreferSingleLinePropertyGetter` |
| `implicit_return` | `OmitExplicitReturns` |
| `modifier_order` | `ModifierOrder` |
| `multiple_closures_with_trailing_closure` | `OnlyOneTrailingClosureArgument` |
| `non_overridable_class_declaration` | `PreferFinalClasses` |
| `number_separator` | `GroupNumericLiterals` |
| `prefer_self_in_static_references` | `RedundantStaticSelf` |
| `redundant_discardable_let` | `RedundantLet` |
| `redundant_self` | `RedundantSelf` |
| `sorted_enum_cases` | `SortSwitchCases` |
| `sorted_imports` | `SortImports` |
| `superfluous_else` | `PreferEarlyExits` |
| `trailing_closure` | `PreferTrailingClosures` |
| `trailing_newline` | `LinebreakAtEndOfFile` |
| `type_name` | `CapitalizedTypeNames` |
| `void_return` | `PreferVoidReturn` |
| `multiline_function_chains` | `WrapMultilineFunctionChains` |
| `convenience_type` | `EnumNamespaces` |
| `discouraged_assert` | `PreferAssertionFailure` |
| `discouraged_object_literal` | `NoPlaygroundLiterals` |
| `duplicate_imports` | `SortImports` (deduplicates) |
| `explicit_init` | `RedundantInit` |
| `fallthrough` | `NoFallthroughOnlyCases` |
| `force_try` | `NoForceTry` |
| `force_unwrapping` | `NoForceUnwrap` |
| `for_where` | `PreferWhereClausesInForLoops` |
| `implicit_optional_initialization` | `RedundantNilInit` |
| `implicitly_unwrapped_optional` | `NoImplicitlyUnwrappedOptionals` |
| `no_empty_block` | `EmptyBraces` |
| `no_extension_access_modifier` | `ExtensionAccessLevel` |
| `no_fallthrough_only` | `NoFallthroughOnlyCases` |
| `pattern_matching_keywords` | `PatternLetPlacement` |
| `prefer_key_path` | `PreferKeyPath` |
| `private_over_fileprivate` | `FileScopedDeclarationPrivacy` |
| `redundant_objc_attribute` | `RedundantObjc` |
| `redundant_string_enum_value` | `RedundantRawValues` |
| `redundant_type_annotation` | `RedundantType` |
| `redundant_void_return` | `NoVoidReturnOnFunctionSignature` |
| `shorthand_optional_binding` | `RedundantOptionalBinding` |
| `syntactic_sugar` | `PreferShorthandTypeNames` |
| `trailing_semicolon` | `NoSemicolons` |
| `unneeded_break_in_switch` | `RedundantBreak` |
| `unneeded_synthesized_initializer` | `PreferSynthesizedInitializer` |
| `async_without_await` | `RedundantAsync` |
| `missing_docs` | `DocumentPublicDeclarations` |
| `private_swiftui_state` | `PrivateStateVariables` |
| `redundant_sendable` | `RedundantSendable` |
| `strong_iboutlet` | `StrongOutlets` |
| `test_case_accessibility` | `TestSuiteAccessControl` |
| `unneeded_throws_rethrows` | `RedundantThrows` |
| `unused_closure_parameter` | `UnusedArguments` |
| `unused_parameter` | `UnusedArguments` |
| `yoda_condition` | `NoYodaConditions` |
| `mark` | `BlankLinesAroundMark` + `FormatSpecialComments` |
| `empty_collection_literal` | `EmptyCollectionLiteral` |
| `empty_count` | `PreferIsEmpty` |
| `empty_string` | `PreferIsEmpty` |
| `unused_optional_binding` | `ExplicitNilCheck` |
| `prefer_condition_list` | `PreferCommaConditions` |

</details>

<details>
<summary>~40 rules handled by PrettyPrinter (click to expand)</summary>

`attribute_name_spacing`, `closure_end_indentation`, `closing_brace`, `closure_parameter_position`, `closure_spacing`, `collection_alignment`, `colon`, `comma`, `comma_inheritance`, `contrasted_opening_brace`, `empty_parameters`, `function_name_whitespace`, `indentation_width`, `leading_whitespace`, `let_var_whitespace`, `literal_expression_end_indentation`, `multiline_arguments`, `multiline_arguments_brackets`, `multiline_call_arguments`, `multiline_literal_brackets`, `multiline_parameters`, `multiline_parameters_brackets`, `no_space_in_method_call`, `opening_brace`, `operator_usage_whitespace`, `period_spacing`, `return_arrow_whitespace`, `statement_position`, `switch_case_alignment`, `switch_case_on_newline`, `trailing_comma`, `trailing_whitespace`, `vertical_parameter_alignment`, `vertical_parameter_alignment_on_call`, `vertical_whitespace`, `vertical_whitespace_between_cases`, `vertical_whitespace_closing_braces`, `vertical_whitespace_opening_braces`, `conditional_returns_on_newline`

</details>

<details>
<summary>~70 rules skipped — legacy, framework-specific, or too opinionated (click to expand)</summary>

**Legacy APIs** (9): `block_based_kvo`, `legacy_cggeometry_functions`, `legacy_constant`, `legacy_constructor`, `legacy_hashing`, `legacy_multiple`, `legacy_nsgeometry_functions`, `legacy_objc_type`, `legacy_random`

**Framework-specific** (5): `nimble_operator`, `prefer_nimble`, `quick_discouraged_call`, `quick_discouraged_focused_test`, `quick_discouraged_pending_test`

**Interface Builder** (5): `ibinspectable_in_extension`, `valid_ibinspectable`, `prohibited_interface_builder`, `private_action`, `private_outlet`

**NSLocalizedString / NSObject** (4): `nslocalizedstring_key`, `nslocalizedstring_require_bundle`, `ns_number_init_as_function_reference`, `nsobject_prefer_isequal`

**SwiftLint/XCTest internals** (6): `invalid_swiftlint_command`, `blanket_disable_command`, `balanced_xctest_lifecycle`, `empty_xctest_method`, `xctfail_message`, `xct_specific_matcher`

**Too opinionated or conflicts with existing** (20): `explicit_acl`, `explicit_top_level_acl`, `explicit_type_interface`, `extension_access_modifier`, `strict_fileprivate`, `explicit_enum_raw_value`, `explicit_self`, `no_grouping_extension`, `prefixed_toplevel_constant`, `self_binding`, `inclusive_language`, `one_declaration_per_file`, `file_types_order`, `type_contents_order`, `attributes`, `no_magic_numbers`, `static_operator`, `shorthand_argument`, `single_test_class`, `file_name`

**Compiler already catches** (5): `return_value_from_void_function`, `duplicate_enum_cases`, `dynamic_inline`, `deployment_target`, `incompatible_concurrency_annotation`

**Too niche / marginal** (10+): `required_deinit`, `required_enum_case`, `raw_value_for_camel_cased_codable_enum`, `typesafe_array_init`, `prefer_asset_symbols`, `file_name_no_space`, `private_subject`, `self_in_property_initialization`, `unused_declaration` (whole-file analysis), `array_init`, `joined_default_parameter`, `discouraged_default_parameter`, `discouraged_direct_init`, `todo`

</details>

## Priority Order

1. **Bug Detection** (Cat 1) — highest value, catches real bugs
2. **Performance Patterns** (Cat 6) — algorithmic improvements, pure AST
3. **Modern Idioms** (Cat 3) — improve code quality
4. **Redundancy** (Cat 2) — clean up noise, several auto-fixable
5. **Delegate & Lifecycle** (Cat 4) — prevent retain cycles
6. **Type Safety** (Cat 5) — moderate value
7. **Documentation** (Cat 8) — extend existing doc rule coverage
8. **Accessor Patterns** (Cat 9) — minor style improvements
9. **Metrics** (Cat 7) — new infrastructure needed (two-tier thresholds), implement last
