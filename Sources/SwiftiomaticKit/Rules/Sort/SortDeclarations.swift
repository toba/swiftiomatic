import SwiftSyntax

/// Sort declarations between `// swiftiomatic:sort:begin` and `// swiftiomatic:sort:end` markers.
///
/// Declarations within the marked region are sorted alphabetically by name. Comments and trivia
/// associated with each declaration move with it. The markers themselves are preserved in place.
///
/// Lint: If declarations in a marked region are not sorted, a lint warning is raised.
///
/// Format: The declarations are reordered alphabetically by name.
final class SortDeclarations: SyntaxFormatRule {
    static let group: ConfigGroup? = .sort
    private static let beginMarker = "swiftiomatic:sort:begin"
    private static let endMarker = "swiftiomatic:sort:end"

    // MARK: - Member blocks (type bodies)

    override func visit(_ node: MemberBlockItemListSyntax) -> MemberBlockItemListSyntax {
        let visited = super.visit(node)
        let items = Array(visited)
        guard items.count > 1 else { return visited }

        // Find sort regions
        var sortedRegions = [(start: Int, end: Int)]()
        var regionStart: Int?

        for (i, item) in items.enumerated() {
            if hasMarker(Self.beginMarker, in: item.leadingTrivia) {
                regionStart = i
            } else if hasMarker(Self.endMarker, in: item.leadingTrivia), let start = regionStart {
                // End marker is on this item, so sorted region is [start, i)
                sortedRegions.append((start, i))
                regionStart = nil
            }
        }

        guard !sortedRegions.isEmpty else { return visited }

        var newItems = items
        for region in sortedRegions.reversed() {
            let slice = Array(items[region.start..<region.end])
            guard slice.count > 1 else { continue }

            let sorted = slice.enumerated().sorted { lhs, rhs in
                let lhsName = declarationName(lhs.element.decl) ?? ""
                let rhsName = declarationName(rhs.element.decl) ?? ""
                if lhsName != rhsName {
                    return lhsName.localizedCompare(rhsName) == .orderedAscending
                }
                return lhs.offset < rhs.offset
            }.map(\.element)

            // Check if already sorted
            let originalNames = slice.compactMap { declarationName($0.decl) }
            let sortedNames = sorted.compactMap { declarationName($0.decl) }
            guard originalNames != sortedNames else { continue }

            if let firstItem = items[region.start].decl.firstToken(viewMode: .sourceAccurate) {
                diagnose(.sortDeclarations, on: firstItem)
            }

            // Rebuild preserving positional trivia (keeps begin marker at position 0)
            for (i, sortedItem) in sorted.enumerated() {
                var newItem = sortedItem
                newItem.leadingTrivia = items[region.start + i].leadingTrivia
                newItems[region.start + i] = newItem
            }
        }

        return MemberBlockItemListSyntax(newItems)
    }

    // MARK: - Code blocks (top-level declarations)

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        let visited = super.visit(node)
        let items = Array(visited)
        guard items.count > 1 else { return visited }

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

        guard !sortedRegions.isEmpty else { return visited }

        var newItems = items
        for region in sortedRegions.reversed() {
            let slice = Array(items[region.start..<region.end])
            guard slice.count > 1 else { continue }

            let sorted = slice.enumerated().sorted { lhs, rhs in
                let lhsName = codeBlockItemName(lhs.element) ?? ""
                let rhsName = codeBlockItemName(rhs.element) ?? ""
                if lhsName != rhsName {
                    return lhsName.localizedCompare(rhsName) == .orderedAscending
                }
                return lhs.offset < rhs.offset
            }.map(\.element)

            let originalNames = slice.compactMap { codeBlockItemName($0) }
            let sortedNames = sorted.compactMap { codeBlockItemName($0) }
            guard originalNames != sortedNames else { continue }

            if let firstToken = items[region.start].firstToken(viewMode: .sourceAccurate) {
                diagnose(.sortDeclarations, on: firstToken)
            }

            for (i, sortedItem) in sorted.enumerated() {
                var newItem = sortedItem
                newItem.leadingTrivia = items[region.start + i].leadingTrivia
                newItems[region.start + i] = newItem
            }
        }

        return CodeBlockItemListSyntax(newItems)
    }

    // MARK: - Helpers

    private func hasMarker(_ marker: String, in trivia: Trivia) -> Bool {
        trivia.pieces.contains { piece in
            if case .lineComment(let text) = piece { return text.contains(marker) }
            if case .blockComment(let text) = piece { return text.contains(marker) }
            return false
        }
    }

    /// Extract the sortable name from a declaration.
    private func declarationName(_ decl: DeclSyntax) -> String? {
        if let enumCase = decl.as(EnumCaseDeclSyntax.self) {
            return enumCase.elements.first?.name.text
        }
        if let variable = decl.as(VariableDeclSyntax.self) {
            return variable.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier
                .text
        }
        if let function = decl.as(FunctionDeclSyntax.self) {
            return function.name.text
        }
        if let typeAlias = decl.as(TypeAliasDeclSyntax.self) {
            return typeAlias.name.text
        }
        if let structDecl = decl.as(StructDeclSyntax.self) {
            return structDecl.name.text
        }
        if let classDecl = decl.as(ClassDeclSyntax.self) {
            return classDecl.name.text
        }
        if let enumDecl = decl.as(EnumDeclSyntax.self) {
            return enumDecl.name.text
        }
        if let protocolDecl = decl.as(ProtocolDeclSyntax.self) {
            return protocolDecl.name.text
        }
        if let initDecl = decl.as(InitializerDeclSyntax.self) {
            return initDecl.initKeyword.text
        }
        return nil
    }

    /// Extract the sortable name from a code block item.
    private func codeBlockItemName(_ item: CodeBlockItemSyntax) -> String? {
        if let decl = item.item.as(DeclSyntax.self) {
            return declarationName(decl)
        }
        return nil
    }
}

extension Finding.Message {
    fileprivate static let sortDeclarations: Finding.Message =
        "sort declarations alphabetically"
}
