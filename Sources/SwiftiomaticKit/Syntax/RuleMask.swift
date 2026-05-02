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
/// ranges. There are three forms:
///
/// - **Lone-line** `// sm:ignore [Rule1, Rule2]` on a line by itself → rules disabled from the
///   comment's position through end of file. Placing it at the top of a file therefore
///   disables those rules for the whole file (replaces the older `sm:ignore-file`).
/// - **Lone-line scoped** `// sm:ignore:next [Rule1, Rule2]` on a line by itself → rules
///   disabled only for the immediately following statement (or member).
/// - **Trailing** `// sm:ignore [Rule1, Rule2]` on the same line as a statement (or member) →
///   rules disabled for that statement only.
///
/// Examples:
///
///   // sm:ignore                                  — ignore all rules from here to EOF
///   // sm:ignore fileLength, typeBodyLength       — those rules off from here to EOF
///   // sm:ignore:next                             — ignore all rules for the next statement
///   // sm:ignore:next Rule1                       — ignore Rule1 for the next statement
///   let x = "trouble" // sm:ignore                — ignore all rules for this line only
///   let x = 1 // sm:ignore Rule1                  — ignore Rule1 for this line only
///
/// `FileLength` and other `SourceFileSyntax`-level rules are gated at the file's end location,
/// so a directive anywhere in the file suppresses them.
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

    typealias RegexExpression = Regex<(Substring, scope: Substring?, ruleNames: Substring?)>

    /// Cached regex object for the unified `sm:ignore` directive.
    ///
    /// Note: We are using a string-based regex instead of a regex literal ( `#/regex/#` ) because
    /// Windows did not have full support for regex literals until Swift 5.10.
    private static nonisolated(unsafe) let ignoreRegex: RegexExpression = {
        let pattern = #"^\s*\/\/\s*sm:ignore(?<scope>:next)?(?:\s+(?<ruleNames>\S.*))?$"#
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

    /// Scans the leading trivia of the node's first token and the trailing trivia of every token
    /// in the node for `// sm:ignore` directives, and records the appropriate source ranges.
    ///
    /// Scoping:
    /// - Lone-line `// sm:ignore` (bare or with rule names) → from the comment's position
    ///   through end of file.
    /// - Trailing `// sm:ignore` on any line of the statement (or member) → that statement only.
    ///   Multi-line nodes accept the directive on any line — first line, last line, or any
    ///   interior line — to give users a natural placement next to a diagnosed expression.
    ///
    /// `FileLength` (and any other `SourceFileSyntax`-level rule) is gated at the file's end
    /// location in `Context.shouldFormat`, so a directive anywhere in the file correctly
    /// suppresses it.
    private func applyDirectives(to node: Syntax) {
        guard let firstToken = node.firstToken(viewMode: .sourceAccurate),
              let sourceFileEnd
        else { return }

        let nodeStart = sourceLocationConverter.location(for: node.position)
        let nodeRange = node.sourceRange(converter: sourceLocationConverter)
        let restOfFileRange = SourceRange(start: nodeStart, end: sourceFileEnd)

        let isFirstInFile = firstToken.previousToken(viewMode: .sourceAccurate) == nil
        for comment in loneLineComments(in: firstToken.leadingTrivia, isFirstToken: isFirstInFile) {
            guard let (match, scope) = ruleStatusDirectiveMatch(in: comment) else { continue }
            // `:next` scopes the directive to this single node; bare lone-line extends to EOF.
            record(match, range: scope == .next ? nodeRange : restOfFileRange)
        }

        for token in node.tokens(viewMode: .sourceAccurate) {
            // Skip tokens that belong to a nested code-block / member-block item — those are
            // handled when that nested item is visited. Without this, a trailing directive
            // on a struct member would leak up to the enclosing type, etc.
            if isInsideDescendantItem(token, of: node) { continue }
            for comment in trailingLineComments(in: token.trailingTrivia) {
                guard let (match, _) = ruleStatusDirectiveMatch(in: comment) else { continue }
                record(match, range: nodeRange)
            }
        }
    }

    /// True if `token` is contained in a descendant `CodeBlockItemSyntax` or
    /// `MemberBlockItemSyntax` of `node`.
    private func isInsideDescendantItem(_ token: TokenSyntax, of node: Syntax) -> Bool {
        var current = Syntax(token).parent
        while let n = current, n != node {
            if n.is(CodeBlockItemSyntax.self) || n.is(MemberBlockItemSyntax.self) {
                return true
            }
            current = n.parent
        }
        return false
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

    /// Scope of a matched directive.
    enum DirectiveScope { case eof, next }

    /// Checks if a comment containing the given text matches a rule status directive. When it does
    /// match, its contents (rule names and scope) are returned.
    private func ruleStatusDirectiveMatch(
        in text: String
    ) -> (match: RuleStatusDirectiveMatch, scope: DirectiveScope)? {
        guard let match = text.firstMatch(of: Self.ignoreRegex) else { return nil }
        let scope: DirectiveScope = match.output.scope != nil ? .next : .eof
        guard let matchedRuleNames = match.output.ruleNames else { return (.all, scope) }

        let rules = matchedRuleNames.split(separator: ",").compactMap { segment -> String? in
            let name = segment.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { return nil }
            // Normalize type names (e.g. SortImports) to key format (e.g. sortImports)
            guard let first = name.first, first.isUppercase else { return name }
            let derived = first.lowercased() + name.dropFirst()

            // Resolve custom keys (e.g. SortImports → "imports" not "sortImports")
            return ConfigurationRegistry.typeNameToKey[derived] ?? derived
        }
        return (.subset(ruleNames: rules), scope)
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
