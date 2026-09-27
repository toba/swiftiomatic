import Foundation
import SwiftSyntax
import SwiftOperators
@_spi(ExperimentalLanguageFeatures) import SwiftWarningControl

/// Context contains the bits that each formatter and linter will need access to.
///
/// Specifically, it is the container for the shared configuration, diagnostic consumer, and URL of
/// the current file.
package final class Context {
    /// Tracks whether a supported test library (see `supportedTestLibraryModuleNames`) has been
    /// imported so that certain logic can be modified for files that are known to be tests.
    package enum AnyTestImportState {
        case notDetermined, importsTestLibrary, doesNotImportTestLibrary
    }

    /// The configuration for this run of the pipeline, provided by a configuration JSON file.
    let configuration: Configuration

    /// The selection to process
    let selection: Selection

    /// Defines the operators and their precedence relationships that were used during parsing.
    let operatorTable: OperatorTable

    /// Emits findings to the finding consumer.
    let findingEmitter: FindingEmitter

    /// The URL of the file being linted or formatted.
    let fileURL: URL

    /// Indicates whether the file is known to import a supported test library.
    ///
    /// The lint and rewrite pipelines drive a single `Context` per file serially, so concurrent
    /// reads/writes are not expected. If that invariant changes, this needs to become atomic.
    package var importsAnyTestLibrary: AnyTestImportState

    /// An object that converts `AbsolutePosition` values to `SourceLocation` values.
    package let sourceLocationConverter: SourceLocationConverter

    /// Contains the rules have been disabled by comments for certain line numbers.
    let ruleMask: RuleMask

    /// The parsed source file syntax for this run. Retained so the warning-control region tree
    /// (`@warn` / `@diagnose` attribute scopes) can be lazily built on first lookup without
    /// re-walking the parser.
    let sourceFileSyntax: SourceFileSyntax

    /// The file's `@warn` attribute scopes, built on first lookup.
    ///
    /// The walk is single-pass and only runs when a rule reaches `warningControlSeverity(of:at:)` ,
    /// which happens when it emits a finding.
    lazy var warningControlRegionTree: WarningControlRegionTree =
        sourceFileSyntax.warningGroupControlRegionTree()

    /// One `FreeFunctionIndex` per tree, built on first lookup.
    ///
    /// Keyed by the root rather than held as one value, because a structural pass hands rules a
    /// new tree. An index records a scope as a node identity, so it only answers for the tree it
    /// was built from.
    private var freeFunctionIndexes: [SyntaxIdentifier: FreeFunctionIndex] = [:]

    /// The functions in `root` that a bare-name call reaches
    ///
    /// The rules that follow a loop into the helpers it calls read this. The index depends on the
    /// tree alone, so building one per loop would walk the whole file once per loop.
    func freeFunctions(in root: Syntax) -> FreeFunctionIndex {
        if let cached = freeFunctionIndexes[root.id] { return cached }

        let index = FreeFunctionIndex(root: root)
        freeFunctionIndexes[root.id] = index
        return index
    }

    /// The rules the lint pipeline dispatches for this run, one bit per rule index.
    ///
    /// Read from `Configuration.ruleActivation` , which holds the sets per configuration, so a
    /// file costs no loop over the rules. `shouldFormat` uses this set to short-circuit disabled
    /// rules before it pays for the `ruleMask.ruleState` work. `shouldRewrite` consults the
    /// narrower `rewriteEnabledRules` so a rule configured with `rewrite: false, lint: .warn`
    /// lints without rewriting.
    ///
    /// In format mode the set holds every rule whose value is active: `rewrite` is on or `lint` is
    /// not `.no` . In lint mode it holds only the rules whose `lint` is not `.no` , because no
    /// other rule can produce a finding.
    let enabledRules: RuleSet

    /// The rules the rewrite pipeline dispatches for this run, one bit per rule index.
    ///
    /// In format mode the set holds the rules whose `rewrite` flag is on. In lint mode (set by
    /// `LintCoordinator` ), it equals `enabledRules` , so that `RewritePipeline` dispatches the
    /// `transform` of every rule that lints, including one configured `rewrite: false, lint: .warn`
    /// , and any `Self.diagnose` calls inside `transform` fire. A rule with `lint: .no` does not
    /// run, because the lint coordinator discards the tree it would build. See issue fn9-zk6.
    let rewriteEnabledRules: RuleSet

    /// Whether the source may hold a `@warn` or `@diagnose` attribute.
    ///
    /// False only when the initializer read the source text and found neither. A finding then
    /// skips the warning-control region tree.
    let mayContainWarningControl: Bool

    // MARK: - Per-rule mutable state
    //
    // One typed lazy property per stateful compact-pipeline rewrite. Each is
    // initialized on first access; the Context itself is constructed fresh
    // per file by `RewriteCoordinator.format(syntax:...)`, so every file
    // starts with empty state.

    lazy var hoistTryState = HoistTry.AwaitState()
    lazy var leadingDotOperatorsState = BreakBeforeLeadingDot.State()
    lazy var namedClosureParamsState = RequireNamedClosureParams.State()
    lazy var noForceTryState = NoForceTry.State()
    lazy var noForceUnwrapState = NoForceUnwrap.State()
    lazy var noGuardInTestsState = NoGuardInTests.State()
    lazy var preferEnvironmentEntryState = UseAtEntryNotEnvironmentKey.State()
    lazy var useFinalClassesState = UseFinalClasses.State()
    lazy var preferSelfTypeState = UseSelfNotTypeName.State()
    lazy var preferSwiftTestingState = UseSwiftTestingNotXCTest.State()
    lazy var redundantAccessControlState = DropRedundantAccessControl.State()
    lazy var redundantBackticksState = DropRedundantBackticks.State()
    lazy var redundantSelfState = DropRedundantSelf.State()
    lazy var redundantSwiftTestingSuiteState = DropRedundantSwiftTestingSuite.State()
    lazy var swiftTestingTestCaseNamesState = UseSwiftTestingNames.State()
    lazy var testSuiteAccessControlState = RequireSuiteAccessControl.State()
    lazy var urlMacroState = UseURLMacroForURLLiterals.State()
    lazy var validateTestCasesState = RequireTestFnPrefixOrAttribute.State()
    lazy var layoutSingleLineBodiesState = LayoutSingleLineBodiesState()

    /// What this file declares, keyed by simple name, built on first lookup.
    ///
    /// Shared by every rule that has to resolve a name against the file rather than against the
    /// module, so the walk happens once however many rules read it. See `FileDeclarationIndex` .
    lazy var fileDeclarationIndex = FileDeclarationIndex(file: sourceFileSyntax)

    /// One `TypeMemberIndex` per tree, built on first lookup.
    ///
    /// Keyed by the root for the same reason as `freeFunctionIndexes` . The index records member
    /// declarations as nodes, so it only answers for the tree it was built from.
    private var typeMemberIndexes: [SyntaxIdentifier: TypeMemberIndex] = [:]

    /// The members of every type in the tree that holds `node`
    func typeMembers(around node: some SyntaxProtocol) -> TypeMemberIndex {
        let root = node.root
        if let cached = typeMemberIndexes[root.id] { return cached }

        let index = TypeMemberIndex(root: root)
        typeMemberIndexes[root.id] = index
        return index
    }

    /// Pre-built `(titlecased, uppercased)` pairs for `UppercaseAcronymsInIdentifiers` , sorted
    /// longest-first so longer acronyms match before shorter substrings. Computed once per file;
    /// reused for every identifier token visited.
    ///
    /// Lazy so a config that disables `UppercaseAcronymsInIdentifiers` never pays the
    /// `uppercased() + sorted + map` cost. The single access site (
    /// `LayoutWriter.applyUppercaseAcronyms` ) is gated by
    /// `context.shouldRewrite(UppercaseAcronymsInIdentifiers.self, ...)` , so when the rule is
    /// disabled this lazy var is never realized.
    lazy var preparedAcronyms: [(titlecased: String, uppercased: String)] =
        configuration[UppercaseAcronymsInIdentifiers.self].words
        .filter { $0.count >= 2 }
        .sorted { $0.count > $1.count }
        .map { (titlecased: $0.capitalized, uppercased: $0.uppercased()) }

    /// Creates a new Context with the provided configuration, diagnostic engine, and file URL.
    ///
    /// - Parameters:
    ///   - source: The text the caller parsed `sourceFileSyntax` from. The context reads it for the
    ///     markers of `// sm:ignore` and `@warn` , and does not parse it again.
    ///   - isLintMode: When `true` , both rule sets hold the rules whose `lint` is not `.no` . A
    ///     transform-based rule with `rewrite: false, lint: .warn` then still dispatches, which its
    ///     transform-emitted findings need. Set by `LintCoordinator` , which discards the tree.
    package init(
        configuration: Configuration,
        operatorTable: OperatorTable,
        findingConsumer: ((Finding) -> Void)?,
        fileURL: URL,
        selection: Selection = .infinite,
        sourceFileSyntax: SourceFileSyntax,
        source: String? = nil,
        isLintMode: Bool = false
    ) {
        self.configuration = configuration
        self.operatorTable = operatorTable
        findingEmitter = FindingEmitter(consumer: findingConsumer)
        self.fileURL = fileURL
        importsAnyTestLibrary = .notDetermined
        // The caller parsed and folded this tree from `source` . Folding moves no bytes, so the
        // converter and every index work on it without a second parse.
        self.sourceFileSyntax = sourceFileSyntax
        sourceLocationConverter = SourceLocationConverter(
            fileName: fileURL.relativePath, tree: sourceFileSyntax)
        self.selection = selection.resolved(with: sourceLocationConverter)
        ruleMask = RuleMask(
            syntaxNode: Syntax(sourceFileSyntax),
            sourceLocationConverter: sourceLocationConverter,
            sourceText: source
        )
        let activation = configuration.ruleActivation
        // In lint mode the rewriter's output is discarded, so the rewrite gate dispatches every
        // rule that lints. This lets transform-emitted findings fire for rules configured
        // `rewrite: false, lint: .warn` (issue fn9-zk6). A rule with `lint: .no` cannot produce a
        // finding, so lint mode does not dispatch it.
        enabledRules = isLintMode ? activation.lint : activation.active
        rewriteEnabledRules = isLintMode ? activation.lint : activation.rewrite
        mayContainWarningControl = source.map {
            WarningControlMarker.occurs(in: $0.utf8.span)
        } ?? true
    }

    /// The UTF-8 offset a gate check reads for `node` .
    ///
    /// A file-wide rule attached to `SourceFileSyntax` (such as `FileLength` ) gates at the end of
    /// the file, so a `// sm:ignore` directive anywhere in the file covers it. Every other rule
    /// gates at its node's start, so a mid-file directive suppresses the following node and
    /// everything after it, as documented.
    @inline(__always)
    func gateOffset(for node: Syntax) -> Int {
        node.kind == .sourceFile
            ? node.endPositionBeforeTrailingTrivia.utf8Offset
            : node.positionAfterSkippingLeadingTrivia.utf8Offset
    }

    /// Whether the rule at `index` belongs to `enabled` and no `// sm:ignore` directive masks it
    /// at `offset` .
    @inline(__always)
    func isUnmasked(_ index: Int, in enabled: RuleSet, atOffset offset: Int) -> Bool {
        enabled[index] && ruleMask.ruleState(index, atOffset: offset) == .default
    }

    /// Given a rule's name and the node it is examining, determine if the rule is disabled at this
    /// location or not. Also makes sure the entire node is contained inside any selection.
    ///
    /// Forwards to the existential overload on purpose. `R` binds to the static call-site type, so
    /// reading the key off `R` directly would name the base class when the caller holds a rule as
    /// its base type.
    func shouldFormat<R: SyntaxRule>(_ rule: R.Type, node: Syntax) -> Bool {
        shouldFormat(ruleType: rule, node: node)
    }

    /// Non-generic counterpart to `shouldFormat<R>(_:node:)` that uses existential dispatch on the
    /// rule's runtime metatype.
    ///
    /// Use this from contexts where a generic `<R>` overload would bind R to the static base type
    /// and look up the wrong configuration key. See `Configuration.isActive(rule:)` .
    func shouldFormat(ruleType rule: any SyntaxRule.Type, node: Syntax) -> Bool {
        guard let index = ConfigurationRegistry.ruleIndex(of: rule), enabledRules[index],
              node.isInsideSelection(selection) else { return false }
        return ruleMask.ruleState(index, atOffset: gateOffset(for: node)) == .default
    }

    /// Rewrite-path entry point for the gate check. Returns whether the rule should rewrite on this
    /// node, consulting `RuleMask` ( `// sm:ignore` ) and the per-rule `rewrite` flag via
    /// `rewriteEnabledRules` . A rule configured with `rewrite: false, lint: .warn` will lint (via
    /// `shouldFormat` ) but skip rewriting here.
    ///
    /// The generated pipelines pass the rule index and skip the lookup. This form serves the
    /// hand-written dispatchers, which hold only the rule type.
    func shouldRewrite<R: SyntaxRule>(_ rule: R.Type, at node: Syntax) -> Bool {
        guard let index = ConfigurationRegistry.ruleIndex(of: rule), rewriteEnabledRules[index],
              node.isInsideSelection(selection) else { return false }
        return ruleMask.ruleState(index, atOffset: gateOffset(for: node)) == .default
    }

    /// Returns the configured lint severity for the given rule type.
    func severity<R: SyntaxRule>(of rule: R.Type) -> Lint {
        guard let index = ConfigurationRegistry.ruleIndex(of: rule) else {
            return configuration[R.self].lint
        }
        return severity(ruleAt: index)
    }

    /// Returns the configured lint severity of the rule at `index` .
    @inline(__always)
    func severity(ruleAt index: Int) -> Lint { configuration.ruleActivation.severities[index] }

    /// Whether this run reaches `rule` at every node of the kinds it visits.
    ///
    /// True means a `// sm:ignore` directive naming the rule had its chance to record a hit, so a
    /// directive that recorded none suppressed nothing. False means the configuration switches the
    /// rule off, or the layout stage owns it and a lint run never reaches that stage. See
    /// `FlagUnusedIgnoreDirective` , the one caller.
    ///
    /// The gate reads `rewriteEnabledRules` because that set equals `enabledRules` in lint mode,
    /// which is the only mode that emits findings. A format run answers `false` for a rule with
    /// `rewrite: false` , which under-reports rather than over-reports.
    func dispatches(_ rule: any SyntaxRule.Type) -> Bool {
        guard let index = ConfigurationRegistry.ruleIndex(of: rule) else { return false }
        return rewriteEnabledRules[index]
            && ConfigurationRegistry.nodeDispatchedRuleIDs.contains(ObjectIdentifier(rule))
    }
}
