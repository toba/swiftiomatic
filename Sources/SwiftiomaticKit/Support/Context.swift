import Foundation
import SwiftParser
import SwiftSyntax
import SwiftOperators

/// Context contains the bits that each formatter and linter will need access to.
///
/// Specifically, it is the container for the shared configuration, diagnostic consumer, and URL of
/// the current file.
package final class Context {

    /// Tracks whether `XCTest` has been imported so that certain logic can be modified for files that
    /// are known to be tests.
    package enum XCTestImportState {

        /// Whether `XCTest` is imported or not has not yet been determined.
        case notDetermined

        /// The file is known to import `XCTest`.
        case importsXCTest

        /// The file is known to not import `XCTest`.
        case doesNotImportXCTest
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

    /// Indicates whether the file is known to import XCTest.
    package var importsXCTest: XCTestImportState

    /// An object that converts `AbsolutePosition` values to `SourceLocation` values.
    package let sourceLocationConverter: SourceLocationConverter

    /// Contains the rules have been disabled by comments for certain line numbers.
    let ruleMask: RuleMask

    // MARK: - Per-rule mutable state
    //
    // One typed lazy property per stateful compact-pipeline rewrite. Each is
    // initialised on first access; the Context itself is constructed fresh
    // per file by `RewriteCoordinator.format(syntax:...)`, so every file
    // starts with empty state.

    lazy var hoistTryState = HoistTry.AwaitState()
    lazy var leadingDotOperatorsState = LeadingDotOperators.State()
    lazy var namedClosureParamsState = NamedClosureParams.State()
    lazy var noForceTryState = NoForceTry.State()
    lazy var noForceUnwrapState = NoForceUnwrap.State()
    lazy var noGuardInTestsState = NoGuardInTests.State()
    lazy var preferEnvironmentEntryState = PreferEnvironmentEntry.State()
    lazy var preferFinalClassesState = PreferFinalClasses.State()
    lazy var preferSelfTypeState = PreferSelfType.State()
    lazy var preferSwiftTestingState = PreferSwiftTesting.State()
    lazy var redundantAccessControlState = RedundantAccessControl.State()
    lazy var redundantSelfState = RedundantSelf.State()
    lazy var redundantSwiftTestingSuiteState = RedundantSwiftTestingSuite.State()
    lazy var swiftTestingTestCaseNamesState = SwiftTestingTestCaseNames.State()
    lazy var testSuiteAccessControlState = TestSuiteAccessControl.State()
    lazy var urlMacroState = URLMacro.State()
    lazy var validateTestCasesState = ValidateTestCases.State()
    lazy var wrapSingleLineBodiesState = WrapSingleLineBodiesState()

    /// Pre-built `(titlecased, uppercased)` pairs for `UppercaseAcronyms`,
    /// sorted longest-first so longer acronyms match before shorter
    /// substrings. Computed once per file; reused for every identifier
    /// token visited.
    lazy var preparedAcronyms: [(titlecased: String, uppercased: String)] = {
        configuration[UppercaseAcronyms.self].words
            .filter { $0.count >= 2 }
            .sorted { $0.count > $1.count }
            .map { (titlecased: $0.capitalized, uppercased: $0.uppercased()) }
    }()

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
        sourceLocationConverter =
            SourceLocationConverter(fileName: fileURL.relativePath, tree: tree)
        self.selection = selection.resolved(with: sourceLocationConverter)
        ruleMask = RuleMask(
            syntaxNode: Syntax(sourceFileSyntax),
            sourceLocationConverter: sourceLocationConverter
        )
    }

    /// Given a rule's name and the node it is examining, determine if the rule is disabled at this
    /// location or not. Also makes sure the entire node is contained inside any selection.
    func shouldFormat<R: SyntaxRule>(_ rule: R.Type, node: Syntax) -> Bool {
        shouldFormat(ruleType: rule, node: node)
    }

    /// Non-generic counterpart to `shouldFormat<R>(_:node:)` that uses existential
    /// dispatch on the rule's runtime metatype.
    ///
    /// Use this from contexts where a generic `<R>` overload would bind R to the
    /// static base type and look up the wrong configuration key. See
    /// `Configuration.isActive(rule:)`.
    func shouldFormat(ruleType rule: any SyntaxRule.Type, node: Syntax) -> Bool {
        guard node.isInsideSelection(selection) else { return false }
        let loc = node.startLocation(converter: sourceLocationConverter)
        let ruleName = ConfigurationRegistry.ruleNameCache[ObjectIdentifier(rule)] ?? rule.key

        switch ruleMask.ruleState(ruleName, at: loc) {
            case .default: return configuration.isActive(rule: rule)
            case .disabled: return false
        }
    }

    /// Rewrite-path entry point for the gate check; equivalent to `shouldFormat(_:node:)`.
    /// Returns whether the rule should run on this node, consulting `RuleMask` (`// sm:ignore`)
    /// and `Configuration.isActive(rule:)` (per-rule `rewrite` flag, with `defaultIsActive: false`
    /// honouring opt-in rules and `Configuration.forTesting(enabledRule:)` honouring tests).
    func shouldRewrite<R: SyntaxRule>(_ rule: R.Type, at node: Syntax) -> Bool {
        shouldFormat(rule, node: node)
    }

    /// Returns the configured lint severity for the given rule type.
    func severity<R: SyntaxRule>(of _: R.Type) -> Lint { configuration[R.self].lint }
}
