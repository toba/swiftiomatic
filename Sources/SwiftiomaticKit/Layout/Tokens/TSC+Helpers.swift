//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

extension TokenStreamCreator {
    /// Applies formatting tokens around and between the attributes in an attribute list.
    func arrangeAttributeList(
        _ attributes: AttributeListSyntax?,
        suppressFinalBreak: Bool = false,
        separateByLineBreaks: Bool = false,
        shouldGroup: Bool = true
    ) {
        let behavior: NewlineBehavior = separateByLineBreaks ? .hard : .elective
        arrangeAttributeList(
            attributes,
            suppressFinalBreak: suppressFinalBreak,
            lineBreak: .break(.same, newlines: behavior),
            shouldGroup: shouldGroup
        )
    }

    /// Applies formatting tokens around and between the attributes in an attribute list.
    func arrangeAttributeList(
        _ attributes: AttributeListSyntax?,
        suppressFinalBreak: Bool,
        lineBreak: Token,
        shouldGroup: Bool
    ) {
        guard let attributes, !attributes.isEmpty else {
            return
        }

        if shouldGroup {
            before(attributes.firstToken(viewMode: .sourceAccurate), tokens: .open)
        }

        if attributes.dropLast().isEmpty,
            let ifConfig = attributes.first?.as(IfConfigDeclSyntax.self)
        {
            for clause in ifConfig.clauses {
                if let nestedAttributes = AttributeListSyntax(clause.elements) {
                    arrangeAttributeList(
                        nestedAttributes,
                        suppressFinalBreak: true,
                        lineBreak: lineBreak,
                        shouldGroup: shouldGroup
                    )
                }
            }
        } else {
            for element in attributes.dropLast() {
                if let ifConfig = element.as(IfConfigDeclSyntax.self) {
                    for clause in ifConfig.clauses {
                        if let nestedAttributes = AttributeListSyntax(clause.elements) {
                            arrangeAttributeList(
                                nestedAttributes,
                                suppressFinalBreak: true,
                                lineBreak: lineBreak,
                                shouldGroup: shouldGroup
                            )
                        }
                    }
                } else {
                    after(element.lastToken(viewMode: .sourceAccurate), tokens: lineBreak)
                }
            }
        }

        var afterAttributeTokens = [Token]()
        if shouldGroup {
            afterAttributeTokens.append(.close)
        }
        if !suppressFinalBreak {
            afterAttributeTokens.append(lineBreak)
        }
        if !afterAttributeTokens.isEmpty {
            after(attributes.lastToken(viewMode: .sourceAccurate), tokens: afterAttributeTokens)
        }
    }

    /// Returns a value indicating whether or not the given braced syntax node is completely empty;
    /// that is, it contains neither child syntax nodes (aside from the braces) *nor* any comments.
    ///
    /// Checking for comments separately is vitally important, because a code block that appears to be
    /// "empty" because it doesn't contain any statements might still contain comments, and if those
    /// are line comments, we need to make sure to insert the same breaks that we would if there were
    /// other statements there to get the same layout.
    ///
    /// Note the slightly different generic constraints on this and the other overloads. All are
    /// required because protocols in Swift do not conform to themselves, so if the element type of
    /// the collection is *precisely* `Syntax`, the constraint `BodyContents.Element: Syntax` is not
    /// satisfied and we must constrain it by `BodyContents.Element == Syntax` instead.
    ///
    /// - Parameters:
    ///   - node: A node that conforms to `BracedSyntax`.
    ///   - contentsKeyPath: A keypath describing how to get from `node` to the contents of the node
    ///     (a `Collection` whose elements are of a type that conforms to `Syntax`).
    /// - Returns: True if the collection at the node's keypath is empty and there are no comments.
    func areBracesCompletelyEmpty<Node: BracedSyntax, BodyContents: SyntaxCollection>(
        _ node: Node,
        contentsKeyPath: KeyPath<Node, BodyContents>
    ) -> Bool where BodyContents.Element: SyntaxProtocol {
        // If the collection is empty, then any comments that might be present in the block must be
        // leading trivia of the right brace.
        let commentPrecedesRightBrace = node.rightBrace.hasAnyPrecedingComment
        // We can't use `count` here because it also includes missing children. Instead, we get an
        // iterator and check if it returns `nil` immediately.
        var contentsIterator = node[keyPath: contentsKeyPath].makeIterator()
        return contentsIterator.next() == nil && !commentPrecedesRightBrace
    }

