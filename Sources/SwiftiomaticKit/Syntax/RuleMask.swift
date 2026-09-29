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

package import Foundation
package import SwiftSyntax

/// Scans the source for `// sm:ignore` directives and records which rules are disabled in which
/// ranges. There are three forms:
///
/// - **Lone-line** `// sm:ignore [Rule1, Rule2]` on a line by itself → rules disabled from the
///   comment's position through end of file. Placing it at the top of a file therefore disables
///   those rules for the whole file (replaces the older `sm:ignore-file`).
/// - **Lone-line scoped** `// sm:ignore:next [Rule1, Rule2]` on a line by itself → rules disabled
///   only for the immediately following statement (or member).
/// - **Trailing** `// sm:ignore [Rule1, Rule2]` on the same line as a statement (or member) → rules
///   disabled for that statement only.
///
/// Examples:
///
/// ```
/// // sm:ignore                                  — ignore all rules from here to EOF
/// // sm:ignore fileLength, typeBodyLength       — those rules off from here to EOF
/// // sm:ignore:next                             — ignore all rules for the next statement
/// // sm:ignore:next Rule1                       — ignore Rule1 for the next statement
/// let x = "trouble" // sm:ignore                — ignore all rules for this line only
/// let x = 1 // sm:ignore Rule1                  — ignore Rule1 for this line only
/// // sm:ignore:next Rule1 explanatory comment   — Rule1 only; trailing text is ignored
/// ```
///
/// The rule list is parsed greedily: the first token must be a valid rule identifier (matches
/// `[A-Za-z_][A-Za-z0-9_]*`), and additional rules continue as long as either a comma separates
/// them OR the next token normalizes to a known rule key (so `// sm:ignore RuleA RuleB` works for
/// real rule names without commas). The first whitespace-separated, non-comma token that doesn't
/// resolve to a known rule — or any non-identifier token — ends the rule list. Everything after
/// that is treated as a free-form explanatory comment and discarded.
///
/// `FileLength` and other `SourceFileSyntax`-level rules are gated at the file's end location, so a
/// directive anywhere in the file suppresses them.
///
/// Rules consult `RuleMask.ruleState(_:at:)` to check whether they are disabled at the location
/// they are currently examining.
///
/// A single `// sm:ignore` directive recorded by `RuleMask`.
///
/// Each directive carries its target source range (the region in which it suppresses rules), its
/// scope (bare `// sm:ignore` covering all rules, or a `// sm:ignore Rule1, Rule2` subset), and
/// per-rule hit counts that are stamped during `RuleMask.ruleState(_:at:)` lookups.
///
/// The hit counts let downstream tooling identify directives that suppress nothing — i.e., stale or
/// typo'd entries that can be removed. See issue `ekr-k5l`.
package final class IgnoreDirective {
    /// What the directive applies to.
    package enum Scope: Equatable, Sendable {
        /// Bare `// sm:ignore` — applies to every rule. Hit-tracking is summary-only.
        case all
        /// Explicit rule list — `// sm:ignore Rule1, Rule2`. Hits are tracked per rule name.
        case subset(ruleNames: [String])
    }

    /// Source location of the `// sm:ignore` comment itself, used as the anchor for findings
    /// emitted about the directive (e.g. unused-directive warnings).
    package let location: SourceLocation
    /// The UTF-8 offsets over which this directive suppresses rules. Both bounds are inclusive.
    package let offsets: ClosedRange<Int>
    /// Whether the directive applies to all rules or to a named subset.
    package let scope: Scope
    /// Number of times this directive matched a `ruleState` lookup whose result was `.disabled`.
    /// For `.subset` directives, see `hitsPerRule` for per-rule attribution.
    package private(set) var totalHits: Int = 0
    /// Per-rule hit counts. Only populated for `.subset` directives.
    package private(set) var hitsPerRule: [String: Int] = [:]

    init(location: SourceLocation, offsets: ClosedRange<Int>, scope: Scope) {
        self.location = location
        self.offsets = offsets
        self.scope = scope
    }

    fileprivate func recordHit(forRule rule: String) {
        totalHits += 1
        if case .subset = scope { hitsPerRule[rule, default: 0] += 1 }
    }
}

