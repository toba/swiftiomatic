import SwiftSyntax

// MARK: - Collection literal and closure inlining

extension LayoutSingleLineBodies {
    /// Puts a collection literal's elements onto one line, separated by a comma and a space
    ///
    /// Both literal kinds clear the same outer trivia and drop the same trailing comma. The fields
    /// inside an element differ, so the caller clears those.
    ///
    /// - Parameters:
    ///   - elements: the literal's elements
    ///   - trailingComma: the path to an element's trailing comma
    ///   - clearInterior: clears the trivia of an element's own children
    fileprivate static func inliningElements<E: SyntaxProtocol>(
        _ elements: [E],
        trailingComma: WritableKeyPath<E, TokenSyntax?>,
        clearInterior: (inout E) -> Void
    ) -> [E] {
        var result = elements
        let lastIdx = result.count - 1

        for i in result.indices {
            var element = MutableRef(&result[i])
            element.value.leadingTrivia = []
            clearInterior(&element.value)

            if i == lastIdx {
                element.value[keyPath: trailingComma] = nil
                element.value.trailingTrivia = []
            } else if let comma = element.value[keyPath: trailingComma] {
                element.value[keyPath: trailingComma] =
                    comma
                    .with(\.trailingTrivia, [.spaces(1)])
            }
        }
        return result
    }

    /// Whether a wrapped collection literal is multiline, comment-free, and short enough to inline
    ///
    /// The caller emits the finding and performs the element-specific trivia reset. Both literal
    /// kinds route through here, so one comment guard covers both.
    ///
    /// - Parameters:
    ///   - leftBracket: the opening bracket of the literal under rewrite, whose trivia the comment
    ///     guard reads
    ///   - originalLeftBracket: the same bracket as it sits in the parsed tree, which is what
    ///     carries the column
    fileprivate static func shouldInlineCollection<E: SyntaxProtocol>(
        elements: [E],
        leftBracket: TokenSyntax,
        originalLeftBracket: TokenSyntax,
        rightBracket: TokenSyntax,
        render: (E) -> String,
        context: Context
    ) -> Bool {
        guard !elements.isEmpty else { return false }
        let isMultiline = elements.contains { $0.leadingTrivia.containsNewlines }
            || rightBracket.leadingTrivia.containsNewlines
        guard isMultiline else { return false }

        // Comments anywhere inside the literal disqualify the rewrite — collapsing would lose them.
        // The opening bracket's own trailing trivia counts, because a comment there sits between
        // the bracket and the first element and the inline clears it outright.
        if leftBracket.trailingTrivia.hasAnyComments { return false }
        for element in elements
            where element.leadingTrivia.hasAnyComments
            || element.trailingTrivia.hasAnyComments
        { return false }
        if rightBracket.leadingTrivia.hasAnyComments { return false }

        let joined = elements.map(render).joined(separator: ", ")
        let openColumn = originalLeftBracket
            .startLocation(converter: context.sourceLocationConverter).column
        let inlinedLength = openColumn - 1 + 1 + joined.count + 1
        return inlinedLength <= Self.maxLength(context: context)
    }

    /// Collapses a wrapped array literal onto one line when its joined form fits the print width.
    /// The trailing comma is dropped (single-line collection literals have no trailing comma per
    /// `multiElementCollectionTrailingCommas`'s default handling).
    static func inlineArrayLiteral(
        _ node: ArrayExprSyntax,
        original: ArrayExprSyntax,
        context: Context
    ) -> ExprSyntax {
        let elements = Array(node.elements)
        guard Self.shouldInlineCollection(
            elements: elements,
            leftBracket: node.leftSquare,
            originalLeftBracket: original.leftSquare,
            rightBracket: node.rightSquare,
            render: { $0.expression.trimmedDescription },
            context: context
        ) else { return ExprSyntax(node) }

        Self.diagnose(.inlineCollectionLiteral, on: original.leftSquare, context: context)

        let newElements = Self.inliningElements(
            elements,
            trailingComma: \.trailingComma,
            clearInterior: { element in
                element.expression = element.expression.with(\.leadingTrivia, [])
                element.expression = element.expression.with(\.trailingTrivia, [])
            }
        )
        var result = node
        result.leftSquare = result.leftSquare.with(\.trailingTrivia, [])
        result.elements = ArrayElementListSyntax(newElements)
        result.rightSquare = result.rightSquare.with(\.leadingTrivia, [])
        return ExprSyntax(result)
    }

