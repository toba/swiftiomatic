import Foundation
import SwiftParser
import SwiftSyntax
import SwiftOperators

/// Context contains the bits that each formatter and linter will need access to.
///
/// Specifically, it is the container for the shared configuration, diagnostic consumer, and URL of
/// the current file.
package final class Context {
    /// Tracks whether `XCTest` has been imported so that certain logic can be modified for files
    /// that are known to be tests.
    package enum XCTestImportState { case notDetermined, importsXCTest, doesNotImportXCTest }

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

    /// Indicates whether the file is known to import XCTest.
    ///
    /// The lint and rewrite pipelines drive a single `Context` per file serially, so concurrent
    /// reads/writes are not expected. If that invariant changes, this needs to become atomic.
    package var importsXCTest: XCTestImportState

    /// An object that converts `AbsolutePosition` values to `SourceLocation` values.
    package let sourceLocationConverter: SourceLocationConverter

    /// Contains the rules have been disabled by comments for certain line numbers.
    let ruleMask: RuleMask

    /// Identifiers of every rule whose configuration is currently active for this run — either
    /// rewrite or lint enabled.
    ///
    /// Computed once per `Context` from `Configuration.isActive(rule:)` . `shouldFormat` uses
    /// this set to short-circuit disabled rules before paying for the per-node `startLocation`
    /// + `ruleMask.ruleState` work — which is the bulk of the per-rule per-node cost when ~half
    /// the rules are off. `shouldRewrite` consults the narrower `rewriteEnabledRules` so a rule
    /// configured with `rewrite: false, lint: .warn` lints without rewriting.
    let enabledRules: Set<ObjectIdentifier>

    /// Identifiers of every rule whose `rewrite` flag is currently active. Subset of
    /// `enabledRules` ; populated alongside it in `init` . `shouldRewrite` consults this set so a
    /// rule configured with `rewrite: false, lint: .warn` lints but never rewrites — independent of
    /// the lint-or-rewrite gate used by `shouldFormat` .
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

    /// Pre-built `(titlecased, uppercased)` pairs for `UppercaseAcronymsInIdentifiers` , sorted longest-first so
    /// longer acronyms match before shorter substrings. Computed once per file; reused for every
    /// identifier token visited.
    ///
    /// Lazy so a config that disables `UppercaseAcronymsInIdentifiers` never pays the
    /// `uppercased() + sorted + map` cost. The single access site (
    /// `LayoutWriter.applyUppercaseAcronyms` ) is gated by
    /// `context.shouldRewrite(UppercaseAcronymsInIdentifiers.self, ...)` , so when the rule is disabled this
    /// lazy var is never realized.
    lazy var preparedAcronyms: [(titlecased: String, uppercased: String)] = configuration[
        UppercaseAcronymsInIdentifiers.self
    ].words
        .filter { $0.count >= 2 }
        .sorted { $0.count > $1.count }
        .map { (titlecased: $0.capitalized, uppercased: $0.uppercased()) }

    /// Creates a new Context with the provided configuration, diagnostic engine, and file URL.
    package init(
        configuration: Configuration,
        operatorTable: OperatorTable,
        findingConsumer: ((Finding) -> Void)?,
        fileURL: URL,
        selection: Selection = .infinite,
        sourceFileSyntax: SourceFileSyntax,
        source: String? = nil
    ) {
        self.configuration = configuration
        self.operatorTable = operatorTable
        findingEmitter = FindingEmitter(consumer: findingConsumer)
        self.fileURL = fileURL
        importsXCTest = .notDetermined
        let tree = source.map { Parser.parse(source: $0) } ?? sourceFileSyntax
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
        where configuration.isActive(rule: ruleType) {
            enabled.insert(ObjectIdentifier(ruleType))
            if configuration.isRewriteActive(rule: ruleType) {
                rewriteEnabled.insert(ObjectIdentifier(ruleType))
            }
        }
        enabledRules = enabled
        rewriteEnabledRules = rewriteEnabled
    }

    /// Given a rule's name and the node it is examining, determine if the rule is disabled at this
    /// location or not. Also makes sure the entire node is contained inside any selection.
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
        // For file-wide rules attached to `SourceFileSyntax` (e.g. `FileLength`), gate at the
        // end of file so any `// sm:ignore` directive in the file — at top or mid-file — covers
        // the gate check. All other rules gate at their node's start, so a mid-file directive
        // only suppresses the *following* node and beyond, as documented.
        let loc =
            node.is(SourceFileSyntax.self)
                ? node.endLocation(converter: sourceLocationConverter)
                : node.startLocation(converter: sourceLocationConverter)
        let ruleName = ConfigurationRegistry.ruleNameCache[ObjectIdentifier(rule)] ?? rule.key
        return ruleMask.ruleState(ruleName, at: loc) == .default
    }

    /// Rewrite-path entry point for the gate check. Returns whether the rule should rewrite on
    /// this node, consulting `RuleMask` ( `// sm:ignore` ) and the per-rule `rewrite` flag via
    /// `rewriteEnabledRules` . A rule configured with `rewrite: false, lint: .warn` will lint
    /// (via `shouldFormat` ) but skip rewriting here.
    func shouldRewrite<R: SyntaxRule>(_ rule: R.Type, at node: Syntax) -> Bool {
        guard rewriteEnabledRules.contains(ObjectIdentifier(rule)) else { return false }
        guard node.isInsideSelection(selection) else { return false }
        let loc =
            node.is(SourceFileSyntax.self)
                ? node.endLocation(converter: sourceLocationConverter)
                : node.startLocation(converter: sourceLocationConverter)
        let ruleName = ConfigurationRegistry.ruleNameCache[ObjectIdentifier(rule)] ?? rule.key
        return ruleMask.ruleState(ruleName, at: loc) == .default
    }

    /// Returns the configured lint severity for the given rule type.
    func severity<R: SyntaxRule>(of _: R.Type) -> Lint { configuration[R.self].lint }
}
