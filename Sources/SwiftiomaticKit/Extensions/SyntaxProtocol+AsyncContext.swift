import SwiftSyntax

extension SyntaxProtocol {
    /// Whether the nearest enclosing function, accessor or closure of this node runs as async code
    ///
    /// Async code is the body of an `async` function, initializer or accessor, or a closure that
    /// ``ClosureExprSyntax/runsAsAsync`` accepts. A type declaration ends the search.
    var isInAsyncContext: Bool { isInAsyncContext(excluding: nil) }

    /// Whether the nearest enclosing function, accessor or closure of this node runs as async code,
    /// when an await inside `excluded` does not count
    ///
    /// A rule that proposes an `await` in `excluded` passes that node, so that the await it wants
    /// cannot prove the scope is async.
    func isInAsyncContext(excluding excluded: Syntax?) -> Bool {
        isInAsyncContext { $0.runsAsAsync(excluding: excluded) }
    }

    /// Whether the nearest enclosing function, accessor or closure of this node runs as async code,
    /// when `closureIsAsync` decides for a closure
    func isInAsyncContext(closureIsAsync: (ClosureExprSyntax) -> Bool) -> Bool {
        var current = parent

        while let syntax = current {
            if let function = syntax.as(FunctionDeclSyntax.self) {
                return function.signature.effectSpecifiers?.asyncSpecifier != nil
            }
            if let initializer = syntax.as(InitializerDeclSyntax.self) {
                return initializer.signature.effectSpecifiers?.asyncSpecifier != nil
            }
            if let accessor = syntax.as(AccessorDeclSyntax.self) {
                return accessor.effectSpecifiers?.asyncSpecifier != nil
            }
            if let closure = syntax.as(ClosureExprSyntax.self) {
                return closureIsAsync(closure)
            }
            if syntax.isProtocol((any DeclGroupSyntax).self) { return false }
            current = syntax.parent
        }
        return false
    }

    /// Whether this node awaits outside any nested closure or function
    ///
    /// A `for await` loop counts as an await.
    var awaitsDirectly: Bool { awaitsDirectly(excluding: nil) }

    /// Whether this node awaits outside any nested closure or function and outside `excluded`
    func awaitsDirectly(excluding excluded: Syntax?) -> Bool {
        let scan = DirectAwaitScanner(viewMode: .sourceAccurate)
        scan.excluded = excluded.map { $0.position..<$0.endPosition }
        scan.walk(self)
        return scan.awaits
    }
}

extension ClosureExprSyntax {
    /// Whether this closure runs as async code
    ///
    /// The closure runs as async code when it is marked `async` , when it is the body of a
    /// `Task { }` , a task factory, a `.task` modifier or a `with…TaskGroup` call, or when it
    /// awaits.
    var runsAsAsync: Bool { runsAsAsync(excluding: nil) }

    /// Whether this closure runs as async code, when an await inside `excluded` does not count
    ///
    /// This check misses a closure whose only await is in `excluded` . That is the safe direction
    /// to miss in. A rule that proposes an `await` in a synchronous closure breaks the build.
    func runsAsAsync(excluding excluded: Syntax?) -> Bool {
        if signature?.effectSpecifiers?.asyncSpecifier != nil { return true }

        if let call = owningCall {
            if call.createsUnstructuredTask { return true }
            let name = call.calleeBaseName
            if name == "task" { return true }
            if let name, name.hasPrefix("with"), name.hasSuffix("TaskGroup") { return true }
        }
        return statements.awaitsDirectly(excluding: excluded)
    }
}

extension ExprSyntax {
    /// Whether this sequence is an array literal or a range between two integer literals
    var isShortLiteralSequence: Bool {
        if self.is(ArrayExprSyntax.self) { return true }
        guard let infix = self.as(InfixOperatorExprSyntax.self),
              let op = infix.operator.as(BinaryOperatorExprSyntax.self),
              op.operator.text == "..<" || op.operator.text == "..."
        else {
            // The linter can see an unfolded sequence.
            guard let list = self.as(SequenceExprSyntax.self), list.elements.count == 3 else {
                return false
            }
            let parts = Array(list.elements)
            guard let op = parts[1].as(BinaryOperatorExprSyntax.self),
                  op.operator.text == "..<" || op.operator.text == "..."
            else { return false }
            return parts[0].is(IntegerLiteralExprSyntax.self)
                && parts[2].is(IntegerLiteralExprSyntax.self)
        }
        return infix.leftOperand.is(IntegerLiteralExprSyntax.self)
            && infix.rightOperand.is(IntegerLiteralExprSyntax.self)
    }
}

/// A visitor that does not enter a nested closure or function.
///
/// Subclass it to scan the code that runs in the current scope only.
class DirectScopeVisitor: SyntaxVisitor {
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }
}

/// Finds an await that is not inside a nested closure or function.
private final class DirectAwaitScanner: DirectScopeVisitor {
    var awaits = false
    /// The source range where an await does not count
    var excluded: Range<AbsolutePosition>?

    override func visit(_ node: AwaitExprSyntax) -> SyntaxVisitorContinueKind {
        if excluded?.contains(node.position) == true { return .skipChildren }
        awaits = true
        return .skipChildren
    }

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        if node.awaitKeyword != nil, excluded?.contains(node.position) != true { awaits = true }
        return .visitChildren
    }
}
