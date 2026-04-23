import Foundation
import SwiftOperators
import SwiftParser
import SwiftSyntax

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
        self.findingEmitter = FindingEmitter(consumer: findingConsumer)
        self.fileURL = fileURL
        self.importsXCTest = .notDetermined
        let tree = source.map { Parser.parse(source: $0) } ?? sourceFileSyntax
        self.sourceLocationConverter =
            SourceLocationConverter(fileName: fileURL.relativePath, tree: tree)
        self.selection = selection.resolved(with: self.sourceLocationConverter)
        self.ruleMask = RuleMask(
            syntaxNode: Syntax(sourceFileSyntax),
            sourceLocationConverter: sourceLocationConverter
        )
    }

    /// Given a rule's name and the node it is examining, determine if the rule is disabled at this
    /// location or not. Also makes sure the entire node is contained inside any selection.
    func shouldFormat<R: SyntaxRule>(_ rule: R.Type, node: Syntax) -> Bool {
        guard node.isInsideSelection(selection) else { return false }
        let loc = node.startLocation(converter: self.sourceLocationConverter)
        let ruleName = ConfigurationRegistry.ruleNameCache[ObjectIdentifier(rule)] ?? R.key
        switch ruleMask.ruleState(ruleName, at: loc) {
        case .default: return configuration[R.self].isActive
        case .disabled: return false
        }
    }

    /// Returns the configured lint severity for the given rule type.
    func severity<R: SyntaxRule>(of rule: R.Type) -> Lint {
        return configuration[R.self].lint
    }
}
