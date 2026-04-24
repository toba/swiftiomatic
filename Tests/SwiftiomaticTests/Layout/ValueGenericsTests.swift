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

@_spi(ExperimentalLanguageFeatures) import SwiftParser
import Testing

@Suite
struct ValueGenericsTests: LayoutTesting {
  @Test func valueGenericDeclaration() {
    let input = "struct Foo<let n: Int> { static let bar = n }"
    let expected = """
      struct Foo<
        let n: Int
      > {
        static let bar = n
      }

      """
    assertLayout(
      input: input,
      expected: expected,
      linelength: 20
    )
  }

  @Test func valueGenericTypeUsage() {
    let input =
      """
      let v1: Vector<100, Int>
      let v2 = Vector<100, Int>()
      """
    let expected = """
      let v1:
        Vector<
          100, Int
        >
      let v2 =
        Vector<
          100, Int
        >()

      """
    assertLayout(
      input: input,
      expected: expected,
      linelength: 15
    )
  }
}
