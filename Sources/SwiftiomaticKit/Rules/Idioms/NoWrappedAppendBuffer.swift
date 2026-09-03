import SwiftSyntax

/// Lint a local buffer that `append` fills in a loop and a second buffer then copies
///
/// The pattern allocates twice and writes the same bytes twice, and neither cost buys anything. The
/// wrapper knows the count before the loop starts, so the loop can write into it directly.
///
/// ```swift
/// var data = Bytes()
/// // append loop
/// self = Data(data)
/// ```
///
/// The rule fires only when the array has no other use. An array that is returned, or handed to any
/// caller other than the wrapper, is doing its job and the second buffer is that caller's business.
/// A fill with no loop is also silent, because one copy of a finished buffer is a different cost
/// from a copy per step.
///
/// The rule reads each reference once, from the pipeline's own walk, and holds one scope frame per
/// statement list that declares a candidate. Walking each statement list separately would read a
/// nested statement once per list around it.
///
/// Lint: A local `var` that `append` fills inside a loop, and that nothing reads except a wrapping
/// initializer or a fixed-size tuple, raises a warning.
final class NoWrappedAppendBuffer: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    /// The types whose initializer copies a collection into storage of its own
    private static let wrappingTypeNames: Set<String> = [
        "Array",
        "ArraySlice",
        "ContiguousArray",
        "Data",
        "Set",
        "String",
        "Substring",
    ]

    /// The methods that fill the buffer rather than read it
    private static let buildingMethodNames: Set<String> = ["append", "reserveCapacity"]

    /// One statement list that declares a candidate, and what its references have shown so far
    private struct Scope {
        let id: SyntaxIdentifier
        let candidates: [(name: String, declaration: VariableDeclSyntax)]
        var uses: [String: Use]
    }

    private struct Use {
        var appendsInLoop = false
        var wraps = 0
        var tupleReads = 0
        var hasOtherUse = false

        var isWrappedAppendBuffer: Bool {
            appendsInLoop && !hasOtherUse && (wraps > 0 || tupleReads > 0)
        }
    }

    private var scopes: [Scope] = []

    override func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        let candidates = Self.localBuffers(declaredIn: node)

        if !candidates.isEmpty {
            scopes.append(Scope(id: node.id, candidates: candidates, uses: [:]))
        }
        return .visitChildren
    }

    override func visitPost(_ node: CodeBlockItemListSyntax) {
        // a masked region can skip visit and still reach visitPost, so match before popping
        guard scopes.last?.id == node.id else { return }

        let scope = scopes.removeLast()

        for candidate in scope.candidates {
            guard let use = scope.uses[candidate.name], use.isWrappedAppendBuffer else { continue }
            diagnose(.wrappedAppendBuffer(candidate.name), on: candidate.declaration)
        }
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        guard !scopes.isEmpty else { return .visitChildren }

        let name = node.baseName.text

        // innermost first, so an inner declaration shadows an outer one of the same name
        guard let frame = scopes.lastIndex(where: { $0.candidates.contains { $0.name == name } })
        else { return .visitChildren }

        classify(node, named: name, in: &scopes[frame])
        return .visitChildren
    }

    /// The `var` declarations with an initializer that this statement list introduces, in source
    /// order. A `let` cannot take an `append` , so only `var` is a candidate.
    private static func localBuffers(
        declaredIn statements: CodeBlockItemListSyntax
    ) -> [(name: String, declaration: VariableDeclSyntax)] {
        statements.compactMap { item -> (name: String, declaration: VariableDeclSyntax)? in
            guard let declaration = item.item.as(VariableDeclSyntax.self),
                declaration.bindingSpecifier.tokenKind == .keyword(.var),
                let binding = declaration.bindings.firstAndOnly,
                binding.initializer != nil,
                let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            else { return nil }

            return (name: name, declaration: declaration)
        }
    }

    /// Sorts one reference into the three uses the rule accepts, or records that something else
    /// reads the buffer.
    private func classify(
        _ reference: DeclReferenceExprSyntax,
        named name: String,
        in scope: inout Scope
    ) {
        var use = scope.uses[name] ?? Use()
        defer { scope.uses[name] = use }

        if let member = reference.parent?.as(MemberAccessExprSyntax.self) {
            // a match on the member name is a different declaration, so it counts as no use at all
            guard member.base?.id == reference.id else { return }

            let method = member.declName.baseName.text
            guard Self.buildingMethodNames.contains(method),
                member.parent?.is(FunctionCallExprSyntax.self) == true
            else {
                use.hasOtherUse = true
                return
            }
            if method == "append", isInsideLoop(Syntax(reference), within: scope.id) {
                use.appendsInLoop = true
            }
            return
        }

        if isWrappedArgument(reference) {
            use.wraps += 1
        } else if isTupleElementRead(reference) {
            use.tupleReads += 1
        } else {
            use.hasOtherUse = true
        }
    }

    /// Whether the reference is the sole unlabelled argument of a wrapping initializer.
    private func isWrappedArgument(_ reference: DeclReferenceExprSyntax) -> Bool {
        guard let argument = reference.parent?.as(LabeledExprSyntax.self),
              argument.label == nil,
              let call = argument.parent?.parent?.as(FunctionCallExprSyntax.self),
              let callee = call.calledExpression.as(DeclReferenceExprSyntax.self)
        else { return false }

        return Self.wrappingTypeNames.contains(callee.baseName.text)
    }

    /// Whether the reference is subscripted by a literal index inside a tuple, which is how a
    /// fixed-size tuple reads a whole buffer out.
    private func isTupleElementRead(_ reference: DeclReferenceExprSyntax) -> Bool {
        guard let subscriptCall = reference.parent?.as(SubscriptCallExprSyntax.self),
              subscriptCall.calledExpression.id == reference.id,
              let index = subscriptCall.arguments.firstAndOnly,
              index.expression.is(IntegerLiteralExprSyntax.self),
              let element = subscriptCall.parent?.as(LabeledExprSyntax.self) else { return false }

        return element.parent?.parent?.is(TupleExprSyntax.self) == true
    }

    /// Whether the reference sits in a loop that the declaring statement list contains. A loop
    /// outside that list runs the declaration again on each pass, so it fills a fresh buffer.
    private func isInsideLoop(_ node: Syntax, within scope: SyntaxIdentifier) -> Bool {
        var current = node.parent

        while let ancestor = current, ancestor.id != scope {
            if isLoopStatement(ancestor) { return true }
            current = ancestor.parent
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static func wrappedAppendBuffer(_ name: String) -> Finding.Message {
        """
        '\(name)' is filled by 'append' in a loop and then copied into a second buffer \
        — write the bytes into the final buffer once
        """
    }
}
