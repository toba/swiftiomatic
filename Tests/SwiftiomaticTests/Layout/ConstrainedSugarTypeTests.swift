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

import Testing
@Suite
struct ConstrainedSugarTypeTests: LayoutTesting {
  @Test func someTypes() {
    let input =
      """
      var body: some View
      func foo() -> some Foo
      """

    assertLayout(input: input, expected: input + "\n", linelength: 25)

    let expected11 =
      """
      var body:
        some View
      func foo()
        -> some Foo

      """
    assertLayout(input: input, expected: expected11, linelength: 11)
  }

  @Test func anyTypes() {
    let input =
      """
      var body: any View
      func foo() -> any Foo
      """

    assertLayout(input: input, expected: input + "\n", linelength: 25)

    let expected11 =
      """
      var body:
        any View
      func foo()
        -> any Foo

      """
    assertLayout(input: input, expected: expected11, linelength: 11)
  }
}
