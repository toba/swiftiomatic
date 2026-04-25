import Foundation
import SwiftSyntax

/// A Rule is a linting or formatting pass that executes in a given context.
protocol SyntaxRule: Configurable, Sendable where Value: SyntaxRuleValue {
    /// The context in which the rule is executed.
    var context: Context { get }

    /// Creates a new Rule in a given context.
    init(context: Context)
}

extension SyntaxRule {
    /// Default value from the `SyntaxRuleValue`'s `init()`.
    static var defaultValue: Value { .init() }

    /// This rule's configuration value, sugar for `context.configuration[Self.self]`.
    var ruleConfig: Value { context.configuration[Self.self] }

    /// Emits the given finding.
    ///
    /// - Parameters:
    ///   - message: The finding message to emit.
    ///   - node: The syntax node to which the finding should be attached. The finding's location will
    ///     be set to the start of the node (excluding leading trivia, unless `leadingTriviaIndex` is
    ///     provided).
    ///   - anchor: The part of the node where the finding should be anchored. Defaults to the start
    ///     of the node's content (after any leading trivia).
    ///   - notes: An array of notes that provide additional detail about the finding.
    func diagnose<SyntaxType: SyntaxProtocol>(
        _ message: Finding.Message,
        on node: SyntaxType?,
        anchor: FindingAnchor = .start,
        notes: [Finding.Note] = []
    ) {
        let severity = context.severity(of: type(of: self))
        guard severity.isActive else { return }
        emitFinding(
            message,
            on: node,
            severity: severity,
            anchor: anchor,
            notes: notes
        )
    }

    /// Emits a finding at an explicit severity, overriding the rule's configured
    /// `lint` value. The rule's master setting still gates emission — if the rule
    /// is disabled (`lint == .no`), nothing is emitted regardless of the override.
    ///
    /// Used by metrics rules that emit at `.warn` over a warning threshold and
    /// `.error` over an error threshold within a single configured rule.
    func diagnose<SyntaxType: SyntaxProtocol>(
        _ message: Finding.Message,
        on node: SyntaxType?,
        severity: Lint,
        anchor: FindingAnchor = .start,
        notes: [Finding.Note] = []
    ) {
        let configured = context.severity(of: type(of: self))
        guard configured.isActive, severity.isActive else { return }
        emitFinding(
            message,
            on: node,
            severity: severity,
            anchor: anchor,
            notes: notes
        )
    }

    private func emitFinding<SyntaxType: SyntaxProtocol>(
        _ message: Finding.Message,
        on node: SyntaxType?,
        severity: Lint,
        anchor: FindingAnchor,
        notes: [Finding.Note]
    ) {

        let syntaxLocation: SourceLocation?

        if let node {
            switch anchor {
                case .start:
                    syntaxLocation = node.startLocation(converter: context.sourceLocationConverter)
                case let .leadingTrivia(index):
                    syntaxLocation = node.startLocation(
                        ofLeadingTriviaAt: index,
                        converter: context.sourceLocationConverter
                    )
                case let .trailingTrivia(index):
                    syntaxLocation = node.startLocation(
                        ofTrailingTriviaAt: index,
                        converter: context.sourceLocationConverter
                    )
            }
        } else {
            syntaxLocation = nil
        }

        let category = SyntaxFindingCategory(ruleType: type(of: self))

        context.findingEmitter.emit(
            message,
            category: category,
            severity: severity,
            location: syntaxLocation.flatMap(Finding.Location.init),
            notes: notes
        )
    }
}
