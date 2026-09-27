import SwiftSyntax

/// An access level that the modifiers of a declaration state, ordered from the most restricted to
/// the least.
enum DeclaredAccessLevel: Int, Comparable {
    case `private`, `fileprivate`, `internal`, `package`, `public`

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    /// The access level that `modifiers` state, or `nil` when they state none.
    ///
    /// A modifier with a detail, such as `private(set)`, restricts only the setter, so this
    /// initializer ignores it. `open` counts as `public`.
    init?(_ modifiers: DeclModifierListSyntax) {
        for modifier in modifiers where modifier.detail == nil {
            switch modifier.name.tokenKind {
                case .keyword(.private): self = .private
                case .keyword(.fileprivate): self = .fileprivate
                case .keyword(.internal): self = .internal
                case .keyword(.package): self = .package
                case .keyword(.public), .keyword(.open): self = .public
                default: continue
            }
            return
        }
        return nil
    }
}

/// The stored properties that the synthesized memberwise initializer of a `struct` takes, and the
/// access level of that initializer.
///
/// The computation reads only the main body of the `struct`. It applies these rules:
///
/// - A `static` or `class` property, a computed property, and a `let` with an initial value take
///   no parameter.
/// - A property that the arguments of a wrapper attribute set up, as in
///   `@Environment(\.dismiss) var dismiss`, takes no parameter.
/// - SE-0502: a property below the access ceiling of the other properties that also has a
///   default value takes no parameter.
struct MemberwiseInitializer {
    /// The properties the initializer takes, in declaration order
    let properties: [VariableDeclSyntax]
    /// The access level of the initializer. It is never above `internal`.
    let accessLevel: DeclaredAccessLevel

    init(of node: StructDeclSyntax) {
        let candidates = node.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter(\.isMemberwiseCandidate)

        // A synthesized memberwise initializer is never above internal. A property with no
        // modifier has the internal level, whatever the level of the type.
        let levels = candidates.map {
            min(DeclaredAccessLevel($0.modifiers) ?? .internal, .internal)
        }

        // SE-0502: a property below the ceiling that also has a default value drops out of the
        // memberwise initializer, so it does not pull the initializer down to its own level.
        let ceiling = levels.max() ?? .internal
        let kept = zip(candidates, levels).filter { property, level in
            level >= ceiling || !property.hasDefaultValue
        }

        properties = kept.map(\.0)
        // The initializer is no more accessible than its least accessible parameter.
        accessLevel = kept.map(\.1).min() ?? .internal
    }
}

extension VariableDeclSyntax {
    /// Whether every binding has a default value.
    ///
    /// An optional `var` with no initial value starts as `nil`, so it counts too. An optional
    /// `let` does not start as `nil`. A wrapped optional `var` also does not start as `nil`,
    /// because the wrapper stores the value.
    var hasDefaultValue: Bool {
        bindings.allSatisfy { binding in
            if binding.initializer != nil { return true }
            guard bindingSpecifier.tokenKind == .keyword(.var),
                  attributes.isEmpty,
                  let type = binding.typeAnnotation?.type else { return false }
            return type.is(OptionalTypeSyntax.self)
                || type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self)
        }
    }

    /// Whether the declaration can take a parameter in the synthesized memberwise initializer,
    /// before the SE-0502 rule applies.
    fileprivate var isMemberwiseCandidate: Bool {
        guard !modifiers.contains(anyOf: [.static, .class]) else { return false }

        // A `let` with an initial value can never change.
        if bindingSpecifier.tokenKind == .keyword(.let),
           bindings.allSatisfy({ $0.initializer != nil }) { return false }

        // The arguments of a wrapper attribute set the property up, as in
        // `@Environment(\.dismiss) var dismiss`.
        if bindings.allSatisfy({ $0.initializer == nil }),
           attributes.contains(where: { $0.as(AttributeSyntax.self)?.arguments != nil }) {
            return false
        }

        // A property with only `willSet` or `didSet` observers stays stored.
        return bindings.allSatisfy { binding in
            switch binding.accessorBlock?.accessors {
                case nil: true
                case .getter?: false
                case let .accessors(list)?:
                    list.allSatisfy {
                        $0.accessorSpecifier.tokenKind == .keyword(.willSet)
                            || $0.accessorSpecifier.tokenKind == .keyword(.didSet)
                    }
            }
        }
    }
}