package final class RuleMask {
    /// All directives in source order.
    package private(set) var directives: [IgnoreDirective] = []

    /// The rules that were queried via `ruleState` at least once during this run, one bit per rule
    /// index. A rule the configuration disables does not appear here, and neither does one whose
    /// visited node kinds are absent from the file.
    private var queried = RuleSet()

    /// Indices into `directives` for bare `// sm:ignore` (all-rules) directives.
    private var allDirectiveIndices: [Int] = []

    /// Indices into `directives` for subset directives, indexed by the rule index they name. Empty
    /// when the file has no subset directive.
    private var subsetIndicesByRuleIndex: [[Int]] = []

    /// Indices into `directives` keyed by rule name, for subset directives. Serves the name-based
    /// lookup, which also answers for a name that no registered rule has.
    private var subsetIndicesByName: [String: [Int]] = [:]

    /// Creates a `RuleMask` that can specify whether a given rule's status is explicitly modified
    /// at a location obtained from the `SourceLocationConverter` .
    ///
    /// Ranges in the source where rules' statuses are modified are pre-computed during init so that
    /// lookups later don't require parsing the source.
    ///
    /// - Parameter sourceText: The text of `syntaxNode` , when the caller has it. A text without
    ///   `sm:ignore` holds no directive, so the tree walk does not run.
    package init(
        syntaxNode: Syntax,
        sourceLocationConverter: SourceLocationConverter,
        sourceText: String? = nil
    ) {
        if let sourceText, !IgnoreMarker.occurs(in: sourceText.utf8.span) { return }
        computeIgnoredRanges(in: syntaxNode, converter: sourceLocationConverter)
    }

    /// The short keys of the rules that were queried via `ruleState` at least once during this
    /// run. `FlagUnusedIgnoreDirective` reads the set as proof that a rule ran, and asks
    /// `Context.dispatches(_:)` about the rules it does not find here.
    package var queriedRules: Set<String> {
        Set(queried.indices.map { ConfigurationRegistry.ruleKeys[$0] })
    }

    /// Computes the ranges in the given node where the status of rules are explicitly modified.
    private func computeIgnoredRanges(in node: Syntax, converter: SourceLocationConverter) {
        let visitor = RuleStatusCollectionVisitor(sourceLocationConverter: converter)
        visitor.walk(node)
        directives = visitor.orderedDirectives

        for (index, directive) in directives.enumerated() {
            switch directive.scope {
                case .all: allDirectiveIndices.append(index)
                case let .subset(ruleNames):
                    if subsetIndicesByRuleIndex.isEmpty {
                        subsetIndicesByRuleIndex = Array(
                            repeating: [], count: ConfigurationRegistry.ruleCount)
                    }
                    for name in ruleNames {
                        subsetIndicesByName[name, default: []].append(index)

                        if let ruleIndex = ConfigurationRegistry.ruleIndexByKey[name] {
                            subsetIndicesByRuleIndex[ruleIndex].append(index)
                        }
                    }
            }
        }
    }

    /// Returns the `RuleState` for the rule at `ruleIndex` at the given UTF-8 offset.
    ///
    /// This is the hot path. It reads no dictionary, and it returns at once when the file holds no
    /// directive. As a side effect, it records the query and increments the hit counter on the
    /// directive responsible for any `.disabled` result.
    @inline(__always)
    func ruleState(_ ruleIndex: Int, atOffset offset: Int) -> RuleState {
        queried[ruleIndex] = true
        guard !directives.isEmpty else { return .default }
        return lookUp(ruleIndex, atOffset: offset)
    }

    private func lookUp(_ ruleIndex: Int, atOffset offset: Int) -> RuleState {
        for index in allDirectiveIndices where directives[index].offsets.contains(offset) {
            directives[index].recordHit(forRule: ConfigurationRegistry.ruleKeys[ruleIndex])
            return .disabled
        }
        guard ruleIndex < subsetIndicesByRuleIndex.count else { return .default }

        for index in subsetIndicesByRuleIndex[ruleIndex]
            where directives[index].offsets.contains(offset)
        {
            directives[index].recordHit(forRule: ConfigurationRegistry.ruleKeys[ruleIndex])
            return .disabled
        }
        return .default
    }

    /// Returns the `RuleState` for the given rule at the provided location.
    ///
    /// As a side effect, increments the hit counter on the directive responsible for any
    /// `.disabled` result. This drives unused-directive detection (see `IgnoreDirective`).
    package func ruleState(_ rule: String, at location: SourceLocation) -> RuleState {
        if let ruleIndex = ConfigurationRegistry.ruleIndexByKey[rule] {
            return ruleState(ruleIndex, atOffset: location.offset)
        }
        let offset = location.offset

        for index in allDirectiveIndices where directives[index].offsets.contains(offset) {
            directives[index].recordHit(forRule: rule)
            return .disabled
        }
        for index in subsetIndicesByName[rule] ?? [] where directives[index].offsets.contains(offset) {
            directives[index].recordHit(forRule: rule)
            return .disabled
        }
        return .default
    }
}

