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
struct DropRedundantOptionalBindingTests: RuleTesting {
  @Test func ifLetBasic() {
    assertFormatting(
      DropRedundantOptionalBinding.self,
      input: """
        if let x 1️⃣= x {
          print(x)
        }
        """,
      expected: """
        if let x {
          print(x)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax 'let x' instead of 'let x = x'"),
      ]
    )
  }

  @Test func guardLetBasic() {
    assertFormatting(
      DropRedundantOptionalBinding.self,
      input: """
        guard let value 1️⃣= value else { return }
        """,
      expected: """
        guard let value else { return }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax 'let value' instead of 'let value = value'"),
      ]
    )
  }

  @Test func whileLetBasic() {
    assertFormatting(
      DropRedundantOptionalBinding.self,
      input: """
        while let item 1️⃣= item {
          process(item)
        }
        """,
      expected: """
        while let item {
          process(item)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax 'let item' instead of 'let item = item'"),
      ]
    )
  }

  @Test func differentNamesNotModified() {
    assertFormatting(
      DropRedundantOptionalBinding.self,
      input: """
        if let x = y {
          print(x)
        }
        """,
      expected: """
        if let x = y {
          print(x)
        }
        """,
      findings: []
    )
  }

  @Test func memberAccessNotModified() {
    assertFormatting(
      DropRedundantOptionalBinding.self,
      input: """
        if let x = self.x {
          print(x)
        }
        """,
      expected: """
        if let x = self.x {
          print(x)
        }
        """,
      findings: []
    )
  }

  @Test func functionCallNotModified() {
    assertFormatting(
      DropRedundantOptionalBinding.self,
      input: """
        if let x = foo() {
          print(x)
        }
        """,
      expected: """
        if let x = foo() {
          print(x)
        }
        """,
      findings: []
    )
  }

  @Test func withTypeAnnotationNotModified() {
    assertFormatting(
      DropRedundantOptionalBinding.self,
      input: """
        if let x: Int = x {
          print(x)
        }
        """,
      expected: """
        if let x: Int = x {
          print(x)
        }
        """,
      findings: []
    )
  }

  @Test func shorthandAlreadyNotModified() {
    assertFormatting(
      DropRedundantOptionalBinding.self,
      input: """
        if let x {
          print(x)
        }
        """,
      expected: """
        if let x {
          print(x)
        }
        """,
      findings: []
    )
  }

  @Test func multipleBindings() {
    assertFormatting(
      DropRedundantOptionalBinding.self,
      input: """
        if let a 1️⃣= a, let b = c, let d 2️⃣= d {
          print(a, b, d)
        }
        """,
      expected: """
        if let a, let b = c, let d {
          print(a, b, d)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax 'let a' instead of 'let a = a'"),
        FindingSpec("2️⃣", message: "use shorthand syntax 'let d' instead of 'let d = d'"),
      ]
    )
  }

  @Test func varBindingNotModified() {
    assertFormatting(
      DropRedundantOptionalBinding.self,
      input: """
        if var x 1️⃣= x {
          x = 42
        }
        """,
      expected: """
        if var x {
          x = 42
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax 'let x' instead of 'let x = x'"),
      ]
    )
  }
}