    /// Returns a value indicating whether or not the given braced syntax node is completely empty;
    /// that is, it contains neither child syntax nodes (aside from the braces) *nor* any comments.
    ///
    /// - Parameters:
    ///   - node: A node that conforms to `BracedSyntax`.
    ///   - contentsKeyPath: A keypath describing how to get from `node` to the contents of the node
    ///     (a `Collection` whose elements are of type `Syntax`).
    /// - Returns: True if the collection at the node's keypath is empty and there are no comments.
    func areBracesCompletelyEmpty<Node: BracedSyntax, BodyContents: SyntaxCollection>(
        _ node: Node,
        contentsKeyPath: KeyPath<Node, BodyContents>
    ) -> Bool where BodyContents.Element == Syntax {
        // If the collection is empty, then any comments that might be present in the block must be
        // leading trivia of the right brace.
        let commentPrecedesRightBrace = node.rightBrace.hasAnyPrecedingComment
        // We can't use `count` here because it also includes missing children. Instead, we get an
        // iterator and check if it returns `nil` immediately.
        var contentsIterator = node[keyPath: contentsKeyPath].makeIterator()
        return contentsIterator.next() == nil && !commentPrecedesRightBrace
    }

    /// Returns a value indicating whether or not the given braced syntax node is completely empty;
    /// that is, it contains neither child syntax nodes (aside from the braces) *nor* any comments.
    ///
    /// - Parameters:
    ///   - node: A node that conforms to `BracedSyntax`.
    ///   - contentsKeyPath: A keypath describing how to get from `node` to the contents of the node
    ///     (a `Collection` whose elements are of type `DeclSyntax`).
    /// - Returns: True if the collection at the node's keypath is empty and there are no comments.
    func areBracesCompletelyEmpty<Node: BracedSyntax, BodyContents: SyntaxCollection>(
        _ node: Node,
        contentsKeyPath: KeyPath<Node, BodyContents>
    ) -> Bool where BodyContents.Element == DeclSyntax {
        // If the collection is empty, then any comments that might be present in the block must be
        // leading trivia of the right brace.
        let commentPrecedesRightBrace = node.rightBrace.hasAnyPrecedingComment
        // We can't use `count` here because it also includes missing children. Instead, we get an
        // iterator and check if it returns `nil` immediately.
        var contentsIterator = node[keyPath: contentsKeyPath].makeIterator()
        return contentsIterator.next() == nil && !commentPrecedesRightBrace
    }

    /// Applies formatting to a collection of parameters for a decl.
    ///
    /// - Parameters:
    ///    - parameters: A node that contains the parameters that can be passed to a decl when its
    ///      called.
    ///    - forcesBreakBeforeRightParen: Whether a break should be required before the right paren
    ///      when the right paren is on a different line than the corresponding left paren.
    func arrangeClosureParameterClause(
        _ parameters: ClosureParameterClauseSyntax,
        forcesBreakBeforeRightParen: Bool
    ) {
        guard !parameters.parameters.isEmpty else { return }

        after(
            parameters.leftParen,
            tokens: .break(.open, size: 0),
            .open(argumentListConsistency())
        )
        before(
            parameters.rightParen,
            tokens: .break(.close(mustBreak: forcesBreakBeforeRightParen), size: 0),
            .close
        )
    }

