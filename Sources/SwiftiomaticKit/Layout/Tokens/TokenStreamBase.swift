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

import Foundation
import SwiftOperators
import SwiftSyntax

/// Visits the nodes of a syntax tree and constructs a linear stream of formatting tokens that
/// tell the pretty printer how the source text should be laid out.
///
/// The final `TokenStream` subclass with generated override stubs lives in
/// `TokenStream+Generated.swift`. Extension methods (the actual visit implementations)
/// are in the `TokenStream+*.swift` files.
class TokenStreamBase: SyntaxVisitor {
    var tokens = [Token]()
    var beforeMap = [TokenSyntax: [Token]]()
    var afterMap = [TokenSyntax: [[Token]]]()
    let config: Configuration
    let operatorTable: OperatorTable
    let maxLineLength: Int
    let selection: Selection

    /// The index of the most recently appended break, or nil when no break has been appended.
    var lastBreakIndex: Int? = nil

    /// Whether newlines can be merged into the most recent break, based on which tokens have been
    /// appended since that break.
    var canMergeNewlinesIntoLastBreak = false

    /// Keeps track of the kind of break that should be used inside a multiline string. This differs
    /// depending on surrounding context due to some tricky special cases, so this lets us pass that
    /// information down to the strings that need it.
    var pendingMultilineStringBreakKinds = [StringLiteralExprSyntax: BreakKind]()

    /// Lists tokens that shouldn't be appended to the token stream as `syntax` tokens. They will be
    /// printed conditionally using a different type of token.
    var ignoredTokens = Set<TokenSyntax>()

    /// Lists the expressions that have been visited, from the outermost expression, where contextual
    /// breaks and start/end contextual breaking tokens have been inserted.
    var preVisitedExprs = Set<SyntaxIdentifier>()

    /// Tracks the "root" expressions where pre-visiting for contextual breaks started so that
    /// `preVisitedExprs` can be emptied after exiting an expression tree.
    var rootExprs = Set<SyntaxIdentifier>()

    /// Lists the tokens that are the closing or final delimiter of a node that shouldn't be split
    /// from the preceding token. When breaks are inserted around compound expressions, the breaks are
    /// moved past these tokens.
    var closingDelimiterTokens = Set<TokenSyntax>()

    /// Tracks closures that are never allowed to be laid out entirely on one line (e.g., closures
    /// in a function call containing multiple trailing closures).
    var forcedBreakingClosures = Set<SyntaxIdentifier>()

    /// Tracks whether we last considered ourselves inside the selection
    var isInsideSelection = true

    init(configuration: Configuration, selection: Selection, operatorTable: OperatorTable) {
        self.config = configuration
        self.selection = selection
        self.operatorTable = operatorTable
        self.maxLineLength = config[LineLength.self]
        super.init(viewMode: .all)
    }

    var openings = 0

    /// If the syntax token is non-nil, enqueue the given list of formatting tokens before it in the
    /// token stream.
    func before(_ token: TokenSyntax?, tokens: Token...) {
        before(token, tokens: tokens)
    }

    /// If the syntax token is non-nil, enqueue the given list of formatting tokens before it in the
    /// token stream.
    func before(_ token: TokenSyntax?, tokens: [Token]) {
        guard let tok = token else { return }
        beforeMap[tok, default: []] += tokens
    }

    /// If the syntax token is non-nil, enqueue the given list of formatting tokens after it in the
    /// token stream.
    func after(_ token: TokenSyntax?, tokens: Token...) {
        after(token, tokens: tokens)
    }

    /// If the syntax token is non-nil, enqueue the given list of formatting tokens after it in the
    /// token stream.
    func after(_ token: TokenSyntax?, tokens: [Token]) {
        guard let tok = token else { return }
        afterMap[tok, default: []].append(tokens)
    }

    /// Enqueues the given list of formatting tokens between each element of the given syntax
    /// collection (but not before the first one nor after the last one).
    func insertTokens<Node: SyntaxCollection>(
        _ tokens: Token...,
        betweenElementsOf collectionNode: Node
    ) where Node.Element == Syntax {
        for element in collectionNode.dropLast() {
            after(element.lastToken(viewMode: .sourceAccurate), tokens: tokens)
        }
    }

    /// Enqueues the given list of formatting tokens between each element of the given syntax
    /// collection (but not before the first one nor after the last one).
    func insertTokens<Node: SyntaxCollection>(
        _ tokens: Token...,
        betweenElementsOf collectionNode: Node
    ) where Node.Element: SyntaxProtocol {
        for element in collectionNode.dropLast() {
            after(element.lastToken(viewMode: .sourceAccurate), tokens: tokens)
        }
    }

    /// Enqueues the given list of formatting tokens between each element of the given syntax
    /// collection (but not before the first one nor after the last one).
    func insertTokens<Node: SyntaxCollection>(
        _ tokens: Token...,
        betweenElementsOf collectionNode: Node
    ) where Node.Element == DeclSyntax {
        for element in collectionNode.dropLast() {
            after(element.lastToken(viewMode: .sourceAccurate), tokens: tokens)
        }
    }
}

// MARK: - Methods that call extension-defined helpers (appendToken, etc.)

extension TokenStream {
    func makeStream(from node: Syntax) -> [Token] {
        // if we have a selection, then we start outside of it
        if case .ranges = selection {
            appendToken(.disableFormatting(AbsolutePosition(utf8Offset: 0)))
            isInsideSelection = false
        }

        // Because `walk` takes an `inout` argument, and we're a class, we have to do the following
        // dance to pass ourselves in.
        self.walk(node)

        // Make sure we output any trailing text after the last selection range
        if case .ranges = selection {
            appendToken(.enableFormatting(nil))
        }
        defer { tokens = [] }
        return tokens
    }

    func verbatimToken(_ node: Syntax, indentingBehavior: IndentingBehavior = .allLines) {
        if let firstToken = node.firstToken(viewMode: .sourceAccurate) {
            appendBeforeTokens(firstToken)
        }

        appendToken(
            .verbatim(Verbatim(text: node.description, indentingBehavior: indentingBehavior))
        )

        if let lastToken = node.lastToken(viewMode: .sourceAccurate) {
            // Extract any comments that trail the verbatim block since they belong to the next syntax
            // token. Leading comments don't need special handling since they belong to the current node,
            // and will get printed.
            appendAfterTokensAndTrailingComments(lastToken)
        }
    }
}

// MARK: - Support

extension AccessorBlockSyntax {
    /// Assuming that the accessor only contains an implicit getter (i.e. no
    /// `get` or `set`), return the code block items in that getter.
    var getterCodeBlockItems: CodeBlockItemListSyntax {
        guard case .getter(let codeBlockItemList) = self.accessors else {
            preconditionFailure("AccessorBlock has an accessor list and not just a getter")
        }
        return codeBlockItemList
    }
}
