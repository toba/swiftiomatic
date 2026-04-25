import SwiftSyntax

/// Initializers declared in `ExpressibleBy*` literal protocols are intended
/// for the compiler. Calling them directly (`Set(arrayLiteral: 1, 2)`) is
/// almost certainly a mistake — the literal form (`[1, 2]`) is shorter,
/// faster, and more idiomatic.
///
/// Lint: When a known standard-library or Foundation type is initialized via
/// a compiler-protocol label like `arrayLiteral`/`dictionaryLiteral`/
/// `stringLiteral`, a warning is raised.
final class NoLiteralProtocolInit: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .literals }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.trailingClosure == nil else { return .visitChildren }

        let labels = node.arguments.compactMap { $0.label?.text }
        guard !labels.isEmpty else { return .visitChildren }

        guard let typeName = functionName(of: node.calledExpression) else {
            return .visitChildren
        }

        for entry in CompilerProtocols.all {
            if entry.types.contains(typeName), entry.argumentLabels.contains(labels) {
                diagnose(.literalProtocolInit(entry.protocolName), on: node)
                return .visitChildren
            }
        }
        return .visitChildren
    }

    /// Returns the type name used in a constructor expression, accepting
    /// both `Foo(...)` and `Foo.init(...)` shapes.
    private func functionName(of expression: ExprSyntax) -> String? {
        if let ref = expression.as(DeclReferenceExprSyntax.self) {
            return ref.baseName.text
        }
        if let memberAccess = expression.as(MemberAccessExprSyntax.self),
            let base = memberAccess.base?.as(DeclReferenceExprSyntax.self),
            memberAccess.declName.baseName.text == "init"
        {
            return base.baseName.text
        }
        return nil
    }
}

private struct CompilerProtocols {
    let protocolName: String
    let types: Set<String>
    let argumentLabels: Set<[String]>

    static let all: [CompilerProtocols] = [
        CompilerProtocols(
            protocolName: "ExpressibleByArrayLiteral",
            types: [
                "Array", "ArraySlice", "ContiguousArray", "IndexPath", "IndexSet",
                "NSArray", "NSCountedSet", "NSMutableArray", "NSMutableOrderedSet",
                "NSMutableSet", "NSOrderedSet", "NSSet", "Set",
            ],
            argumentLabels: [["arrayLiteral"]]
        ),
        CompilerProtocols(
            protocolName: "ExpressibleByNilLiteral",
            types: ["Optional"],
            argumentLabels: [["nilLiteral"]]
        ),
        CompilerProtocols(
            protocolName: "ExpressibleByBooleanLiteral",
            types: ["Bool", "NSDecimalNumber", "NSNumber", "ObjCBool"],
            argumentLabels: [["booleanLiteral"]]
        ),
        CompilerProtocols(
            protocolName: "ExpressibleByFloatLiteral",
            types: ["Decimal", "NSDecimalNumber", "NSNumber"],
            argumentLabels: [["floatLiteral"]]
        ),
        CompilerProtocols(
            protocolName: "ExpressibleByIntegerLiteral",
            types: ["Decimal", "Double", "Float", "Float80", "NSDecimalNumber", "NSNumber"],
            argumentLabels: [["integerLiteral"]]
        ),
        CompilerProtocols(
            protocolName: "ExpressibleByUnicodeScalarLiteral",
            types: ["StaticString", "String", "UnicodeScalar"],
            argumentLabels: [["unicodeScalarLiteral"]]
        ),
        CompilerProtocols(
            protocolName: "ExpressibleByExtendedGraphemeClusterLiteral",
            types: ["Character", "StaticString", "String"],
            argumentLabels: [["extendedGraphemeClusterLiteral"]]
        ),
        CompilerProtocols(
            protocolName: "ExpressibleByStringLiteral",
            types: ["NSMutableString", "NSString", "Selector", "StaticString", "String"],
            argumentLabels: [["stringLiteral"]]
        ),
        CompilerProtocols(
            protocolName: "ExpressibleByStringInterpolation",
            types: ["String"],
            argumentLabels: [["stringInterpolation"], ["stringInterpolationSegment"]]
        ),
        CompilerProtocols(
            protocolName: "ExpressibleByDictionaryLiteral",
            types: ["Dictionary", "NSDictionary", "NSMutableDictionary"],
            argumentLabels: [["dictionaryLiteral"]]
        ),
    ]
}

extension Finding.Message {
    fileprivate static func literalProtocolInit(_ protocolName: String) -> Finding.Message {
        "initializers declared in compiler protocol '\(protocolName)' shouldn't be called directly"
    }
}
