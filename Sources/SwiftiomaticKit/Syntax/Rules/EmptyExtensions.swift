import SwiftSyntax

/// Remove empty extensions that do not add protocol conformance.
///
/// An extension with no members and no inheritance clause serves no purpose and should be removed.
/// Extensions that add protocol conformance (e.g. `extension Foo: Equatable {}`) are kept even
/// when empty, because the conformance itself is meaningful.
///
/// Extensions containing only comments are preserved.
///
/// Lint: If an empty, non-conforming extension is found, a lint warning is raised.
///
/// Format: The entire extension declaration is removed.
final class EmptyExtensions: SyntaxFormatRule {

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        let visited = super.visit(node)

        var newItems = [CodeBlockItemSyntax]()
        var changed = false
        var removedFirst = false

        for (index, item) in visited.enumerated() {
            if let ext = item.item.as(ExtensionDeclSyntax.self),
                isRemovableEmptyExtension(ext)
            {
                diagnose(
                    .removeEmptyExtension(name: ext.extendedType.trimmedDescription),
                    on: ext.extensionKeyword
                )
                changed = true
                if index == 0 { removedFirst = true }
                continue
            }
            newItems.append(item)
        }

        guard changed else { return visited }

        // If items were removed from the beginning, strip leading newlines from the new first item
        // so the output doesn't start with a blank line.
        if removedFirst, var first = newItems.first {
            first.leadingTrivia = Trivia(
                pieces: first.leadingTrivia.drop {
                    switch $0 {
                    case .newlines, .carriageReturns, .carriageReturnLineFeeds, .spaces, .tabs:
                        true
                    default:
                        false
                    }
                }
            )
            newItems[0] = first
        }

        return CodeBlockItemListSyntax(newItems)
    }

    /// Returns `true` if the extension is empty, adds no protocol conformance, and contains
    /// no comments.
    private func isRemovableEmptyExtension(_ ext: ExtensionDeclSyntax) -> Bool {
        // Must have no members.
        guard ext.memberBlock.members.isEmpty else { return false }

        // Must not add protocol conformance.
        guard ext.inheritanceClause == nil else { return false }

        // Don't remove if there are comments inside the braces.
        if ext.memberBlock.leftBrace.trailingTrivia.hasAnyComments
            || ext.memberBlock.rightBrace.leadingTrivia.hasAnyComments
        {
            return false
        }

        return true
    }
}

extension Finding.Message {
    fileprivate static func removeEmptyExtension(name: String) -> Finding.Message {
        "remove empty extension on '\(name)'"
    }
}
