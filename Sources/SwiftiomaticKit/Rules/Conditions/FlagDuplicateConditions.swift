import SwiftSyntax

/// The same condition appearing twice in an if/else-if chain or switch is dead code.
///
/// Walks each top-level if/else-if chain and groups branches by their normalized condition set
/// (order-insensitive). Any condition appearing in more than one branch is flagged.
///
/// Walks each switch's case list and groups case items by their normalized `pattern + where` . Any
/// case item appearing more than once is flagged.
///
/// Lint: When the same condition or case appears multiple times in the same branch instruction, an
/// error is raised.
final class FlagDuplicateConditions: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .conditions }
    override class var defaultValue: LintOnlyValue { .init(lint: .error) }

    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        // Only the outermost `if` walks its chain — skip nested `else if` ifs, which are visited
        // again as elseBody of the parent.
        if node.parent?.is(IfExprSyntax.self) == true { return .visitChildren }

        var chain: [IfExprSyntax] = []
        var current: IfExprSyntax? = node

        while let curr = current {
            chain.append(curr)
            current = curr.elseBody?.as(IfExprSyntax.self)
        }

        var byConditionSet: [Set<String>: [IfExprSyntax]] = [:]

        for branch in chain {
            let key = Set(branch.conditions.map(\.condition.trimmedDescription))
            byConditionSet[key, default: []].append(branch)
        }

        for branches in byConditionSet.values where branches.count > 1 {
            for branch in branches { diagnose(.duplicateCondition, on: branch.conditions) }
        }

        return .visitChildren
    }

    override func visit(_ node: SwitchCaseListSyntax) -> SyntaxVisitorContinueKind {
        var byPattern: [String: [SwitchCaseItemSyntax]] = [:]

        for element in node {
            guard let switchCase = element.as(SwitchCaseSyntax.self),
                  case let .case(label) = switchCase.label else { continue }

            for item in label.caseItems {
                let pattern = item.pattern.trimmedDescription
                let whereClause = item.whereClause?.trimmedDescription ?? ""
                byPattern[pattern + whereClause, default: []].append(item)
            }
        }

        for items in byPattern.values where items.count > 1 {
            for item in items { diagnose(.duplicateCase, on: item) }
        }

        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let duplicateCondition: Finding.Message =
        "this condition appears multiple times in the same if/else-if chain"

    static let duplicateCase: Finding.Message = "this case appears multiple times in the switch"
}
