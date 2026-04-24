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
struct AsExprTests: LayoutTesting {
  @Test func withoutPunctuation() throws {
    let input =
      """
      func foo() {
        let a = b as Int
        a = b as Int
        let reallyLongVariableName = x as ReallyLongTypeName
        reallyLongVariableName = x as ReallyLongTypeName
      }
      """

    let expected =
      """
      func foo() {
        let a = b as Int
        a = b as Int
        let reallyLongVariableName = x
          as ReallyLongTypeName
        reallyLongVariableName = x
          as ReallyLongTypeName
      }

      """

    assertLayout(input: input, expected: expected, linelength: 40)
  }

  @Test func withPunctuation() throws {
    let input =
      """
      func foo() {
        let a = b as? Int
        a = b as? Int
        let c = d as! Int
        c = d as! Int
        let reallyLongVariableName = x as? ReallyLongTypeName
        reallyLongVariableName = x as? ReallyLongTypeName
      }
      """

    let expected =
      """
      func foo() {
        let a = b as? Int
        a = b as? Int
        let c = d as! Int
        c = d as! Int
        let reallyLongVariableName = x
          as? ReallyLongTypeName
        reallyLongVariableName = x
          as? ReallyLongTypeName
      }

      """

    assertLayout(input: input, expected: expected, linelength: 40)
  }
}
