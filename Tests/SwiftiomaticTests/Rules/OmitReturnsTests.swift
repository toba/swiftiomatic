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

@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct OmitReturnsTests: RuleTesting {
  @Test func omitReturnInFunction() {
    assertFormatting(
      RedundantReturn.self,
      input: """
          func test() -> Bool {
            1️⃣return false
          }
        """,
      expected: """
          func test() -> Bool {
            false
          }
        """,
      findings: [
        FindingSpec("1️⃣", message: "'return' can be omitted because body consists of a single expression")
      ]
    )
  }

  @Test func omitReturnInClosure() {
    assertFormatting(
      RedundantReturn.self,
      input: """
          vals.filter {
            1️⃣return $0.count == 1
          }
        """,
      expected: """
          vals.filter {
            $0.count == 1
          }
        """,
      findings: [
        FindingSpec("1️⃣", message: "'return' can be omitted because body consists of a single expression")
      ]
    )
  }

  @Test func omitReturnInSubscript() {
    assertFormatting(
      RedundantReturn.self,
      input: """
          struct Test {
            subscript(x: Int) -> Bool {
              1️⃣return false
            }
          }

          struct Test {
            subscript(x: Int) -> Bool {
              get {
                2️⃣return false
              }
              set { }
            }
          }
        """,
      expected: """
          struct Test {
            subscript(x: Int) -> Bool {
              false
            }
          }

          struct Test {
            subscript(x: Int) -> Bool {
              get {
                false
              }
              set { }
            }
          }
        """,
      findings: [
        FindingSpec("1️⃣", message: "'return' can be omitted because body consists of a single expression"),
        FindingSpec("2️⃣", message: "'return' can be omitted because body consists of a single expression"),
      ]
    )
  }

  @Test func omitReturnInComputedVars() {
    assertFormatting(
      RedundantReturn.self,
      input: """
          var x: Int {
            1️⃣return 42
          }

          struct Test {
            var x: Int {
              get {
                2️⃣return 42
              }
              set { }
            }
          }
        """,
      expected: """
          var x: Int {
            42
          }

          struct Test {
            var x: Int {
              get {
                42
              }
              set { }
            }
          }
        """,
      findings: [
        FindingSpec("1️⃣", message: "'return' can be omitted because body consists of a single expression"),
        FindingSpec("2️⃣", message: "'return' can be omitted because body consists of a single expression"),
      ]
    )
  }

  @Test func inVariableBindings() {
    assertFormatting(
      RedundantReturn.self,
      input: """
          var f = l.filter { 1️⃣return $0.a != o }
          var bar = l.filter {
            2️⃣return $0.a != o
          }
        """,
      expected: """
          var f = l.filter { $0.a != o }
          var bar = l.filter {
            $0.a != o
          }
        """,
      findings: [
        FindingSpec("1️⃣", message: "'return' can be omitted because body consists of a single expression"),
        FindingSpec("2️⃣", message: "'return' can be omitted because body consists of a single expression"),
      ]
    )
  }

  @Test func inVariableBindingWithTrailingTrivia() {
    assertFormatting(
      RedundantReturn.self,
      input: """
          var f = l.filter {
            1️⃣return $0.a != o // comment
          }
        """,
      expected: """
          var f = l.filter {
            $0.a != o // comment
          }
        """,
      findings: [
        FindingSpec("1️⃣", message: "'return' can be omitted because body consists of a single expression")
      ]
    )
  }

  // MARK: - Multi-branch implicit returns (SE-0380)

  @Test
  func switchInClosure() {
    assertFormatting(
      RedundantReturn.self,
      input: """
          val.contains {
            switch $0 {
            case .a, .b:
              1️⃣return true
            default:
              2️⃣return false
            }
          }
        """,
      expected: """
          val.contains {
            switch $0 {
            case .a, .b:
              true
            default:
              false
            }
          }
        """,
      findings: [
        FindingSpec("1️⃣", message: "'return' can be omitted because body consists of a single expression"),
        FindingSpec("2️⃣", message: "'return' can be omitted because body consists of a single expression"),
      ]
    )
  }

  @Test
  func switchInComputedProperty() {
    assertFormatting(
      RedundantReturn.self,
      input: """
          var x: Bool {
            switch self {
            case .a:
              1️⃣return true
            case .b:
              2️⃣return false
            }
          }
        """,
      expected: """
          var x: Bool {
            switch self {
            case .a:
              true
            case .b:
              false
            }
          }
        """,
      findings: [
        FindingSpec("1️⃣", message: "'return' can be omitted because body consists of a single expression"),
        FindingSpec("2️⃣", message: "'return' can be omitted because body consists of a single expression"),
      ]
    )
  }

  @Test
  func ifElseInFunction() {
    assertFormatting(
      RedundantReturn.self,
      input: """
          func f(_ x: Bool) -> Int {
            if x {
              1️⃣return 1
            } else {
              2️⃣return 2
            }
          }
        """,
      expected: """
          func f(_ x: Bool) -> Int {
            if x {
              1
            } else {
              2
            }
          }
        """,
      findings: [
        FindingSpec("1️⃣", message: "'return' can be omitted because body consists of a single expression"),
        FindingSpec("2️⃣", message: "'return' can be omitted because body consists of a single expression"),
      ]
    )
  }

  @Test
  func ifElseIfElseChain() {
    assertFormatting(
      RedundantReturn.self,
      input: """
          func f(_ x: Int) -> String {
            if x > 0 {
              1️⃣return "positive"
            } else if x < 0 {
              2️⃣return "negative"
            } else {
              3️⃣return "zero"
            }
          }
        """,
      expected: """
          func f(_ x: Int) -> String {
            if x > 0 {
              "positive"
            } else if x < 0 {
              "negative"
            } else {
              "zero"
            }
          }
        """,
      findings: [
        FindingSpec("1️⃣", message: "'return' can be omitted because body consists of a single expression"),
        FindingSpec("2️⃣", message: "'return' can be omitted because body consists of a single expression"),
        FindingSpec("3️⃣", message: "'return' can be omitted because body consists of a single expression"),
      ]
    )
  }

  @Test
  func nestedSwitchInIf() {
    assertFormatting(
      RedundantReturn.self,
      input: """
          func f(_ x: Bool, _ y: E) -> Int {
            if x {
              switch y {
              case .a:
                1️⃣return 1
              case .b:
                2️⃣return 2
              }
            } else {
              3️⃣return 0
            }
          }
        """,
      expected: """
          func f(_ x: Bool, _ y: E) -> Int {
            if x {
              switch y {
              case .a:
                1
              case .b:
                2
              }
            } else {
              0
            }
          }
        """,
      findings: [
        FindingSpec("1️⃣", message: "'return' can be omitted because body consists of a single expression"),
        FindingSpec("2️⃣", message: "'return' can be omitted because body consists of a single expression"),
        FindingSpec("3️⃣", message: "'return' can be omitted because body consists of a single expression"),
      ]
    )
  }

  @Test
  func switchInExplicitGetter() {
    assertFormatting(
      RedundantReturn.self,
      input: """
          struct S {
            var x: Int {
              get {
                switch self.kind {
                case .a:
                  1️⃣return 1
                default:
                  2️⃣return 0
                }
              }
              set { }
            }
          }
        """,
      expected: """
          struct S {
            var x: Int {
              get {
                switch self.kind {
                case .a:
                  1
                default:
                  0
                }
              }
              set { }
            }
          }
        """,
      findings: [
        FindingSpec("1️⃣", message: "'return' can be omitted because body consists of a single expression"),
        FindingSpec("2️⃣", message: "'return' can be omitted because body consists of a single expression"),
      ]
    )
  }

  @Test
  func ifWithoutElseNotTransformed() {
    assertFormatting(
      RedundantReturn.self,
      input: """
          func f(_ x: Bool) -> Int {
            if x {
              return 1
            }
            return 0
          }
        """,
      expected: """
          func f(_ x: Bool) -> Int {
            if x {
              return 1
            }
            return 0
          }
        """,
      findings: []
    )
  }

  @Test
  func switchWithNonReturnBranchNotTransformed() {
    assertFormatting(
      RedundantReturn.self,
      input: """
          func f(_ x: E) -> Int {
            switch x {
            case .a:
              return 1
            case .b:
              print("b")
            }
          }
        """,
      expected: """
          func f(_ x: E) -> Int {
            switch x {
            case .a:
              return 1
            case .b:
              print("b")
            }
          }
        """,
      findings: []
    )
  }

  @Test
  func multiStatementBranchNotTransformed() {
    assertFormatting(
      RedundantReturn.self,
      input: """
          func f(_ x: Bool) -> Int {
            if x {
              print("yes")
              return 1
            } else {
              return 2
            }
          }
        """,
      expected: """
          func f(_ x: Bool) -> Int {
            if x {
              print("yes")
              return 1
            } else {
              return 2
            }
          }
        """,
      findings: []
    )
  }
}
