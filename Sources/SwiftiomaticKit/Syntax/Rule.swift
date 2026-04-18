//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftSyntax

/// A Rule is a linting or formatting pass that executes in a given context.
protocol Rule: ConfigurableItem {
    /// The context in which the rule is executed.
    var context: Context { get }

    /// The human-readable name of the rule. This defaults to the type name.
    static var name: String { get }

    /// The config group this rule belongs to, or `nil` if ungrouped.
    static var group: ConfigGroup? { get }

    /// The default handling for this rule when not overridden by configuration.
    ///
    /// Base classes provide the default: `.fix` for format rules, `.warning` for
    /// lint rules. Override to `.off` for rules that should be disabled by default.
    static var defaultHandling: RuleHandling { get }

    /// Creates a new Rule in a given context.
    init(context: Context)
}

extension Rule {
    /// By default, the `ruleName` is just the name of the implementing rule class.
    static var name: String { String("\(self)".split(separator: ".").last!) }
    static var group: ConfigGroup? { nil }
    static var key: String { name }
    static var defaultValue: RuleHandling { defaultHandling }

}

extension Rule where Self: SyntaxFormatRule {
    static var defaultHandling: RuleHandling { .fix }
}

extension Rule where Self: SyntaxLintRule {
    static var defaultHandling: RuleHandling { .warning }
}

extension Rule {
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
        let syntaxLocation: SourceLocation?
        if let node = node {
            switch anchor {
            case .start:
                syntaxLocation = node.startLocation(converter: context.sourceLocationConverter)
            case .leadingTrivia(let index):
                syntaxLocation = node.startLocation(
                    ofLeadingTriviaAt: index,
                    converter: context.sourceLocationConverter
                )
            case .trailingTrivia(let index):
                syntaxLocation = node.startLocation(
                    ofTrailingTriviaAt: index,
                    converter: context.sourceLocationConverter
                )
            }
        } else {
            syntaxLocation = nil
        }

        let category = RuleBasedFindingCategory(ruleType: type(of: self))
        let severity = context.severity(of: type(of: self)).diagnosticSeverity
        context.findingEmitter.emit(
            message,
            category: category,
            severity: severity,
            location: syntaxLocation.flatMap(Finding.Location.init),
            notes: notes
        )
    }
}
