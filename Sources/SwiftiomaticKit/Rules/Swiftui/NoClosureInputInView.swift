import SwiftSyntax

/// Flag a stored property of function type in a `View` or `ViewModifier` type.
///
/// SwiftUI compares the stored inputs of a view to decide whether to evaluate its `body` again. It
/// cannot compare two closures, so a view that stores one looks changed on every update of its
/// parent. Store the value the closure computes, or keep the action at the call site.
///
/// Builder content is not an input of this kind. A property with a result builder attribute such
/// as `@ViewBuilder` or `@ContentBuilder` is exempt, and so is a closure whose result type is a
/// generic parameter of the view, such as `() -> Label` .
///
/// Lint: A stored property of a view type has a function type and no result builder attribute.
final class NoClosureInputInView: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard !node.attributes.hasResultBuilder,
              !node.modifiers.contains(where: {
                  $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
              }),
              context.viewEntry(forMember: node) != nil else { return .skipChildren }
        let generics = node.enclosingGenericParameterNames

        for binding in node.bindings where binding.accessorBlock == nil {
            guard let type = binding.typeAnnotation?.type,
                  let function = Self.functionType(type),
                  !Self.returnsGenericParameter(function, generics),
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            else { continue }
            diagnose(.closureInput(name), on: node)
        }
        return .skipChildren
    }

    /// The function type under any optional and attribute layers, such as `@MainActor` or
    /// `@Sendable`
    private static func functionType(_ type: TypeSyntax) -> FunctionTypeSyntax? {
        var current = type.unwrappingOptional

        while true {
            if let function = current.as(FunctionTypeSyntax.self) { return function }
            if let attributed = current.as(AttributedTypeSyntax.self) {
                current = attributed.baseType
            } else if let tuple = current.as(TupleTypeSyntax.self),
                      let only = tuple.elements.first, tuple.elements.count == 1 {
                current = only.type.unwrappingOptional
            } else {
                return nil
            }
        }
    }

    private static func returnsGenericParameter(
        _ function: FunctionTypeSyntax,
        _ generics: Set<String>
    ) -> Bool {
        guard let name = function.returnClause.type.simpleTypeName else { return false }
        return generics.contains(name)
    }
}

fileprivate extension Finding.Message {
    static func closureInput(_ name: String) -> Finding.Message {
        """
        '\(name)' stores a closure input. SwiftUI cannot compare a closure, so the view cannot \
        skip 'body'. Store the value, or keep the action at the call site
        """
    }
}
