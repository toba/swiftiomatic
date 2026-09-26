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
/// A closure type also earns a name when the file spells it more than once, in stored properties
/// or in function and initializer parameters. Two spellings match when they differ only in
/// parameter labels, attributes such as `@escaping` , or an outer optional. Two closure types with
/// the same list of two or more parameters also match, so `(ID, Edge, ID) -> Bool` and
/// `(ID, Edge, ID) -> Void` both report. `() -> Void` never counts as a repeat.
///
/// Two closure types of two or more parameters that differ in exactly one parameter type share a
/// shape, as in `(Item, Importable) -> Void` and `(Item, Exportable) -> Void` . A generic
/// `typealias` names that shape once.
///
/// A closure type with three or more attributes and effects, such as
/// `@escaping @Sendable (Transaction) throws -> ID` , also counts as complex. This check applies to
/// parameters as well as to stored properties.
///
/// Lint: A stored property of a type has a complex closure type, a parameter has a heavily
/// decorated closure type, or a stored property or parameter spells a closure type or a closure
/// shape that the file repeats.
final class UseClosureTypeAlias: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }
    override class var guidance: GuidanceLevel { .consider }

    /// The number of spelled types at which a closure type counts as complex
    private static let complexTypeCount = 5
    /// The number of attributes and effects at which a closure type counts as complex
    private static let complexDecorationCount = 3

    /// How often the file spells each normalized closure type
    private var typeCounts: [String: Int] = [:]
    /// How often the file spells each normalized parameter list of two or more parameters
    private var parameterListCounts: [String: Int] = [:]
    /// The distinct normalized closure types that match each shape of two or more parameters
    private var shapeSpellings: [String: Set<String>] = [:]

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        let collector = ClosureTypeCollector(viewMode: .sourceAccurate)
        collector.walk(node)

        for function in collector.functions {
            let spelling = Self.normalized(function)
            if spelling.type != "() -> Void" { typeCounts[spelling.type, default: 0] += 1 }
            if let parameters = spelling.parameters {
                parameterListCounts[parameters, default: 0] += 1
            }
            for shape in Self.shapes(function) { shapeSpellings[shape, default: []].insert(spelling.type) }
        }
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.parent?.is(MemberBlockItemSyntax.self) == true else { return .skipChildren }

        for binding in node.bindings where binding.accessorBlock == nil {
            guard let type = binding.typeAnnotation?.type,
                  let function = type.functionType,
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            else { continue }

            if Self.isComplex(function) || Self.isHeavilyDecorated(type, function) {
                diagnose(.complexClosureType(name), on: node)
            } else if let repeated = repeatedSpelling(function) {
                diagnose(.repeatedClosureType(name, repeated), on: node)
            } else if let shape = sharedShape(function) {
                diagnose(.sharedClosureShape(name, shape), on: node)
            }
        }
        return .skipChildren
    }

    override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
        guard let function = node.type.functionType else { return .skipChildren }
        let name = (node.secondName ?? node.firstName).text

        if Self.isHeavilyDecorated(node.type, function) {
            diagnose(.complexClosureType(name), on: node)
        } else if let repeated = repeatedSpelling(function) {
            diagnose(.repeatedClosureType(name, repeated), on: node)
        } else if let shape = sharedShape(function) {
            diagnose(.sharedClosureShape(name, shape), on: node)
        }
        return .skipChildren
    }

    /// The normalized spelling of `function` when the file repeats it, or `nil`
    private func repeatedSpelling(_ function: FunctionTypeSyntax) -> String? {
        let spelling = Self.normalized(function)
        if typeCounts[spelling.type, default: 0] >= 2 { return spelling.type }
        if let parameters = spelling.parameters, parameterListCounts[parameters, default: 0] >= 2 {
            return spelling.type
        }
        return nil
    }

    /// The shape of `function` that another closure type in the file shares, or `nil`
    private func sharedShape(_ function: FunctionTypeSyntax) -> String? {
        Self.shapes(function).first { shapeSpellings[$0, default: []].count >= 2 }
    }

    /// The spellings of `function` with one parameter type replaced by `_` , one per parameter,
    /// when it has two or more parameters
    private static func shapes(_ function: FunctionTypeSyntax) -> [String] {
        let parameters = parameterTypes(function)
        guard parameters.count >= 2 else { return [] }
        let tail = effects(function) + " -> " + collapsed(function.returnClause.type.trimmedDescription)

        return parameters.indices.map { index in
            var shape = parameters
            shape[index] = "_"
            return "(" + shape.joined(separator: ", ") + ")" + tail
        }
    }

    private static func parameterTypes(_ function: FunctionTypeSyntax) -> [String] {
        function.parameters.map { collapsed($0.type.trimmedDescription) }
    }

    private static func effects(_ function: FunctionTypeSyntax) -> String {
        function.effectSpecifiers.map { " " + $0.trimmedDescription } ?? ""
    }

    /// The closure type without parameter labels or parameter attributes, and its parameter list
    /// when it has two or more parameters
    private static func normalized(_ function: FunctionTypeSyntax) -> (type: String, parameters: String?) {
        let parameters = parameterTypes(function)
        let list = "(" + parameters.joined(separator: ", ") + ")"
        let result = collapsed(function.returnClause.type.trimmedDescription)
        return (list + effects(function) + " -> " + result, parameters.count >= 2 ? list : nil)
    }

    private static func collapsed(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private static func isComplex(_ function: FunctionTypeSyntax) -> Bool {
        let nested = function.parameters.contains { $0.type.functionType != nil }
            || function.returnClause.type.functionType != nil
        return nested || spelledTypeCount(function) >= complexTypeCount
    }

    /// Whether `type` , which wraps `function` , spells three or more attributes and effects
    private static func isHeavilyDecorated(_ type: TypeSyntax, _ function: FunctionTypeSyntax) -> Bool {
        var count = 0
        var current = type

        while true {
            if let attributed = current.as(AttributedTypeSyntax.self) {
                count += attributed.attributes.count
                current = attributed.baseType
            } else if let optional = current.as(OptionalTypeSyntax.self) {
                current = optional.wrappedType
            } else if let tuple = current.as(TupleTypeSyntax.self), tuple.elements.count == 1,
                      let element = tuple.elements.first {
                current = element.type
            } else {
                break
            }
        }
        if function.effectSpecifiers?.asyncSpecifier != nil { count += 1 }
        if function.effectSpecifiers?.throwsClause != nil { count += 1 }
        return count >= complexDecorationCount
    }

    /// The number of named types, optionals and collections the closure type spells
    private static func spelledTypeCount(_ function: FunctionTypeSyntax) -> Int {
        let counter = TypeCounter(viewMode: .sourceAccurate)
        counter.walk(function)
        return counter.count
    }

    /// Collects the closure types of stored properties and of function, initializer and
    /// subscript parameters
    private final class ClosureTypeCollector: SyntaxVisitor {
        var functions: [FunctionTypeSyntax] = []

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            guard node.parent?.is(MemberBlockItemSyntax.self) == true else { return .visitChildren }

            for binding in node.bindings where binding.accessorBlock == nil {
                if let function = binding.typeAnnotation?.type.functionType {
                    functions.append(function)
                }
            }
            return .visitChildren
        }

        override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
            if let function = node.type.functionType { functions.append(function) }
            return .skipChildren
        }
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
    static func repeatedClosureType(_ name: String, _ type: String) -> Finding.Message {
        "'\(name)' repeats the closure type '\(type)', which this file spells more than once. Name it with a 'typealias'"
    }

    static func sharedClosureShape(_ name: String, _ shape: String) -> Finding.Message {
        "'\(name)' shares the closure shape '\(shape)' with another declaration in this file. Name the shape with a generic 'typealias'"
    }

    static func complexClosureType(_ name: String) -> Finding.Message {
        "'\(name)' spells out a complex closure type. Name it with a 'typealias' so the declaration reads at a glance"
    }
}
