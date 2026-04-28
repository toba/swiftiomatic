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

    /// Per-file, per-rule mutable state cache. Keyed by `ObjectIdentifier(R.self)`.
    /// Access only through `ruleState(for:initialize:)`.
    private let ruleStateLock = NSLock()
    private var ruleStateStorage: [ObjectIdentifier: AnyObject] = [:]

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
        guard node.isInsideSelection(selection) else { return false }
        let loc = node.startLocation(converter: sourceLocationConverter)
        let ruleName = ConfigurationRegistry.ruleNameCache[ObjectIdentifier(rule)] ?? R.key

        switch ruleMask.ruleState(ruleName, at: loc) {
            case .default: return configuration[R.self].isActive
            case .disabled: return false
        }
    }

    /// Returns the configured lint severity for the given rule type.
    func severity<R: SyntaxRule>(of _: R.Type) -> Lint { configuration[R.self].lint }

    /// Returns a per-file, per-rule mutable state object, lazily initialised on
    /// first access. Used by rules ported to the combined `CompactStageOneRewriter`
    /// that need to carry state across multiple `static func transform` calls
    /// (file-level pre-scans, scope stacks, accumulated flags).
    ///
    /// The cache lives on `Context`, which is constructed fresh per file by
    /// `RewriteCoordinator.format(syntax:...)`, so each file starts with an empty
    /// cache. State objects must be reference types — mutations made via the
    /// returned reference are visible to subsequent callers within the same file.
    package func ruleState<R, S: AnyObject>(
        for _: R.Type,
        initialize: () -> S
    ) -> S {
        ruleStateLock.lock()
        defer { ruleStateLock.unlock() }
        let key = ObjectIdentifier(R.self)
        if let cached = ruleStateStorage[key] as? S { return cached }
        let fresh = initialize()
        ruleStateStorage[key] = fresh
        return fresh
    }
}