    /// Applies formatting to a collection of enum case parameters for a decl.
    ///
    /// - Parameters:
    ///    - parameters: A node that contains the parameters that can be passed to a decl when its
    ///      called.
    ///    - forcesBreakBeforeRightParen: Whether a break should be required before the right paren
    ///      when the right paren is on a different line than the corresponding left paren.
    func arrangeEnumCaseParameterClause(
        _ parameters: EnumCaseParameterClauseSyntax,
        forcesBreakBeforeRightParen: Bool
    ) {
        guard !parameters.parameters.isEmpty else { return }

        after(
            parameters.leftParen,
            tokens: .break(.open, size: 0),
            .open(argumentListConsistency())
        )
        before(
            parameters.rightParen,
            tokens: .break(.close(mustBreak: forcesBreakBeforeRightParen), size: 0),
            .close
        )
    }

    /// Applies formatting to a collection of parameters for a decl.
    ///
    /// - Parameters:
    ///    - parameters: A node that contains the parameters that can be passed to a decl when its
    ///      called.
    ///    - forcesBreakBeforeRightParen: Whether a break should be required before the right paren
    ///      when the right paren is on a different line than the corresponding left paren.
    func arrangeParameterClause(
        _ parameters: FunctionParameterClauseSyntax,
        forcesBreakBeforeRightParen: Bool
    ) {
        guard !parameters.parameters.isEmpty else { return }

        after(
            parameters.leftParen,
            tokens: .break(.open, size: 0),
            .open(argumentListConsistency())
        )
        before(
            parameters.rightParen,
            tokens: .break(.close(mustBreak: forcesBreakBeforeRightParen), size: 0),
            .close
        )
    }

    /// Applies consistent formatting to the braces and contents of the given node.
    ///
    /// - Parameters:
    ///   - node: A node that conforms to `BracedSyntax`.
    ///   - contentsKeyPath: A keypath describing how to get from `node` to the contents of the node
    ///     (a `Collection` whose elements are of a type that conforms to `Syntax`).
    ///   - shouldResetBeforeLeftBrace: If true, a `reset` break will be inserted before the node's
    ///     left brace (the default behavior). Passing false will suppress this break, which is useful
    ///     if you have already placed a `reset` elsewhere (for example, in a `guard` statement, the
    ///     `reset` is inserted before the `else` keyword to force both it and the brace down to the
    ///     next line).
    ///   - openBraceNewlineBehavior: The newline behavior to apply to the break following the open
    ///     brace; defaults to `.elective`.
    func arrangeBracesAndContents<Node: BracedSyntax, BodyContents: SyntaxCollection>(
        of node: Node?,
        contentsKeyPath: KeyPath<Node, BodyContents>?,
        shouldResetBeforeLeftBrace: Bool = true,
        openBraceNewlineBehavior: NewlineBehavior = .elective
    ) where BodyContents.Element: SyntaxProtocol {
        guard let node = node, let contentsKeyPath = contentsKeyPath else { return }

        if shouldResetBeforeLeftBrace {
            before(
                node.leftBrace,
                tokens: .break(.reset, size: 1, newlines: .elective(ignoresDiscretionary: true))
            )
        }
        if !areBracesCompletelyEmpty(node, contentsKeyPath: contentsKeyPath) {
            after(
                node.leftBrace,
                tokens: .break(.open, size: 1, newlines: openBraceNewlineBehavior),
                .open
            )
            before(node.rightBrace, tokens: .break(.close, size: 1), .close)
        } else {
            after(
                node.leftBrace,
                tokens: .break(.open, size: 0, newlines: openBraceNewlineBehavior)
            )
            before(node.rightBrace, tokens: .break(.close, size: 0))
        }
    }

