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

/// Functions that return `()` or `Void` should omit the return signature.
///
/// Lint: Function declarations that explicitly return `()` or `Void` will yield a lint error.
///
/// Rewrite: Function declarations with explicit returns of `()` or `Void` will have their return
/// signature stripped.
final class DropVoidReturnFromSignature: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .types }

    /// Strip an explicit `-> Void` / `-> ()` return clause from a function signature. Called from
    /// `CompactSyntaxRewriter.visit(_: FunctionSignatureSyntax)` .
    static func apply(
        _ node: FunctionSignatureSyntax,
        context: Context
    ) -> FunctionSignatureSyntax {
        guard let returnType = node.returnClause?.type else { return node }

        if let identifierType = returnType.as(IdentifierTypeSyntax.self),
           identifierType.name.text == "Void",
           identifierType.genericArgumentClause?.arguments.isEmpty ?? true
        {
            Self.diagnose(
                .removeRedundantReturn("Void"),
                on: identifierType,
                context: context
            )
            var result = node
            result.returnClause = nil
            return result
        }
        if let tupleType = returnType.as(TupleTypeSyntax.self), tupleType.elements.isEmpty {
            Self.diagnose(
                .removeRedundantReturn("()"),
                on: tupleType,
                context: context
            )
            var result = node
            result.returnClause = nil
            return result
        }
        return node
    }
}

fileprivate extension Finding.Message {
    static func removeRedundantReturn(_ type: String) -> Finding.Message {
        "remove the explicit return type '\(type)' from this function"
    }
}
