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
struct RedundantLetTests: RuleTesting {
  @Test func basicRedundantLet() {
    assertLint(
      RedundantLet.self,
      """
      1️⃣let _ = foo()
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove 'let' from 'let _ = ...'; use '_ = ...' instead"),
      ]
    )
  }

  @Test func namedBindingNotFlagged() {
    assertLint(
      RedundantLet.self,
      """
      let x = foo()
      """,
      findings: []
    )
  }

  @Test func varWildcardNotFlagged() {
    assertLint(
      RedundantLet.self,
      """
      var _ = foo()
      """,
      findings: []
    )
  }

  @Test func wildcardAssignmentNotFlagged() {
    assertLint(
      RedundantLet.self,
      """
      _ = foo()
      """,
      findings: []
    )
  }

  @Test func multipleBindingsNotFlagged() {
    assertLint(
      RedundantLet.self,
      """
      let _ = foo(), x = bar()
      """,
      findings: []
    )
  }

  @Test func insideFunction() {
    assertLint(
      RedundantLet.self,
      """
      func test() {
        1️⃣let _ = something()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove 'let' from 'let _ = ...'; use '_ = ...' instead"),
      ]
    )
  }

  @Test func tryExpression() {
    assertLint(
      RedundantLet.self,
      """
      1️⃣let _ = try foo()
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove 'let' from 'let _ = ...'; use '_ = ...' instead"),
      ]
    )
  }
}
