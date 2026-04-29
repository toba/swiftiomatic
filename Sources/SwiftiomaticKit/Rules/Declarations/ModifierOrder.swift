import SwiftSyntax

/// Enforce consistent ordering for declaration modifiers.
///
/// Modifiers should appear in a canonical order: access control, then `override`, then
/// `class`/`static`, then other modifiers. For example, `public static func` not
/// `static public func`.
///
/// Lint: If modifiers are out of order, a lint warning is raised.
///
/// Rewrite: The modifiers are reordered to match the canonical order.
final class ModifierOrder: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }

    /// Canonical modifier order. Modifiers not in this list keep their relative position
    /// after all listed modifiers.
    private static let canonicalOrder: [Keyword] = [
        // Access control
        .open, .public, .package, .internal, .fileprivate, .private,
        // Override
        .override,
        // Class/static
        .class, .static,
        // Final
        .final,
        // Required/convenience/optional
        .required, .convenience, .optional,
        // Lazy
        .lazy,
        // Dynamic
        .dynamic,
        // Ownership
        .weak, .unowned,
        // Mutation
        .mutating, .nonmutating,
        // Isolation
        .nonisolated,
        // Indirect
        .indirect,
        // Consuming/borrowing
        .consuming, .borrowing,
    ]

    /// Maps each keyword to its canonical position for O(1) lookup.
    private static let orderIndex: [Keyword: Int] = {
        var map = [Keyword: Int]()
        for (index, keyword) in canonicalOrder.enumerated() {
            map[keyword] = index
        }
        return map
    }()

    // MARK: - Visitors

    static func transform(
        _ node: FunctionDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(reorderingModifiers(of: node, keyPath: \.modifiers, context: context))
    }

    static func transform(
        _ node: VariableDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(reorderingModifiers(of: node, keyPath: \.modifiers, context: context))
    }

    static func transform(
        _ node: ClassDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(reorderingModifiers(of: node, keyPath: \.modifiers, context: context))
    }

    static func transform(
        _ node: StructDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(reorderingModifiers(of: node, keyPath: \.modifiers, context: context))
    }

    static func transform(
        _ node: EnumDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(reorderingModifiers(of: node, keyPath: \.modifiers, context: context))
    }

    static func transform(
        _ node: ActorDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(reorderingModifiers(of: node, keyPath: \.modifiers, context: context))
    }

    static func transform(
        _ node: InitializerDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(reorderingModifiers(of: node, keyPath: \.modifiers, context: context))
    }

    static func transform(
        _ node: SubscriptDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(reorderingModifiers(of: node, keyPath: \.modifiers, context: context))
    }

    static func transform(
        _ node: TypeAliasDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(reorderingModifiers(of: node, keyPath: \.modifiers, context: context))
    }

    // MARK: - Reordering

    private static func reorderingModifiers<Decl: DeclSyntaxProtocol>(
        of node: Decl,
        keyPath: WritableKeyPath<Decl, DeclModifierListSyntax>,
        context: Context
    ) -> Decl {
        let modifiers = node[keyPath: keyPath]
        guard modifiers.count > 1 else { return node }

        // Assign a sort key to each modifier based on canonical order.
        // Modifiers not in the canonical list get a high index to preserve relative position.
        let sorted = modifiers.enumerated().sorted { lhs, rhs in
            let lhsOrder = Self.sortKey(for: lhs.element, at: lhs.offset)
            let rhsOrder = Self.sortKey(for: rhs.element, at: rhs.offset)
            return lhsOrder < rhsOrder
        }

        // Check if the order actually changed.
        let sortedIndices = sorted.map(\.offset)
        let originalIndices = Array(0..<modifiers.count)
        guard sortedIndices != originalIndices else { return node }

        Self.diagnose(.reorderModifiers, on: modifiers.first!, context: context)

        // Build new modifier list preserving trivia from original positions.
        var reordered = sorted.map(\.element)

        // The first modifier in the new list should get the leading trivia from the
        // original first modifier (newline + indentation).
        let originalLeadingTrivia = modifiers.first!.leadingTrivia
        reordered[0] = reordered[0]
            .with(\.leadingTrivia, originalLeadingTrivia)

        // Non-first modifiers should have a single space as leading trivia
        // (removing any original leading indentation they might have had).
        for i in 1..<reordered.count {
            if !reordered[i].leadingTrivia.isEmpty {
                reordered[i] = reordered[i].with(\.leadingTrivia, [])
            }
        }

        var result = node
        result[keyPath: keyPath] = DeclModifierListSyntax(reordered)
        return result
    }

    /// Returns a sort key for a modifier. Known modifiers use their canonical index;
    /// unknown modifiers use a high index + their original position to preserve relative order.
    private static func sortKey(for modifier: DeclModifierSyntax, at originalIndex: Int) -> Int {
        if case .keyword(let keyword) = modifier.name.tokenKind,
            let index = orderIndex[keyword]
        {
            return index
        }
        // Unknown modifiers sort after all known ones, preserving relative order.
        return canonicalOrder.count + originalIndex
    }
}

extension Finding.Message {
    fileprivate static let reorderModifiers: Finding.Message =
        "reorder declaration modifiers to follow canonical order"
}
