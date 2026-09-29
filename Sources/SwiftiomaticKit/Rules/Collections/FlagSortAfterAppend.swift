import SwiftSyntax

/// Flag a `sort` call that directly follows one `append` on the same receiver.
///
/// A collection that is already sorted needs only one insert to stay sorted. A `sort()` after one
/// `append` sorts the whole collection again, which costs O(n log n) where an insert at the sorted
/// index costs O(n).
///
/// The rule reads each pair of adjacent statements. The first statement is `x.append(e)` with one
/// unlabeled argument, and the second is `x.sort()` or `x.sort(by:)` on the same receiver. An
/// `append(contentsOf:)` adds a batch, so the rule skips it. A loop that appends each element and
/// then sorts once after the loop is correct, and the rule does not flag it.
///
/// Lint: `x.sort()` directly follows `x.append(e)` .
final class FlagSortAfterAppend: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .collections }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        var previousAppendReceiver: String?

        for item in node {
            let call = Self.call(in: item)

            if let call, let receiver = Self.receiver(of: call, named: "sort"),
               receiver == previousAppendReceiver
            {
                diagnose(.insertSorted(receiver), on: call)
            }
            previousAppendReceiver = call.flatMap(Self.singleAppendReceiver)
        }
        return .visitChildren
    }

    /// The call that `item` holds as its whole statement, or `nil`
    private static func call(in item: CodeBlockItemSyntax) -> FunctionCallExprSyntax? {
        item.item.as(ExprSyntax.self)?.as(FunctionCallExprSyntax.self)
    }

    /// The receiver text of `call` when it calls the method `name` on an explicit receiver
    private static func receiver(of call: FunctionCallExprSyntax, named name: String) -> String? {
        guard let member = call.calledExpression.as(MemberAccessExprSyntax.self),
              member.declName.baseName.text == name,
              let base = member.base else { return nil }
        return base.trimmedDescription
    }

    /// The receiver text of `call` when it is `x.append(e)` with one unlabeled argument
    private static func singleAppendReceiver(_ call: FunctionCallExprSyntax) -> String? {
        guard call.trailingClosure == nil, call.arguments.count == 1,
              call.arguments.first?.label == nil else { return nil }
        return receiver(of: call, named: "append")
    }
}

fileprivate extension Finding.Message {
    static func insertSorted(_ receiver: String) -> Finding.Message {
        "consider an insert at the sorted index of '\(receiver)'. A 'sort' after one 'append' sorts the whole collection again"
    }
}
