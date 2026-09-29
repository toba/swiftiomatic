// ===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors Licensed under Apache License
// v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information See https://swift.org/CONTRIBUTORS.txt
// for the list of Swift project authors
//
// ===----------------------------------------------------------------------===//

import SwiftSyntax

/// Common protocol implemented by expression syntax types that support calling another expression.
protocol CallingExprSyntax: ExprSyntaxProtocol {
    var calledExpression: ExprSyntax { get }
}

extension FunctionCallExprSyntax: CallingExprSyntax {}
extension SubscriptCallExprSyntax: CallingExprSyntax {}

extension Syntax {
    func asProtocol(_: (any CallingExprSyntax).Type) -> any CallingExprSyntax? {
        asProtocol((any SyntaxProtocol).self) as? any CallingExprSyntax
    }
    func isProtocol(_: (any CallingExprSyntax).Type) -> Bool {
        asProtocol((any CallingExprSyntax).self) != nil
    }
}

extension ExprSyntax {
    func asProtocol(_: (any CallingExprSyntax).Type) -> any CallingExprSyntax? {
        Syntax(self).asProtocol((any SyntaxProtocol).self) as? any CallingExprSyntax
    }
    func isProtocol(_: (any CallingExprSyntax).Type) -> Bool {
        asProtocol((any CallingExprSyntax).self) != nil
    }
}

/// Common protocol implemented by expression syntax types that are expressed as a modified
/// subexpression of the form `<keyword> <subexpr>` .
protocol KeywordModifiedExprSyntax: ExprSyntaxProtocol {
    var expression: ExprSyntax { get }
}

extension AwaitExprSyntax: KeywordModifiedExprSyntax {}
extension TryExprSyntax: KeywordModifiedExprSyntax {}
extension UnsafeExprSyntax: KeywordModifiedExprSyntax {}

extension Syntax {
    func asProtocol(_: (any KeywordModifiedExprSyntax).Type) -> any KeywordModifiedExprSyntax? {
        asProtocol((any SyntaxProtocol).self) as? any KeywordModifiedExprSyntax
    }
    func isProtocol(_: (any KeywordModifiedExprSyntax).Type) -> Bool {
        asProtocol((any KeywordModifiedExprSyntax).self) != nil
    }
}

extension ExprSyntax {
    func asProtocol(_: (any KeywordModifiedExprSyntax).Type) -> any KeywordModifiedExprSyntax? {
        Syntax(self).asProtocol((any SyntaxProtocol).self) as? any KeywordModifiedExprSyntax
    }
    func isProtocol(_: (any KeywordModifiedExprSyntax).Type) -> Bool {
        asProtocol((any KeywordModifiedExprSyntax).self) != nil
    }
}

/// Common protocol implemented by comma-separated lists whose elements support a `trailingComma` .
protocol CommaSeparatedListSyntax: SyntaxCollection
    where Element: WithTrailingCommaSyntax & Equatable
{
    /// The node used for trailing comma handling; inserted immediately after this node.
    var lastNodeForTrailingComma: any SyntaxProtocol? { get }
}

extension ArrayElementListSyntax: CommaSeparatedListSyntax {
    var lastNodeForTrailingComma: any SyntaxProtocol? { last?.expression }
}
extension DictionaryElementListSyntax: CommaSeparatedListSyntax {
    var lastNodeForTrailingComma: any SyntaxProtocol? { last }
}
extension LabeledExprListSyntax: CommaSeparatedListSyntax {
    var lastNodeForTrailingComma: any SyntaxProtocol? { last?.expression }
}
extension ClosureCaptureListSyntax: CommaSeparatedListSyntax {
    var lastNodeForTrailingComma: any SyntaxProtocol? {
        if let initializer = last?.initializer { initializer } else { last?.name }
    }
}
extension EnumCaseParameterListSyntax: CommaSeparatedListSyntax {
    var lastNodeForTrailingComma: any SyntaxProtocol? {
        if let defaultValue = last?.defaultValue { defaultValue } else { last?.type }
    }
}
extension FunctionParameterListSyntax: CommaSeparatedListSyntax {
    var lastNodeForTrailingComma: any SyntaxProtocol? {
        if let defaultValue = last?.defaultValue {
            defaultValue
        } else if let ellipsis = last?.ellipsis {
            ellipsis
        } else {
            last?.type
        }
    }
}
extension GenericParameterListSyntax: CommaSeparatedListSyntax {
    var lastNodeForTrailingComma: any SyntaxProtocol? {
        if let inheritedType = last?.inheritedType { inheritedType } else { last?.name }
    }
}
extension TuplePatternElementListSyntax: CommaSeparatedListSyntax {
    var lastNodeForTrailingComma: any SyntaxProtocol? { last?.pattern }
}
extension TupleTypeElementListSyntax: CommaSeparatedListSyntax {
    var lastNodeForTrailingComma: any SyntaxProtocol? { last?.type }
}

extension SyntaxProtocol {
    func asProtocol(_: (any CommaSeparatedListSyntax).Protocol) -> any CommaSeparatedListSyntax? {
        Syntax(self).asProtocol((any SyntaxProtocol).self) as? any CommaSeparatedListSyntax
    }
    func isProtocol(_: (any CommaSeparatedListSyntax).Protocol) -> Bool {
        asProtocol((any CommaSeparatedListSyntax).self) != nil
    }
}
