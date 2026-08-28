import Foundation
import SwiftParser
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

    /// Identifiers of every rule whose configuration is currently active for this run — either
    /// rewrite or lint enabled.
    ///
    /// Computed once per `Context` from `Configuration.isActive(rule:)` . `shouldFormat` uses this
    /// set to short-circuit disabled rules before paying for the per-node `startLocation`
    /// + `ruleMask.ruleState` work — which is the bulk of the per-rule per-node cost when ~half
    /// the rules are off. `shouldRewrite` consults the narrower `rewriteEnabledRules` so a rule
    /// configured with `rewrite: false, lint: .warn` lints without rewriting.
    let enabledRules: Set<ObjectIdentifier>

    /// Identifiers of every rule whose `rewrite` flag is currently active. Subset of `enabledRules`
    /// ; populated alongside it in `init` . `shouldRewrite` consults this set so a rule configured
    /// with `rewrite: false, lint: .warn` lints but never rewrites — independent of the
    /// lint-or-rewrite gate used by `shouldFormat` .
    ///
    /// In lint-only mode (set by `LintCoordinator` ), this set is widened to equal `enabledRules`
    /// so that `RewritePipeline` dispatches every active rule's `transform` — including those
    /// configured `rewrite: false, lint: .warn` — and any `Self.diagnose` calls inside `transform`
    /// fire. The mutated tree is discarded by the lint coordinator regardless, so widening is safe.
    /// See issue fn9-zk6.
    let rewriteEnabledRules: Set<ObjectIdentifier>

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
    lazy var redundantSelfState = DropRedundantSelf.State()
    lazy var redundantSwiftTestingSuiteState = DropRedundantSwiftTestingSuite.State()
    lazy var swiftTestingTestCaseNamesState = UseSwiftTestingNames.State()
    lazy var testSuiteAccessControlState = RequireSuiteAccessControl.State()
    lazy var urlMacroState = UseURLMacroForURLLiterals.State()
    lazy var validateTestCasesState = RequireTestFnPrefixOrAttribute.State()
    lazy var layoutSingleLineBodiesState = LayoutSingleLineBodiesState()

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
    /// - Parameter isLintMode: When `true` , `rewriteEnabledRules` is widened to equal
    ///   `enabledRules` so transform-based rules with `rewrite: false, lint: .warn` still dispatch
    ///   — required for findings emitted from inside `transform` to fire. Set by `LintCoordinator`
    ///   ; the mutated tree it produces is discarded.
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
        let tree = source.map { Parser.parse(source: $0) } ?? sourceFileSyntax
        self.sourceFileSyntax = tree
        sourceLocationConverter = SourceLocationConverter(
            fileName: fileURL.relativePath, tree: tree)
        self.selection = selection.resolved(with: sourceLocationConverter)
        ruleMask = RuleMask(
            syntaxNode: Syntax(sourceFileSyntax),
            sourceLocationConverter: sourceLocationConverter
        )
        var enabled: Set<ObjectIdentifier> = []
        var rewriteEnabled: Set<ObjectIdentifier> = []
        enabled.reserveCapacity(ConfigurationRegistry.allRuleTypes.count)
        rewriteEnabled.reserveCapacity(ConfigurationRegistry.allRuleTypes.count)

        for ruleType in ConfigurationRegistry.allRuleTypes
            where configuration.isActive(rule: ruleType)
        {
            enabled.insert(ObjectIdentifier(ruleType))
            if configuration.isRewriteActive(rule: ruleType) {
                rewriteEnabled.insert(ObjectIdentifier(ruleType))
            }
        }
        enabledRules = enabled
        // In lint mode the rewriter's output is discarded, so widen the rewrite gate to dispatch
        // every active rule. This lets transform-emitted findings fire for rules configured
        // `rewrite: false, lint: .warn` — see issue fn9-zk6.
        rewriteEnabledRules = isLintMode ? enabled : rewriteEnabled
    }

    /// The location a gate check reads for `node` .
    ///
    /// A file-wide rule attached to `SourceFileSyntax` (such as `FileLength` ) gates at the end of
    /// the file, so a `// sm:ignore` directive anywhere in the file covers it. Every other rule
    /// gates at its node's start, so a mid-file directive suppresses the following node and
    /// everything after it, as documented.
    @inline(__always)
    func gateLocation(for node: Syntax) -> SourceLocation {
        node.is(SourceFileSyntax.self)
            ? node.endLocation(converter: sourceLocationConverter)
            : node.startLocation(converter: sourceLocationConverter)
    }

    /// Whether `rule` belongs to `enabled` and no `// sm:ignore` directive masks it at `location` .
    ///
    /// Stays generic on `R` so a disabled rule costs one set probe. Binding the rule to
    /// `any SyntaxRule.Type` here would add an existential metatype conversion to every gate check
    /// on every node.
    @inline(__always)
    func isUnmasked<R: SyntaxRule>(
        _ rule: R.Type,
        in enabled: Set<ObjectIdentifier>,
        at location: @autoclosure () -> SourceLocation
    ) -> Bool {
        let identifier = ObjectIdentifier(rule)
        guard enabled.contains(identifier) else { return false }
        let ruleName = ConfigurationRegistry.ruleNameCache[identifier] ?? rule.key
        return ruleMask.ruleState(ruleName, at: location()) == .default
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
        guard enabledRules.contains(ObjectIdentifier(rule)) else { return false }
        guard node.isInsideSelection(selection) else { return false }
        let ruleName = ConfigurationRegistry.ruleNameCache[ObjectIdentifier(rule)] ?? rule.key
        return ruleMask.ruleState(ruleName, at: gateLocation(for: node)) == .default
    }

    /// Rewrite-path entry point for the gate check. Returns whether the rule should rewrite on this
    /// node, consulting `RuleMask` ( `// sm:ignore` ) and the per-rule `rewrite` flag via
    /// `rewriteEnabledRules` . A rule configured with `rewrite: false, lint: .warn` will lint (via
    /// `shouldFormat` ) but skip rewriting here.
    func shouldRewrite<R: SyntaxRule>(_ rule: R.Type, at node: Syntax) -> Bool {
        guard node.isInsideSelection(selection) else { return false }
        return isUnmasked(rule, in: rewriteEnabledRules, at: gateLocation(for: node))
    }

    /// Returns the configured lint severity for the given rule type.
    func severity<R: SyntaxRule>(of _: R.Type) -> Lint { configuration[R.self].lint }
}
