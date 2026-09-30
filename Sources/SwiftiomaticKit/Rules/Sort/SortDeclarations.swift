import Foundation
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
    private static let beginMarker: StaticString = "swiftiomatic:sort:begin"
    private static let endMarker: StaticString = "swiftiomatic:sort:end"

    /// Tells if `source` can hold a region for this rule to sort.
    ///
    /// A region starts at a comment with the begin marker, so a source without the marker bytes has
    /// nothing to sort, and the format pipeline skips the walk.
    static func sourceCanMatch(_ source: String) -> Bool { source.containsBytes(beginMarker) }

    // MARK: - Member blocks (type bodies)

    // In lint mode the pipeline visits every list itself, so neither visit recurses or builds a new
    // node.
    override func visit(_ node: MemberBlockItemListSyntax) -> MemberBlockItemListSyntax {
        let closingTrivia = triviaAfter(node)
        guard !context.isLintMode else {
            _ = sortMarkedRegions(items: Array(node), closingTrivia: closingTrivia) {
                declarationName($0.decl)
            }
            return node
        }
        let visited = super.visit(node)
        let items = Array(visited)
        let sorted = sortMarkedRegions(items: items, closingTrivia: closingTrivia) {
            declarationName($0.decl)
        }
        return sorted.map(MemberBlockItemListSyntax.init) ?? visited
    }

    // MARK: - Code blocks (top-level declarations)

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        let closingTrivia = triviaAfter(node)
        guard !context.isLintMode else {
            _ = sortMarkedRegions(items: Array(node), closingTrivia: closingTrivia) {
                codeBlockItemName($0)
            }
            return node
        }
        let visited = super.visit(node)
        let items = Array(visited)
        let sorted = sortMarkedRegions(items: items, closingTrivia: closingTrivia) {
            codeBlockItemName($0)
        }
        return sorted.map(CodeBlockItemListSyntax.init) ?? visited
    }

    /// Sorts items inside `swiftiomatic:sort:begin` / `end` regions in place
    ///
    /// The begin marker stays at the top of its region. Every other leading comment moves with its
    /// item. Returns `nil` if there are no regions to sort or all regions are already sorted.
    ///
    /// - Parameters:
    ///   - items: The list to sort within.
    ///   - closingTrivia: The leading trivia of the token after the list, such as the closing
    ///     brace. An end marker on the last line of a body lives there, not on any item.
    ///   - name: The sort key of an item, or `nil` when it has none.
    private func sortMarkedRegions<Element: SyntaxProtocol>(
        items: [Element],
        closingTrivia: Trivia?,
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
        // an end marker on the last line of the body closes the open region
        if let start = regionStart, let closingTrivia {
            if hasMarker(Self.endMarker, in: closingTrivia) {
                sortedRegions.append((start, items.count))
            }
        }
        guard !sortedRegions.isEmpty else { return nil }

        var newItems = items
        var didChange = false

        for region in sortedRegions.reversed() {
            let slice = items[region.start..<region.end]
            guard slice.count > 1 else { continue }

            let keyed = slice.enumerated().map { item in
                (key: name(item.element), offset: item.offset, element: item.element)
            }
            let sortedKeyed = keyed.sorted { lhs, rhs in
                let lhsName = lhs.key ?? ""
                let rhsName = rhs.key ?? ""
                return lhsName != rhsName
                    ? lhsName.localizedCompare(rhsName) == .orderedAscending
                    : lhs.offset < rhs.offset
            }
            guard keyed.compactMap(\.key) != sortedKeyed.compactMap(\.key) else { continue }
            let sorted = sortedKeyed.map(\.element)

            if let firstToken = items[region.start].firstToken(viewMode: .sourceAccurate) {
                diagnose(.sortDeclarations, on: firstToken)
            }
            guard !context.isLintMode else { continue }

            // the begin marker stays on the first position, the rest of the trivia moves
            let first = items[region.start]
            let (markerTrivia, firstOwnTrivia) = splitAfterBeginMarker(first.leadingTrivia)

            for (i, sortedItem) in sorted.enumerated() {
                var newItem = sortedItem
                let ownTrivia = sortedItem.id == first.id
                    ? firstOwnTrivia
                    : sortedItem.leadingTrivia
                newItem.leadingTrivia = i == 0 ? markerTrivia + ownTrivia : ownTrivia
                newItems[region.start + i] = newItem
            }
            didChange = true
        }
        return didChange ? newItems : nil
    }

    // MARK: - Helpers

    private func triviaAfter(_ node: some SyntaxProtocol) -> Trivia? {
        node.lastToken(viewMode: .sourceAccurate)?.nextToken(viewMode: .sourceAccurate)?
            .leadingTrivia
    }

    /// Splits `trivia` after the comment holding the begin marker.
    ///
    /// - Returns: The pieces through the marker comment, and the pieces after it. With no marker,
    ///   the first part is empty.
    private func splitAfterBeginMarker(_ trivia: Trivia) -> (marker: Trivia, rest: Trivia) {
        let pieces = Array(trivia.pieces)
        guard let index = pieces.lastIndex(where: { isMarkerComment($0, Self.beginMarker) }) else {
            return ([], trivia)
        }
        return (Trivia(pieces: pieces[...index]), Trivia(pieces: pieces[(index + 1)...]))
    }

    private func hasMarker(_ marker: StaticString, in trivia: Trivia) -> Bool {
        trivia.pieces.contains { isMarkerComment($0, marker) }
    }

    private func isMarkerComment(_ piece: TriviaPiece, _ marker: StaticString) -> Bool {
        switch piece {
            case let .lineComment(text), let .blockComment(text): text.containsBytes(marker)
            default: false
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
