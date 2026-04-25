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
struct NewlineTests: LayoutTesting {
  @Test func leadingNewlines() {
    let input =
      """


      let a = 123
      """

    let expected =
      """
      let a = 123

      """

    assertLayout(input: input, expected: expected, linelength: 45)
  }

  @Test func leadingNewlinesWithComments() {
    let input =
      """


      // Comment

      let a = 123
      """

    let expected =
      """
      // Comment

      let a = 123

      """

    assertLayout(input: input, expected: expected, linelength: 45)
  }

  @Test func trailingNewlines() {
    let input =
      """
      let a = 123


      """

    let expected =
      """
      let a = 123

      """

    assertLayout(input: input, expected: expected, linelength: 45)
  }

  @Test func trailingNewlinesWithComments() {
    let input =
      """
      let a = 123

      // Comment


      """

    let expected =
      """
      let a = 123

      // Comment

      """

    assertLayout(input: input, expected: expected, linelength: 45)
  }

  @Test func newlinesBetweenMembers() {
    let input =
      """


      class MyClazz {

        lazy var memberView: UIView = {
          let view = UIView()
          return view
        }()


        func doSomething() {
          print("!")
        }


        func doSomethingElse() {
          print("else!")
        }


        let constMember = 1



      }
      """

    let expected =
      """
      class MyClazz {
        lazy var memberView: UIView = {
          let view = UIView()
          return view
        }()

        func doSomething() {
          print("!")
        }

        func doSomethingElse() {
          print("else!")
        }

        let constMember = 1
      }

      """

    assertLayout(input: input, expected: expected, linelength: 100)
  }
}
