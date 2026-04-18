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
struct RedundantLetErrorTests: RuleTesting {
  @Test func basicRedundantLetError() {
    assertFormatting(
      RedundantLetError.self,
      input: """
        do {
          try foo()
        } catch 1️⃣let error {
          print(error)
        }
        """,
      expected: """
        do {
          try foo()
        } catch {
          print(error)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'let error' from catch clause; 'error' is implicitly available"),
      ]
    )
  }

  @Test func bareCatchIsNotModified() {
    assertFormatting(
      RedundantLetError.self,
      input: """
        do {
          try foo()
        } catch {
          print(error)
        }
        """,
      expected: """
        do {
          try foo()
        } catch {
          print(error)
        }
        """,
      findings: []
    )
  }

  @Test func renamedErrorIsNotModified() {
    assertFormatting(
      RedundantLetError.self,
      input: """
        do {
          try foo()
        } catch let e {
          print(e)
        }
        """,
      expected: """
        do {
          try foo()
        } catch let e {
          print(e)
        }
        """,
      findings: []
    )
  }

  @Test func typedCatchIsNotModified() {
    assertFormatting(
      RedundantLetError.self,
      input: """
        do {
          try foo()
        } catch let error as SomeError {
          print(error)
        }
        """,
      expected: """
        do {
          try foo()
        } catch let error as SomeError {
          print(error)
        }
        """,
      findings: []
    )
  }

  @Test func whereClauseIsNotModified() {
    assertFormatting(
      RedundantLetError.self,
      input: """
        do {
          try foo()
        } catch let error where error is SomeError {
          print(error)
        }
        """,
      expected: """
        do {
          try foo()
        } catch let error where error is SomeError {
          print(error)
        }
        """,
      findings: []
    )
  }

  @Test func enumPatternIsNotModified() {
    assertFormatting(
      RedundantLetError.self,
      input: """
        do {
          try foo()
        } catch MyError.specific {
          print("specific error")
        }
        """,
      expected: """
        do {
          try foo()
        } catch MyError.specific {
          print("specific error")
        }
        """,
      findings: []
    )
  }

  @Test func varErrorIsNotModified() {
    assertFormatting(
      RedundantLetError.self,
      input: """
        do {
          try foo()
        } catch var error {
          error = SomeError()
          print(error)
        }
        """,
      expected: """
        do {
          try foo()
        } catch var error {
          error = SomeError()
          print(error)
        }
        """,
      findings: []
    )
  }
}
