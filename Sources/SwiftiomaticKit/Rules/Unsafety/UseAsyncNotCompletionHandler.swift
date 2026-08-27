import SwiftSyntax

/// Flag a function that returns its result through a trailing completion handler.
///
/// A completion handler carries the result out of band. The caller cannot `try` it, cannot cancel
/// it, and gets no compiler check that the handler runs exactly once on every path. An `async`
/// function returns the value on the normal path and inherits cancellation from its caller.
///
/// The rule reports only the shape a mechanical translation fits: the last parameter is `@escaping`
/// , it is named `completion` or `completionHandler` , its type is a function type that returns
/// `Void` , and the function is not already `async` .
///
/// Lint: A function with such a parameter raises a warning.
final class UseAsyncNotCompletionHandler: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    private static let handlerNames: Set<String> = ["completion", "completionHandler"]

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.signature.effectSpecifiers?.asyncSpecifier == nil,
              let last = node.signature.parameterClause.parameters.last,
              Self.handlerNames.contains((last.secondName ?? last.firstName).text),
              isEscapingVoidFunction(last.type) else { return .visitChildren }

        diagnose(.useAsync((last.secondName ?? last.firstName).text), on: last)
        return .visitChildren
    }

    /// Whether the type is an `@escaping` function type that returns `Void` .
    private func isEscapingVoidFunction(_ type: TypeSyntax) -> Bool {
        guard let attributed = type.as(AttributedTypeSyntax.self),
              attributed.attributes.attribute(named: "escaping") != nil,
              let function = attributed.baseType.as(FunctionTypeSyntax.self) else { return false }

        let returned = function.returnClause.type.trimmedDescription
        return returned == "Void" || returned == "()"
    }
}

fileprivate extension Finding.Message {
    static func useAsync(_ name: String) -> Finding.Message {
        """
        '\(name)' returns its result through an escaping closure — mark the function 'async' and \
        return the value
        """
    }
}
