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

/// Scans the source for `// sm:ignore` directives and records which rules are disabled in which
/// ranges. The comment's form and position determine its scope:
///
/// - **Bare** `// sm:ignore` on a line by itself → all rules disabled from that comment's
///   position through end of file. Placing it at the top of the file ignores the whole file.
/// - **`// sm:ignore Rule1, Rule2`** on a line by itself → those rules disabled for the
///   following node and its children only.
/// - **Trailing** `// sm:ignore` on the same line as a statement (or member) → rules disabled
///   for that statement only.
///
/// Examples:
///
///   // sm:ignore                                  — ignore all rules from here to EOF
///   // sm:ignore RuleName                         — ignore RuleName for the next node only
///   // sm:ignore Rule1, Rule2                     — ignore those rules for the next node only
///   let x = "trouble" // sm:ignore                — ignore all rules for this line only
///   let x = 1 // sm:ignore Rule1                  — ignore Rule1 for this line only
///
/// For backwards compatibility the legacy forms `// sm:ignore-file` and `// sm:ignore: Rule` are
/// also accepted and behave like their unprefixed equivalents.
///
/// Rules consult `RuleMask.ruleState(_:at:)` to check whether they are disabled at the location
/// they are currently examining.
package final class RuleMask {
    /// Stores the source ranges in which all rules are ignored.
    private var allRulesIgnoredRanges: [SourceRange] = []

    /// Map of rule names to list ranges in the source where the rule is ignored.
    private var ruleMap: [String: [SourceRange]] = [:]

    /// Used to compute line numbers of syntax nodes.
    private let sourceLocationConverter: SourceLocationConverter

    /// Creates a `RuleMask` that can specify whether a given rule's status is explicitly modified
    /// at a location obtained from the `SourceLocationConverter` .
    ///
    /// Ranges in the source where rules' statuses are modified are pre-computed during init so that
    /// lookups later don't require parsing the source.
    package init(syntaxNode: Syntax, sourceLocationConverter: SourceLocationConverter) {
        self.sourceLocationConverter = sourceLocationConverter
        computeIgnoredRanges(in: syntaxNode)
    }

    /// Computes the ranges in the given node where the status of rules are explicitly modified.
    private func computeIgnoredRanges(in node: Syntax) {
        let visitor = RuleStatusCollectionVisitor(sourceLocationConverter: sourceLocationConverter)
        visitor.walk(node)
        allRulesIgnoredRanges = visitor.allRulesIgnoredRanges
        ruleMap = visitor.ruleMap
    }

    /// Returns the `RuleState` for the given rule at the provided location.
    package func ruleState(_ rule: String, at location: SourceLocation) -> RuleState {
        if allRulesIgnoredRanges.contains(where: { $0.contains(location) }) {
            .disabled
        } else if let ignoredRanges = ruleMap[rule] {
            ignoredRanges.contains { $0.contains(location) } ? .disabled : .default
        } else {
            .default
        }
    }
}

fileprivate extension SourceRange {
    /// Returns whether the range includes the given location.
    func contains(_ location: SourceLocation) -> Bool {
        start.offset <= location.offset && end.offset >= location.offset
    }
}

/// A syntax visitor that finds `SourceRange` s of nodes that have rule status modifying comment
/// directives. The changes requested in each comment is parsed and collected into a map to support
/// status lookup per rule name.
///
/// The rule status comment directives implementation intentionally supports exactly the same nodes
/// as `TokenStream` to disable pretty printing. This ensures ignore comments for pretty printing
/// and for rules are as consistent as possible.
private final class RuleStatusCollectionVisitor: SyntaxVisitor {
    /// Describes the possible matches for ignore directives, in comments.
    enum RuleStatusDirectiveMatch {
        /// There is a directive that applies to all rules.
        case all

        /// There is a directive that applies to a number of rules. The names of the rules are
        /// provided in `ruleNames` .
        case subset(ruleNames: [String])
    }

    typealias RegexExpression = Regex<(Substring, ruleNames: Substring?)>

    /// Cached regex object for the unified `sm:ignore` directive.
    ///
    /// Note: We are using a string-based regex instead of a regex literal ( `#/regex/#` ) because
    /// Windows did not have full support for regex literals until Swift 5.10.
    private static nonisolated(unsafe) let ignoreRegex: RegexExpression = {
        // Accepts the canonical form `// sm:ignore [Rule1, Rule2]` and, for backwards
        // compatibility, the legacy `sm:ignore-file` / `sm:ignore: Rule1` forms. All variants
        // produce the same node-or-rest-of-file scope based on where the comment appears.
        let pattern = #"^\s*\/\/\s*sm:ignore(?:-file)?(?:[\s:]+(?<ruleNames>\S.*))?$"#
        return try! Regex(pattern).matchingSemantics(.unicodeScalar)
    }()

    /// Computes source locations and ranges for syntax nodes in a source file.
    private let sourceLocationConverter: SourceLocationConverter

    /// End-of-file location, captured at `SourceFileSyntax` visit. Used as the upper bound for
    /// lone-line `sm:ignore` directives, which extend from their position to EOF.
    private var sourceFileEnd: SourceLocation?

    /// Stores the source ranges in which all rules are ignored.
    var allRulesIgnoredRanges: [SourceRange] = []

