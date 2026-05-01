import SwiftSyntax

/// Remove empty extensions that do not add protocol conformance.
///
/// An extension with no members and no inheritance clause serves no purpose and should be removed.
/// Extensions that add protocol conformance (e.g. `extension Foo: Equatable {}` ) are kept even
/// when empty, because the conformance itself is meaningful.
///
/// Extensions containing only comments are preserved.
///
/// Lint: If an empty, non-conforming extension is found, a lint warning is raised.
///
/// Rewrite: The entire extension declaration is removed.
final class RemoveEmptyExtensions: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }

    static func transform(
        _ visited: CodeBlockItemListSyntax,
        original _: CodeBlockItemListSyntax,
        parent _: Syntax?,
        context: Context
    ) -> CodeBlockItemListSyntax {
        var newItems = [CodeBlockItemSyntax]()
        var changed = false
        var removedFirst = false

        for (index, item) in visited.enumerated() {
            if let ext = item.item.as(ExtensionDeclSyntax.self),
               isRemovableEmptyExtension(ext)
            {
                Self.diagnose(
                    .removeEmptyExtension(name: ext.extendedType.trimmedDescription),
                    on: ext.extensionKeyword,
                    context: context
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
                        default: false
                    }
                }
            )
            newItems[0] = first
        }

        return CodeBlockItemListSyntax(newItems)
    }

    /// Returns `true` if the extension is empty, adds no protocol conformance, and contains no
    /// comments.
    private static func isRemovableEmptyExtension(_ ext: ExtensionDeclSyntax) -> Bool {
        // Must have no members.
        guard ext.memberBlock.members.isEmpty else { return false }

        // Must not add protocol conformance.
        guard ext.inheritanceClause == nil else { return false }

        // Don't remove if there are comments inside the braces.
        return ext.memberBlock.leftBrace.trailingTrivia.hasAnyComments
            || ext.memberBlock.rightBrace.leadingTrivia.hasAnyComments
            ? false
            : true
    }
}

fileprivate extension Finding.Message {
    static func removeEmptyExtension(name: String) -> Finding.Message {
        "remove empty extension on '\(name)'"
    }
}
