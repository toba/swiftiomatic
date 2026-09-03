import SwiftSyntax

/// Every function in one file that a bare-name call reaches, indexed by name
///
/// A call through a receiver names a member, and no bare name reaches a member, so a type member
/// never enters the index.
///
/// Two nested functions can share a name, so the index keeps the statement list each declaration
/// sits in and resolves a call against the caller's own scope chain. A flat name-to-declaration map
/// would let one of the two overwrite the other, and the loser's callers would then resolve to the
/// wrong body.
///
/// The index depends on the tree and on nothing else, so `Context` builds one per tree and hands
/// the same one to every loop. Building one per loop would walk the whole file once per loop.
///
/// A scope is recorded as a node identity, so the index must be built from the tree the caller
/// walks. `Context` parses a tree of its own when it is given source text, and an identity from
/// that tree matches nothing in the walked one.
struct FreeFunctionIndex {
    private let declarations: [String: [ScopedFunction]]

    init(root: Syntax) {
        let collector = FreeFunctionCollector(viewMode: .sourceAccurate)
        collector.walk(root)
        declarations = collector.declarations
    }

    /// The function a bare call reaches, or `nil` when no scope around the call declares one
    ///
    /// - Parameters:
    ///   - name: The name the call writes, with no receiver in front of it.
    ///   - scope: The statement list holding the call.
    func function(
        named name: String,
        calledFrom scope: CodeBlockItemListSyntax
    ) -> FunctionDeclSyntax? {
        guard let candidates = declarations[name] else { return nil }

        // the innermost enclosing scope wins, so a nested function shadows a file-scope one
        var enclosing: Syntax? = Syntax(scope)

        while let current = enclosing {
            if let match = candidates.first(where: { $0.scope == current.id }) {
                return match.declaration
            }
            enclosing = current.parent
        }
        return nil
    }
}

/// One function declaration and the statement list it was declared in
private struct ScopedFunction {
    let scope: SyntaxIdentifier
    let declaration: FunctionDeclSyntax
}

/// Collects every function a bare name reaches: a nested function and a file-scope function, but
/// never a type member.
private final class FreeFunctionCollector: SyntaxVisitor {
    var declarations: [String: [ScopedFunction]] = [:]

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        // a member sits in a MemberBlockItemList instead, so the cast drops it
        if let scope = node.parent?.parent?.as(CodeBlockItemListSyntax.self) {
            declarations[node.name.text, default: []]
                .append(ScopedFunction(scope: scope.id, declaration: node))
        }
        return .visitChildren
    }
}

/// The statements a loop runs, including the bodies of the local functions it calls
///
/// A cost hidden behind a helper call is still paid once per iteration, so a check that reads the
/// loop body alone misses it. `UUID.init?(hexString:)` in Toba Core put its slice and its radix
/// parse in two nested functions and called both from the loop.
struct LoopReach {
    /// The loop body first, then the body of each function the loop reaches through a call
    let bodies: [CodeBlockItemListSyntax]

    /// - Parameters:
    ///   - body: The loop body to start from.
    ///   - functions: The file's index, which `Context` holds so one file costs one walk.
    init(body: CodeBlockItemListSyntax, functions: FreeFunctionIndex) {
        var bodies = [body]
        var pending = [body]
        var visited: Set<SyntaxIdentifier> = [body.id]

        while let next = pending.popLast() {
            let collector = CalledNameCollector(viewMode: .sourceAccurate)
            collector.walk(next)

            // sorted so the reach, and therefore the reported call, is the same on every run
            for name in collector.names.sorted() {
                guard let called = functions.function(named: name, calledFrom: next),
                      let statements = called.body?.statements,
                      visited.insert(statements.id).inserted else { continue }

                bodies.append(statements)
                pending.append(statements)
            }
        }
        self.bodies = bodies
    }

    /// Walks every statement list in the reach with one visitor, so the visitor accumulates across
    /// the loop body and the helpers together.
    func walk(_ visitor: SyntaxVisitor) { for body in bodies { visitor.walk(body) } }
}

/// Collects the names of every function called without a receiver.
private final class CalledNameCollector: SyntaxVisitor {
    var names: Set<String> = []

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let callee = node.calledExpression.as(DeclReferenceExprSyntax.self) {
            names.insert(callee.baseName.text)
        }
        return .visitChildren
    }
}