    /// Map of rule names to list ranges in the source where the rule is ignored.
    var ruleMap: [String: [SourceRange]] = [:]

    init(sourceLocationConverter: SourceLocationConverter) {
        self.sourceLocationConverter = sourceLocationConverter
        super.init(viewMode: .sourceAccurate)
    }

    // MARK: - Syntax Visitation Methods

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        sourceFileEnd = sourceLocationConverter.location(for: node.endPosition)
        return .visitChildren
    }

    override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
        applyDirectives(to: Syntax(node))
        return .visitChildren
    }

    override func visit(_ node: MemberBlockItemSyntax) -> SyntaxVisitorContinueKind {
        applyDirectives(to: Syntax(node))
        return .visitChildren
    }

    // MARK: - Helper Methods

    /// Scans both the leading trivia of the node's first token and the trailing trivia of its last
    /// token for `// sm:ignore` directives, and records the appropriate source ranges.
    ///
    /// Scoping:
    /// - Lone-line *bare* `// sm:ignore` (no rule names) → from the node's start through EOF.
    ///   Place it at the top of the file to ignore the whole file.
    /// - Lone-line `// sm:ignore Rule1, Rule2` (with rule names) → the node only. Used for
    ///   surgical, per-rule suppression on a specific declaration or statement.
    /// - Trailing `// sm:ignore` (on the same line as code) → the node only.
    private func applyDirectives(to node: Syntax) {
        guard let firstToken = node.firstToken(viewMode: .sourceAccurate),
              let sourceFileEnd
        else { return }

        let nodeStart = sourceLocationConverter.location(for: node.position)
        let nodeRange = node.sourceRange(converter: sourceLocationConverter)
        let restOfFileRange = SourceRange(start: nodeStart, end: sourceFileEnd)

        let isFirstInFile = firstToken.previousToken(viewMode: .sourceAccurate) == nil
        for comment in loneLineComments(in: firstToken.leadingTrivia, isFirstToken: isFirstInFile) {
            guard let match = ruleStatusDirectiveMatch(in: comment) else { continue }
            // Bare `sm:ignore` extends to EOF; `sm:ignore Rule1, Rule2` stays node-scoped.
            switch match {
                case .all: record(match, range: restOfFileRange)
                case .subset: record(match, range: nodeRange)
            }
        }

        if let lastToken = node.lastToken(viewMode: .sourceAccurate) {
            for comment in trailingLineComments(in: lastToken.trailingTrivia) {
                guard let match = ruleStatusDirectiveMatch(in: comment) else { continue }
                record(match, range: nodeRange)
            }
        }
    }

    private func record(_ match: RuleStatusDirectiveMatch, range: SourceRange) {
        switch match {
            case .all:
                allRulesIgnoredRanges.append(range)
            case let .subset(ruleNames):
                for ruleName in ruleNames {
                    ruleMap[ruleName, default: []].append(range)
                }
        }
    }

    /// Checks if a comment containing the given text matches a rule status directive. When it does
    /// match, its contents (e.g. list of rule names) are returned.
    private func ruleStatusDirectiveMatch(in text: String) -> RuleStatusDirectiveMatch? {
        guard let match = text.firstMatch(of: Self.ignoreRegex) else { return nil }
        guard let matchedRuleNames = match.output.ruleNames else { return .all }

        let rules = matchedRuleNames.split(separator: ",").compactMap { segment -> String? in
            let name = segment.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { return nil }
            // Normalize type names (e.g. SortImports) to key format (e.g. sortImports)
            guard let first = name.first, first.isUppercase else { return name }
            let derived = first.lowercased() + name.dropFirst()

            // Resolve custom keys (e.g. SortImports → "imports" not "sortImports")
            return ConfigurationRegistry.typeNameToKey[derived] ?? derived
        }
        return .subset(ruleNames: rules)
    }

    /// Returns the list of line comments in the given trivia that are on a line by themselves
    /// (excluding leading whitespace).
    ///
    /// - Parameters:
    ///   - trivia: The trivia collection to scan for comments.
    ///   - isFirstToken: True if the trivia came from the first token in the file.
    ///   - Returns: The list of lone line comments from the trivia.
    private func loneLineComments(in trivia: Trivia, isFirstToken: Bool) -> [String] {
        var currentComment: String?
        var lineComments = [String]()

        for piece in trivia.reversed() {
            switch piece {
                case let .lineComment(text): currentComment = text
                case .spaces, .tabs: break
                case .carriageReturnLineFeeds, .carriageReturns, .newlines:
                    if let text = currentComment {
                        lineComments.append(text)
                        currentComment = nil
                    }
                default: currentComment = nil
            }
        }

        // For the first token in the file, there may not be a newline preceding the first line
        // comment, so check for that here.
        if isFirstToken, let text = currentComment { lineComments.append(text) }

        lineComments.reverse()
        return lineComments
    }

    /// Returns line comments in trailing trivia that appear on the same line as the code (i.e.,
    /// before any newline). These are "trailing" line comments like `let x = 1 // sm:ignore`.
    private func trailingLineComments(in trivia: Trivia) -> [String] {
        var comments: [String] = []
        for piece in trivia {
            switch piece {
                case let .lineComment(text): comments.append(text)
                case .carriageReturnLineFeeds, .carriageReturns, .newlines:
                    return comments
                default: continue
            }
        }
        return comments
    }
}
