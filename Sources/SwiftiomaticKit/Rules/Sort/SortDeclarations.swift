import SwiftSyntax

/// Sort declarations between `// swiftiomatic:sort:begin` and `// swiftiomatic:sort:end` markers.
///
/// Declarations within the marked region are sorted alphabetically by name. Comments and trivia
/// associated with each declaration move with it. The markers themselves are preserved in place.
///
/// Lint: If declarations in a marked region are not sorted, a lint warning is raised.
///
/// Rewrite: The declarations are reordered alphabetically by name.
final class SortDeclarations: StructuralFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .sort }
    private static let beginMarker = "swiftiomatic:sort:begin"
    private static let endMarker = "swiftiomatic:sort:end"

    // MARK: - Member blocks (type bodies)

    override func visit(_ node: MemberBlockItemListSyntax) -> MemberBlockItemListSyntax {
        let visited = super.visit(node)
        let items = Array(visited)
        let sorted = sortMarkedRegions(items: items) { declarationName($0.decl) }
        return sorted.map(MemberBlockItemListSyntax.init) ?? visited
    }

    // MARK: - Code blocks (top-level declarations)

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        let visited = super.visit(node)
        let items = Array(visited)
        let sorted = sortMarkedRegions(items: items) { codeBlockItemName($0) }
        return sorted.map(CodeBlockItemListSyntax.init) ?? visited
    }

    /// Sorts items inside `swiftiomatic:sort:begin` / `end` regions in-place, preserving each
    /// position's leading trivia (so the begin/end markers stay put). Returns `nil` if there are no
    /// regions to sort or all regions are already sorted.
    private func sortMarkedRegions<Element: SyntaxProtocol>(
        items: [Element],
        name: (Element) -> String?
    ) -> [Element]? {
        guard items.count > 1 else { return nil }

        var sortedRegions = [(start: Int, end: Int)]()
        var regionStart: Int?

        for (i, item) in items.enumerated() {
            if hasMarker(Self.beginMarker, in: item.leadingTrivia) {
                regionStart = i
            } else if hasMarker(Self.endMarker, in: item.leadingTrivia), let start = regionStart {
                sortedRegions.append((start, i))
                regionStart = nil
            }
        }
        guard !sortedRegions.isEmpty else { return nil }

        var newItems = items
        var didChange = false

        for region in sortedRegions.reversed() {
            let slice = items[region.start..<region.end]
            guard slice.count > 1 else { continue }

            let originalNames = slice.compactMap(name)

            let sorted = slice.enumerated().sorted { lhs, rhs in
                let lhsName = name(lhs.element) ?? ""
                let rhsName = name(rhs.element) ?? ""
                return lhsName != rhsName
                    ? lhsName.localizedCompare(rhsName) == .orderedAscending
                    : lhs.offset < rhs.offset
            }.map(\.element)

            let sortedNames = sorted.compactMap(name)
            guard originalNames != sortedNames else { continue }

            if let firstToken = items[region.start].firstToken(viewMode: .sourceAccurate) {
                diagnose(.sortDeclarations, on: firstToken)
            }

            // Rebuild preserving positional trivia (keeps begin marker at position 0).
            for (i, sortedItem) in sorted.enumerated() {
                var newItem = sortedItem
                newItem.leadingTrivia = items[region.start + i].leadingTrivia
                newItems[region.start + i] = newItem
            }
            didChange = true
        }
        return didChange ? newItems : nil
    }

    // MARK: - Helpers

    private func hasMarker(_ marker: String, in trivia: Trivia) -> Bool {
        trivia.pieces.contains { piece in
            if case let .lineComment(text) = piece {
                text.contains(marker)
            } else if case let .blockComment(text) = piece {
                text.contains(marker)
            } else {
                false
            }
        }
    }

    /// Extract the sortable name from a declaration.
    private func declarationName(_ decl: DeclSyntax) -> String? {
        if let enumCase = decl.as(EnumCaseDeclSyntax.self) {
            enumCase.elements.first?.name.text
        } else if let variable = decl.as(VariableDeclSyntax.self) {
            variable.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier
                .text
        } else if let function = decl.as(FunctionDeclSyntax.self) {
            function.name.text
        } else if let typeAlias = decl.as(TypeAliasDeclSyntax.self) {
            typeAlias.name.text
        } else if let structDecl = decl.as(StructDeclSyntax.self) {
            structDecl.name.text
        } else if let classDecl = decl.as(ClassDeclSyntax.self) {
            classDecl.name.text
        } else if let enumDecl = decl.as(EnumDeclSyntax.self) {
            enumDecl.name.text
        } else if let protocolDecl = decl.as(ProtocolDeclSyntax.self) {
            protocolDecl.name.text
        } else if let initDecl = decl.as(InitializerDeclSyntax.self) {
            initDecl.initKeyword.text
        } else {
            nil
        }
    }

    /// Extract the sortable name from a code block item.
    private func codeBlockItemName(_ item: CodeBlockItemSyntax) -> String? {
        if let decl = item.item.as(DeclSyntax.self) { return declarationName(decl) }
        return nil
    }
}

fileprivate extension Finding.Message {
    static let sortDeclarations: Finding.Message = "sort declarations alphabetically"
}
