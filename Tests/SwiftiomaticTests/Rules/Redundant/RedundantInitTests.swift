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
struct RedundantInitTests: RuleTesting {
  @Test func basicInit() {
    assertFormatting(
      RedundantInit.self,
      input: """
        let x = Foo1️⃣.init()
        """,
      expected: """
        let x = Foo()
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit '.init'; call the type directly"),
      ]
    )
  }

  @Test func initWithArguments() {
    assertFormatting(
      RedundantInit.self,
      input: """
        let x = Foo1️⃣.init(bar: 1, baz: 2)
        """,
      expected: """
        let x = Foo(bar: 1, baz: 2)
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit '.init'; call the type directly"),
      ]
    )
  }

  @Test func qualifiedTypeInit() {
    assertFormatting(
      RedundantInit.self,
      input: """
        let x = Foundation.URL1️⃣.init(string: "https://example.com")
        """,
      expected: """
        let x = Foundation.URL(string: "https://example.com")
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit '.init'; call the type directly"),
      ]
    )
  }

  @Test func dotInitShorthandNotModified() {
    assertFormatting(
      RedundantInit.self,
      input: """
        let x: Foo = .init(bar: 1)
        """,
      expected: """
        let x: Foo = .init(bar: 1)
        """,
      findings: []
    )
  }

  @Test func directCallNotModified() {
    assertFormatting(
      RedundantInit.self,
      input: """
        let x = Foo()
        """,
      expected: """
        let x = Foo()
        """,
      findings: []
    )
  }

  @Test func methodCallNotModified() {
    assertFormatting(
      RedundantInit.self,
      input: """
        let x = foo.bar()
        """,
      expected: """
        let x = foo.bar()
        """,
      findings: []
    )
  }

  @Test func chainedFunctionCallInitNotModified() {
    assertFormatting(
      RedundantInit.self,
      input: """
        let x = foo().init()
        """,
      expected: """
        let x = foo().init()
        """,
      findings: []
    )
  }
}
