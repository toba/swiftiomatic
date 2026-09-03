import SwiftSyntax

/// The syntax shapes that mark a byte-level text parse
///
/// A parse of this kind reads ASCII digits at fixed offsets, so it needs none of the grapheme
/// handling a `String` walk pays for. Two rules use the same tests to tell it apart from prose
/// handling, which is a legitimate use of the same API.
enum BytewiseParsing {
    /// The fixed-width integer types that declare `init?(_:radix:)`
    static let integerTypeNames: Set<String> = [
        "Int",
        "Int128",
        "Int16",
        "Int32",
        "Int64",
        "Int8",
        "UInt",
        "UInt128",
        "UInt16",
        "UInt32",
        "UInt64",
        "UInt8",
    ]

    /// The methods that return a slice of the receiver rather than a new collection
    static let sliceMethodNames: Set<String> = ["dropFirst", "dropLast", "prefix", "suffix"]

    /// The name of the fixed-width integer type a call initializes, or `nil` when it initializes
    /// something else.
    static func integerTypeName(of call: FunctionCallExprSyntax) -> String? {
        guard let callee = call.calledExpression.as(DeclReferenceExprSyntax.self),
            integerTypeNames.contains(callee.baseName.text) else { return nil }

        return callee.baseName.text
    }

    /// The name of the fixed-width integer type a radix call initializes, or `nil` when the call
    /// carries no `radix` argument.
    static func radixTypeName(of call: FunctionCallExprSyntax) -> String? {
        guard let name = integerTypeName(of: call),
              call.arguments.contains(where: { $0.label?.text == "radix" }) else { return nil }

        return name
    }

    /// Whether an expression cuts a slice out of a collection, by subscript or by a slice method
    static func isSlice(_ expr: ExprSyntax) -> Bool { sliceBase(of: expr) != nil }

    /// The identifier a slice expression cuts from, or `nil` when the expression is not a slice or
    /// its receiver is not a plain identifier.
    static func sliceBase(of expr: ExprSyntax) -> String? {
        if let subscriptCall = expr.as(SubscriptCallExprSyntax.self) {
            return subscriptCall.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text
        }

        guard let call = expr.as(FunctionCallExprSyntax.self),
              let member = call.calledExpression.as(MemberAccessExprSyntax.self),
              sliceMethodNames.contains(member.declName.baseName.text) else { return nil }

        return member.base?.as(DeclReferenceExprSyntax.self)?.baseName.text
    }
}
