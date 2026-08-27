import SwiftSyntax

/// Flag `dropFirst` on a `Data` value.
///
/// `Data` is a value type over a copy-on-write buffer, and `dropFirst` hands back a new `Data` . A
/// parse loop that drops one byte per pass therefore copies the rest of the buffer on every pass,
/// which makes the loop quadratic in the input size. Advance an index instead, or take one slice
/// and read through it.
///
/// The rule reads the type from the source alone. It collects the names the file declares as `Data`
/// , through a type annotation, a `Data(...)` initializer or a parameter type, and it reports a
/// `dropFirst` whose receiver is one of them. A receiver it cannot resolve stays quiet, so
/// `dropFirst` on a `String` or an `Array` raises nothing.
///
/// Lint: A `dropFirst` call on a value the file declares as `Data` raises a warning.
final class NoDropFirstOnData: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    private var dataNames: Set<String> = []

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        let collector = DataNameCollector(viewMode: .sourceAccurate)
        collector.walk(node)
        dataNames = collector.names
        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            member.declName.baseName.text == "dropFirst",
            receiverIsData(member.base) else { return .visitChildren }

        diagnose(.dropFirstOnData, on: member.declName)
        return .visitChildren
    }

    /// Whether the receiver resolves to `Data` , by declared name or as a direct `Data(...)` call.
    private func receiverIsData(_ expr: ExprSyntax?) -> Bool {
        guard let expr else { return false }

        if let reference = expr.as(DeclReferenceExprSyntax.self) {
            return dataNames.contains(reference.baseName.text)
        }

        if let member = expr.as(MemberAccessExprSyntax.self) {
            // self.buffer resolves through the stored property name
            guard member.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "self" else {
                return false
            }
            return dataNames.contains(member.declName.baseName.text)
        }
        if let call = expr.as(FunctionCallExprSyntax.self) {
            return call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "Data"
        }
        return false
    }
}

/// Collects every name the file declares as `Data` .
private final class DataNameCollector: SyntaxVisitor {
    private(set) var names: Set<String> = []

    override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
        guard let identifier = node.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            return .visitChildren
        }

        if let annotation = node.typeAnnotation, isData(annotation.type) {
            names.insert(identifier)
        } else if let call = node.initializer?.value.as(FunctionCallExprSyntax.self),
            call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "Data"
        {
            names.insert(identifier)
        }
        return .visitChildren
    }

    override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
        if isData(node.type) { names.insert((node.secondName ?? node.firstName).text) }
        return .visitChildren
    }

    private func isData(_ type: TypeSyntax) -> Bool {
        var base = type
        if let optional = base.as(OptionalTypeSyntax.self) { base = optional.wrappedType }
        return base.as(IdentifierTypeSyntax.self)?.name.text == "Data"
    }
}

fileprivate extension Finding.Message {
    static let dropFirstOnData: Finding.Message = """
        'dropFirst' copies the whole 'Data' buffer, so a parse loop is quadratic — advance an \
        index, or slice once
        """
}
