import SwiftSyntax

extension FunctionCallExprSyntax {
    /// The closure that builds one row per element, for a `ForEach` call or a data-driven `List`
    /// call
    ///
    /// The closure is the trailing closure or the argument labeled `content` . A `List` counts only
    /// when it takes a data argument, because `List { }` holds static content rather than rows.
    ///
    /// - Parameter includingList: Whether `List(data) { }` also counts.
    func rowContentClosure(includingList: Bool = false) -> ClosureExprSyntax? {
        guard let callee = calledExpression.as(DeclReferenceExprSyntax.self) else { return nil }

        switch callee.baseName.text {
            case "ForEach": break
            case "List" where includingList:
                guard arguments.contains(where: { $0.label == nil }) else { return nil }
            default: return nil
        }
        if let trailingClosure { return trailingClosure }
        return arguments.first { $0.label?.text == "content" }?.expression.as(
            ClosureExprSyntax.self)
    }

    /// The name the callee spells: `ForEach` for `ForEach(...)` and `task` for `view.task { }`
    var calleeBaseName: String? {
        if let reference = calledExpression.as(DeclReferenceExprSyntax.self) {
            return reference.baseName.text
        }
        return calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
    }
}

extension ClosureExprSyntax {
    /// The call this closure is an argument of, as its trailing closure or as a labeled argument
    ///
    /// An additional trailing closure such as `label:` has no owning call here, because it hangs
    /// off a `MultipleTrailingClosureElementSyntax` rather than an argument list.
    var owningCall: FunctionCallExprSyntax? {
        if let argument = parent?.as(LabeledExprSyntax.self) {
            return argument.parent?.parent?.as(FunctionCallExprSyntax.self)
        }
        return parent?.as(FunctionCallExprSyntax.self)
    }
}