/// Finds the `sm:ignore` marker in UTF-8 text without decoding it.
enum IgnoreMarker {
    private static let marker: [UInt8] = Array("sm:ignore".utf8)

    /// Whether `bytes` contains `sm:ignore` .
    static func occurs(in bytes: Span<UInt8>) -> Bool {
        let count = marker.count
        guard bytes.count >= count else { return false }
        let first = marker[0]
        var start = 0
        let last = bytes.count - count

        while start <= last {
            if bytes[start] == first {
                var matched = 1
                while matched < count, bytes[start + matched] == marker[matched] { matched += 1 }
                if matched == count { return true }
            }
            start += 1
        }
        return false
    }
}

/// A syntax visitor that finds the ranges of nodes that have rule status modifying comment
/// directives. The changes requested in each comment is parsed and collected into a map to support
/// status lookup per rule name.
///
/// The rule status comment directives implementation intentionally supports exactly the same nodes
/// as `TokenStream` to disable pretty printing. This ensures ignore comments for pretty printing
/// and for rules are as consistent as possible.
///
/// The visitor walks each token once. It keeps a stack of the enclosing `CodeBlockItemSyntax` and
/// `MemberBlockItemSyntax` nodes, and the top of the stack owns the token. A directive on a struct
/// member therefore belongs to the member and does not leak up to the enclosing type.
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

    /// An enclosing item and its place in a pre-order walk of the items.
    private struct Item {
        let node: Syntax
        let order: Int
    }

    /// Computes source locations for the directives that match.
    private let sourceLocationConverter: SourceLocationConverter

    /// End-of-file UTF-8 offset, captured at `SourceFileSyntax` visit. Used as the upper bound for
    /// lone-line `sm:ignore` directives, which extend from their position to EOF.
    private var sourceFileEnd: Int?

    /// The items that enclose the current token, innermost last.
    private var items: [Item] = []

    /// The number of items entered so far, which orders the directives the way a walk per item
    /// would find them.
    private var itemCount = 0

    /// Whether the walk has reached a token yet. The first token of the file has no newline before
    /// its first comment.
    private var sawToken = false

    /// Collected directives, each with the order of the item that owns it.
    private var found: [(order: Int, directive: IgnoreDirective)] = []

    /// The directives, grouped by owning item in pre-order and in source order within an item.
    var orderedDirectives: [IgnoreDirective] {
        found.enumerated()
            .sorted { ($0.element.order, $0.offset) < ($1.element.order, $1.offset) }
            .map(\.element.directive)
    }

    init(sourceLocationConverter: SourceLocationConverter) {
        self.sourceLocationConverter = sourceLocationConverter
        super.init(viewMode: .sourceAccurate)
    }

    // MARK: - Syntax Visitation Methods

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        sourceFileEnd = node.endPosition.utf8Offset
        return .visitChildren
    }

    override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
        enter(Syntax(node))
        return .visitChildren
    }

    override func visitPost(_: CodeBlockItemSyntax) { items.removeLast() }

    override func visit(_ node: MemberBlockItemSyntax) -> SyntaxVisitorContinueKind {
        enter(Syntax(node))
        return .visitChildren
    }

    override func visitPost(_: MemberBlockItemSyntax) { items.removeLast() }

    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        let isFirstInFile = !sawToken
        sawToken = true
        guard let owner = items.last, sourceFileEnd != nil else { return .visitChildren }
        scanLeadingTrivia(of: token, owner: owner, isFirstInFile: isFirstInFile)
        scanTrailingTrivia(of: token, owner: owner)
        return .visitChildren
    }

    // MARK: - Helper Methods

    private func enter(_ node: Syntax) {
        items.append(Item(node: node, order: itemCount))
        itemCount += 1
    }

    /// Scans the lone-line comments in the leading trivia of `token` .
    ///
    /// Scoping:
    /// - Lone-line `// sm:ignore` (bare or with rule names) before the item's first token → from
    ///   the item's position through end of file.
    /// - `// sm:ignore:next` , or a lone-line directive inside the item's trivia → that item only.
    ///   A bare directive *inside* the item's trivia is treated as scoped to the item, since "rest
    ///   of file" would accidentally cover sibling nodes the user didn't target.
    ///
    /// Directives may sit on their own line anywhere within the item's trivia (e.g. between an
    /// attribute and the modifier list of a function decl), not just before the first token.
    private func scanLeadingTrivia(of token: TokenSyntax, owner: Item, isFirstInFile: Bool) {
        var offset = token.position.utf8Offset
        // The first token of the file may carry a comment with no newline before it.
        var atLineStart = isFirstInFile

        for piece in token.leadingTrivia {
            switch piece {
                case let .lineComment(text):
                    if atLineStart, let (match, scope) = ruleStatusDirectiveMatch(in: text) {
                        let isFirstTokenOfItem =
                            owner.node.firstToken(viewMode: .sourceAccurate)?.id == token.id
                        let offsets =
                            scope == .eof && isFirstTokenOfItem
                            ? restOfFileOffsets(of: owner.node)
                            : itemOffsets(of: owner.node)
                        record(match, offsets: offsets, at: offset, owner: owner)
                    }
                    atLineStart = false
                case .spaces, .tabs: break
                case .carriageReturnLineFeeds, .carriageReturns, .newlines: atLineStart = true
                default: atLineStart = false
            }
            offset += piece.sourceLength.utf8Length
        }
    }

    /// Scans the trailing trivia of `token` for line comments. Trailing trivia never holds a
    /// newline, so each one sits on the same line as the code, like `let x = 1 // sm:ignore`. A
    /// trailing directive on any line of a multi-line item covers that item.
    private func scanTrailingTrivia(of token: TokenSyntax, owner: Item) {
        var offset = token.endPositionBeforeTrailingTrivia.utf8Offset

        for piece in token.trailingTrivia {
            if case let .lineComment(text) = piece,
               let (match, _) = ruleStatusDirectiveMatch(in: text)
            {
                record(match, offsets: itemOffsets(of: owner.node), at: offset, owner: owner)
            }
            offset += piece.sourceLength.utf8Length
        }
    }

    /// The offsets of an item's own text, without its leading and trailing trivia.
    private func itemOffsets(of node: Syntax) -> ClosedRange<Int> {
        node.positionAfterSkippingLeadingTrivia.utf8Offset...node.endPositionBeforeTrailingTrivia
            .utf8Offset
    }

    /// The offsets from an item's position through the end of the file.
    private func restOfFileOffsets(of node: Syntax) -> ClosedRange<Int> {
        node.position.utf8Offset...max(node.position.utf8Offset, sourceFileEnd ?? 0)
    }

    private func record(
        _ match: RuleStatusDirectiveMatch,
        offsets: ClosedRange<Int>,
        at offset: Int,
        owner: Item
    ) {
        let scope: IgnoreDirective.Scope =
            switch match {
                case .all: .all
                case let .subset(ruleNames): .subset(ruleNames: ruleNames)
            }
        let location = sourceLocationConverter.location(for: AbsolutePosition(utf8Offset: offset))
        found.append(
            (owner.order, IgnoreDirective(location: location, offsets: offsets, scope: scope)))
    }

    /// Scope of a matched directive.
    enum DirectiveScope { case eof, next }

    /// Checks if a comment containing the given text matches a rule status directive. When it does
    /// match, its contents (rule names and scope) are returned.
    private func ruleStatusDirectiveMatch(
        in text: String
    ) -> (match: RuleStatusDirectiveMatch, scope: DirectiveScope)? {
        // Most comments are not directives. The byte search is cheaper than the regex.
        guard IgnoreMarker.occurs(in: text.utf8.span),
              let match = text.firstMatch(of: Self.ignoreRegex) else { return nil }
        let scope: DirectiveScope = match.output.scope != nil ? .next : .eof
        guard let matchedRuleNames = match.output.ruleNames else { return (.all, scope) }

        // Parse leading rule tokens. Rules continue as long as commas separate them, OR — for
        // tokens after the first — as long as the next token normalizes to a known rule key. The
        // first token that follows whitespace without a comma AND is not a known rule — or the
        // first non-identifier token — ends the rule list. Everything after that is treated as a
        // free-form explanatory comment and discarded.
        var rules: [String] = []
        var index = matchedRuleNames.startIndex
        var sawCommaBeforeNextToken = true  // First token doesn't need a leading comma.

        while index < matchedRuleNames.endIndex {
            // Consume separators (whitespace and commas) before the next token; record whether at
            // least one comma appeared.
            while index < matchedRuleNames.endIndex {
                let c = matchedRuleNames[index]
                if c == "," { sawCommaBeforeNextToken = true } else if c != " ", c != "\t" { break }
                index = matchedRuleNames.index(after: index)
            }
            guard index < matchedRuleNames.endIndex else { break }

            let tokenStart = index

            while index < matchedRuleNames.endIndex {
                let c = matchedRuleNames[index]
                if c == " " || c == "\t" || c == "," { break }
                index = matchedRuleNames.index(after: index)
            }
            let token = matchedRuleNames[tokenStart..<index]
            guard isRuleIdentifier(token) else { break }
            let name = String(token)
            // Normalize type names (e.g. SortImports) to key format (e.g. sortImports).
            let normalized: String

            if let first = name.first, first.isUppercase {
                let derived = first.lowercased() + name.dropFirst()
                // Resolve custom keys (e.g. SortImports → "imports" not "sortImports").
                normalized = ConfigurationRegistry.typeNameToKey[derived] ?? derived
            } else {
                normalized = name
            }
            // After the first rule, only continue without a comma if this token is a known rule key
            // — otherwise it's the start of a free-form trailing comment.
            if !rules.isEmpty,
               !sawCommaBeforeNextToken,
               !ConfigurationRegistry.allRuleKeys.contains(normalized) { break }
            rules.append(normalized)
            sawCommaBeforeNextToken = false
        }
        return (.subset(ruleNames: rules), scope)
    }

    /// True if `token` matches `[A-Za-z_][A-Za-z0-9_]*`.
    private func isRuleIdentifier(_ token: Substring) -> Bool {
        guard let first = token.first else { return false }
        guard first.isLetter || first == "_" else { return false }
        return token.dropFirst().allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }
}
