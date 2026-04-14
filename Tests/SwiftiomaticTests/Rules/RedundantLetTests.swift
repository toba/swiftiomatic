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
    assertFormatting(
      RedundantLet.self,
      input: """
        1️⃣let _ = foo()
        """,
      expected: """
        _ = foo()
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 'let' from 'let _ = ...'; use '_ = ...' instead"),
      ]
    )
  }

  @Test func namedBindingNotFlagged() {
    assertFormatting(
      RedundantLet.self,
      input: """
        let x = foo()
        """,
      expected: """
        let x = foo()
        """,
      findings: []
    )
  }

  @Test func varWildcardNotFlagged() {
    assertFormatting(
      RedundantLet.self,
      input: """
        var _ = foo()
        """,
      expected: """
        var _ = foo()
        """,
      findings: []
    )
  }

  @Test func wildcardAssignmentNotFlagged() {
    assertFormatting(
      RedundantLet.self,
      input: """
        _ = foo()
        """,
      expected: """
        _ = foo()
        """,
      findings: []
    )
  }

  @Test func multipleBindingsNotFlagged() {
    assertFormatting(
      RedundantLet.self,
      input: """
        let _ = foo(), x = bar()
        """,
      expected: """
        let _ = foo(), x = bar()
        """,
      findings: []
    )
  }

  @Test func insideFunction() {
    assertFormatting(
      RedundantLet.self,
      input: """
        func test() {
          1️⃣let _ = something()
        }
        """,
      expected: """
        func test() {
          _ = something()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 'let' from 'let _ = ...'; use '_ = ...' instead"),
      ]
    )
  }

  @Test func tryExpression() {
    assertFormatting(
      RedundantLet.self,
      input: """
        func test() throws {
          1️⃣let _ = try foo()
        }
        """,
      expected: """
        func test() throws {
          _ = try foo()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 'let' from 'let _ = ...'; use '_ = ...' instead"),
      ]
    )
  }

  // MARK: - Adapted from SwiftFormat

  @Test func removeRedundantLetWithTrailingClosure() {
    assertFormatting(
      RedundantLet.self,
      input: """
        func test() {
          1️⃣let _ = bar {}
        }
        """,
      expected: """
        func test() {
          _ = bar {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 'let' from 'let _ = ...'; use '_ = ...' instead"),
      ]
    )
  }

  @Test func noRemoveLetWithType() {
    assertFormatting(
      RedundantLet.self,
      input: """
        let _: String = bar {}
        """,
      expected: """
        let _: String = bar {}
        """,
      findings: []
    )
  }

  @Test func noRemoveLetInIf() {
    assertFormatting(
      RedundantLet.self,
      input: """
        if let _ = foo {}
        """,
      expected: """
        if let _ = foo {}
        """,
      findings: []
    )
  }

  @Test func noRemoveLetInGuard() {
    assertFormatting(
      RedundantLet.self,
      input: """
        guard let _ = foo else {}
        """,
      expected: """
        guard let _ = foo else {}
        """,
      findings: []
    )
  }

  @Test func noRemoveLetInWhile() {
    assertFormatting(
      RedundantLet.self,
      input: """
        while let _ = foo {}
        """,
      expected: """
        while let _ = foo {}
        """,
      findings: []
    )
  }

  @Test func noRemoveLetInViewBuilder() {
    assertFormatting(
      RedundantLet.self,
      input: """
        HStack {
          let _ = print("Hi")
          Text("Some text")
        }
        """,
      expected: """
        HStack {
          let _ = print("Hi")
          Text("Some text")
        }
        """,
      findings: []
    )
  }

  @Test func noRemoveLetInViewBuilderModifier() {
    assertFormatting(
      RedundantLet.self,
      input: """
        VStack {
          Text("Some text")
        }
        .overlay(
          HStack {
            let _ = print("")
          }
        )
        """,
      expected: """
        VStack {
          Text("Some text")
        }
        .overlay(
          HStack {
            let _ = print("")
          }
        )
        """,
      findings: []
    )
  }

  @Test func noRemoveAsyncLet() {
    assertFormatting(
      RedundantLet.self,
      input: """
        async let _ = foo()
        """,
      expected: """
        async let _ = foo()
        """,
      findings: []
    )
  }

  @Test func noRemoveLetInPreviewMacro() {
    assertFormatting(
      RedundantLet.self,
      input: """
        #Preview {
          let _ = 1234
          Text("Test")
        }
        """,
      expected: """
        #Preview {
          let _ = 1234
          Text("Test")
        }
        """,
      findings: []
    )
  }
}
