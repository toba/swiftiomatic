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
struct RedundantNilInitTests: RuleTesting {
  @Test func basicOptionalVar() {
    assertFormatting(
      RedundantNilInit.self,
      input: """
        var x: Int? 1️⃣= nil
        """,
      expected: """
        var x: Int?
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '= nil' initializer"),
      ]
    )
  }

  @Test func optionalGenericSyntax() {
    assertFormatting(
      RedundantNilInit.self,
      input: """
        var x: Optional<String> 1️⃣= nil
        """,
      expected: """
        var x: Optional<String>
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '= nil' initializer"),
      ]
    )
  }

  @Test func implicitlyUnwrappedOptional() {
    assertFormatting(
      RedundantNilInit.self,
      input: """
        var x: Int! 1️⃣= nil
        """,
      expected: """
        var x: Int!
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '= nil' initializer"),
      ]
    )
  }

  @Test func letIsNotModified() {
    assertFormatting(
      RedundantNilInit.self,
      input: """
        let x: Int? = nil
        """,
      expected: """
        let x: Int? = nil
        """,
      findings: []
    )
  }

  @Test func nonNilInitializerIsNotModified() {
    assertFormatting(
      RedundantNilInit.self,
      input: """
        var x: Int? = 42
        """,
      expected: """
        var x: Int? = 42
        """,
      findings: []
    )
  }

  @Test func nonOptionalTypeIsNotModified() {
    assertFormatting(
      RedundantNilInit.self,
      input: """
        var x: Int = 0
        """,
      expected: """
        var x: Int = 0
        """,
      findings: []
    )
  }

  @Test func noTypeAnnotationIsNotModified() {
    assertFormatting(
      RedundantNilInit.self,
      input: """
        var x = nil
        """,
      expected: """
        var x = nil
        """,
      findings: []
    )
  }

  @Test func protocolRequirementIsNotModified() {
    assertFormatting(
      RedundantNilInit.self,
      input: """
        protocol P {
          var x: Int? { get }
        }
        """,
      expected: """
        protocol P {
          var x: Int? { get }
        }
        """,
      findings: []
    )
  }

  @Test func classProperty() {
    assertFormatting(
      RedundantNilInit.self,
      input: """
        class Foo {
          var name: String? 1️⃣= nil
        }
        """,
      expected: """
        class Foo {
          var name: String?
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '= nil' initializer"),
      ]
    )
  }

  @Test func multipleBindings() {
    assertFormatting(
      RedundantNilInit.self,
      input: """
        var a: Int? 1️⃣= nil, b: String? 2️⃣= nil
        """,
      expected: """
        var a: Int?, b: String?
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '= nil' initializer"),
        FindingSpec("2️⃣", message: "remove redundant '= nil' initializer"),
      ]
    )
  }
}
