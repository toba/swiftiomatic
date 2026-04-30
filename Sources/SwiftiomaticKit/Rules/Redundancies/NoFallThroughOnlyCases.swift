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

import SwiftSyntax

/// Cases that contain only the `fallthrough` statement are forbidden.
///
/// Lint: Cases containing only the `fallthrough` statement yield a lint error.
///
/// Rewrite: The fall-through `case` is added as a prefix to the next case unless the next case is
///         `default`; in that case, the fallthrough `case` is deleted.
final class NoFallThroughOnlyCases: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    /// Diagnose against the pre-traversal node so finding source locations
    /// are accurate.
    static func willEnter(_ node: SwitchCaseListSyntax, context: Context) {
        _ = applyImpl(node, context: context, diagnose: true)
    }

    /// Collapse `case`s whose only statement is `fallthrough` into the
    /// following case's pattern list. Called from
    /// `CompactStageOneRewriter.visit(_: SwitchCaseListSyntax)`.
    static func apply(_ node: SwitchCaseListSyntax, context: Context) -> SwitchCaseListSyntax {
        applyImpl(node, context: context, diagnose: false)
    }

    private static func applyImpl(
        _ node: SwitchCaseListSyntax,
        context: Context,
        diagnose: Bool
    ) -> SwitchCaseListSyntax {
        var newChildren: [SwitchCaseListSyntax.Element] = []
        var fallThroughOnlyCases: [SwitchCaseSyntax] = []

        func flushViolations() {
            for node in fallThroughOnlyCases { newChildren.append(.switchCase(node)) }
            fallThroughOnlyCases.removeAll()
        }

        for element in node {
            guard let switchCase = element.as(SwitchCaseSyntax.self) else {
                // `#if` block or similar — partitions the merge sets.
                flushViolations()
                newChildren.append(element)
                continue
            }

            if isMergeableFallThroughOnly(switchCase) {
                fallThroughOnlyCases.append(switchCase)
            } else {
                guard !fallThroughOnlyCases.isEmpty else {
                    newChildren.append(.switchCase(switchCase))
                    continue
                }

                if canMergeWithPreviousCases(switchCase) {
                    newChildren.append(
                        .switchCase(
                            mergedCases(
                                fallThroughOnlyCases + [switchCase],
                                context: context,
                                diagnose: diagnose
                            )
                        )
                    )
                } else {
                    newChildren.append(
                        .switchCase(
                            mergedCases(
                                fallThroughOnlyCases, context: context, diagnose: diagnose
                            )
                        )
                    )
                    newChildren.append(.switchCase(switchCase))
                }

                fallThroughOnlyCases.removeAll()
            }
        }

        flushViolations()
        return SwitchCaseListSyntax(newChildren)
    }

    private static func canMergeWithPreviousCases(_ node: SwitchCaseSyntax) -> Bool {
        node.label.is(SwitchCaseLabelSyntax.self) && !containsValueBindingPattern(node.label)
    }

    private static func containsValueBindingPattern(_ node: SwitchCaseSyntax.Label) -> Bool {
        switch node {
            case let .case(label): containsValueBindingPattern(Syntax(label))
            case .default: false
        }
    }

    private static func containsValueBindingPattern(_ node: Syntax) -> Bool {
        if node.is(ValueBindingPatternSyntax.self) { return true }
        for child in node.children(viewMode: .sourceAccurate) {
            if containsValueBindingPattern(child) { return true }
        }
        return false
    }

    private static func isMergeableFallThroughOnly(_ switchCase: SwitchCaseSyntax) -> Bool {
        guard switchCase.label.is(SwitchCaseLabelSyntax.self) else { return false }

        guard let onlyStatement = switchCase.statements.firstAndOnly,
              onlyStatement.item.is(FallThroughStmtSyntax.self)
        else {
            return false
        }

        if containsValueBindingPattern(switchCase.label) { return false }

        if switchCase.allPrecedingTrivia
            .drop(while: { !$0.isNewline }).contains(where: { $0.isComment })
        {
            return false
        }
        if onlyStatement.allPrecedingTrivia
            .drop(while: { !$0.isNewline }).contains(where: { $0.isComment })
        {
            return false
        }
        if onlyStatement.allFollowingTrivia
            .prefix(while: { !$0.isNewline }).contains(where: { $0.isComment })
        {
            return false
        }
        return true
    }

    private static func mergedCases(
        _ cases: [SwitchCaseSyntax],
        context: Context,
        diagnose: Bool = false
    ) -> SwitchCaseSyntax {
        precondition(!cases.isEmpty, "Must have at least one case to merge")
        if cases.count == 1 { return cases.first! }

        var newCaseItems: [SwitchCaseItemSyntax] = []
        let labels = cases.lazy.compactMap { $0.label.as(SwitchCaseLabelSyntax.self) }

        for label in labels.dropLast() {
            if diagnose {
                Self.diagnose(.collapseCase, on: label, context: context)
            }

            newCaseItems.append(contentsOf: label.caseItems.dropLast())

            var lastItem = label.caseItems.last!
            lastItem.trailingComma = TokenSyntax.commaToken(trailingTrivia: [.spaces(1)])
            newCaseItems.append(lastItem)
        }
        newCaseItems.append(contentsOf: labels.last!.caseItems)

        var lastLabel = labels.last!
        lastLabel.caseItems = SwitchCaseItemListSyntax(newCaseItems)

        var lastCase = cases.last!
        lastCase.label = .case(lastLabel)

        lastCase.leadingTrivia =
            cases.first!.leadingTrivia.withoutLastLine() + lastCase.leadingTrivia
        return lastCase
    }
}

extension TriviaPiece {
    /// Returns whether this piece is any type of comment.
    var isComment: Bool {
        switch self {
            case .lineComment, .blockComment, .docLineComment, .docBlockComment:
                true
            default:
                false
        }
    }

    /// Returns whether this piece is a number of newlines.
    var isNewline: Bool {
        switch self {
            case .newlines:
                true
            default:
                false
        }
    }
}

extension Finding.Message {
    fileprivate static var collapseCase: Finding.Message {
        "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"
    }
}
