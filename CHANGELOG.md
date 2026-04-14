# Changelog

## Week of Apr 12 – Apr 18, 2026

### ✨ Features

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

### 🐛 Fixes

- Format command ignores correctable Swiftiomatic rules ([#262](https://github.com/toba/swiftiomatic/issues/262))
- Fix O(n²) performance anti-patterns in `RuleMask` and `GroupNumericLiterals`
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

- Add typed throws to API layer; `throws(SwiftiomaticError)` on 9 functions
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
