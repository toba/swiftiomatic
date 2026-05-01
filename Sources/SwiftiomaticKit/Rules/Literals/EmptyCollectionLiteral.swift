// ===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors Licensed under Apache License
// v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information See https://swift.org/CONTRIBUTORS.txt
// for the list of Swift project authors
//
// ===----------------------------------------------------------------------===//

import Foundation
import SwiftParser
import SwiftSyntax

/// Never use `[<Type>]()` syntax. In call sites that should be replaced with `[]` , for
/// initializations use explicit type combined with empty array literal `let _: [<Type>] = []`
/// Static properties of a type that return that type should not include a reference to their type.
///
/// Lint: Non-literal empty array initialization will yield a lint error. Rewrite: All invalid use
/// sites would be related with empty literal (with or without explicit type annotation).
final class EmptyCollectionLiteral: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .literals }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    static func transform(
        _ node: PatternBindingSyntax,
        original _: PatternBindingSyntax,
        parent _: Syntax?,
        context: Context
    ) -> PatternBindingSyntax {
        guard let initializer = node.initializer,
              let type = isRewritable(initializer) else { return node }

        if let type = type.as(ArrayTypeSyntax.self) {
            return rewrite(node, type: type, context: context)
        }
        if let type = type.as(DictionaryTypeSyntax.self) {
            return rewrite(node, type: type, context: context)
        }

        return node
    }

    static func transform(
        _ param: FunctionParameterSyntax,
        original _: FunctionParameterSyntax,
        parent _: Syntax?,
        context: Context
    ) -> FunctionParameterSyntax {
        guard let initializer = param.defaultValue,
              let type = isRewritable(initializer) else { return param }

        if let type = type.as(ArrayTypeSyntax.self) {
            return rewrite(param, type: type, context: context)
        }
        if let type = type.as(DictionaryTypeSyntax.self) {
            return rewrite(param, type: type, context: context)
        }

        return param
    }

    /// Check whether the initializer is `[<Type>]()` and, if so, it could be rewritten to use an
    /// empty collection literal. Return a type of the collection.
    static func isRewritable(_ initializer: InitializerClauseSyntax) -> TypeSyntax? {
        guard let initCall = initializer.value.as(FunctionCallExprSyntax.self),
              initCall.arguments.isEmpty else { return nil }

        if let arrayLiteral = initCall.calledExpression.as(ArrayExprSyntax.self) {
            return getLiteralType(arrayLiteral)
        }
        if let dictLiteral = initCall.calledExpression.as(DictionaryExprSyntax.self) {
            return getLiteralType(dictLiteral)
        }

        return nil
    }

    private static func rewrite(
        _ node: PatternBindingSyntax,
        type: ArrayTypeSyntax,
        context: Context
    ) -> PatternBindingSyntax {
        var replacement = node

        diagnose(node, type: type, context: context)

        if replacement.typeAnnotation == nil {
            // Drop trailing trivia after pattern because ':' has to appear connected to it.
            replacement.pattern = node.pattern.with(\.trailingTrivia, [])
            // Add explicit type annotation: ': [<Type>]`
            replacement.typeAnnotation = .init(
                type: type.with(\.leadingTrivia, .space)
                    .with(\.trailingTrivia, .space)
            )
        }

        let initializer = node.initializer!
        let emptyArrayExpr = ArrayExprSyntax(elements: ArrayElementListSyntax([]))

        // Replace initializer call with empty array literal: `[<Type>]()` -> `[]`
        replacement.initializer = initializer.with(\.value, ExprSyntax(emptyArrayExpr))

        return replacement
    }

    private static func rewrite(
        _ node: PatternBindingSyntax,
        type: DictionaryTypeSyntax,
        context: Context
    ) -> PatternBindingSyntax {
        var replacement = node

        diagnose(node, type: type, context: context)

        if replacement.typeAnnotation == nil {
            // Drop trailing trivia after pattern because ':' has to appear connected to it.
            replacement.pattern = node.pattern.with(\.trailingTrivia, [])
            // Add explicit type annotation: ': [<Type>]`
            replacement.typeAnnotation = .init(
                type: type.with(\.leadingTrivia, .space).with(
                    \.trailingTrivia,
                    .space
                ))
        }

        let initializer = node.initializer!
        // Replace initializer call with empty dictionary literal: `[<Type>]()` -> `[]`
        replacement.initializer = initializer.with(\.value, ExprSyntax(getEmptyDictionaryLiteral()))

        return replacement
    }

    private static func rewrite(
        _ param: FunctionParameterSyntax,
        type _: ArrayTypeSyntax,
        context: Context
    ) -> FunctionParameterSyntax {
        guard let initializer = param.defaultValue else { return param }

        emitDiagnostic(
            replace: "\(initializer.value)",
            with: "[]",
            on: initializer.value,
            context: context
        )
        return param.with(\.defaultValue, initializer.with(\.value, getEmptyArrayLiteral()))
    }

    private static func rewrite(
        _ param: FunctionParameterSyntax,
        type _: DictionaryTypeSyntax,
        context: Context
    ) -> FunctionParameterSyntax {
        guard let initializer = param.defaultValue else { return param }

        emitDiagnostic(
            replace: "\(initializer.value)",
            with: "[:]",
            on: initializer.value,
            context: context
        )
        return param.with(\.defaultValue, initializer.with(\.value, getEmptyDictionaryLiteral()))
    }

    private static func diagnose(
        _ node: PatternBindingSyntax,
        type: ArrayTypeSyntax,
        context: Context
    ) {
        var withFixIt = "[]"
        if node.typeAnnotation == nil { withFixIt = ": \(type) = []" }

        let initCall = node.initializer!.value
        emitDiagnostic(replace: "\(initCall)", with: withFixIt, on: initCall, context: context)
    }

    private static func diagnose(
        _ node: PatternBindingSyntax,
        type: DictionaryTypeSyntax,
        context: Context
    ) {
        var withFixIt = "[:]"
        if node.typeAnnotation == nil { withFixIt = ": \(type) = [:]" }

        let initCall = node.initializer!.value
        emitDiagnostic(replace: "\(initCall)", with: withFixIt, on: initCall, context: context)
    }

    private static func emitDiagnostic(
        replace: String,
        with fixIt: String,
        on: ExprSyntax?,
        context: Context
    ) {
        Self.diagnose(
            .refactorIntoEmptyLiteral(replace: replace, with: fixIt),
            on: on,
            context: context
        )
    }

    private static func getLiteralType(_ arrayLiteral: ArrayExprSyntax) -> TypeSyntax? {
        guard arrayLiteral.elements.count == 1 else { return nil }

        var parser = Parser(arrayLiteral.description)
        let elementType = TypeSyntax.parse(from: &parser)

        guard !elementType.hasError, elementType.is(ArrayTypeSyntax.self) else { return nil }

        return elementType
    }

    private static func getLiteralType(_ dictLiteral: DictionaryExprSyntax) -> TypeSyntax? {
        var parser = Parser(dictLiteral.description)
        let elementType = TypeSyntax.parse(from: &parser)

        guard !elementType.hasError, elementType.is(DictionaryTypeSyntax.self) else { return nil }

        return elementType
    }

    private static func getEmptyArrayLiteral() -> ExprSyntax {
        ExprSyntax(ArrayExprSyntax(elements: ArrayElementListSyntax([])))
    }

    private static func getEmptyDictionaryLiteral() -> ExprSyntax {
        ExprSyntax(DictionaryExprSyntax(content: .colon(.colonToken())))
    }
}

fileprivate extension Finding.Message {
    static func refactorIntoEmptyLiteral(
        replace: String,
        with: String
    ) -> Finding.Message { "replace '\(replace)' with '\(with)'" }
}