    static func inlineDictionaryLiteral(
        _ node: DictionaryExprSyntax,
        original: DictionaryExprSyntax,
        context: Context
    ) -> ExprSyntax {
        guard let elementList = node.content.as(DictionaryElementListSyntax.self) else {
            return ExprSyntax(node)
        }
        let elements = Array(elementList)
        guard Self.shouldInlineCollection(
            elements: elements,
            leftBracket: node.leftSquare,
            originalLeftBracket: original.leftSquare,
            rightBracket: node.rightSquare,
            render: { "\($0.key.trimmedDescription): \($0.value.trimmedDescription)" },
            context: context
        ) else { return ExprSyntax(node) }

        Self.diagnose(.inlineCollectionLiteral, on: original.leftSquare, context: context)

        let newElements = Self.inliningElements(
            elements,
            trailingComma: \.trailingComma,
            clearInterior: { element in
                element.key = element.key.with(\.leadingTrivia, [])
                element.key = element.key.with(\.trailingTrivia, [])
                element.colon = element.colon.with(\.leadingTrivia, [])
                element.colon = element.colon.with(\.trailingTrivia, [.spaces(1)])
                element.value = element.value.with(\.leadingTrivia, [])
                element.value = element.value.with(\.trailingTrivia, [])
            }
        )
        var result = node
        result.leftSquare = result.leftSquare.with(\.trailingTrivia, [])
        result.content = .elements(DictionaryElementListSyntax(newElements))
        result.rightSquare = result.rightSquare.with(\.leadingTrivia, [])
        return ExprSyntax(result)
    }

    static func inlineClosure(
        _ node: ClosureExprSyntax,
        original: ClosureExprSyntax,
        context: Context
    ) -> ExprSyntax {
        guard node.statements.count == 1,
              let firstStmt = node.statements.first else { return ExprSyntax(node) }

        let isMultiline = firstStmt.leadingTrivia.containsNewlines
            || node.rightBrace.leadingTrivia.containsNewlines
            || node.leftBrace.trailingTrivia.containsNewlines
            || (node.signature?.trailingTrivia.containsNewlines ?? false)
        guard isMultiline else { return ExprSyntax(node) }

        if Self.commentPrecedesBrace(node.leftBrace, source: original.leftBrace) {
            return ExprSyntax(node)
        }
        if node.leftBrace.trailingTrivia.hasAnyComments { return ExprSyntax(node) }

        if let sig = node.signature {
            if sig.leadingTrivia.hasAnyComments { return ExprSyntax(node) }
            if sig.trailingTrivia.hasAnyComments { return ExprSyntax(node) }
        }
        if firstStmt.leadingTrivia.hasAnyComments { return ExprSyntax(node) }
        if firstStmt.trailingTrivia.hasAnyComments { return ExprSyntax(node) }
        if node.rightBrace.leadingTrivia.hasAnyComments { return ExprSyntax(node) }

        let bodyText = firstStmt.trimmedDescription
        let signatureText = node.signature.map { $0.trimmedDescription + " " } ?? ""
        let braceEndCol = original.leftBrace
            .endLocation(converter: context.sourceLocationConverter).column
        let prefix = braceEndCol - 1
        let totalLength = prefix + 1 + signatureText.count + bodyText.count + 2
        guard totalLength <= Self.maxLength(context: context) else { return ExprSyntax(node) }

        Self.diagnose(.inlineClosureBody, on: original.leftBrace, context: context)

        var result = node
        result.leftBrace = result.leftBrace.with(\.trailingTrivia, .space)

        if let sig = result.signature {
            result.signature = sig
                .with(\.leadingTrivia, [])
                .with(\.trailingTrivia, .space)
        }
        var items = Array(result.statements)
        items[0].leadingTrivia = []
        items[0].trailingTrivia = []
        result.statements = CodeBlockItemListSyntax(items)
        result.rightBrace = result.rightBrace.with(\.leadingTrivia, .space)
        return ExprSyntax(result)
    }
}

// MARK: - Finding Messages

fileprivate extension Finding.Message {
    static let inlineClosureBody: Finding.Message = "place closure body on same line"

    static let inlineCollectionLiteral: Finding.Message =
        "place collection literal on same line as declaration"
}
