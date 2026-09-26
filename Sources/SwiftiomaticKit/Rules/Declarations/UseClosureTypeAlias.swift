import SwiftSyntax

/// Name a complex closure type of a stored property with a `typealias` .
///
/// A closure type that takes or returns another closure, or that spells several nested types, is
/// hard to read in a declaration. A `typealias` names what the closure does and keeps the stored
/// property on one short line.
///
/// A closure type counts as complex when a parameter or the result is itself a closure type, or
/// when it spells five or more types in total. `(Item?, Binding<Bool>) -> Editor` spells five:
/// `Item?` , `Item` , `Binding<Bool>` , `Bool` and `Editor` .
///
/// Lint: A stored property of a type has a complex closure type.
final class UseClosureTypeAlias: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }
    override class var guidance: GuidanceLevel { .consider }

    /// The number of spelled types at which a closure type counts as complex
    private static let complexTypeCount = 5

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.parent?.is(MemberBlockItemSyntax.self) == true else { return .skipChildren }

        for binding in node.bindings where binding.accessorBlock == nil {
            guard let type = binding.typeAnnotation?.type,
                  let function = type.functionType,
                  Self.isComplex(function),
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            else { continue }
            diagnose(.complexClosureType(name), on: node)
        }
        return .skipChildren
    }

    private static func isComplex(_ function: FunctionTypeSyntax) -> Bool {
        let nested = function.parameters.contains { $0.type.functionType != nil }
            || function.returnClause.type.functionType != nil
        return nested || spelledTypeCount(function) >= complexTypeCount
    }

    /// The number of named types, optionals and collections the closure type spells
    private static func spelledTypeCount(_ function: FunctionTypeSyntax) -> Int {
        let counter = TypeCounter(viewMode: .sourceAccurate)
        counter.walk(function)
        return counter.count
    }

    private final class TypeCounter: SyntaxVisitor {
        var count = 0

        override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
            count += 1
            return .visitChildren
        }

        override func visit(_ node: MemberTypeSyntax) -> SyntaxVisitorContinueKind {
            count += 1
            return .skipChildren
        }

        override func visit(_ node: OptionalTypeSyntax) -> SyntaxVisitorContinueKind {
            count += 1
            return .visitChildren
        }

        override func visit(_ node: ArrayTypeSyntax) -> SyntaxVisitorContinueKind {
            count += 1
            return .visitChildren
        }

        override func visit(_ node: DictionaryTypeSyntax) -> SyntaxVisitorContinueKind {
            count += 1
            return .visitChildren
        }
    }
}

fileprivate extension Finding.Message {
    static func complexClosureType(_ name: String) -> Finding.Message {
        "'\(name)' spells out a complex closure type. Name it with a 'typealias' so the declaration reads at a glance"
    }
}
