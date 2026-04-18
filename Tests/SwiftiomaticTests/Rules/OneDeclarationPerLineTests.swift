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
struct OneDeclarationPerLineTests: RuleTesting {

  // MARK: - Enum cases

  // The inconsistent leading whitespace in the expected text is intentional. This transform does
  // not attempt to preserve leading indentation since the pretty printer will correct it when
  // running the full formatter.

  @Test func invalidCasesOnLine() {
    assertFormatting(
      OneDeclarationPerLine.self,
      input: """
        public enum Token {
          case arrow
          case comma, 1️⃣identifier(String), semicolon, 2️⃣stringSegment(String)
          case period
          case 3️⃣ifKeyword(String), 4️⃣forKeyword(String)
          indirect case guardKeyword, elseKeyword, 5️⃣contextualKeyword(String)
          var x: Bool
          case leftParen, 6️⃣rightParen = ")", leftBrace, 7️⃣rightBrace = "}"
        }
        """,
      expected: """
        public enum Token {
          case arrow
          case comma
        case identifier(String)
        case semicolon
        case stringSegment(String)
          case period
          case ifKeyword(String)
        case forKeyword(String)
          indirect case guardKeyword, elseKeyword
        indirect case contextualKeyword(String)
          var x: Bool
          case leftParen
        case rightParen = ")"
        case leftBrace
        case rightBrace = "}"
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'identifier' to its own 'case' declaration"),
        FindingSpec("2️⃣", message: "move 'stringSegment' to its own 'case' declaration"),
        FindingSpec("3️⃣", message: "move 'ifKeyword' to its own 'case' declaration"),
        FindingSpec("4️⃣", message: "move 'forKeyword' to its own 'case' declaration"),
        FindingSpec("5️⃣", message: "move 'contextualKeyword' to its own 'case' declaration"),
        FindingSpec("6️⃣", message: "move 'rightParen' to its own 'case' declaration"),
        FindingSpec("7️⃣", message: "move 'rightBrace' to its own 'case' declaration"),
      ]
    )
  }

  @Test func elementOrderIsPreserved() {
    assertFormatting(
      OneDeclarationPerLine.self,
      input: """
        enum Foo: Int {
          case 1️⃣a = 0, b, c, d
        }
        """,
      expected: """
        enum Foo: Int {
          case a = 0
        case b, c, d
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'a' to its own 'case' declaration")
      ]
    )
  }

  @Test func commentsAreNotRepeated() {
    assertFormatting(
      OneDeclarationPerLine.self,
      input: """
        enum Foo: Int {
          /// This should only be above `a`.
          case 1️⃣a = 0, b, c, d
          // This should only be above `e`.
          case e, 2️⃣f = 100
        }
        """,
      expected: """
        enum Foo: Int {
          /// This should only be above `a`.
          case a = 0
        case b, c, d
          // This should only be above `e`.
          case e
        case f = 100
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'a' to its own 'case' declaration"),
        FindingSpec("2️⃣", message: "move 'f' to its own 'case' declaration"),
      ]
    )
  }

  @Test func attributesArePropagated() {
    assertFormatting(
      OneDeclarationPerLine.self,
      input: """
        enum Foo {
          @someAttr case 1️⃣a(String), b, c, d
          case e, 2️⃣f(Int)
          @anotherAttr case g, 3️⃣h(Float)
        }
        """,
      expected: """
        enum Foo {
          @someAttr case a(String)
        @someAttr case b, c, d
          case e
        case f(Int)
          @anotherAttr case g
        @anotherAttr case h(Float)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'a' to its own 'case' declaration"),
        FindingSpec("2️⃣", message: "move 'f' to its own 'case' declaration"),
        FindingSpec("3️⃣", message: "move 'h' to its own 'case' declaration"),
      ]
    )
  }

  // MARK: - Variable declarations

