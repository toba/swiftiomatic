//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantBreakTests: RuleTesting {
  @Test func trailingBreakAfterStatements() {
    assertLint(
      RedundantBreak.self,
      """
      switch x {
      case .a:
        print("a")
        1️⃣break
      case .b:
        print("b")
        2️⃣break
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'break'; switch cases do not fall through by default"),
        FindingSpec("2️⃣", message: "remove redundant 'break'; switch cases do not fall through by default"),
      ]
    )
  }

  @Test func breakAsOnlyStatementNotFlagged() {
    assertLint(
      RedundantBreak.self,
      """
      switch x {
      case .a:
        break
      default:
        break
      }
      """,
      findings: []
    )
  }

  @Test func labeledBreakNotFlagged() {
    assertLint(
      RedundantBreak.self,
      """
      outer: switch x {
      case .a:
        print("a")
        break outer
      }
      """,
      findings: []
    )
  }

  @Test func defaultCase() {
    assertLint(
      RedundantBreak.self,
      """
      switch x {
      default:
        print("default")
        1️⃣break
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'break'; switch cases do not fall through by default"),
      ]
    )
  }

  @Test func noBreakNotFlagged() {
    assertLint(
      RedundantBreak.self,
      """
      switch x {
      case .a:
        print("a")
      case .b:
        print("b")
      }
      """,
      findings: []
    )
  }

  @Test func breakInMiddleNotFlagged() {
    assertLint(
      RedundantBreak.self,
      """
      switch x {
      case .a:
        if condition {
          break
        }
        print("a")
      }
      """,
      findings: []
    )
  }
}