    /// Applies consistent formatting to the braces and contents of the given node.
    ///
    /// - Parameters:
    ///   - node: A node that conforms to `BracedSyntax`.
    ///   - contentsKeyPath: A keypath describing how to get from `node` to the contents of the node
    ///     (a `Collection` whose elements are of type `Syntax`).
    ///   - shouldResetBeforeLeftBrace: If true, a `reset` break will be inserted before the node's
    ///     left brace (the default behavior). Passing false will suppress this break, which is useful
    ///     if you have already placed a `reset` elsewhere (for example, in a `guard` statement, the
    ///     `reset` is inserted before the `else` keyword to force both it and the brace down to the
    ///     next line).
    func arrangeBracesAndContents<Node: BracedSyntax, BodyContents: SyntaxCollection>(
        of node: Node?,
        contentsKeyPath: KeyPath<Node, BodyContents>?,
        shouldResetBeforeLeftBrace: Bool = true
    ) where BodyContents.Element == Syntax {
        guard let node = node, let contentsKeyPath = contentsKeyPath else { return }

        if shouldResetBeforeLeftBrace {
            before(node.leftBrace, tokens: .break(.reset, size: 1))
        }
        if !areBracesCompletelyEmpty(node, contentsKeyPath: contentsKeyPath) {
            after(node.leftBrace, tokens: .break(.open, size: 1), .open)
            before(node.rightBrace, tokens: .break(.close, size: 1), .close)
        } else {
            after(node.leftBrace, tokens: .break(.open, size: 0))
            before(node.rightBrace, tokens: .break(.close, size: 0))
        }
    }

    /// Applies consistent formatting to the braces and contents of the given node.
    ///
    /// - Parameters:
    ///   - node: A node that conforms to `BracedSyntax`.
    ///   - contentsKeyPath: A keypath describing how to get from `node` to the contents of the node
    ///     (a `Collection` whose elements are of type `DeclSyntax`).
    ///   - shouldResetBeforeLeftBrace: If true, a `reset` break will be inserted before the node's
    ///     left brace (the default behavior). Passing false will suppress this break, which is useful
    ///     if you have already placed a `reset` elsewhere (for example, in a `guard` statement, the
    ///     `reset` is inserted before the `else` keyword to force both it and the brace down to the
    ///     next line).
    func arrangeBracesAndContents<Node: BracedSyntax, BodyContents: SyntaxCollection>(
        of node: Node?,
        contentsKeyPath: KeyPath<Node, BodyContents>?,
        shouldResetBeforeLeftBrace: Bool = true
    ) where BodyContents.Element == DeclSyntax {
        guard let node = node, let contentsKeyPath = contentsKeyPath else { return }

        if shouldResetBeforeLeftBrace {
            before(node.leftBrace, tokens: .break(.reset, size: 1))
        }
        if !areBracesCompletelyEmpty(node, contentsKeyPath: contentsKeyPath) {
            after(node.leftBrace, tokens: .break(.open, size: 1), .open)
            before(node.rightBrace, tokens: .break(.close, size: 1), .close)
        } else {
            after(node.leftBrace, tokens: .break(.open, size: 0))
            before(node.rightBrace, tokens: .break(.close, size: 0))
        }
    }

    /// Applies consistent formatting to the braces and contents of the given node.
    ///
    /// - Parameter node: An `AccessorBlockSyntax` node.
    func arrangeBracesAndContents(
        leftBrace: TokenSyntax,
        accessors: AccessorDeclListSyntax,
        rightBrace: TokenSyntax
    ) {
        // If the collection is empty, then any comments that might be present in the block must be
        // leading trivia of the right brace.
        let commentPrecedesRightBrace = rightBrace.hasAnyPrecedingComment
        // We can't use `count` here because it also includes missing children. Instead, we get an
        // iterator and check if it returns `nil` immediately.
        var accessorsIterator = accessors.makeIterator()
        let areAccessorsEmpty = accessorsIterator.next() == nil
        let bracesAreCompletelyEmpty = areAccessorsEmpty && !commentPrecedesRightBrace

        before(leftBrace, tokens: .break(.reset, size: 1))

        if !bracesAreCompletelyEmpty {
            after(leftBrace, tokens: .break(.open, size: 1), .open)
            before(rightBrace, tokens: .break(.close, size: 1), .close)
        } else {
            after(leftBrace, tokens: .break(.open, size: 0))
            before(rightBrace, tokens: .break(.close, size: 0))
        }
    }

