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

/// Remove explicit `.init` when calling a type initializer directly.
///
/// `Foo.init(args)` can be written as `Foo(args)` when the type is explicit. The `.init` is only
/// necessary when the type is inferred (e.g. `.init(args)` ).
///
/// This rule only fires when `init` is called on a named base expression (not on `.init()`
/// shorthand, method chains, or subscripts).
///
/// Lint: If an explicit `.init` is found on a direct type reference, a lint warning is raised.
///
/// Rewrite: The `.init` member access is removed, leaving the type called directly.
final class RedundantInit: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    static func transform(
        _ node: FunctionCallExprSyntax,
        original _: FunctionCallExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.tokenKind == .keyword(.`init`),
              memberAccess.declName.argumentNames == nil,
              let base = memberAccess.base else { return ExprSyntax(node) }

        // Only fire when the base is a simple type reference or another member access (e.g.
        // `Module.Type` ), not when it's `.init()` (no base) which is shorthand inference syntax.
        // Also skip if the base is a function call (e.g. `foo().init()` ) — unusual but not
        // redundant.
        guard !base.is(FunctionCallExprSyntax.self) else { return ExprSyntax(node) }

        // Skip `self.init(...)` , `Self.init(...)` , and `super.init(...)` — these are
        // delegation/chaining calls where `.init` is required.
        if let baseRef = base.as(DeclReferenceExprSyntax.self) {
            switch baseRef.baseName.tokenKind {
                case .keyword(.self), .keyword(.Self), .keyword(.super): return ExprSyntax(node)
                default: break
            }
        }
        if base.is(SuperExprSyntax.self) { return ExprSyntax(node) }

        // Skip metatype values: when the base is a value of metatype type (e.g. a parameter
        // `rule: R.Type` called as `rule.init(...)` ), `.init` is required — dropping it produces
        // `rule(...)` , which doesn't compile. We can't tell value-vs-type from syntax alone, so
        // use the Swift convention: type names are UpperCamelCase, value identifiers are
        // lowerCamelCase. Only fire when the leftmost identifier in the base looks like a type.
        guard leftmostIdentifierIsType(base) else { return ExprSyntax(node) }

        Self.diagnose(.removeRedundantInit, on: memberAccess.period, context: context)

        // Replace `Foo.init(args)` with `Foo(args)` . Transfer the trailing trivia from `init`
        // (typically empty) and preserve the base's trivia.
        var newNode = node
        var newBase = base
        newBase.trailingTrivia = memberAccess.declName.baseName.trailingTrivia
        newNode.calledExpression = ExprSyntax(newBase)
        return ExprSyntax(newNode)
    }
}

fileprivate extension RedundantInit {
    /// Walks down a base expression to its leftmost identifier and returns `true` if that
    /// identifier looks like a type by Swift convention (UpperCamelCase). Returns `false` for
    /// value-typed receivers like `rule.init(...)` .
    static func leftmostIdentifierIsType(_ base: ExprSyntax) -> Bool {
        var current: ExprSyntax = base

        while true {
            if let memberAccess = current.as(MemberAccessExprSyntax.self),
               let inner = memberAccess.base
            {
                current = inner
                continue
            }
            if let generic = current.as(GenericSpecializationExprSyntax.self) {
                current = generic.expression
                continue
            }
            break
        }
        guard let declRef = current.as(DeclReferenceExprSyntax.self),
              let first = declRef.baseName.text.first else { return false }
        return first.isUppercase || first == "_"
    }
}

fileprivate extension Finding.Message {
    static let removeRedundantInit: Finding.Message =
        "remove explicit '.init'; call the type directly"
}
