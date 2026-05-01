import SwiftSyntax

/// Lint `withObservationTracking { ... } onChange: { … self.f() … }` where the `onChange` closure
/// calls the enclosing function `f()` . The pattern is a recursive re-tracker that fires forever as
/// observed values mutate. Use the `Observations` AsyncSequence instead.
final class WarnRecursiveWithObservationTracking: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable
{
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let ident = node.calledExpression.as(DeclReferenceExprSyntax.self),
              ident.baseName.text == "withObservationTracking",
              let onChangeClosure = onChangeClosure(of: node),
              let enclosingName = enclosingFunctionName(of: node) else { return .visitChildren }
        let collector = NameUseCollector(name: enclosingName, viewMode: .sourceAccurate)
        collector.walk(onChangeClosure.statements)
        if collector.found {
            diagnose(.recursiveObservationTracking(enclosingName), on: node.calledExpression)
        }
        return .visitChildren
    }

    private func onChangeClosure(of call: FunctionCallExprSyntax) -> ClosureExprSyntax? {
        for additional in call.additionalTrailingClosures where additional.label.text == "onChange"
        {
            return additional.closure
        }
        for arg in call.arguments where arg.label?.text == "onChange" {
            if let closure = arg.expression.as(ClosureExprSyntax.self) { return closure }
        }
        return nil
    }

    private func enclosingFunctionName(of node: SyntaxProtocol) -> String? {
        var current: Syntax? = node.parent

        while let cursor = current {
            if let funcDecl = cursor.as(FunctionDeclSyntax.self) { return funcDecl.name.text }
            current = cursor.parent
        }
        return nil
    }
}

private final class NameUseCollector: SyntaxVisitor {
    let name: String
    var found = false

    init(name: String, viewMode: SyntaxTreeViewMode) {
        self.name = name
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        if node.baseName.text == name { found = true }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func recursiveObservationTracking(_ name: String) -> Finding.Message {
        "'withObservationTracking' onChange calls enclosing '\(name)' — infinite re-tracking. Use 'Observations' AsyncSequence."
    }
}
