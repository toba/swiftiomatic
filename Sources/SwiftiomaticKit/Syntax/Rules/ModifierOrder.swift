import SwiftSyntax

/// Enforce consistent ordering for declaration modifiers.
///
/// Modifiers should appear in a canonical order: access control, then `override`, then
/// `class`/`static`, then other modifiers. For example, `public static func` not
/// `static public func`.
///
/// Lint: If modifiers are out of order, a lint warning is raised.
///
/// Format: The modifiers are reordered to match the canonical order.
final class ModifierOrder: RewriteSyntaxRule<BasicRuleValue> {

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

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        DeclSyntax(reorderingModifiers(of: node, keyPath: \.modifiers))
    }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        DeclSyntax(reorderingModifiers(of: node, keyPath: \.modifiers))
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node).cast(ClassDeclSyntax.self)
        return DeclSyntax(reorderingModifiers(of: visited, keyPath: \.modifiers))
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node).cast(StructDeclSyntax.self)
        return DeclSyntax(reorderingModifiers(of: visited, keyPath: \.modifiers))
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node).cast(EnumDeclSyntax.self)
        return DeclSyntax(reorderingModifiers(of: visited, keyPath: \.modifiers))
    }

    override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node).cast(ActorDeclSyntax.self)
        return DeclSyntax(reorderingModifiers(of: visited, keyPath: \.modifiers))
    }

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        DeclSyntax(reorderingModifiers(of: node, keyPath: \.modifiers))
    }

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        DeclSyntax(reorderingModifiers(of: node, keyPath: \.modifiers))
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
        DeclSyntax(reorderingModifiers(of: node, keyPath: \.modifiers))
    }

    // MARK: - Reordering

    private func reorderingModifiers<Decl: DeclSyntaxProtocol>(
        of node: Decl,
        keyPath: WritableKeyPath<Decl, DeclModifierListSyntax>
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

        diagnose(.reorderModifiers, on: modifiers.first!)

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
