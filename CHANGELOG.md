# Changelog

## Week of Apr 19 – Apr 25, 2026

### ✨ Features

- Add `update` subcommand; sync config with current rule registry
- `RedundantReturn`; support multi-branch implicit returns per SE-0380
- `RedundantReturn`; treat Never-returning calls as terminal branches
- Add `BlankLinesBeforeControlFlow` rule
- `blankLines.closingBraceAsBlankLine` layout option; treat solitary `}` as visual separation ([#368](https://github.com/toba/swiftiomatic/issues/368))
- `blankLines.commentAsBlankLine` layout option; treat comment lines as visual separation
- New rules: `RedundantFinal` + `PreferStaticOverClassFunc`
- Add `doctor` subcommand; JSON Schema validation + full config parsing
- Simplify rule configuration; uniform object shape, remove shorthand
- Convert code generator to SPM build tool plugin
- Rationalize rule value types; `SyntaxRuleValue` protocol replaces `RuleHandling` enum
- Prefer implicit member expression over explicit type in known-type context
- `PreferTernary`; rewrite simple if-else return to ternary ([#380](https://github.com/toba/swiftiomatic/issues/380))
- `PreferIfElseChain`; convert series of early returns to chained if/else ([#386](https://github.com/toba/swiftiomatic/issues/386))
- `WrapSwitchCaseBodies`; wrap or inline switch case bodies ([#384](https://github.com/toba/swiftiomatic/issues/384))
- `CollapseSimpleEnums`; single-line enum for simple cases ([#388](https://github.com/toba/swiftiomatic/issues/388))
- `AlignWrappedConditions`; align continuation conditions in if/guard ([#395](https://github.com/toba/swiftiomatic/issues/395))
- `NestedCallLayout` rule ([#385](https://github.com/toba/swiftiomatic/issues/385))
- `CollapseSimpleIfElse`; single-line if/else for simple cases ([#397](https://github.com/toba/swiftiomatic/issues/397))
- Cat 1 bug-detection rules; `IdenticalOperands`, `DuplicateConditions`, `DuplicateDictionaryKeys`, `MutableCapture`, `UnhandledThrowingTask`, `RetainNotificationObserver`, `RequireSuperCall`, `NoLiteralProtocolInit`, `UnusedSetterValue`, `UnusedControlFlowLabel`, `InvisibleCharacters` ([#320](https://github.com/toba/swiftiomatic/issues/320))
- Cat 4 delegate/observer/lifecycle rules; `DelegateProtocolRequiresAnyObject`, `WeakDelegates`, `DeinitObserverRemoval` ([#313](https://github.com/toba/swiftiomatic/issues/313))
- Cat 6 performance rules; `PreferFirstWhere`, `PreferLastWhere`, `PreferContains`, `PreferFlatMap`, `PreferAllSatisfy`, `PreferReduceInto`, `PreferMinMax`, `FinalTestCase` ([#316](https://github.com/toba/swiftiomatic/issues/316))
- Publish separate `swiftiomatic-plugins` repo with `binaryTarget` ([#405](https://github.com/toba/swiftiomatic/issues/405))
- Layout; collapse `else {` onto preceding line for guard/if when it fits ([#406](https://github.com/toba/swiftiomatic/issues/406))

### 🐞 Fixes

- `BlankLinesBeforeControlFlow` crashes on empty code blocks; invalid range `1..<0` ([#370](https://github.com/toba/swiftiomatic/issues/370))
- JSON schema now emits enum constraints for rule-specific properties; validates `mode`, `style`, `placement`, `accessLevel`, `sortOrder`
- `SortImports` checks fail on CI ([#361](https://github.com/toba/swiftiomatic/issues/361))
- Prefer breaking at `.` over `=` in long assignments ([#363](https://github.com/toba/swiftiomatic/issues/363))
- Fix camelCase key generation for acronym-prefixed rule names ([#367](https://github.com/toba/swiftiomatic/issues/367))
- `keepFunctionOutputTogether` doesn't move opening brace to output line when wrapping parameters ([#376](https://github.com/toba/swiftiomatic/issues/376))
- Line break precedence; prefer splitting at `??` / `+` over `=` assignment
- `PreferTrailingClosures` assignment continuation line-breaking is wrong ([#381](https://github.com/toba/swiftiomatic/issues/381))
- Prefer breaking at condition operators over guard/if/while keywords ([#366](https://github.com/toba/swiftiomatic/issues/366))
- `sm --version` prints `main` instead of actual version ([#396](https://github.com/toba/swiftiomatic/issues/396))
- `PreferIfElseChain`; don't convert chained returns when not at implicit-return position
- `sm update` doesn't sync rules in config
- `AlignWrappedConditions`; align at normal indent when `beforeGuardConditions` break is set
- Ternary breaks at `=` before breaking ternary parts
- `guard` bindings should not wrap to next line ([#402](https://github.com/toba/swiftiomatic/issues/402))
- Capture of non-`Sendable` `D.Type` in `Configuration` setting/rule closures; `Sendable` requirement on `LayoutRule`/`SyntaxRule` protocols, `@unchecked Sendable` on `LintSyntaxRule`/`RewriteSyntaxRule` base classes
- `LintSyntaxRule`/`RewriteSyntaxRule` `class var key` overrides shadowed `Configurable.key` fix; acronym rules like `URLMacro` regressed to `uRLMacro` ([#407](https://github.com/toba/swiftiomatic/issues/407))
- `nestedCallLayout` inline mode doesn't collapse chained `.with()` calls ([#409](https://github.com/toba/swiftiomatic/issues/409))
- `singleLineBodies` inline mode doesn't collapse multi-line conditions when body fits ([#408](https://github.com/toba/swiftiomatic/issues/408))
- `sm update` rewrites entire configuration instead of editing ([#410](https://github.com/toba/swiftiomatic/issues/410))
- `PreferStaticOverClassFunc` skips `override` members; `UseImplicitInit` skips single-unlabeled-arg type-erasure conversions ([#411](https://github.com/toba/swiftiomatic/issues/411))
- `collapseSimpleEnums` doesn't collapse `CodingKeys` enum in `Indent.swift` ([#412](https://github.com/toba/swiftiomatic/issues/412))
- `NestedCallLayout` silently deletes trailing-closure bodies when collapsing ([#413](https://github.com/toba/swiftiomatic/issues/413))

### 🗜️ Tweaks

- Swift review; JSON encoding, decoding, schema generation, schema validation ([#355](https://github.com/toba/swiftiomatic/issues/355))
- Upstream citation review; level-set ([#357](https://github.com/toba/swiftiomatic/issues/357))
- Config properties match rule capabilities; `LintOnlyValue` for 16 lint-only rules
- Fix JSON schema code; rewrite `SchemaValidator` on typed `JSONValue`, eliminate ObjC bridging
- Unify `JSONValue` into ConfigurationKit; eliminate `[String: Any]` from config encoding
- Split `TokenStreamCreator.swift` into 17 extension files
- Co-locate layout rule config with `TokenStream` implementation
- Generate `TokenStreamCreator` forwarding stubs
- Refactor `GeneratePaths` to accept injected base paths
- Handle `schema.json` output location; manual step outside plugin
- Break `GeneratorKit` → `SwiftiomaticKit` circular dependency
- Remove standalone `Generator` executable target
- Add 9 configuration groups for ungrouped rules
- Eliminate swift-syntax compilation in CI ([#373](https://github.com/toba/swiftiomatic/issues/373))
- Rename config keys for clarity
- Pre-commit hook to regenerate `schema.json` ([#369](https://github.com/toba/swiftiomatic/issues/369))
- Create SPM build tool plugin target ([#352](https://github.com/toba/swiftiomatic/issues/352))
- Swift review; code quality and modernization fixes
- Update GitHub Actions to Node.js 24-native versions; remove `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` workaround
- Rename `NoExtensionAccessLevel` to `ExtensionAccessLevel`; rename `onDeclarations` to `onMembers` ([#383](https://github.com/toba/swiftiomatic/issues/383))
- Rename `compoundCaseStatements` to `wrapCompoundCaseItems` ([#382](https://github.com/toba/swiftiomatic/issues/382))
- Convert `EmptyBraces` from syntax rewrite rule to layout
- Convert `BlankLinesBetweenImports` to layout; `maxBlankLines: 0` between consecutive imports
- Convert `NoEmptyLinesOpeningClosingBraces` to layout; `maxBlankLines: 0` on brace breaks
- Convert `BlankLinesBetweenChainedFunctions` to layout; `maxBlankLines: 0` on chain period breaks
- Add per-break `maxBlankLines` to `NewlineBehavior`; enables per-context blank line limits in layout
- Rename `PrettyPrint` test folder to `Layout`; `assertPrettyPrintEqual` to `assertLayout`
- Investigate redundant wrap rules ([#391](https://github.com/toba/swiftiomatic/issues/391))
- Reorganize `Layout/Rules` into config-group folders

## Week of Apr 12 – Apr 18, 2026

### ✨ Features

- Unify rule toggles and rule options into single `rules` dict ([#323](https://github.com/toba/swiftiomatic/issues/323))
- Modern Swift idiom rules ([#290](https://github.com/toba/swiftiomatic/issues/290))
- Declaration, modifier, and cleanup rules ([#287](https://github.com/toba/swiftiomatic/issues/287))
- Blank lines and structural spacing rules ([#291](https://github.com/toba/swiftiomatic/issues/291))
- Wrapping and body formatting rules ([#286](https://github.com/toba/swiftiomatic/issues/286))
- Code organization and documentation rules ([#289](https://github.com/toba/swiftiomatic/issues/289))
- Redundancy removal rules; `RedundantNilInit`, `RedundantInit`, `RedundantRawValues`, `RedundantOptionalBinding`, and more ([#292](https://github.com/toba/swiftiomatic/issues/292))
- Convert app from document-based to single-window `UserDefaults`-based ([#264](https://github.com/toba/swiftiomatic/issues/264))
- Redesign rule nav; category list → detail rule list ([#259](https://github.com/toba/swiftiomatic/issues/259))
- Rule options UX in detail view ([#261](https://github.com/toba/swiftiomatic/issues/261))
- Move scope filter from toolbar to picker above rule list in nav sidebar ([#219](https://github.com/toba/swiftiomatic/issues/219))
- Move Format Options from toolbar button to left nav item ([#221](https://github.com/toba/swiftiomatic/issues/221))
- Add `DiagnosticCategory` hierarchy for rule grouping ([#250](https://github.com/toba/swiftiomatic/issues/250))
- Add diagnostic highlights and notes to `RuleViolation` ([#252](https://github.com/toba/swiftiomatic/issues/252))
- Add AST-level `FixIt.Change` variants to `SyntaxViolation.Correction` ([#243](https://github.com/toba/swiftiomatic/issues/243))
- Integrate incremental parsing for IDE extension performance ([#249](https://github.com/toba/swiftiomatic/issues/249))
- Dry-run diff for `--fix` ([#170](https://github.com/toba/swiftiomatic/issues/170))
- `AssignmentWrappingRule`; keep RHS on the `=` line when it fits ([#201](https://github.com/toba/swiftiomatic/issues/201))
- Missing swift-format rules; 6 genuinely unimplemented checks ([#240](https://github.com/toba/swiftiomatic/issues/240))
- Document-based SwiftUI app; open/create `.swiftiomatic.yaml` ([#223](https://github.com/toba/swiftiomatic/issues/223))

### 🐞 Fixes

- Format command ignores correctable Swiftiomatic rules ([#262](https://github.com/toba/swiftiomatic/issues/262))
- Fix O(n²) performance anti-patterns in `RuleMask` and `GroupNumericLiterals` ([#273](https://github.com/toba/swiftiomatic/issues/273))
- Formatter strips backtick-quoted test names ([#227](https://github.com/toba/swiftiomatic/issues/227))
- `RuleExampleTests`; `identifier_name` false failure from `prefixed_toplevel_constant` ([#230](https://github.com/toba/swiftiomatic/issues/230))
- `RuleExampleTests` fails in isolation but passes in full suite ([#206](https://github.com/toba/swiftiomatic/issues/206))
- Fix 5 test failures; `StatementPositionRule` no-SourceKit fallback + `IdentifierNameRule` emoji length ([#205](https://github.com/toba/swiftiomatic/issues/205))
- Swift Testing misattributes failures in serialized parameterized tests ([#234](https://github.com/toba/swiftiomatic/issues/234))
- CI blind spot; agent never catches batch `RuleExampleTests` failures ([#255](https://github.com/toba/swiftiomatic/issues/255))
- Agents push broken releases in a loop; each "fix" introducing new failures ([#204](https://github.com/toba/swiftiomatic/issues/204))
- Search/filter bar missing from above the rule list in nav ([#217](https://github.com/toba/swiftiomatic/issues/217))
- Fix SF Symbol sizing and placement in rule list ([#224](https://github.com/toba/swiftiomatic/issues/224))
- Move Format Options button above the rule list ([#258](https://github.com/toba/swiftiomatic/issues/258))
- Use standard macOS About window instead of toolbar button ([#216](https://github.com/toba/swiftiomatic/issues/216))
- SourceKit warnings spam stderr when running `sm` with no arguments ([#228](https://github.com/toba/swiftiomatic/issues/228))
- `sm format` emits SourceKit warnings after formatting ([#226](https://github.com/toba/swiftiomatic/issues/226))
- Xcode app build fails; `SwiftiomaticKit` types not visible to `SwiftiomaticApp` ([#220](https://github.com/toba/swiftiomatic/issues/220))
- Audit; rules that skip `CodeBlockSyntax` but not `AccessorBlockSyntax` ([#235](https://github.com/toba/swiftiomatic/issues/235))

### 🗜️ Tweaks

- Migrate PrettyPrint, Rules, API, Core, Utilities tests to Swift Testing ([#279](https://github.com/toba/swiftiomatic/issues/279), [#275](https://github.com/toba/swiftiomatic/issues/275), [#276](https://github.com/toba/swiftiomatic/issues/276), [#270](https://github.com/toba/swiftiomatic/issues/270), [#271](https://github.com/toba/swiftiomatic/issues/271))
- Rewrite `_SwiftiomaticTestSupport` for Swift Testing ([#278](https://github.com/toba/swiftiomatic/issues/278))
- Add typed throws to API layer; `throws(SwiftiomaticError)` on 9 functions ([#277](https://github.com/toba/swiftiomatic/issues/277))
- Modernize concurrency; replace `DispatchQueue` with `Mutex` in `StderrDiagnosticPrinter` ([#274](https://github.com/toba/swiftiomatic/issues/274))
- Clean up debug prints and `fatalError` patterns; replace `print`/`assert(false)` with `assertionFailure`/`preconditionFailure` ([#269](https://github.com/toba/swiftiomatic/issues/269))
- Port `FixItApplier` conflict resolution for multi-rule corrections ([#244](https://github.com/toba/swiftiomatic/issues/244))
- Use `SwiftSyntaxBuilder` result builders for correction node construction ([#251](https://github.com/toba/swiftiomatic/issues/251))
- Extract `SwiftiomaticSyntax` wrapper target to cache swift-syntax builds ([#202](https://github.com/toba/swiftiomatic/issues/202))
- Generator; detect pipeline-ineligible rules automatically ([#233](https://github.com/toba/swiftiomatic/issues/233))
- `RedundantBackticks`; context-aware backtick removal ([#232](https://github.com/toba/swiftiomatic/issues/232))
- Evaluate `BasicFormat` token-pair abstraction for format rules ([#246](https://github.com/toba/swiftiomatic/issues/246))
- Replace scope badges with SF Symbols ([#225](https://github.com/toba/swiftiomatic/issues/225))
- Remove padding around app icon for macOS 26 ([#231](https://github.com/toba/swiftiomatic/issues/231))
- Medium gap fixes; `ImplicitOptionalInit` exclusions, `RedundantType` `@Model`/ternary ([#236](https://github.com/toba/swiftiomatic/issues/236))
- Remaining medium gaps; `EmptyBraces` linebreak, `RedundantType` if/switch + Set literal ([#247](https://github.com/toba/swiftiomatic/issues/247))
- Investigate 5 unmapped SwiftFormat rules for Swiftiomatic equivalents ([#203](https://github.com/toba/swiftiomatic/issues/203))
- Correctable lint rule; XCTest assertions → Swift Testing assertions ([#209](https://github.com/toba/swiftiomatic/issues/209))
- Correctable lint rule; redundant `@MainActor` on View ([#213](https://github.com/toba/swiftiomatic/issues/213))
- Correctable lint rule; `@_specialize` → `@specialize` (Swift 6.3) ([#210](https://github.com/toba/swiftiomatic/issues/210))
- Correctable lint rule; `@_cdecl` → `@c` (Swift 6.3) ([#214](https://github.com/toba/swiftiomatic/issues/214))
- Lint rule; `file`/`line` params → `sourceLocation` pattern ([#238](https://github.com/toba/swiftiomatic/issues/238))
- Suggest rule; module selector syntax (`import struct`/`class`/`func` → `::`) ([#212](https://github.com/toba/swiftiomatic/issues/212))
- Suggest rule; SwiftUI view anti-patterns (formatters in body, unstable identity, etc.) ([#208](https://github.com/toba/swiftiomatic/issues/208))
- Suggest rule; SwiftUI superseded patterns ([#211](https://github.com/toba/swiftiomatic/issues/211))
- Suggest rule; Foundation modernization (`AttributedString`, typed notifications) ([#215](https://github.com/toba/swiftiomatic/issues/215))
- Suggest rule; concurrency modernization additions (`Task.immediate`, `SendableMetatype`, `nonisolated`) ([#207](https://github.com/toba/swiftiomatic/issues/207))
- `FullyIndirectEnum` rule ([#254](https://github.com/toba/swiftiomatic/issues/254))
- `OneCasePerLine` rule ([#245](https://github.com/toba/swiftiomatic/issues/245))
- `NoLabelsInCasePatterns` rule ([#242](https://github.com/toba/swiftiomatic/issues/242))
- `DontRepeatTypeInStaticProperties` rule ([#241](https://github.com/toba/swiftiomatic/issues/241))
- `UseEarlyExits` rule ([#248](https://github.com/toba/swiftiomatic/issues/248))
- `ValidateDocumentationComments` rule ([#253](https://github.com/toba/swiftiomatic/issues/253))
- Infrastructure review; modernize support patterns ([#257](https://github.com/toba/swiftiomatic/issues/257))
- Trim `/rule` skill for conciseness ([#237](https://github.com/toba/swiftiomatic/issues/237))
- Fix naming convention violations; drop `-Protocol` suffix, rename `OrderedImports` booleans ([#272](https://github.com/toba/swiftiomatic/issues/272))
- Consolidate duplicated visitor patterns in rules; evaluated and confirmed existing extraction is sufficient ([#268](https://github.com/toba/swiftiomatic/issues/268))
- Migrate test suite from XCTest to Swift Testing; protocol-based test helpers replace class hierarchy ([#265](https://github.com/toba/swiftiomatic/issues/265))
- Adapt swift-format codebase for Swiftiomatic; macOS 26+, Swift 6.3+ ([#266](https://github.com/toba/swiftiomatic/issues/266))
