import SwiftSyntax

/// Lint chains of 3+ collection transforms ( `.map` , `.filter` , `.compactMap` , `.flatMap` ,
/// `.prefix` , `.dropFirst` ). Each step allocates an intermediate `Array` . Inserting `.lazy` at
/// the head of the chain forwards lazily and avoids the allocations.
///
/// A shorter chain allocates too when a single-pass operation consumes it. `xs.map { … }.min()`
/// builds an array that `min()` walks once and throws away, so the rule also lints a one-link or
/// two-link chain that feeds `min` , `max` , `reduce` , `joined(separator:)` , `contains` ,
/// `allSatisfy` , or `first(where:)` .
///
/// `Optional` also has `.map` and `.flatMap` , and neither one allocates. `Optional` has no `.lazy`
/// either, so the suggested fix does not compile there. The tree carries no type information, so
/// the rule reads the receiver type from two syntactic signals. A chain that uses a method
/// `Optional` does not have is a `Sequence` chain. A chain of `.map` and `.flatMap` alone is
/// ambiguous, so the rule skips it when the surrounding code proves the value is an `Optional` .
/// See ``isInOptionalContext(_:)`` for the four proofs.
final class UseLazyForLongChainOps: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    private static let chainableMethods: Set<String> = [
        "map",
        "filter",
        "compactMap",
        "flatMap",
        "prefix",
        "dropFirst",
        "dropLast",
    ]

    /// Reports whether `Optional` also has this chainable method. A chain built from these alone
    /// may be an `Optional` chain rather than a `Sequence` chain. Two names beat a `Set` here,
    /// because a comparison costs less than a hash.
    private static func isOptionalMethod(_ name: String) -> Bool {
        name == "map" || name == "flatMap"
    }

    /// `Sequence` operations that walk their receiver once and never materialize it, so a transform
    /// feeding one of them needs no intermediate array.
    ///
    /// `sorted()` and `reversed()` are absent on purpose. Each one has to materialize its receiver,
    /// so `.lazy` buys nothing there. `first` counts only as `first(where:)` , which the call check
    /// below enforces, because the `first` property belongs to `Collection` rather than `Sequence` .
    private static let singlePassConsumers: Set<String> = [
        "min", "max", "reduce", "joined", "contains", "allSatisfy", "first",
    ]

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        // Only emit on the outermost chain link to avoid duplicate findings.
        if isChainLink(node.parent) { return .visitChildren }
        let chain = chainShape(of: node)

        if chain.length >= 3 {
            if chain.isOptionalCompatible, isInOptionalContext(node) { return .visitChildren }
            diagnose(.useLazyForLongChainOps(chain.length), on: node)
            return .visitChildren
        }
        if let consumer = singlePassConsumer(of: node) {
            diagnose(.useLazyBeforeSinglePassConsumer(consumer), on: node)
        }
        return .visitChildren
    }

    /// Reports the name of the single-pass operation `call` invokes, when a short allocating
    /// transform chain feeds it.
    ///
    /// A chain of three or more transforms already reports through
    /// ``useLazyForLongChainOps(_:)`` , so only a one-link or two-link chain qualifies here.
    /// The consumer also settles the receiver type: `Optional` declares none of these operations,
    /// so the chain is a `Sequence` chain and `.lazy` compiles.
    private func singlePassConsumer(of call: FunctionCallExprSyntax) -> String? {
        guard let member = call.calledExpression.as(MemberAccessExprSyntax.self) else { return nil }
        let name = member.declName.baseName.text
        guard Self.singlePassConsumers.contains(name) else { return nil }

        // A lazy sequence resolves a bare `joined()` to the overload that flattens a sequence of
        // sequences, so the result stops being a `String` . `joined(separator:)` returns a `String`
        // either way.
        if name == "joined", call.arguments.isEmpty { return nil }

        guard let receiver = member.base?.as(FunctionCallExprSyntax.self) else { return nil }

        // A `.lazy` inside the chain resets the length to zero, so a zero length here means the
        // chain allocates nothing.
        let chain = chainShape(of: receiver)
        guard chain.length >= 1, chain.length <= 2 else { return nil }
        return name
    }

    private func isChainLink(_ syntax: Syntax?) -> Bool {
        // Walk up through member-access nodes (e.g., `.lazy`) that may sit between this call and an
        // outer chainable call. The call is a chain link if any enclosing function call's receiver
        // path passes through it via a chainable method name.
        var node = syntax

        while let current = node, let member = current.as(MemberAccessExprSyntax.self) {
            if let parentCall = member.parent?.as(FunctionCallExprSyntax.self),
               parentCall.calledExpression.id == member.id,
               Self.chainableMethods.contains(member.declName.baseName.text) { return true }
            node = member.parent
        }
        return false
    }

    /// Walks down the receiver chain measuring the consecutive chainable calls. `length` counts
    /// them. `isOptionalCompatible` reports whether every one of them names a method `Optional`
    /// also has.
    ///
    /// Calls downstream of a `.lazy` access are already lazy and don't allocate intermediate
    /// arrays, so a `.lazy` resets both values.
    private func chainShape(
        of call: FunctionCallExprSyntax
    ) -> (length: Int, isOptionalCompatible: Bool) {
        var current = ExprSyntax(call)
        var length = 0
        var isOptionalCompatible = true

        while let funcCall = current.as(FunctionCallExprSyntax.self),
              let member = funcCall.calledExpression.as(MemberAccessExprSyntax.self),
              let receiver = member.base
        {
            let name = member.declName.baseName.text
            guard Self.chainableMethods.contains(name) else { break }
            length += 1
            if !Self.isOptionalMethod(name) { isOptionalCompatible = false }

            if let recvMember = receiver.as(MemberAccessExprSyntax.self),
               recvMember.declName.baseName.text == "lazy"
            {
                length = 0
                isOptionalCompatible = true
                guard let inner = recvMember.base else { break }
                current = inner
                continue
            }
            current = receiver
        }
        return (length, isOptionalCompatible)
    }

    /// Reports whether the surrounding code proves the chain produces an `Optional` .
    ///
    /// Four forms prove it: the chain is returned from a function whose return type is `Optional` ,
    /// the chain is the left operand of `??` , the chain initializes a binding annotated `Optional`
    /// , or the chain initializes an `if let` or `guard let` binding. Anything else reports `false`
    /// , which keeps the finding.
    private func isInOptionalContext(_ call: FunctionCallExprSyntax) -> Bool {
        var child = Syntax(call)
        var current = call.parent

        while let node = current {
            // `try` and `await` wrap the whole chain without changing its type.
            if node.is(TryExprSyntax.self) || node.is(AwaitExprSyntax.self) {
                child = node
                current = node.parent
                continue
            }
            // The initializer clause holds the chain. Keep `child` on the chain itself, because the
            // binding below compares against `initializer.value`.
            if node.is(InitializerClauseSyntax.self) {
                current = node.parent
                continue
            }
            if let infix = node.as(InfixOperatorExprSyntax.self) {
                guard let op = infix.operator.as(BinaryOperatorExprSyntax.self),
                    op.operator.text == "??" else { return false }
                return infix.leftOperand.id == child.id
            }
            if let returnStmt = node.as(ReturnStmtSyntax.self) {
                guard returnStmt.expression?.id == child.id else { return false }
                return enclosingFunctionReturnsOptional(returnStmt)
            }
            if let binding = node.as(OptionalBindingConditionSyntax.self) {
                // `if let x = <chain>` compiles only when the chain is an `Optional`.
                return binding.initializer?.value.id == child.id
            }
            if let binding = node.as(PatternBindingSyntax.self) {
                guard binding.initializer?.value.id == child.id else { return false }
                return isOptionalType(binding.typeAnnotation?.type)
            }
            return false
        }
        return false
    }

    /// Reports whether the function enclosing `node` declares an `Optional` return type. The walk
    /// stops at a closure, because a closure without an explicit signature states no return type.
    private func enclosingFunctionReturnsOptional(_ node: SyntaxProtocol) -> Bool {
        var current: Syntax? = node.parent

        while let cursor = current {
            if cursor.is(ClosureExprSyntax.self) { return false }

            if let funcDecl = cursor.as(FunctionDeclSyntax.self) {
                return isOptionalType(funcDecl.signature.returnClause?.type)
            }
            if let binding = cursor.as(PatternBindingSyntax.self) {
                // A computed property: the accessor returns the property's own type.
                return isOptionalType(binding.typeAnnotation?.type)
            }
            current = cursor.parent
        }
        return false
    }

    private func isOptionalType(_ type: TypeSyntax?) -> Bool {
        guard let type else { return false }
        if type.is(OptionalTypeSyntax.self) { return true }
        if type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) { return true }
        if let identifier = type.as(IdentifierTypeSyntax.self) {
            return identifier.name.text == "Optional"
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static func useLazyForLongChainOps(_ count: Int) -> Finding.Message {
        "chain of \(count) collection transforms allocates intermediate arrays — consider '.lazy'"
    }

    static func useLazyBeforeSinglePassConsumer(_ consumer: String) -> Finding.Message {
        "collection transforms before '\(consumer)' allocate an intermediate array — consider '.lazy'"
    }
}
