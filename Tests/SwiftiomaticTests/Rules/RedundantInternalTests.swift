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
struct RedundantInternalTests: RuleTesting {
  @Test func functionDecl() {
    assertFormatting(
      RedundantInternal.self,
      input: """
        1️⃣internal func foo() {}
        """,
      expected: """
        func foo() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func classDecl() {
    assertFormatting(
      RedundantInternal.self,
      input: """
        1️⃣internal class Foo {}
        """,
      expected: """
        class Foo {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func structDecl() {
    assertFormatting(
      RedundantInternal.self,
      input: """
        1️⃣internal struct Foo {}
        """,
      expected: """
        struct Foo {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func enumDecl() {
    assertFormatting(
      RedundantInternal.self,
      input: """
        1️⃣internal enum Foo {}
        """,
      expected: """
        enum Foo {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func variableDecl() {
    assertFormatting(
      RedundantInternal.self,
      input: """
        1️⃣internal var x = 1
        """,
      expected: """
        var x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func typealiasDecl() {
    assertFormatting(
      RedundantInternal.self,
      input: """
        1️⃣internal typealias Foo = Int
        """,
      expected: """
        typealias Foo = Int
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func protocolDecl() {
    assertFormatting(
      RedundantInternal.self,
      input: """
        1️⃣internal protocol Foo {}
        """,
      expected: """
        protocol Foo {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func initializerDecl() {
    assertFormatting(
      RedundantInternal.self,
      input: """
        struct Foo {
          1️⃣internal init() {}
        }
        """,
      expected: """
        struct Foo {
          init() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func internalWithOtherModifiers() {
    assertFormatting(
      RedundantInternal.self,
      input: """
        1️⃣internal final class Foo {}
        """,
      expected: """
        final class Foo {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func publicIsNotModified() {
    assertFormatting(
      RedundantInternal.self,
      input: """
        public func foo() {}
        """,
      expected: """
        public func foo() {}
        """,
      findings: []
    )
  }

  @Test func privateIsNotModified() {
    assertFormatting(
      RedundantInternal.self,
      input: """
        private func foo() {}
        """,
      expected: """
        private func foo() {}
        """,
      findings: []
    )
  }

  @Test func noAccessLevelIsNotModified() {
    assertFormatting(
      RedundantInternal.self,
      input: """
        func foo() {}
        """,
      expected: """
        func foo() {}
        """,
      findings: []
    )
  }

  @Test func internalSetIsNotModified() {
    assertFormatting(
      RedundantInternal.self,
      input: """
        public internal(set) var x = 1
        """,
      expected: """
        public internal(set) var x = 1
        """,
      findings: []
    )
  }

  @Test func preservesLeadingComment() {
    assertFormatting(
      RedundantInternal.self,
      input: """
        /// A function.
        1️⃣internal func foo() {}
        """,
      expected: """
        /// A function.
        func foo() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func memberInsideClass() {
    assertFormatting(
      RedundantInternal.self,
      input: """
        public class Foo {
          1️⃣internal func bar() {}
          2️⃣internal var x = 1
        }
        """,
      expected: """
        public class Foo {
          func bar() {}
          var x = 1
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
        FindingSpec("2️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }
}
