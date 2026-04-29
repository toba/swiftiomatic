import SwiftSyntax

/// Compact-pipeline merge of all `FunctionSignatureSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
func rewriteFunctionSignature(
    _ node: FunctionSignatureSyntax,
    parent: Syntax?,
    context: Context
) -> FunctionSignatureSyntax {
    var result = node
    // No ported rules currently register `static transform` for
    // FunctionSignatureSyntax.

    // NoVoidReturnOnFunctionSignature — strips an explicit `-> Void` / `-> ()`
    // return clause. Inlined from
    // `Sources/SwiftiomaticKit/Rules/Types/NoVoidReturnOnFunctionSignature.swift`.
    if context.shouldFormat(NoVoidReturnOnFunctionSignature.self, node: Syntax(result)) {
        result = applyNoVoidReturnOnFunctionSignature(result, context: context)
    }

    return result
}

private func applyNoVoidReturnOnFunctionSignature(
    _ node: FunctionSignatureSyntax,
    context: Context
) -> FunctionSignatureSyntax {
    guard let returnType = node.returnClause?.type else { return node }

    if let identifierType = returnType.as(IdentifierTypeSyntax.self),
       identifierType.name.text == "Void",
       identifierType.genericArgumentClause?.arguments.isEmpty ?? true
    {
        NoVoidReturnOnFunctionSignature.diagnose(
            .removeRedundantReturn("Void"),
            on: identifierType,
            context: context
        )
        var result = node
        result.returnClause = nil
        return result
    }
    if let tupleType = returnType.as(TupleTypeSyntax.self), tupleType.elements.isEmpty {
        NoVoidReturnOnFunctionSignature.diagnose(
            .removeRedundantReturn("()"),
            on: tupleType,
            context: context
        )
        var result = node
        result.returnClause = nil
        return result
    }
    return node
}

extension Finding.Message {
    fileprivate static func removeRedundantReturn(_ type: String) -> Finding.Message {
        "remove the explicit return type '\(type)' from this function"
    }
}
