import SwiftSyntax

/// Flag a mutable stored property of an `@Observable` class whose type is not `Equatable`.
///
/// The setter that `@Observable` generates compares the new value with the stored one when the type
/// is `Equatable`. An equal value then does not notify the views that read the property. Without
/// the conformance, each assignment notifies them, also when the new value has the same contents.
/// This costs most when a property of a custom type gets frequent assignments, for example a new
/// snapshot from an async sequence that often holds the same data.
///
/// Give the type a meaningful `Equatable` conformance. A struct whose members are all `Equatable`
/// gets synthesized equality:
///
/// ```swift
/// struct Sighting: Equatable, Identifiable {
///     let id: UUID
///     var name: String
/// }
/// ```
///
/// For a collection, the element type needs the conformance. The observable class itself does not.
/// Include every field that a view shows in the equality. Do not compare only an identifier when
/// other fields change. Keep the type as it is when no meaningful equality exists, such as a type
/// that holds closures or a reference model, and suppress the finding. The comparison runs only on
/// an assignment. An in-place mutation such as `append` always notifies.
///
/// The rule checks the type of the property, and the element or value type of an optional, an
/// array, a dictionary or a set. It reports a struct, a class or an enum with associated values
/// that this file declares, when neither the declaration nor a same-file extension adopts
/// `Equatable` , `Hashable` or `Comparable` . An enum without associated values is exempt, because
/// Swift synthesizes its equality. An `@Observable` class is exempt, because it is a reference
/// model. A type from another file is not checked.
///
/// Lint: A mutable stored property of an `@Observable` class has a same-file type without an
/// `Equatable` conformance.
final class FlagNonEquatableObservableProperty: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    /// The protocols that include `Equatable`
    private static let equatableProtocols: Set<String> = ["Equatable", "Hashable", "Comparable"]

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.bindingSpecifier.tokenKind == .keyword(.var),
              !node.modifiers.contains(anyOf: [.static, .class]),
              node.attributes.attribute(named: "ObservationIgnored") == nil,
              node.parent?.is(MemberBlockItemSyntax.self) == true,
              let owner = TypeMemberIndex.owningDeclaration(of: node)?.as(ClassDeclSyntax.self),
              owner.attributes.attribute(named: "Observable") != nil else { return .skipChildren }
        let types = context.typeMembers(around: node).types

        for binding in node.bindings where binding.accessorBlock == nil {
            guard let type = binding.typeAnnotation?.type,
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            else { continue }

            for typeName in Self.checkedTypeNames(of: type) {
                guard let entry = types[typeName], Self.lacksEquality(entry) else { continue }
                diagnose(.notEquatable(name, typeName), on: node)
                break
            }
        }
        return .skipChildren
    }

    /// The type names whose equality decides the comparison: the type itself, or the wrapped,
    /// element or value types of an optional, an array, a dictionary or a set
    private static func checkedTypeNames(of type: TypeSyntax) -> [String] {
        let type = type.unwrappingOptional
        if let array = type.as(ArrayTypeSyntax.self) { return checkedTypeNames(of: array.element) }

        if let dictionary = type.as(DictionaryTypeSyntax.self) {
            return checkedTypeNames(of: dictionary.key) + checkedTypeNames(of: dictionary.value)
        }
        guard let identifier = type.as(IdentifierTypeSyntax.self) else { return [] }
        let name = identifier.name.text

        if ["Array", "Set", "Optional", "Dictionary"].contains(name),
           let arguments = identifier.genericArgumentClause?.arguments
        {
            return arguments.flatMap { argument -> [String] in
                guard case let .type(inner) = argument.argument else { return [] }
                return checkedTypeNames(of: inner)
            }
        }
        return [name]
    }

    /// Whether `entry` is a same-file struct, class or enum with associated values that adopts
    /// no protocol that includes `Equatable`
    ///
    /// An enum without associated values gets equality from Swift, and an `@Observable` class is a
    /// reference model, so neither counts.
    private static func lacksEquality(_ entry: TypeMemberIndex.TypeEntry) -> Bool {
        guard entry.conformances.isDisjoint(with: equatableProtocols) else { return false }
        return switch entry.kind {
            case .struct: true
            case .class: !entry.isObservable
            case .enum: entry.hasPayloadCases
            case .actor, nil: false
        }
    }
}

fileprivate extension Finding.Message {
    static func notEquatable(_ name: String, _ type: String) -> Finding.Message {
        """
        '\(name)' stores '\(type)', which is not 'Equatable', so each assignment notifies the \
        views that read it, also when the value did not change. Give '\(type)' a meaningful \
        'Equatable' conformance
        """
    }
}
