//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Replace `forEach` with `for-in` loop unless its argument is a function reference.
///
/// Lint: invalid use of `forEach` yield will yield a lint error.
final class UseForLoopNotForEach: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .controlFlow }
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        // We are only interested in calls with a single trailing closure argument.
        if !node.arguments.isEmpty || node.trailingClosure == nil
            || !node.additionalTrailingClosures.isEmpty
        {
            return .visitChildren
        }

        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self) else {
            return .visitChildren
        }

        let memberName = member.declName.baseName
        guard memberName.text == "forEach" else { return .visitChildren }

        // If there is another chained member after `.forEach` , let's skip the diagnostic because
        // resulting code might be less understandable.
        if node.parent?.is(MemberAccessExprSyntax.self) == true { return .visitChildren }

        // Skip throwing non-`Sequence.forEach` (e.g. GRDB `Cursor.forEach`):
        // `Sequence.forEach` is `rethrows`, so `try receiver.forEach { ... }` with no
        // `try`/`throw` in the closure body cannot be `Sequence.forEach` — it must be a
        // distinct unconditionally-throwing method, and `for x in receiver` would not compile.
        if node.parent?.is(TryExprSyntax.self) == true,
            let closure = node.trailingClosure,
            !ClosureThrowScanner.containsTryOrThrow(closure)
        {
            return .visitChildren
        }

        diagnose(.replaceForEachWithLoop(), on: memberName)
        return .visitChildren
    }
}

/// Walks a closure body looking for any `try`/`throw` token. Descends into nested
/// closures and functions — any throwing site anywhere makes the call ambiguous
/// (could be `Sequence.forEach` rethrowing), so the rule should still fire.
private final class ClosureThrowScanner: SyntaxVisitor {
    var found = false

    static func containsTryOrThrow(_ closure: ClosureExprSyntax) -> Bool {
        let scanner = ClosureThrowScanner(viewMode: .sourceAccurate)
        scanner.walk(closure.statements)
        return scanner.found
    }

    override func visit(_ node: TryExprSyntax) -> SyntaxVisitorContinueKind {
        found = true
        return .skipChildren
    }

    override func visit(_ node: ThrowStmtSyntax) -> SyntaxVisitorContinueKind {
        found = true
        return .skipChildren
    }
}

fileprivate extension Finding.Message {
    static func replaceForEachWithLoop() -> Finding.Message {
        "replace use of '.forEach { ... }' with for-in loop"
    }
}
