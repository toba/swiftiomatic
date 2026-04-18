//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Common protocol implemented by expression syntax types that support calling another expression.
protocol CallingExprSyntax: ExprSyntaxProtocol {
    var calledExpression: ExprSyntax { get }
}

extension FunctionCallExprSyntax: CallingExprSyntax {}
extension SubscriptCallExprSyntax: CallingExprSyntax {}

extension Syntax {
    func asProtocol(_: CallingExprSyntax.Protocol) -> CallingExprSyntax? {
        return self.asProtocol(SyntaxProtocol.self) as? CallingExprSyntax
    }
    func isProtocol(_: CallingExprSyntax.Protocol) -> Bool {
        return self.asProtocol(CallingExprSyntax.self) != nil
    }
}

extension ExprSyntax {
    func asProtocol(_: CallingExprSyntax.Protocol) -> CallingExprSyntax? {
        return Syntax(self).asProtocol(SyntaxProtocol.self) as? CallingExprSyntax
    }
    func isProtocol(_: CallingExprSyntax.Protocol) -> Bool {
        return self.asProtocol(CallingExprSyntax.self) != nil
    }
}

/// Common protocol implemented by expression syntax types that are expressed as a modified
/// subexpression of the form `<keyword> <subexpr>`.
protocol KeywordModifiedExprSyntax: ExprSyntaxProtocol {
    var expression: ExprSyntax { get }
}

extension AwaitExprSyntax: KeywordModifiedExprSyntax {}
extension TryExprSyntax: KeywordModifiedExprSyntax {}
extension UnsafeExprSyntax: KeywordModifiedExprSyntax {}

extension Syntax {
    func asProtocol(_: KeywordModifiedExprSyntax.Protocol) -> KeywordModifiedExprSyntax? {
        return self.asProtocol(SyntaxProtocol.self) as? KeywordModifiedExprSyntax
    }
    func isProtocol(_: KeywordModifiedExprSyntax.Protocol) -> Bool {
        return self.asProtocol(KeywordModifiedExprSyntax.self) != nil
    }
}

extension ExprSyntax {
    func asProtocol(_: KeywordModifiedExprSyntax.Protocol) -> KeywordModifiedExprSyntax? {
        return Syntax(self).asProtocol(SyntaxProtocol.self) as? KeywordModifiedExprSyntax
    }
    func isProtocol(_: KeywordModifiedExprSyntax.Protocol) -> Bool {
        return self.asProtocol(KeywordModifiedExprSyntax.self) != nil
    }
}

/// Common protocol implemented by comma-separated lists whose elements
/// support a `trailingComma`.
protocol CommaSeparatedListSyntax: SyntaxCollection
where Element: WithTrailingCommaSyntax & Equatable {
    /// The node used for trailing comma handling; inserted immediately after this node.
    var lastNodeForTrailingComma: SyntaxProtocol? { get }
}

extension ArrayElementListSyntax: CommaSeparatedListSyntax {
    var lastNodeForTrailingComma: SyntaxProtocol? { last?.expression }
}
extension DictionaryElementListSyntax: CommaSeparatedListSyntax {
    var lastNodeForTrailingComma: SyntaxProtocol? { last }
}
extension LabeledExprListSyntax: CommaSeparatedListSyntax {
    var lastNodeForTrailingComma: SyntaxProtocol? { last?.expression }
}
extension ClosureCaptureListSyntax: CommaSeparatedListSyntax {
    var lastNodeForTrailingComma: SyntaxProtocol? {
        if let initializer = last?.initializer {
            return initializer
        } else {
            return last?.name
        }
    }
}
extension EnumCaseParameterListSyntax: CommaSeparatedListSyntax {
    var lastNodeForTrailingComma: SyntaxProtocol? {
        if let defaultValue = last?.defaultValue {
            return defaultValue
        } else {
            return last?.type
        }
    }
}
extension FunctionParameterListSyntax: CommaSeparatedListSyntax {
    var lastNodeForTrailingComma: SyntaxProtocol? {
        if let defaultValue = last?.defaultValue {
            return defaultValue
        } else if let ellipsis = last?.ellipsis {
            return ellipsis
        } else {
            return last?.type
        }
    }
}
extension GenericParameterListSyntax: CommaSeparatedListSyntax {
    var lastNodeForTrailingComma: SyntaxProtocol? {
        if let inheritedType = last?.inheritedType {
            return inheritedType
        } else {
            return last?.name
        }
    }
}
extension TuplePatternElementListSyntax: CommaSeparatedListSyntax {
    var lastNodeForTrailingComma: SyntaxProtocol? { last?.pattern }
}

extension SyntaxProtocol {
    func asProtocol(_: (any CommaSeparatedListSyntax).Protocol) -> (any CommaSeparatedListSyntax)? {
        return Syntax(self).asProtocol(SyntaxProtocol.self) as? (any CommaSeparatedListSyntax)
    }
    func isProtocol(_: (any CommaSeparatedListSyntax).Protocol) -> Bool {
        return self.asProtocol((any CommaSeparatedListSyntax).self) != nil
    }
}
