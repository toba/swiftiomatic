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

/// Remove `break` at the end of switch cases.
///
/// In Swift, switch cases do not fall through by default. A trailing `break` at the end of a
/// case body is therefore redundant.
///
/// This rule does NOT remove labeled `break` statements (e.g. `break outerLoop`), which transfer
/// control to a specific enclosing statement. It also does not remove `break` when it is the
/// sole statement in a case body (since at least one statement is required).
///
/// Lint: If a redundant `break` is found at the end of a switch case, a lint warning is raised.
@_spi(Rules)
public final class RedundantBreak: SyntaxLintRule {

  public override func visit(_ node: SwitchCaseSyntax) -> SyntaxVisitorContinueKind {
    let statements = node.statements

    // A case must have at least one statement. If `break` is the only statement, it's required.
    guard statements.count > 1 else {
      return .visitChildren
    }

    // Check if the last statement is an unlabeled `break`.
    guard let lastItem = statements.last,
      let breakStmt = lastItem.item.as(StmtSyntax.self)?.as(BreakStmtSyntax.self),
      breakStmt.label == nil
    else {
      return .visitChildren
    }

    diagnose(.removeRedundantBreak, on: breakStmt.breakKeyword)
    return .visitChildren
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantBreak: Finding.Message =
    "remove redundant 'break'; switch cases do not fall through by default"
}
