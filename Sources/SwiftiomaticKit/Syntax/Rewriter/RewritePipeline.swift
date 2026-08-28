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

/// The helpers every generated `visit(_:)` override calls.
///
/// The class itself and all 75 overrides live in `RewritePipeline+Generated.swift` , which the
/// generator derives from the hooks each rule declares. Only these two helpers stay hand-written,
/// because they carry the generic signatures the generated call sites depend on.
extension RewritePipeline {
    /// Applies a rule to an accumulator of the node's own kind.
    ///
    /// The override returns that same kind, so no rule in the chain can replace the node with a
    /// different one. A result that is not the node's kind is dropped.
    @inline(__always)
    func apply<N: SyntaxProtocol, R: SyntaxRule>(
        _: R.Type,
        to concrete: inout N,
        original: N,
        gate: Context.Gate,
        _ body: (N, N, Context) -> some SyntaxProtocol
    ) {
        guard context.shouldRewrite(R.self, gate: gate) else { return }
        if let next = body(concrete, original, context).as(N.self) { concrete = next }
    }

    /// Applies a rule to a base-typed accumulator, narrowing to the rule's own node kind first.
    ///
    /// The override returns a base type, so an earlier rule in the chain may have replaced the node
    /// with a different kind. This rule then finds no `N` and skips itself, which is what leaves
    /// the earlier rewrite standing.
    ///
    /// - Parameters:
    ///   - current: The accumulator, typed as the base the override returns.
    ///   - original: The node as it stood before the walk, which rules compare against.
    @inline(__always)
    func applyNarrowing<N: SyntaxProtocol, R: SyntaxRule, W: SyntaxProtocol>(
        _: R.Type,
        to current: inout W,
        as _: N.Type,
        original: N,
        gate: Context.Gate,
        _ body: (N, N, Context) -> some SyntaxProtocol
    ) {
        guard context.shouldRewrite(R.self, gate: gate),
              let concrete = current.as(N.self) else { return }

        if let next = Syntax(body(concrete, original, context)).as(W.self) { current = next }
    }
}
