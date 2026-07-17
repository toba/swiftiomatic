# Changelog

## Week of Jul 12 – Jul 18, 2026

### 🗜️ Tweaks

- `NoImplicitlyUnwrappedOptionals` and `RequireCamelCaseIdentifiers` now relax inside Swift Testing files, not just XCTest; ports upstream swift-format's `ImportsXCTestVisitor` → `ImportsAnyTestingLibrary` rework (#1244/#1247) behind an extensible `supportedTestLibraryModuleNames` list, and renames `Context.importsXCTest` → `importsAnyTestLibrary` so the field no longer reads as XCTest-only when it now matches any test library ([#754](https://github.com/toba/swiftiomatic/issues/754))

## Week of Jul 05 – Jul 11, 2026

### 🐞 Fixes

- `DropRedundantProperty`; a `let` carrying modifiers or attributes (`@preconcurrency let x = …; return x`, `nonisolated(unsafe) let …`) is no longer inlined into the `return`, which silently dropped the modifier/attribute; the `tryMerge` guard now also requires `modifiers.isEmpty` and `attributes.isEmpty` (mirrors nicklockwood/SwiftFormat `redundantVariable` #2569) ([#749](https://github.com/toba/swiftiomatic/issues/749))
- `UseFirstWhere`; a trailing-closure `xs.filter { … }.first { … }` (or `.first(where:)`) — already the short-circuiting form — is no longer flagged as preferring `first(where:)` over `filter(_:).first`; adds the `FunctionCallExprSyntax` parent guard that `UseMinMax` already carried (surfaced by nicklockwood/SwiftFormat `preferFirstWhere` #2561) ([#748](https://github.com/toba/swiftiomatic/issues/748))
- `UseDocCommentsOnAPI`; a regular group-header comment above the *last* case group in a blank-line-free run (`// Boolean operators` above `case and, or`) is no longer converted to a `///` doc comment; a backward-continuity scan now preserves it when an earlier member in the same run is itself a preserved group header (mirrors nicklockwood/SwiftFormat `docComments` #2557) ([#750](https://github.com/toba/swiftiomatic/issues/750))
- Three lint rules no longer misfire on legitimate idioms; `NoSwapThenRemoveAll` exempts the canonical double-buffer cycle when `removeAll(keepingCapacity: true)` deliberately retains capacity; `UseContains` fires on `first(where:) == nil` only for the closure form, not a custom value-arg `first(_:)` (e.g. `Span.first(byte)` returning an Index); `NoUnusedSetterValue` exempts any empty `set {}`, covering protocol-extension default setters, not just `override` ([#752](https://github.com/toba/swiftiomatic/issues/752))
- Multi-pattern `switch` cases; a `case` whose patterns each carry a trailing `//` comment with the body on the next line no longer reflows the comments onto their own de-indented lines or swallows the body statement into the final pattern's comment (`0x5F:  // _ continue`, which emptied the case body and broke the build) under `alignWrappedConditions`; a trailing line comment is now glued before the alignment-scope close break so it stays end-of-line ([#753](https://github.com/toba/swiftiomatic/issues/753))

## Week of Jun 28 – Jul 04, 2026

### 🗜️ Tweaks

- Port three upstream swift-format bugfixes; `NoAssignmentInExpressions` no longer false-positives on a standalone assignment wrapped by a custom operator (`x = try f() ?! error`, swift-format #1232); `SplitMultipleDeclsPerLine` leaves bare enum cases written on continuation lines untouched instead of collapsing `case\n  first` into `casefirst` (swift-format #1221); `SortImports` ignores backticks so raw-identifier module names sort by content rather than being grouped by their escaping (swift-format #1233) ([#746](https://github.com/toba/swiftiomatic/issues/746))

## Week of Jun 21 – Jun 27, 2026

### 🐞 Fixes

- Mirror upstream swift-format #1225; an attribute-block `#if … @frozen … #endif` annotating a declaration no longer merges `#endif` onto the following decl (`#endif struct S {}`, collapsing non-idempotently to `#endifstruct S {}`) when `respectsExistingLineBreaks` is off; `visitIfConfigDecl` now branches the after-`#endif` newline behavior and `arrangeAttributeList` forces a hard break when an attribute list ends with an `#if` ([#743](https://github.com/toba/swiftiomatic/issues/743))
- Mirror upstream swift-format #1227; port the `outermostEnclosingNode` fix that keeps a parenthesized ternary base's postfix `?`/`!` glued to its closing paren (`(a ? b : c)?.f`); Swiftiomatic's chain handling already produced the correct layout, so this is an upstream-alignment port with a regression guard ([#744](https://github.com/toba/swiftiomatic/issues/744))
- `excludes`; an absolute exclude pattern (or `realpath`-resolved input path) written in the `/private/var…` form no longer silently fails to match files under macOS firmlinks like `/var` and `/tmp`; `standardizedFileURL` strips a leading `/private` from the candidate path, so `FileIterator.excludeCandidates` now also offers the `/private`-toggled absolute form (string-only, no per-file `stat`), mirroring realm/SwiftLint #6783 ([#741](https://github.com/toba/swiftiomatic/issues/741))

## Week of Jun 14 – Jun 20, 2026

### 🐞 Fixes

- `NestedCallLayout`; in `inline` mode, a SwiftUI modifier-chain call whose callee spans multiple lines (e.g. `.background(RoundedRectangle(cornerRadius: 5).fill(color))` after a wrapped `Text(name)…onHover { … }` chain) now collapses its argument inline when the modifier segment fits, instead of being expanded onto three lines; the multiline callee was distorting the width measurement (`calledExpression.trimmedDescription` carried the whole chain and `columnOffset` anchored on the chain root), so the new `tryInlineModifierCallArgument` measures only the `.method(args)` segment at its real rendered column ([#738](https://github.com/toba/swiftiomatic/issues/738))
- Member-access chains; an assignment RHS whose value is a chain wrapped in a binary op (e.g. `chain.max() ?? 1`) no longer breaks after `=` when the chain is already wrapped at its dots; the base now stays on the `=` line and the chain dots wrap below it; `shouldRetargetChainHeadCloseForAssignmentRHS` now walks through a non-assignment binary op when the chain is its left operand, so the head group closes after the chain base and stops inflating the `=` break's chunk ([#737](https://github.com/toba/swiftiomatic/issues/737))
- `SortImports`; mirror upstream swift-format #1207; restore a shebang line's trailing newline after reordering imports so the file header or first import no longer gets pulled up onto the `#!` line ([#736](https://github.com/toba/swiftiomatic/issues/736))
- Member-access chains; a `.`-chain that continues a base whose closing delimiter (or `#endif`) stands alone on its own line — a SwiftUI trailing-closure call like `Button { … } label: { … }` / `HStack { … }`, an argument list whose `)` was forced onto its own line, or a postfix-`#if` — now stays flush with that delimiter instead of indenting as a continuation; chains continuing a base whose delimiter sits inline after wrapped arguments still indent (regression from the multiline-base chain change) ([#735](https://github.com/toba/swiftiomatic/issues/735))
- Member-access chains; a `.`-chain that continues a multiline base (e.g. `.padding()` / `.background()` after a wrapped `OuterView(…)`) now indents as a continuation instead of aligning flush with the statement keyword — one level for a bare expression, two levels for a chain bound by `return` / `throw` / assignment; single-line bases are unchanged, and postfix-`#if` modifier chains now match the already-indented `#if`-after-modifier case; a deliberate divergence from upstream swift-format ([#734](https://github.com/toba/swiftiomatic/issues/734))
- `IndentConditionalCompilationBlocks`; a `case` wrapped in a `#if` directly inside a `switch` now stays flush with its sibling cases when `indentConditionalCompilationBlocks` is enabled, instead of gaining an extra indentation level; the conditional-compilation indent still applies to the case body and to normal non-switch `#if` blocks ([#732](https://github.com/toba/swiftiomatic/issues/732))
- Guard statements; when conditions wrap, an inline single-statement `else { stmt }` now stays glued to the closing condition when the whole `else { stmt }` fits on that line, and drops to its own line as a unit only when it doesn't; reverses the earlier "always break before `else`" behavior as a hybrid that preserves the deeply-nested non-fitting case ([#731](https://github.com/toba/swiftiomatic/issues/731))
- Function calls; collapsing a nested call passed as the sole argument of an outer call (e.g. `built.append(Thing(…))`) no longer strands the user's trailing commas before the closing parens (`positionOverride: nil, ), )`); the closing-paren break is forced onto its own line when the call only partially collapses and a trailing comma is present, the now-stray comma is dropped when the call collapses fully to one line (`foo(Bar(a: 1, b: 2))`), and the residual space before `)` is removed ([#739](https://github.com/toba/swiftiomatic/issues/739))

## Week of Jun 07 – Jun 13, 2026

### ✨ Features

- `UseTypedNotificationName` and `UseTypedSystemNotification` lint rules (Swiftui group); flag pre-OS 26 `NotificationCenter` patterns in favor of typed `NotificationCenter.MainActorMessage` adapters — custom `extension Notification.Name { … }` / `Notification.Name("…")` constructions, and uses of system notification names with shipped adapters across `addObserver(forName:)` / `notifications(named:)` / `messages(named:)` / `post(name:)`; adapter table generated from macOS + iOS SDK swiftinterfaces by `Scripts/generate-notification-adapters.sh` (121 entries) plus a hand-curated Foundation legacy-name supplement (17 free-floating `NS*` names)

### 🐞 Fixes

- `ReflowComments`; skip the entire `//` run when it contains commented-out code (any `{` or `}`, or ≥2 lines indented 4+ spaces after the prefix), so SwiftUI snippets and similar blocks aren't reflowed and corrupted; `///` doc comments are unaffected
- Mirror upstream swift-format #1215; attribute argument lists no longer gain an inserted trailing comma under `multilineTrailingCommaBehavior: alwaysUsed` (e.g. `@Foo("a", "b", "c")` stays without a comma); existing trailing commas are preserved
- `SortModifiers`; recognize the `isolated` declaration modifier (Swift 6.2) as part of the isolation slot, so `isolated public func` reorders to `public isolated func` consistently with `nonisolated`
- `NestedCallLayout`; compute the preceding-column prefix in grapheme clusters uniformly instead of mixing `String.count` (graphemes) on tokens with UTF-8 byte length on trivia, so multi-byte characters in preceding comments or identifiers no longer over-count the column and force a needless wrap

## Week of May 31 – Jun 06, 2026

### ✨ Features

- `RequireTaskName` lint rule; warns on `Task { }`, `Task.detached`, `Task.immediate`, `Task.immediateDetached`, `addTask`, and `addTaskUnlessCancelled` calls that omit the Swift 6.2 `name:` argument, so unnamed tasks don't stay anonymous in Instruments and the debugger task list
- `PairAcquireWithDefer` lint rule; flags acquire calls (`lock`, `beginEditing`, `saveGState`, `startAccessingSecurityScopedResource`, etc.) that have no paired `defer { release() }` in the same scope when an early exit (`return` / `throw` / `break` / `continue` / unmarked `try`) follows, with a configurable pair catalog

### 🐞 Fixes

- Function calls; force-break both closures in a two-trailing-closure call when the call has parenthesized arguments (e.g. `.alert(isPresented: …, error: …) { _ in … } message: { … }`), instead of leaving the first closure's body inline while the closing `}` breaks; the empty-args case (`With { expr } query: { … }`) still preserves the inline first closure
- Function calls; a nested call used as the sole argument of an outer call (e.g. `.withTint(Color(red:green:blue:))`) now collapses inline when the whole chain fits, instead of preserving user-supplied per-argument newlines that explode the inner call across 5 lines
- `UseSwiftTestingNames`; in `rawIdentifier` mode, leave single-word `@Test` function names alone (e.g. `@Test func insert()`) instead of wrapping them in pointless backticks that `dropRedundantBackticks` would then flag at every call site
- `CollapseSimpleEnums`; collapse enums with explicit raw values (e.g. `enum Priority: Int { case low = 0, high = 1 }`) instead of skipping them, so single-case forms like `@SQLEntity public enum GoalMetric: Int, CaseIterable, Sendable { case wordCount = 1 }` stay on one line ([#721](https://github.com/toba/swiftiomatic/issues/721))

### 🗜️ Tweaks

- `Layout/Tokens`; remove force unwraps in `CommentMovingRewriter`, extract `arrangeBlockBreaks` helper for the repeated open/close break pattern, name the keyword-alignment offsets in `TokenStream+ControlFlow`, and resolve outstanding `wrapTernaryBranches` lint

## Week of May 24 – May 30, 2026

### ✨ Features

- `HoistCaseLet`; normalize `let`/`var` placement in `catch`-clause patterns, matching existing coverage of `switch`/`if`/`guard`/`while`/`for`-case patterns ([#709](https://github.com/toba/swiftiomatic/issues/709))
- `UseSwiftTestingNames`; add a `style` option with a new `rawIdentifier` mode that converts camelCase `@Test` function names into backtick raw identifiers with spaces (`testMyFeatureHasNoBugs` → `` `my feature has no bugs` ``), matching SwiftFormat's `swiftTestingTestCaseNames` ([#710](https://github.com/toba/swiftiomatic/issues/710))

### 🐞 Fixes

- Conditional compilation; fix an assertion failure (`Too many unresolved delimiter token lengths`) when a `// sm:ignore` directive is applied to the last element of an `#if`/`#elseif`/`#else` clause ([#708](https://github.com/toba/swiftiomatic/issues/708))
- Function calls; keep a single-line string-literal argument value inline with its `label:` when wrapping it onto the next line would still overflow the line and dedent it by less than one indentation unit, instead of pointlessly pushing the string down a line ([#706](https://github.com/toba/swiftiomatic/issues/706))
- `guard`/`if`/`while` conditions; when `alignWrappedConditions` is true and the first condition is a multi-step call chain, wrapped chain lines and subsequent conditions now use the same continuation indent instead of mixing alignment and continuation offsets
- Mirror upstream swift-format #1208; `SplitMultipleDeclsPerLine` no longer leaves the `case` keyword stranded on its own line when a multi-element case declaration's elements span continuation lines
- Function calls; a multi-step member-access chain whose base is itself a function call (e.g. `RoundedRectangle(...).strokeBorder(...)`) no longer over-indents the chain step by one continuation level when used as a single call argument with a discretionary chain newline

### 🗜️ Tweaks

- Evaluate upstream `realm/SwiftLint` rule improvements for Swiftiomatic analogues ([#707](https://github.com/toba/swiftiomatic/issues/707))
- Mirror upstream swift-format #1211; move `@_spi(...)` attributes from an extension onto its members alongside the access level when `HoistExtensionAccess` strips the explicit access level from the extension

## Week of May 17 – May 23, 2026

### ✨ Features

- `CollapseSimpleChains` rule (off by default); collapses multi-line member-access chains onto a single line when the collapsed form fits the line length
- Indent a regular `//` comment one extra space when it directly follows a `///` doc comment, so its body aligns with the doc comment body; gated behind the new `indentation.alignCommentWithAdjacentDocComment` setting (default on) ([#696](https://github.com/toba/swiftiomatic/issues/696))

### 🐞 Fixes

- Mirror upstream swift-format #1203; suppress duplicate whitespace before `where` in a bare-`where` `catch` clause (`do { … } catch where c { … }`) ([#692](https://github.com/toba/swiftiomatic/issues/692))
- `SortImports`; preserve trailing comments that reordering pushes past the final import instead of silently dropping them ([#691](https://github.com/toba/swiftiomatic/issues/691))
- `CollapseSimpleEnums`; collapse raw-value-typed enums (`: String`, `: Int`) onto one line when no case assigns an explicit raw value, instead of refusing on the inheritance type alone ([#693](https://github.com/toba/swiftiomatic/issues/693))
- `LayoutSingleLineBodies`; in inline mode, wrap a function/init/subscript body onto new lines when its generic `where` clause is wrapped onto its own line, instead of gluing an inline `{ body }` to the lone brace ([#694](https://github.com/toba/swiftiomatic/issues/694))
- `if let` / `let` bindings; keep `= try` glued and break at the chain dots instead of wrapping after `=`, when a `try`/`await` member-access chain has discretionary newlines at the dots ([#695](https://github.com/toba/swiftiomatic/issues/695))
- `DropRedundantEquatable`; descend into `#if`/`#else` blocks when collecting stored properties so a conditionally-compiled property (e.g. `#if DEBUG let base: Any.Type`) no longer hides from the rule and triggers wrongful removal of a custom `==` ([#698](https://github.com/toba/swiftiomatic/issues/698))
- Function calls; collapse a single compact argument (array, dict, closure, or function call) onto one line when it fits, discarding source newlines the user placed after `(` or before `)` (e.g. `.starts(with: symbol.utf8.reversed())`) ([#697](https://github.com/toba/swiftiomatic/issues/697))
- Function calls; exclude single function-call arguments containing a closure from the #697 collapse, so a closure-bearing argument (e.g. `.iOSSpecificModifier(SpecificType().onChanged { … })`) keeps its multi-line layout instead of hugging the parens ([#699](https://github.com/toba/swiftiomatic/issues/699))
- Function calls; in a two-trailing-closure call (e.g. `With { expr } query: { … }`), leave the first closure's newline behavior discretionary so an inline single-statement body is preserved as written; 3+ closures still all break
- Function calls; update `multipleTrailingClosures` test expectations to match the per-closure breaking behavior from #700 (each closure breaks independently when it doesn't fit) ([#701](https://github.com/toba/swiftiomatic/issues/701))
- Pattern bindings; type annotation no longer wraps to its own line when the RHS is a `try`/`await`-wrapped member-access chain
- `for … where …` loops; when the header wraps, indent the `where` clause as a continuation and force the opening `{` onto its own line, instead of leaving `where` at the `for` indent with an inline brace ([#702](https://github.com/toba/swiftiomatic/issues/702))

## Week of May 10 – May 16, 2026

### 🐞 Fixes

- `LayoutSingleLineBodies`; chain-wrapping consistent group no longer force-breaks an inlined else-if's `{` onto its own line when sibling branches in the same chain are multi-statement ([#690](https://github.com/toba/swiftiomatic/issues/690))

## Week of May 03 – May 09, 2026

### ✨ Features

- Honor Swift's `@warn(<group>, as: error|warning|ignored)` attribute (renamed `@diagnose` upstream) for per-region finding suppression and severity override; `SwiftWarningControl` integration via lazy region-tree on `Context`; matches both `dropRedundantEscaping` and `DropRedundantEscaping` group identifiers; rule disabled in config stays off ([#641](https://github.com/toba/swiftiomatic/issues/641))
- `NestedCallLayout`; collapse wrapped multi-arg single-level calls and `MacroExpansionExprSyntax` (e.g. `#externalMacro(module:type:)`) onto one line when they fit ([#643](https://github.com/toba/swiftiomatic/issues/643))
- `flagUnusedIgnoreDirective`; lint `// sm:ignore` directives that suppress nothing ([#644](https://github.com/toba/swiftiomatic/issues/644))
- `// sm:ignore:next`; support multiple rules in a single directive ([#645](https://github.com/toba/swiftiomatic/issues/645))
- Where-clause layout; glue `where` to decl line when requirements span multiple lines (each requirement on its own line via consistent group); preserves existing two-tier layout when `where + reqs` fits on a single subsequent line
- `LayoutSingleLineBodies`; inline mode now collapses single-statement closure bodies (`prepareDependencies { … }`)
- Inline computed-property accessor blocks when `get`/`set` bodies are single statements ([#657](https://github.com/toba/swiftiomatic/issues/657))
- `excludes` config option with glob support to skip folders during recursive lint/format
- `sm lint` / `sm format`; default to recursing the cwd or directory argument without `--recursive`; auto-prune `.build`, `.git`, `DerivedData`, `node_modules`, and other known build/artifact dirs
- `RequireSubprocessTeardownSequence`; lint `Subprocess.run(...)` calls missing `platformOptions:` (or default `PlatformOptions()`) which orphan the child on cancellation
- `NoAnyViewInForEach`; lint `AnyView(...)` constructed inside a `ForEach` body
- `FlagUncheckedSendable`; review-only warning on `@unchecked Sendable` conformances
- `FlagMutableStaticVar`; lint `static var` with mutable storage outside test files
- `FlagSupersededSwiftUI`; lint `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `@Published`, `ObservableObject` conformance, and `NavigationView`
- `FlagTaskInMainActor`; lint `Task { ... }` started from a `@MainActor`-isolated context; suggest `Task.immediate`
- `FlagTaskDetached`; lint `Task.detached(...)`; suggest `@concurrent` or `Task.immediateDetached`
- `NoFirstIndexOfInForLoop`; lint quadratic `coll.firstIndex(of:)` / `firstIndex(where:)` inside `for x in coll`
- `sm lint --reporter json`; emit findings as a stable JSON array on stdout with `{file, line, column, severity, rule, message}` per entry; `null` preserved for absent location/rule fields ([#686](https://github.com/toba/swiftiomatic/issues/686))
- `sm format --reporter json`; emit `{changed, unchanged, skipped}` summary on stdout when run with `--in-place`; schema mirrors the lint reporter's `file` key ([#687](https://github.com/toba/swiftiomatic/issues/687))
- `sm upgrade`; run `brew update` then `brew upgrade sm` from the CLI, reporting before/after Cellar versions and warning if Xcode's toolchain `swift-format` symlink no longer points at the Homebrew `sm` binary; `--no-update` skips the metadata refresh

### 🐞 Fixes

- `DropRedundantEscaping`; taint variables propagated through tuple expressions and tuple-pattern destructuring; closures that escape via `inner(tuple: (closure, …))` or `let (local, _) = (completion, …); self.local = local` now correctly keep `@escaping`
- `useForLoopNotForEach`; skip throwing non-`Sequence` `forEach` (e.g. GRDB `Cursor`) ([#646](https://github.com/toba/swiftiomatic/issues/646))
- `flagForEachIDSelfInView`; skip false-positive on `id: \.element.id` from `.enumerated()` ([#647](https://github.com/toba/swiftiomatic/issues/647))
- `useLazyForLongChainOps`; skip chains that already include `.lazy` (multiline receivers no longer mis-fire) ([#648](https://github.com/toba/swiftiomatic/issues/648))
- `flagForEachIDSelfInView`; skip when collection is `*.indices` (`Range<Int>`) ([#649](https://github.com/toba/swiftiomatic/issues/649))
- `flagUnusedIgnoreDirective`; skip flagging known rules that never queried `RuleMask` (eliminates noise on `// sm:ignore:next noForceCast` / `useKeyPath`)
- Lint-only mode now dispatches transform-based rules (`NoForceCast`, `UseKeyPath`); `rewrite: false, lint: .warn` configs emit findings instead of silently dropping them
- Assignment-RHS chain precedence; bound `=`-break chunk so `try`/`await`-prefixed member chains wrap on the chain dot rather than the assignment
- Assignment `=` no longer fires alongside chain breaks for member chains whose head has a trailing closure (e.g. SQL builder DSLs); retarget the head-call's group close before the discretionary chain dot when the chain is the RHS of `let/var =` ([#658](https://github.com/toba/swiftiomatic/issues/658))
- Don't wrap `Regex` generic argument with tuple type when it fits ([#655](https://github.com/toba/swiftiomatic/issues/655))
- `ReflowComments`; blockquotes no longer lose lazy continuation lines ([#654](https://github.com/toba/swiftiomatic/issues/654))
- `ReflowComments`; punctuation around inline code spans no longer gets space-separated ([#656](https://github.com/toba/swiftiomatic/issues/656))
- `sm format`; preserve binary operators across newlines inside multi-line `"""` interpolations; `type\n?? outputType` no longer collapses to `type?? outputType` (Swift lexer reclassified `??` as postfix) ([#662](https://github.com/toba/swiftiomatic/issues/662))
- `sm lint` with no arguments produces no output in project root ([#661](https://github.com/toba/swiftiomatic/issues/661))
- `useFinalClasses`; findings collapsed to line 1 of the file; bind `original` in `transform` and resolve the lint cache's executable fingerprint via `Bundle.main.executablePath` so bare `sm` invocations pick up rebuilds instead of returning stale cached findings ([#664](https://github.com/toba/swiftiomatic/issues/664))
- `convertStaticStructToEnum`; same location collapse and stale-cache symptom as `useFinalClasses`; resolved by the same anchor and cache-fingerprint fix ([#665](https://github.com/toba/swiftiomatic/issues/665))
- `useWeakLetForUnreassigned`; misses cross-class assignments ([#666](https://github.com/toba/swiftiomatic/issues/666))
- `dropRedundantClosureWrapper`; no longer recommends switch-expression in argument position where it wouldn't compile ([#667](https://github.com/toba/swiftiomatic/issues/667))
- `requireAsyncStreamFinish`; skip `AsyncStream(unfolding:)` which has no `finish()` API ([#668](https://github.com/toba/swiftiomatic/issues/668))
- `requireSuiteAccessControl`; thread the un-detached `original` decl through diagnose anchors so findings land on the actual line/col when sibling rules detach the rewritten subtree ([#670](https://github.com/toba/swiftiomatic/issues/670))
- `DropRedundantSendable`; remove rule entirely; the non-public-strip premise was unsound without type info, stripping `: Sendable` from types whose stored properties weren't actually `Sendable`
- `DropRedundantThrows`; restrict to non-`override`, explicitly `private`/`fileprivate` functions; previously stripped `throws` from override / internal / public functions, breaking compile at `try` call sites and `@objc` overrides
- `// sm:ignore:next`; honor directives placed in interior token leading trivia (e.g. between `@MainActor` and `override func setUp() async throws`), not just before the node's first token
- `UseTernary`; refuse to fold when either branch is a `switch` or `if` expression; those forms are only valid in return/throw/assignment-RHS positions, never as a ternary sub-expression
- `sm format`; preserve `#if false ... #endif` compilation guards instead of stripping them and exposing intentionally-disabled code to the compiler ([#672](https://github.com/toba/swiftiomatic/issues/672))
- DocC; `- Returns:` no longer indented as a `Parameters` child
- `DropRedundantReturn`; preserve explicit `return` in multi-branch if/switch bodies when the enclosing decl's return type is opaque (`some P`) or existential (`any P`); collapsing to an if/switch *expression* breaks generic-parameter inference for branch calls whose type is pinned by the contextual return type ([#689](https://github.com/toba/swiftiomatic/issues/689))

### 🗜️ Tweaks

- `visitExpressionSegment`; restore upstream apple/swift-format verbatim emission with per-line re-indent so multi-line interpolations preserve developer formatting and stay above the closing `"""` column; eliminates the token-adjacency heuristic surface that caused `ugi-3p0` ([#663](https://github.com/toba/swiftiomatic/issues/663))
- Investigate upstream HIGH cite changes; defer `unused_imports` rule and first-class `@diagnose` (`SwiftWarningControl`) adoption to follow-ups ([#640](https://github.com/toba/swiftiomatic/issues/640))
- Evaluate swift-syntax 604 prerelease / Swift 6.3.1 alignment; skip both; `603.0.1` is stable and no 604-only API is needed today ([#642](https://github.com/toba/swiftiomatic/issues/642))
- Address build warnings ([#639](https://github.com/toba/swiftiomatic/issues/639))
- `Lint pipeline perf & cleanup follow-ups`; close out epic covering P2, P3, P6, P8–P14, C1, C2, C4, N1–N5, M1, M2, M4 ([#536](https://github.com/toba/swiftiomatic/issues/536))
- Address `sm lint` warnings in recently-changed source files; replace `description!` ternaries with `?? propertyName`, factor `arguments.first!` in `NestedCallLayout` behind `soleArgument(of:)`, wrap `CommentReflowEngine` block-quote ternary, drop redundant `self.` in `Glob.init?`
- `FlagForEachOverIndices`; lint `ForEach` whose receiver is integer-indexed (`.indices`, ranges); orthogonal to `flagForEachIDSelfInView` (id-axis vs receiver-axis)
- Audit and extend `UseContinuousClockNotDate` for elapsed-timing patterns including `Date().timeIntervalSince(start)`
- Mechanical rule candidates from `/swift` skill review; epic closed (rules tracked individually)

## Week of Apr 26 – May 02, 2026

### ✨ Features

- `noMutableInCaptureList`; replace `noMutableCapture`; flag explicit `[var]` capture-list entries instead of implicit references; matches SwiftLint's `CaptureVariableRule` semantics ([#627](https://github.com/toba/swiftiomatic/issues/627))
- `RequireCamelCaseIdentifiers`; allow `debug_` and `unsafe_` prefixes ([#623](https://github.com/toba/swiftiomatic/issues/623))
- `ReflowComments` rule; rewrap regular and DocC comments to line length
- `guard ... else { stmt }`; keep inline body attached when conditions wrap ([#530](https://github.com/toba/swiftiomatic/issues/530))
- Cat 9 accessor & declaration patterns; 3 new rules ([#315](https://github.com/toba/swiftiomatic/issues/315))
- Configuration schema redesign; `style` + universal parameters
- CLI; replace `--rules` plumbing with `--style`
- Spike combined `SyntaxRewriter`; single walk for node-local rules
- Collapse compact-pipeline rule shells into pure helpers ([#509](https://github.com/toba/swiftiomatic/issues/509))
- Eliminate `RewriteSyntaxRule` base class ([#508](https://github.com/toba/swiftiomatic/issues/508))
- `singleLineBodies`; keep inline body when conditions wrap (guard/if) ([#448](https://github.com/toba/swiftiomatic/issues/448))
- Configuration schema redesign; `style` + universal parameters ([#481](https://github.com/toba/swiftiomatic/issues/481))
- CLI; replace `--rules` plumbing with `--style` ([#482](https://github.com/toba/swiftiomatic/issues/482))
- Spike combined `SyntaxRewriter`; single walk for node-local rules ([#479](https://github.com/toba/swiftiomatic/issues/479))
- Cache lint results by file content hash ([#526](https://github.com/toba/swiftiomatic/issues/526))
- Comment reformatter; exclude file header comment ([#532](https://github.com/toba/swiftiomatic/issues/532))
- `ReflowComments`; rewrap regular and DocC comments to fit print width ([#457](https://github.com/toba/swiftiomatic/issues/457))
- `PreferOfficialCDecl`; rewrite `@_cdecl` to `@c` (SE-0407) ([#571](https://github.com/toba/swiftiomatic/issues/571))
- `PreferOfficialSpecialize`; rewrite `@_specialize` to `@specialize` ([#580](https://github.com/toba/swiftiomatic/issues/580))
- `WeakLetForUnreassignedWeakVar`; lint `weak var` properties never reassigned (SE-0481) ([#578](https://github.com/toba/swiftiomatic/issues/578))
- `RedundantMainActorOnView`; strip `@MainActor` from `View`/`App`/`Scene` conformers ([#570](https://github.com/toba/swiftiomatic/issues/570))
- `PreferEmptyCollectionForArrayArgs`; opt-in lint of `[]`/`[x]` as call arguments ([#576](https://github.com/toba/swiftiomatic/issues/576))
- `PreferContinuousClockOverDate`; lint `Date().timeIntervalSince(_:)` elapsed-time pattern ([#574](https://github.com/toba/swiftiomatic/issues/574))
- `SuggestOrderedSetForUniqueAppend`; lint `if !x.contains(y) { x.append(y) }` ([#569](https://github.com/toba/swiftiomatic/issues/569))
- `NoAwaitInsideWithLock`; lint `await` inside `withLock { … }` bodies ([#581](https://github.com/toba/swiftiomatic/issues/581))
- `NoNestedWithLock`; lint nested `withLock` on the same receiver ([#583](https://github.com/toba/swiftiomatic/issues/583))
- `NoMutationOfIteratedCollection`; lint mutating calls on the loop subject ([#579](https://github.com/toba/swiftiomatic/issues/579))
- `NoFormatterInSwiftUIBody`; lint `Formatter()` constructed in SwiftUI `body` ([#586](https://github.com/toba/swiftiomatic/issues/586))
- `NoSortFilterInForEachData`; lint `.sorted`/`.filter`/`.map` chains in `ForEach` data ([#575](https://github.com/toba/swiftiomatic/issues/575))
- `WarnForEachIdSelf`; lint `ForEach(_, id: \.self)` ([#587](https://github.com/toba/swiftiomatic/issues/587))
- `PreferClosureNotificationObserver`; lint selector-based `addObserver(_:selector:name:object:)` ([#567](https://github.com/toba/swiftiomatic/issues/567))
- `AsyncStreamMissingTermination`; lint `AsyncStream` bodies that yield without `finish()` or `onTermination` ([#573](https://github.com/toba/swiftiomatic/issues/573))
- `NoDataDropPrefixInLoop`; lint `.dropFirst`/`.prefix`/`.dropLast`/`.suffix` inside loop bodies ([#585](https://github.com/toba/swiftiomatic/issues/585))
- `PreferLazyForLongChain`; lint chains of 3+ collection transforms ([#582](https://github.com/toba/swiftiomatic/issues/582))
- `WarnRecursiveWithObservationTracking`; lint `withObservationTracking` `onChange` recursing into the enclosing function ([#584](https://github.com/toba/swiftiomatic/issues/584))
- `PreferTypedThrowsOverResult`; lint `Result<T, E>` returns with a single do/catch ([#572](https://github.com/toba/swiftiomatic/issues/572))
- `WarnSwapThenRemoveAll`; lint `swap(&a, &b)` followed by `a.removeAll`/`b.removeAll` ([#577](https://github.com/toba/swiftiomatic/issues/577))
- `// sm:ignore`; unified directive replaces `// sm:ignore-file`; applies from comment to end of file (lone-line) or to the line only (trailing) ([#595](https://github.com/toba/swiftiomatic/issues/595))
- `// sm:ignore:next`; new directive scoped to the next line only ([#620](https://github.com/toba/swiftiomatic/issues/620))
- `guard`/`else`; always break before `else` when conditions wrap ([#635](https://github.com/toba/swiftiomatic/issues/635))

### 🗜️ Tweaks

- Address build warnings; replace `data(using:)` with `Data(_:.utf8)`, drop IUOs, switch IIFEs to `if`/`else` expressions, mark `Configurable` `Sendable`, discard unused `popLast` results ([#639](https://github.com/toba/swiftiomatic/issues/639))

### 🐞 Fixes

- `useTrailingClosures`; anchor finding on the original pre-rewrite call instead of the detached `super.visit` result so the warning lands on the actual call site rather than line 1 ([#636](https://github.com/toba/swiftiomatic/issues/636))
- `noMutableCapture`; gate on stored closures and skip property-wrapper vars, member-access bases, subscript writes, pure writes, and inout to eliminate false positives on inline closures ([#626](https://github.com/toba/swiftiomatic/issues/626))
- `sm:ignore`; per-finding mask gate so directives suppress findings emitted from rules that visit an enclosing node ([#624](https://github.com/toba/swiftiomatic/issues/624))
- Multiline string formatter mangles indentation, producing 'Insufficient indentation' error ([#625](https://github.com/toba/swiftiomatic/issues/625))
- `noMutableCapture`; invert semantics to flag implicit references rather than explicit `[var]` capture lists; downgrade default severity to `warn` ([#622](https://github.com/toba/swiftiomatic/issues/622))
- `LintCache`; mix the running executable's path/size/mtime into the rule-set fingerprint so binary rebuilds invalidate stale cached findings ([#621](https://github.com/toba/swiftiomatic/issues/621))
- `SimplifyGenericConstraints`; anchor diagnostics to the original `where` clause instead of the rewritten subtree's detached position ([#615](https://github.com/toba/swiftiomatic/issues/615))
- `wrapTernaryBranches`; skip when both `?` and `:` source lines already fit, even when an operand is a multi-line chain ([#614](https://github.com/toba/swiftiomatic/issues/614))
- `ReflowComments`; preserve CommonMark link reference definitions (`[label]: url`) instead of merging adjacent definitions into one paragraph ([#613](https://github.com/toba/swiftiomatic/issues/613))
- `wrapTernary`; skip ternaries inside single-line string interpolations to avoid producing invalid Swift ([#602](https://github.com/toba/swiftiomatic/issues/602))
- `PreferIfElseChain`; rewrite guard-return + trailing return to `if/else` expression in implicit-return positions ([#563](https://github.com/toba/swiftiomatic/issues/563))
- `extension` where-clause; apply continuation indent when `where` wraps to its own line
- `sm update`; respect rule sort order
- Don't re-indent commented-out code lines ([#445](https://github.com/toba/swiftiomatic/issues/445))
- `schema.json`; emit severity properties on lint-only rules with `Lint`-typed config
- Threshold lint rules; replace `lint` property with `enabled`; introduce `ThresholdRuleValue` ([#447](https://github.com/toba/swiftiomatic/issues/447))
- Formatter; preserve inline `nestedCallLayout`; don't wrap long strings pointlessly ([#444](https://github.com/toba/swiftiomatic/issues/444))
- `sm format`; don't mangle closures and `reduce` expressions ([#443](https://github.com/toba/swiftiomatic/issues/443))
- Member access chain assignment; chain `.` break now beats args `(` and `=` per documented precedence ([#454](https://github.com/toba/swiftiomatic/issues/454))
- `KeepFunctionOutputTogether`; protocol method no longer wraps return arrow off the signature ([#456](https://github.com/toba/swiftiomatic/issues/456))
- `ReflowComments`; preserve indentation on `- Parameters:` sub-items ([#459](https://github.com/toba/swiftiomatic/issues/459))
- `ReflowComments`; keep DocC `` ``Symbol`` `` references intact instead of splitting with stray spaces ([#460](https://github.com/toba/swiftiomatic/issues/460))
- Suppress whitespace findings during `sm lint`; indentation no longer surfaces as warnings in Xcode ([#465](https://github.com/toba/swiftiomatic/issues/465))
- `case ... where ...`; indent the `where` keyword past `case` when the clause wraps
- `NestingDepth`; depth counter now decrements on `visitPost`
- `ExtensionAccessLevel`; don't hoist access modifier onto extensions that declare protocol conformance
- `guard` with single-line body; wrap body onto next line instead of splitting the condition
- `RedundantBackticks`; suppress false positive on `guard` used as a property name
- `NoSelfReference`; preserve `self.` before keyword-named methods like `is(_:)`
- Fix 8 failing layout tests
- `return`; break after the keyword instead of before the first chained call
- Comment wrapping; converge in a single formatter pass
- `BeforeGuardConditions`; pretty printer is now idempotent for guard `else` placement (single-statement bodies always glue `else {` to the closing condition when it fits)
- Lint-mode finding emission; verify behavior after compact-pipeline cutover ([#506](https://github.com/toba/swiftiomatic/issues/506))
- Formatter; keep single chained trailing `.with()` call on one line instead of wrapping ([#477](https://github.com/toba/swiftiomatic/issues/477))
- Wrapped comma lists; once any element wraps, every element wraps to its own line ([#529](https://github.com/toba/swiftiomatic/issues/529))
- `RedundantFinal`; preserve `final` on nested class decls ([#527](https://github.com/toba/swiftiomatic/issues/527))
- Wrap function call args before breaking comparison operators ([#533](https://github.com/toba/swiftiomatic/issues/533))
- Keep short `if let` conditions on one line instead of splitting across lines ([#473](https://github.com/toba/swiftiomatic/issues/473))
- Comparison operator no longer wraps before call args in `if` condition ([#531](https://github.com/toba/swiftiomatic/issues/531))
- `if case let` early return now converts to if/else expression ([#524](https://github.com/toba/swiftiomatic/issues/524))
- Don't wrap type annotation onto its own line in `let` with ternary RHS ([#476](https://github.com/toba/swiftiomatic/issues/476))
- Single-element array literal stays inline ([#523](https://github.com/toba/swiftiomatic/issues/523))
- Don't strip `.init` from metatype call; preserves valid Swift ([#520](https://github.com/toba/swiftiomatic/issues/520))
- Inline `guard else { stmt }` body when `alignWrappedConditions = true` ([#525](https://github.com/toba/swiftiomatic/issues/525))
- `PreferTernary`; convert if/return + return into ternary return ([#522](https://github.com/toba/swiftiomatic/issues/522))
- Don't wrap type annotation in `let` with function-call RHS ([#535](https://github.com/toba/swiftiomatic/issues/535))
- `case ... where ...`; continuation line indents past `case` ([#467](https://github.com/toba/swiftiomatic/issues/467))
- `extension` where-clause; apply continuation indent on wrapped `where` ([#455](https://github.com/toba/swiftiomatic/issues/455))
- `for ... where`; place `where` keyword on its own line at base indent when the header wraps
- Nested call args; inner call no longer cascades into a redundant wrap when the outer call wraps
- `switch case`; align wrapped patterns under the first pattern when `alignWrappedConditions` is set
- `switch case`; keep inline single-statement body when wrapped patterns share an alignment column
- Tuple return type; stay inline when the function signature already wraps
- `WrapTernary`; produce wrapped form rather than collapsing to a single-line ternary
- `PreferTrailingClosures`; don't rewrite closures inside bare `guard`/`if` conditions ([#591](https://github.com/toba/swiftiomatic/issues/591))
- `preferFinalClasses`; honor per-rule `rewrite: false` and skip the rewrite path ([#590](https://github.com/toba/swiftiomatic/issues/590))
- `uppercaseAcronyms`; honor per-rule `rewrite: false` and skip the rewrite path ([#592](https://github.com/toba/swiftiomatic/issues/592))
- `noDataDropPrefixInLoop`; restrict to receivers tied to the loop's iteration or shrink-in-place pattern ([#594](https://github.com/toba/swiftiomatic/issues/594))
- `assertFormatting`; add regression coverage for the bare-guard/if conditional-context fix ([#593](https://github.com/toba/swiftiomatic/issues/593))
- `schema.json`; emit string properties that omit an explicit `type` annotation ([#596](https://github.com/toba/swiftiomatic/issues/596))
- Misfiring `wrapTernary`/`useImplicitInit`/`redundantType`; thread `original` node through `StaticFormatRule.transform` so findings anchor in the original source's coordinate space; `redundantType` exempts stored properties on type declarations
- Schema generator; emit raw values (e.g. `get_set`/`set_get`) instead of Swift case identifiers for enum-typed config properties ([#609](https://github.com/toba/swiftiomatic/issues/609))
- `// sm:ignore`; trailing directive now suppresses across the whole statement when placed on the opening line (e.g. `if x { // sm:ignore Foo`), matching the prior closing-brace behavior
- `DropRedundantSelf`; preserve `self.` in extensions on `@dynamicMemberLookup` types (`AttributedString`, `AttributedSubstring`, `ScopedAttributeContainer`, `Binding`); document the cross-module limitation
- `LayoutSingleLineBodies`; else-if condition no longer wraps to a brace-on-next-line layout
- `LayoutSingleLineBodies`; wrapped collection literal now collapses onto one line in inline mode when it fits; dictionary-literal collapse clears `key.trailingTrivia`, `colon` trivia, and `value.leadingTrivia` so odd whitespace around `:` is normalized
- `noMutableCapture`; track shadowing from enclosing function bodies, parameters, accessors, and code blocks (not just enclosing closure signatures) so a `let` declared in an outer scope shadows an unrelated file-level `var` of the same name; exclude stored properties of types from the mutable-names set so SwiftUI views and class members aren't treated as implicit-capture candidates
- `RemoveRedundantSelf`; preserve required `self.` in extension property accessors ([#616](https://github.com/toba/swiftiomatic/issues/616))
- Nested call; inner call with wrapped args hugs outer call's open paren ([#597](https://github.com/toba/swiftiomatic/issues/597))
- `dropRedundantNilCoalescing`; correct finding location instead of anchoring on doc comment or struct decl ([#632](https://github.com/toba/swiftiomatic/issues/632))
- `DropRedundantSelf`; preserve `self.` in `@autoclosure @escaping` arguments ([#630](https://github.com/toba/swiftiomatic/issues/630))
- Don't wrap labeled argument when wrapping doesn't help fit the line ([#631](https://github.com/toba/swiftiomatic/issues/631))
- `DropRedundantSelf`; preserve `self.X` where `X` is the enclosing function's name ([#634](https://github.com/toba/swiftiomatic/issues/634))
- `DropRedundantNilCoalescing`; preserve `?? nil` needed to flatten double-optional from `fetchOne` ([#633](https://github.com/toba/swiftiomatic/issues/633))
- Single-line body rule; collapse multi-pattern case with body on next line ([#598](https://github.com/toba/swiftiomatic/issues/598))
- `InlineBodies`; preserve trailing comment when collapsing to single line ([#628](https://github.com/toba/swiftiomatic/issues/628))
- Single-line body rule; collapse multi-condition `if` with single-statement body ([#599](https://github.com/toba/swiftiomatic/issues/599))
- `splitMultipleDeclsPerLine`; suppress false positive on enum case with raw value ([#629](https://github.com/toba/swiftiomatic/issues/629))

### 🗜️ Tweaks

- Self-lint review; dogfood Swiftiomatic on `Sources/`; reduce 293 warnings to 31 structural ([#589](https://github.com/toba/swiftiomatic/issues/589))
- Port missing SwiftLint rules ([#308](https://github.com/toba/swiftiomatic/issues/308))
- Align rule type names with config keys ([#441](https://github.com/toba/swiftiomatic/issues/441))
- Rule configuration groups; rename `forcing`→`unsafety`; add `memory`; regroup ungrouped ([#440](https://github.com/toba/swiftiomatic/issues/440))
- Add golden-corpus diff harness for format pipeline ([#461](https://github.com/toba/swiftiomatic/issues/461))
- Inventory format rules; node-local vs structural vs deletable
- Design `compact` style spec
- Stub `roomy` style; reserve name only
- Scaffold compact dispatch in `RewriteCoordinator`
- Emit `CompactStageOneRewriter+Generated.swift`
- Extract static transforms; Access + Closures + Conditions clusters ([#493](https://github.com/toba/swiftiomatic/issues/493))
- Extract static transforms; Declarations + Generics + Hoist + Idioms + Literals ([#490](https://github.com/toba/swiftiomatic/issues/490))
- Extract static transforms; Redundancies + Sort + Wrap ([#494](https://github.com/toba/swiftiomatic/issues/494))
- Order and wire 13 structural passes for `compact` ([#488](https://github.com/toba/swiftiomatic/issues/488))
- Convert deferred rules; complete the rule port ([#496](https://github.com/toba/swiftiomatic/issues/496))
- Golden-corpus diff verification and perf gate ([#489](https://github.com/toba/swiftiomatic/issues/489))
- Triage rules with cross-visit state and recursive rewriter calls ([#501](https://github.com/toba/swiftiomatic/issues/501))
- Phase 4a; merge `SourceFile` rewrites ([#502](https://github.com/toba/swiftiomatic/issues/502))
- Phase 4b; merge token rewrites ([#503](https://github.com/toba/swiftiomatic/issues/503))
- Phase 4c; merge declaration rewrites ([#495](https://github.com/toba/swiftiomatic/issues/495))
- Phase 4d; merge statement rewrites ([#500](https://github.com/toba/swiftiomatic/issues/500))
- Phase 4e; merge expression rewrites ([#499](https://github.com/toba/swiftiomatic/issues/499))
- Phase 4f; retarget test harness and verify ([#498](https://github.com/toba/swiftiomatic/issues/498))
- Phase 4 swift review; refactor merged compact-pipeline files ([#504](https://github.com/toba/swiftiomatic/issues/504))
- `WrapTernary`; retarget layout test harness off the rule's instance override ([#507](https://github.com/toba/swiftiomatic/issues/507))
- Cut over to `compact` pipeline; delete superseded rule files ([#480](https://github.com/toba/swiftiomatic/issues/480))
- Replace discrete rules with style-driven pipelines ([#470](https://github.com/toba/swiftiomatic/issues/470))
- Update README, `CLAUDE.md`, and sub-target READMEs for the style model ([#483](https://github.com/toba/swiftiomatic/issues/483))
- Drop `applyRule` ladders; push selection / `sm:ignore` checks into the dispatcher ([#514](https://github.com/toba/swiftiomatic/issues/514))
- Replace metatype-keyed `Context.ruleState(for:)` with typed state properties ([#513](https://github.com/toba/swiftiomatic/issues/513))
- Rename `RewriteSyntaxRule` to `StructuralFormatRule`; hoist gating to dispatcher ([#511](https://github.com/toba/swiftiomatic/issues/511))
- Delete legacy `RewritePipeline` shells; regen `schema.json` ([#487](https://github.com/toba/swiftiomatic/issues/487))
- Phase 4g; flip default and delete legacy ([#497](https://github.com/toba/swiftiomatic/issues/497))
- Collapse rewrite pipeline boilerplate; let the generator do the work ([#510](https://github.com/toba/swiftiomatic/issues/510))
- Cache `shouldRewrite` per visit in `CompactStageOneRewriter` ([#516](https://github.com/toba/swiftiomatic/issues/516))
- Inline compact-pipeline rule transforms; delete `applyRewrite` shim ([#515](https://github.com/toba/swiftiomatic/issues/515))
- Speed up `swift package test` wall-time; prebuild lint plugin ([#528](https://github.com/toba/swiftiomatic/issues/528))
- Lint pipeline review; perf, correctness, modernization findings ([#534](https://github.com/toba/swiftiomatic/issues/534))
- Remove style configuration concept ([#518](https://github.com/toba/swiftiomatic/issues/518))
- Compact rewriter; dedupe and perf-tune visit overrides ([#521](https://github.com/toba/swiftiomatic/issues/521))
- Remove vestigial `CombinedRewriter` spike ([#517](https://github.com/toba/swiftiomatic/issues/517))
- Generator no longer emits duplicate `shouldRewrite` checks per node ([#519](https://github.com/toba/swiftiomatic/issues/519))
- `LintCache.Entry`; store `Lint` directly; drop parallel `Severity` enum ([#540](https://github.com/toba/swiftiomatic/issues/540))
- `LintCache`; promote `Entry.Location` and `Entry.Note` to top-level types ([#542](https://github.com/toba/swiftiomatic/issues/542))
- `LintCache`; document concurrent writer race; last-writer-wins ([#548](https://github.com/toba/swiftiomatic/issues/548))
- `CapturingFindingConsumer`; document single-thread invariant ([#547](https://github.com/toba/swiftiomatic/issues/547))
- `Context.preparedAcronyms`; verified gated by `shouldRewrite` when `UppercaseAcronyms` disabled ([#545](https://github.com/toba/swiftiomatic/issues/545))
- `Mutex` shape on `LintCache.lastFingerprint`; verified ([#544](https://github.com/toba/swiftiomatic/issues/544))
- Audit `LintSyntaxRule` subclasses for `final` and `static`; documented `class var` requirement ([#538](https://github.com/toba/swiftiomatic/issues/538))
- Audit lint-flagged IIFE patterns; simplify `preparedAcronyms` initializer ([#541](https://github.com/toba/swiftiomatic/issues/541))
- Verify `consumeFinding` and `consumeCachedEntry` produce byte-identical output; add `LintCache` schema round-trip tests ([#553](https://github.com/toba/swiftiomatic/issues/553))
- Rename DocC comment rules for self-documenting names; `convertRegularCommentToDocC`→`useDocCommentsOnAPI`, `useTripleSlashForDocComments`→`useTripleSlashOverDocBlock`, `requireDocCommentSummary`→`requireDocSummaryStructure`, `requireParameterDocs`→`requireParameterAndReturnDocs`, `noDocCommentsInsideFunctions`→`noDocCommentsInFunctionBodies`, `flagOrphanedDocComment`→`noOrphanedDocComment`
- `LayoutSingleLineBodies`; extract shared `shouldInlineCollection` helper so array/dict variants share precondition + length check + diagnostic emission
- `WrapTernaryBranches.singleLineLength`; replace `split(...).joined(...).count` with a single-pass character scan that collapses whitespace runs in place
- Split `SwiftiomaticKit` into parallelizable targets ([#566](https://github.com/toba/swiftiomatic/issues/566))
- Review high-relevance upstream `swift-format` changes ([#600](https://github.com/toba/swiftiomatic/issues/600))
- Make rule config keys self-describing ([#607](https://github.com/toba/swiftiomatic/issues/607))
- Rename rule config keys for clarity in Xcode JSON editor ([#604](https://github.com/toba/swiftiomatic/issues/604))
- Strict-mirror keys + verb re-evaluation in `wrap`/`lineBreaks`/`indentation` groups ([#608](https://github.com/toba/swiftiomatic/issues/608))
- Standardize rule config naming verbs (`use*`/`no*`/`flag*`/`require*`) ([#605](https://github.com/toba/swiftiomatic/issues/605))

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
- Cat 2 redundancy & cleanup rules ([#319](https://github.com/toba/swiftiomatic/issues/319))
- Cat 3 modern Swift idiom rules ([#311](https://github.com/toba/swiftiomatic/issues/311))
- Cat 5 type-safety & data-handling rules ([#318](https://github.com/toba/swiftiomatic/issues/318))
- Cat 7 metrics rules; `LineLengthLimit`, `FileLength`, `TypeBodyLength`, `FunctionBodyLength`, `ClosureBodyLength`, `CyclomaticComplexity`, `NestingDepth`, `ParameterCount`, `TupleSize`, `AssociatedValueCount` ([#314](https://github.com/toba/swiftiomatic/issues/314))
- Cat 8 documentation & comments rules; `ExpiringTodo`, `NoLocalDocComments`, `OrphanedDocComment` ([#317](https://github.com/toba/swiftiomatic/issues/317))
- Wrap ternary; true and false branches each on their own line ([#415](https://github.com/toba/swiftiomatic/issues/415))

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
- Format rule deletes trailing closure on `.reduce`; leaving call broken ([#416](https://github.com/toba/swiftiomatic/issues/416))
- `singleLineBodies` inline doesn't collapse `for-in` body that fits on one line ([#414](https://github.com/toba/swiftiomatic/issues/414))
- Commented-out code lines preserve author's column at column 0; don't re-indent to scope
- Suppress continuation wraps that don't bring overflowing lines below the limit; long string args stay on their label line

### 🗜️ Tweaks

- Align rule type names with config keys; uniform grammar within each group, drop gratuitous key overrides
- Rename `forcing` group to `unsafety`; add `memory` group; assign all previously-ungrouped rules to a group ([#440](https://github.com/toba/swiftiomatic/issues/440))
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
- Pre-release Swift code review cleanup ([#417](https://github.com/toba/swiftiomatic/issues/417))
- Convert trivia-only rewrite rules to pretty-print layout ([#387](https://github.com/toba/swiftiomatic/issues/387))
- Improve JSON schema descriptions for rules ([#439](https://github.com/toba/swiftiomatic/issues/439))
- Audit visitor-state lifecycle ([#419](https://github.com/toba/swiftiomatic/issues/419))
- `ConfigurationLoader`; mutating struct to `final class` ([#428](https://github.com/toba/swiftiomatic/issues/428))
- Extract `Configuration` entry / JSON-modify / range-parse helpers ([#434](https://github.com/toba/swiftiomatic/issues/434))
- Extract modifier-check and config-reading helpers ([#418](https://github.com/toba/swiftiomatic/issues/418))
- Layout output; hot-path string allocations ([#429](https://github.com/toba/swiftiomatic/issues/429))
- `Configuration` equality; avoid encoder allocation per call ([#436](https://github.com/toba/swiftiomatic/issues/436))
- Remove unnecessary `nonisolated(unsafe)` annotations ([#433](https://github.com/toba/swiftiomatic/issues/433))
- Replace `[String: any Sendable]` storage in `Configuration` ([#430](https://github.com/toba/swiftiomatic/issues/430))
- Misc small perf nits in Layout, Schema, Rules ([#427](https://github.com/toba/swiftiomatic/issues/427))
- Naming nits; `no`, `doesThrow`, `isUsed` ([#425](https://github.com/toba/swiftiomatic/issues/425))
- Consolidate `TokenStream+Helpers` overloads ([#435](https://github.com/toba/swiftiomatic/issues/435))
- Frontend parallelism; `DispatchQueue` to `TaskGroup`; stream files ([#426](https://github.com/toba/swiftiomatic/issues/426))
- Quadratic lookups in `PreferSynthesizedInitializer` / `OpaqueGenericParameters` ([#437](https://github.com/toba/swiftiomatic/issues/437))
- Findings emission; better anchors and notes ([#423](https://github.com/toba/swiftiomatic/issues/423))
- Dead code; commented `ConfigurationItem`; missing `schemaURL` ref ([#420](https://github.com/toba/swiftiomatic/issues/420))
- Drop `@unchecked Sendable` from Frontend classes ([#438](https://github.com/toba/swiftiomatic/issues/438))
- Typed throws on `JSON5Scanner` and configuration loaders ([#421](https://github.com/toba/swiftiomatic/issues/421))
- `fatalError` audit; convert programmer-error invariants ([#432](https://github.com/toba/swiftiomatic/issues/432))
- Consolidate duplicated rule `visit` overloads ([#424](https://github.com/toba/swiftiomatic/issues/424))

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