  @Test func multipleVariableBindings() {
    assertFormatting(
      OneDeclarationPerLine.self,
      input: """
        1️⃣var a = 0, b = 2, (c, d) = (0, "h")
        2️⃣let e = 0, f = 2, (g, h) = (0, "h")
        var x: Int { return 3 }
        3️⃣let a, b, c: Int
        4️⃣var j: Int, k: String, l: Float
        """,
      expected: """
        var a = 0
        var b = 2
        var (c, d) = (0, "h")
        let e = 0
        let f = 2
        let (g, h) = (0, "h")
        var x: Int { return 3 }
        let a: Int
        let b: Int
        let c: Int
        var j: Int
        var k: String
        var l: Float
        """,
      findings: [
        FindingSpec("1️⃣", message: "split this variable declaration to introduce only one variable per 'var'"),
        FindingSpec("2️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("3️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("4️⃣", message: "split this variable declaration to introduce only one variable per 'var'"),
      ]
    )
  }

  @Test func nestedVariableBindings() {
    assertFormatting(
      OneDeclarationPerLine.self,
      input: """
        var x: Int = {
          1️⃣let y = 5, z = 10
          return z
        }()

        func foo() {
          2️⃣let x = 4, y = 10
        }

        var x: Int {
          3️⃣let y = 5, z = 10
          return z
        }

        var a: String = "foo" {
          didSet {
            4️⃣let b, c: Bool
          }
        }

        5️⃣let
          a: Int = {
            6️⃣let p = 10, q = 20
            return p * q
          }(),
          b: Int = {
            7️⃣var s: Int, t: Double
            return 20
          }()
        """,
      expected: """
        var x: Int = {
          let y = 5
        let z = 10
          return z
        }()

        func foo() {
          let x = 4
        let y = 10
        }

        var x: Int {
          let y = 5
        let z = 10
          return z
        }

        var a: String = "foo" {
          didSet {
            let b: Bool
        let c: Bool
          }
        }

        let
          a: Int = {
            let p = 10
        let q = 20
            return p * q
          }()
        let
          b: Int = {
            var s: Int
        var t: Double
            return 20
          }()
        """,
      findings: [
        FindingSpec("1️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("2️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("3️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("4️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("5️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("6️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("7️⃣", message: "split this variable declaration to introduce only one variable per 'var'"),
      ]
    )
  }

  @Test func mixedInitializedAndTypedBindings() {
    assertFormatting(
      OneDeclarationPerLine.self,
      input: """
        1️⃣var a = 5, b: String
        2️⃣let c: Int, d = "d", e = "e", f: Double
        """,
      expected: """
        var a = 5
        var b: String
        let c: Int
        let d = "d"
        let e = "e"
        let f: Double
        """,
      findings: [
        FindingSpec("1️⃣", message: "split this variable declaration to introduce only one variable per 'var'"),
        FindingSpec("2️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
      ]
    )
  }

  @Test func commentPrecedingDeclIsNotRepeated() {
    assertFormatting(
      OneDeclarationPerLine.self,
      input: """
        // Comment
        1️⃣let a, b, c: Int
        """,
      expected: """
        // Comment
        let a: Int
        let b: Int
        let c: Int
        """,
      findings: [
        FindingSpec("1️⃣", message: "split this variable declaration to introduce only one variable per 'let'")
      ]
    )
  }

  @Test func commentsPrecedingBindingsAreKept() {
    assertFormatting(
      OneDeclarationPerLine.self,
      input: """
        1️⃣let /* a */ a, /* b */ b, /* c */ c: Int
        """,
      expected: """
        let /* a */ a: Int
        let /* b */ b: Int
        let /* c */ c: Int
        """,
      findings: [
        FindingSpec("1️⃣", message: "split this variable declaration to introduce only one variable per 'let'")
      ]
    )
  }

  @Test func invalidBindingsAreNotDestroyed() {
    assertFormatting(
      OneDeclarationPerLine.self,
      input: """
        1️⃣let a, b, c = 5
        2️⃣let d, e
        3️⃣let f, g, h: Int = 5
        4️⃣let a: Int, b, c = 5, d, e: Int
        """,
      expected: """
        let a, b, c = 5
        let d, e
        let f, g, h: Int = 5
        let a: Int
        let b, c = 5
        let d: Int
        let e: Int
        """,
      findings: [
        FindingSpec("1️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("2️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("3️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("4️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
      ]
    )
  }

  @Test func multipleBindingsWithAccessorsAreCorrected() {
    // Swift parses multiple bindings with accessors but forbids them at a later
    // stage. That means that if the individual bindings would be correct in
    // isolation then we can correct them, which is kind of nice.
    assertFormatting(
      OneDeclarationPerLine.self,
      input: """
        1️⃣var x: Int { return 10 }, y = "foo" { didSet { print("changed") } }
        """,
      expected: """
        var x: Int { return 10 }
        var y = "foo" { didSet { print("changed") } }
        """,
      findings: [
        FindingSpec("1️⃣", message: "split this variable declaration to introduce only one variable per 'var'")
      ]
    )
  }
}
