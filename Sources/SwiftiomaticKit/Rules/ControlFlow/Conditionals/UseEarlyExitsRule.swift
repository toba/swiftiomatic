// sm:disable file_header
//
// Adapted from swift-format's UseEarlyExits.swift
//
// https://github.com/apple/swift-format
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import SwiftiomaticSyntax

struct UseEarlyExitsRule {
  static let id = "use_early_exits"
  static let name = "Use Early Exits"
  static let summary =
    "Prefer `guard` for early exits instead of `if/else` when the else branch exits."
  static let isOptIn = true
  var options = SeverityOption<Self>(.warning)
}

extension UseEarlyExitsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension UseEarlyExitsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: IfExprSyntax) {
      // Only handle simple if/else — skip if/else-if chains.
      // The elseBody is a CodeBlockSyntax for `else { }` and an
      // IfExprSyntax for `else if`.
      guard let elseBody = node.elseBody?.as(CodeBlockSyntax.self),
        endsWithEarlyExit(elseBody)
      else {
        return
      }

      // Skip trivial if-blocks (3 or fewer statements) — guard only
      // helps readability for longer true-branches.
      guard node.body.statements.count > 3 else {
        return
      }

      // Skip if this if-expression is itself the else-branch of another if
      // (i.e., part of an if/else-if chain).
      if node.parent?.as(IfExprSyntax.self)?.elseBody != nil {
        return
      }

      violations.append(
        .init(
          position: node.ifKeyword.positionAfterSkippingLeadingTrivia,
          reason: "Replace this 'if/else' block with a 'guard' statement containing the early exit"
        )
      )
    }

    /// Whether the last statement in the code block is an early exit.
    private func endsWithEarlyExit(_ block: CodeBlockSyntax) -> Bool {
      guard let lastItem = block.statements.last else { return false }

      switch lastItem.item {
      case .stmt(let stmt):
        switch stmt.kind {
        case .returnStmt, .throwStmt, .breakStmt, .continueStmt:
          return true
        default:
          return false
        }
      default:
        return false
      }
    }
  }
}