    /// Returns the group consistency that should be used for argument lists based on the user's
    /// current configuration.
    func argumentListConsistency() -> GroupBreakStyle {
        return config[BeforeEachArgument.self] ? .consistent : .inconsistent
    }

    /// Returns the group consistency that should be used for generic requirement lists based on
    /// the user's current configuration.
    func genericRequirementListConsistency() -> GroupBreakStyle {
        return config[BeforeEachGenericRequirement.self] ? .consistent : .inconsistent
    }

    func afterTokensForTrailingComment(
        _ token: TokenSyntax
    ) -> (isLineComment: Bool, tokens: [Token]) {
        let (_, trailingComments) = partitionTrailingTrivia(token.trailingTrivia)
        let trivia =
            Trivia(pieces: trailingComments)
            + (token.nextToken(viewMode: .sourceAccurate)?.leadingTrivia ?? [])

        guard let firstPiece = trivia.first else {
            return (false, [])
        }

        switch firstPiece {
        case .lineComment(let text):
            return (
                true,
                [
                    .space(size: config[SpacesBeforeEndOfLineComments.self], flexible: true),
                    .comment(
                        Comment(kind: .line, leadingIndent: nil, text: text),
                        wasEndOfLine: true
                    ),
                    // There must be a break with a soft newline after the comment, but it's impossible to
                    // know which kind of break must be used. Adding this newline is deferred until the
                    // comment is added to the token stream.
                ]
            )

        case .blockComment(let text):
            return (
                false,
                [
                    .space(size: 1, flexible: true),
                    .comment(
                        Comment(kind: .block, leadingIndent: nil, text: text),
                        wasEndOfLine: false
                    ),
                    // We place a size-0 break after the comment to allow a discretionary newline after
                    // the comment if the user places one here but the comment is otherwise adjacent to a
                    // text token.
                    .break(.same, size: 0),
                ]
            )

        default:
            return (false, [])
        }
    }

    /// Splits the before tokens for the given token into an opening-scope collection and a
    /// closing-scope collection. The opening-scope collection contains `.open` and `.break` tokens
    /// that start a "scope" before the token. The closing-scope collection contains `.close` and
    /// `.break` tokens that end a "scope" after the token.
    func splitScopingBeforeTokens(
        of token: TokenSyntax
    ) -> (openingScope: [Token], closingScope: [Token]) {
        guard let beforeTokens = beforeMap[token] else {
            return ([], [])
        }

        // Find the first index of a non-opening-scope token, and split into the two sections.
        for (index, beforeToken) in beforeTokens.enumerated() {
            switch beforeToken {
            case .break(.open, _, _), .break(.continue, _, _), .break(.same, _, _),
                .break(.contextual, _, _), .open:
                break
            default:
                if index > 0 {
                    return (Array(beforeTokens[0...(index - 1)]), Array(beforeTokens[index...]))
                } else {
                    return ([], beforeTokens)
                }
            }
        }
        // Never found a closing-scope token, so assume they're all opening-scope.
        return (beforeTokens, [])
    }

    /// Partitions the given trailing trivia into two contiguous slices: the first containing only
    /// whitespace and unexpected text, and the second containing everything else from the first
    /// non-whitespace/non-unexpected-text.
    ///
    /// It is possible that one or both of the slices will be empty.
    func partitionTrailingTrivia(_ trailingTrivia: Trivia) -> (Slice<Trivia>, Slice<Trivia>)
    {
        let pivot =
            trailingTrivia.firstIndex { !$0.isSpaceOrTab && !$0.isUnexpectedText }
            ?? trailingTrivia.endIndex
        return (trailingTrivia[..<pivot], trailingTrivia[pivot...])
    }
}
