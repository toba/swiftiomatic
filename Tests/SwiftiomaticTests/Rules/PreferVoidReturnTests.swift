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
struct ReturnVoidInsteadOfEmptyTupleTests: RuleTesting {
  @Test func basic() {
    assertFormatting(
      PreferVoidReturn.self,
      input: """
        let callback: () -> 1️⃣()
        typealias x = Int -> 2️⃣()
        func y() -> Int -> 3️⃣() { return }
        func z(d: Bool -> 4️⃣()) {}
        """,
      expected: """
        let callback: () -> Void
        typealias x = Int -> Void
        func y() -> Int -> Void { return }
        func z(d: Bool -> Void) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("2️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("3️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("4️⃣", message: "replace '()' with 'Void'"),
      ]
    )
  }

  @Test func nestedFunctionTypes() {
    assertFormatting(
      PreferVoidReturn.self,
      input: """
        typealias Nested1 = (() -> 1️⃣()) -> Int
        typealias Nested2 = (() -> 2️⃣()) -> 3️⃣()
        typealias Nested3 = Int -> (() -> 4️⃣())
        """,
      expected: """
        typealias Nested1 = (() -> Void) -> Int
        typealias Nested2 = (() -> Void) -> Void
        typealias Nested3 = Int -> (() -> Void)
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("2️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("3️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("4️⃣", message: "replace '()' with 'Void'"),
      ]
    )
  }

  @Test func closureSignatures() {
    assertFormatting(
      PreferVoidReturn.self,
      input: """
        callWithTrailingClosure(arg) { arg -> 1️⃣() in body }
        callWithTrailingClosure(arg) { arg -> 2️⃣() in
          nestedCallWithTrailingClosure(arg) { arg -> 3️⃣() in
            body
          }
        }
        callWithTrailingClosure(arg) { (arg: () -> 4️⃣()) -> Int in body }
        callWithTrailingClosure(arg) { (arg: () -> 5️⃣()) -> 6️⃣() in body }
        """,
      expected: """
        callWithTrailingClosure(arg) { arg -> Void in body }
        callWithTrailingClosure(arg) { arg -> Void in
          nestedCallWithTrailingClosure(arg) { arg -> Void in
            body
          }
        }
        callWithTrailingClosure(arg) { (arg: () -> Void) -> Int in body }
        callWithTrailingClosure(arg) { (arg: () -> Void) -> Void in body }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("2️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("3️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("4️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("5️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("6️⃣", message: "replace '()' with 'Void'"),
      ]
    )
  }

  @Test func triviaPreservation() {
    assertFormatting(
      PreferVoidReturn.self,
      input: """
        let callback: () -> /*foo*/1️⃣()/*bar*/
        let callback: ((Int) ->   /*foo*/   2️⃣()   /*bar*/) -> 3️⃣()
        """,
      expected: """
        let callback: () -> /*foo*/Void/*bar*/
        let callback: ((Int) ->   /*foo*/   Void   /*bar*/) -> Void
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("2️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("3️⃣", message: "replace '()' with 'Void'"),
      ]
    )
  }

  @Test func emptyTupleWithInternalCommentsIsDiagnosedButNotReplaced() {
    assertFormatting(
      PreferVoidReturn.self,
      input: """
        let callback: () -> 1️⃣( )
        let callback: () -> 2️⃣(\t)
        let callback: () -> 3️⃣(
        )
        let callback: () -> 4️⃣( /* please don't change me! */ )
        let callback: () -> 5️⃣( /** please don't change me! */ )
        let callback: () -> 6️⃣(
          // don't change me either!
        )
        let callback: () -> 7️⃣(
          /// don't change me either!
        )
        let callback: () -> 8️⃣(\u{feff})

        let callback: (() -> 9️⃣()) -> 🔟( /* please don't change me! */ )
        callWithTrailingClosure(arg) { (arg: () -> 0️⃣()) -> ℹ️( /* no change */ ) in body }
        """,
      expected: """
        let callback: () -> Void
        let callback: () -> Void
        let callback: () -> Void
        let callback: () -> ( /* please don't change me! */ )
        let callback: () -> ( /** please don't change me! */ )
        let callback: () -> (
          // don't change me either!
        )
        let callback: () -> (
          /// don't change me either!
        )
        let callback: () -> (\u{feff})

        let callback: (() -> Void) -> ( /* please don't change me! */ )
        callWithTrailingClosure(arg) { (arg: () -> Void) -> ( /* no change */ ) in body }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("2️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("3️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("4️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("5️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("6️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("7️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("8️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("9️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("🔟", message: "replace '()' with 'Void'"),
        FindingSpec("0️⃣", message: "replace '()' with 'Void'"),
        FindingSpec("ℹ️", message: "replace '()' with 'Void'"),
      ]
    )
  }
}
