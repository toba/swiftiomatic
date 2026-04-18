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

@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct DoNotUseSemicolonsTests: RuleTesting {
  @Test func semicolonUse() {
    assertFormatting(
      NoSemicolons.self,
      input: """
        print("hello")1️⃣; print("goodbye")2️⃣;
        print("3")
        """,
      expected: """
        print("hello")
        print("goodbye")
        print("3")
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove ';' and move the next statement to a new line"),
        FindingSpec("2️⃣", message: "remove ';'"),
      ]
    )
  }

  @Test func semicolonsInNestedStatements() {
    assertFormatting(
      NoSemicolons.self,
      input: """
        guard let someVar = Optional(items.filter ({ a in foo(a)1️⃣; return true2️⃣; })) else {
          items.forEach { a in foo(a)3️⃣; }4️⃣; return5️⃣;
        }
        """,
      // The formatting in the expected output is unappealing, but that is fixed by the pretty
      // printer and isn't a concern for the format rule.
      expected: """
        guard let someVar = Optional(items.filter ({ a in foo(a)
        return true })) else {
          items.forEach { a in foo(a) }
        return
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove ';' and move the next statement to a new line"),
        FindingSpec("2️⃣", message: "remove ';'"),
        FindingSpec("3️⃣", message: "remove ';'"),
        FindingSpec("4️⃣", message: "remove ';' and move the next statement to a new line"),
        FindingSpec("5️⃣", message: "remove ';'"),
      ]
    )
  }

  @Test func semicolonsInMemberLists() {
    assertFormatting(
      NoSemicolons.self,
      input: """
        struct Foo {
          func foo() {
            code()
          }1️⃣;

          let someVar = 52️⃣;let someOtherVar = 63️⃣;
        }
        """,
      expected: """
        struct Foo {
          func foo() {
            code()
          }

          let someVar = 5
        let someOtherVar = 6
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove ';'"),
        FindingSpec("2️⃣", message: "remove ';' and move the next statement to a new line"),
        FindingSpec("3️⃣", message: "remove ';'"),
      ]
    )
  }

  @Test func newlinesAfterSemicolons() {
    assertFormatting(
      NoSemicolons.self,
      input: """
        print("hello")1️⃣;
        /// This is a doc comment for printing "goodbye".
        print("goodbye")2️⃣;

        /// This is a doc comment for printing "3".
        print("3")3️⃣;

        print("4")4️⃣; /** Inline comment. */ print("5")5️⃣;

        print("6")6️⃣;  // This is an important statement.
        print("7")7️⃣;
        """,
      expected: """
        print("hello")
        /// This is a doc comment for printing "goodbye".
        print("goodbye")

        /// This is a doc comment for printing "3".
        print("3")

        print("4")
        /** Inline comment. */ print("5")

        print("6")  // This is an important statement.
        print("7")
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove ';'"),
        FindingSpec("2️⃣", message: "remove ';'"),
        FindingSpec("3️⃣", message: "remove ';'"),
        FindingSpec("4️⃣", message: "remove ';' and move the next statement to a new line"),
        FindingSpec("5️⃣", message: "remove ';'"),
        FindingSpec("6️⃣", message: "remove ';'"),
        FindingSpec("7️⃣", message: "remove ';'"),
      ]
    )
  }

  @Test func blockCommentAtEndOfBlock() {
    assertFormatting(
      NoSemicolons.self,
      input: """
        print("hello")1️⃣; /* block comment */
        """,
      expected: """
        print("hello") /* block comment */
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove ';'")
      ]
    )

    assertFormatting(
      NoSemicolons.self,
      input: """
        if x {
          print("hello")1️⃣; /* block comment */
        }
        """,
      expected: """
        if x {
          print("hello") /* block comment */
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove ';'")
      ]
    )
  }

  @Test func blockCommentAfterSemicolonPrecedingOtherStatement() {
    assertFormatting(
      NoSemicolons.self,
      input: """
        print("hello")1️⃣; /* block comment */ print("world")
        """,
      expected: """
        print("hello")
        /* block comment */ print("world")
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove ';' and move the next statement to a new line")
      ]
    )

    assertFormatting(
      NoSemicolons.self,
      input: """
        if x {
          print("hello")1️⃣; /* block comment */
        }
        """,
      expected: """
        if x {
          print("hello") /* block comment */
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove ';'")
      ]
    )
  }

  @Test func semicolonsSeparatingDoWhile() {
    assertFormatting(
      NoSemicolons.self,
      input: """
        do { f() };
        while someCondition { g() }

        do {
          f()
        };

        // Comment and whitespace separating blocks.
        while someCondition {
          g()
        }

        do { f() }1️⃣;
        for _ in 0..<10 { g() }
        """,
      expected: """
        do { f() };
        while someCondition { g() }

        do {
          f()
        };

        // Comment and whitespace separating blocks.
        while someCondition {
          g()
        }

        do { f() }
        for _ in 0..<10 { g() }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove ';'")
      ]
    )
  }
}
