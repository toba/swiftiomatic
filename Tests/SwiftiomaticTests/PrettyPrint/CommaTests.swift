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

import SwiftiomaticKit
import Testing

@Suite
struct CommaTests: PrettyPrintTesting {
  @Test func arrayCommasAbsentEnabled() {
    let input =
      """
      let MyCollection = [
        1,
        2,
        3
      ]

      """

    let expected =
      """
      let MyCollection = [
        1,
        2,
        3,
      ]

      """

    var configuration = Configuration.forTesting
    configuration[MultiElementCollectionTrailingCommas.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test func arrayCommasAbsentDisabled() {
    let input =
      """
      let MyCollection = [
        1,
        2,
        3
      ]

      """

    let expected =
      """
      let MyCollection = [
        1,
        2,
        3
      ]

      """

    var configuration = Configuration.forTesting
    configuration[MultiElementCollectionTrailingCommas.self] = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test func arrayCommasPresentEnabled() {
    let input =
      """
      let MyCollection = [
        1,
        2,
        3,
      ]

      """

    let expected =
      """
      let MyCollection = [
        1,
        2,
        3,
      ]

      """

    var configuration = Configuration.forTesting
    configuration[MultiElementCollectionTrailingCommas.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test func arrayCommasPresentDisabled() {
    let input =
      """
      let MyCollection = [
        1,
        2,
        3,
      ]

      """

    let expected =
      """
      let MyCollection = [
        1,
        2,
        3
      ]

      """

    var configuration = Configuration.forTesting
    configuration[MultiElementCollectionTrailingCommas.self] = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test func arraySingleLineCommasPresentEnabled() {
    let input =
      """
      let MyCollection = [1, 2, 3,]

      """

    // no effect expected
    let expected =
      """
      let MyCollection = [1, 2, 3]

      """

    var configuration = Configuration.forTesting
    configuration[MultiElementCollectionTrailingCommas.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func arraySingleLineCommasPresentDisabled() {
    let input =
      """
      let MyCollection = [1, 2, 3,]

      """

    // no effect expected
    let expected =
      """
      let MyCollection = [1, 2, 3]

      """

    var configuration = Configuration.forTesting
    configuration[MultiElementCollectionTrailingCommas.self] = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func arrayWithCommentCommasPresentEnabled() {
    let input =
      """
      let MyCollection = [
        1,
        2 // some comment
      ]

      """

    let expected =
      """
      let MyCollection = [
        1,
        2,  // some comment
      ]

      """

    var configuration = Configuration.forTesting
    configuration[MultiElementCollectionTrailingCommas.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func arrayWithCommentCommasPresentDisabled() {
    let input =
      """
      let MyCollection = [
        1,
        2 // some comment
      ]

      """

    let expected =
      """
      let MyCollection = [
        1,
        2  // some comment
      ]

      """

    var configuration = Configuration.forTesting
    configuration[MultiElementCollectionTrailingCommas.self] = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func arrayWithTernaryOperatorAndCommentCommasPresentEnabled() {
    let input =
      """
      let MyCollection = [
        1,
        true ? 1 : 2 // some comment
      ]

      """

    let expected =
      """
      let MyCollection = [
        1,
        true ? 1 : 2,  // some comment
      ]

      """

    var configuration = Configuration.forTesting
    configuration[MultiElementCollectionTrailingCommas.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func arrayWithTernaryOperatorAndCommentCommasPresentDisabled() {
    let input =
      """
      let MyCollection = [
        1,
        true ? 1 : 2 // some comment
      ]

      """

    let expected =
      """
      let MyCollection = [
        1,
        true ? 1 : 2  // some comment
      ]

      """

    var configuration = Configuration.forTesting
    configuration[MultiElementCollectionTrailingCommas.self] = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func dictionaryCommasAbsentEnabled() {
    let input =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3
      ]

      """

    let expected =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]

      """

    var configuration = Configuration.forTesting
    configuration[MultiElementCollectionTrailingCommas.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test func dictionaryCommasAbsentDisabled() {
    let input =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3
      ]

      """

    let expected =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3
      ]

      """

    var configuration = Configuration.forTesting
    configuration[MultiElementCollectionTrailingCommas.self] = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test func dictionaryCommasPresentEnabled() {
    let input =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]

      """

    let expected =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]

      """

    var configuration = Configuration.forTesting
    configuration[MultiElementCollectionTrailingCommas.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test func dictionaryCommasPresentDisabled() {
    let input =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]

      """

    let expected =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3
      ]

      """

    var configuration = Configuration.forTesting
    configuration[MultiElementCollectionTrailingCommas.self] = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test func dictionarySingleLineCommasPresentDisabled() {
    let input =
      """
      let MyCollection = ["a": 1, "b": 2, "c": 3,]

      """

    let expected =
      """
      let MyCollection = [
        "a": 1, "b": 2, "c": 3,
      ]

      """

    var configuration = Configuration.forTesting
    configuration[MultiElementCollectionTrailingCommas.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func dictionarySingleLineCommasPresentEnabled() {
    let input =
      """
      let MyCollection = ["a": 1, "b": 2, "c": 3,]

      """

    let expected =
      """
      let MyCollection = [
        "a": 1, "b": 2, "c": 3
      ]

      """

    var configuration = Configuration.forTesting
    configuration[MultiElementCollectionTrailingCommas.self] = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func alwaysTrailingCommasInGenericParameterList() {
    let input =
      """
      struct S<
        T1,
        T2,
        T3
      > {}

      struct S<
        T1,
        T2,
        T3: Foo
      > {}

      """

    let expected =
      """
      struct S<
        T1,
        T2,
        T3,
      > {}

      struct S<
        T1,
        T2,
        T3: Foo,
      > {}

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func alwaysTrailingCommasInTuple() {
    let input =
      """
      let velocity = (
        1.66007664274403694e-03,
        7.69901118419740425e-03,
        6.90460016972063023e-05
      )

      let (
        velocityX,
        velocityY,
        velocityZ
      ) = velocity

      """

    let expected =
      """
      let velocity = (
        1.66007664274403694e-03,
        7.69901118419740425e-03,
        6.90460016972063023e-05,
      )

      let (
        velocityX,
        velocityY,
        velocityZ,
      ) = velocity

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: configuration)
  }

  @Test func alwaysTrailingCommasInFunction() {
    let input =
      """
      func foo(
        input1: Int = 0,
        input2: Int = 0
      ) {}

      func foo(
        input1: Int = 0,
        input2: Int
      ) {}

      func foo(
        input1: Int = 0,
        input2: Int...
      ) {}

      foo(
        input1: 1,
        input2: 1
      )
      """

    let expected =
      """
      func foo(
        input1: Int = 0,
        input2: Int = 0,
      ) {}

      func foo(
        input1: Int = 0,
        input2: Int,
      ) {}

      func foo(
        input1: Int = 0,
        input2: Int...,
      ) {}

      foo(
        input1: 1,
        input2: 1,
      )

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func alwaysTrailingCommasInInitializer() {
    let input =
      """
      struct S {
        init(
          input1: Int = 0,
          input2: Int = 0
        ) {}
      }

      """

    let expected =
      """
      struct S {
        init(
          input1: Int = 0,
          input2: Int = 0,
        ) {}
      }

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func alwaysTrailingCommasInEnumeration() {
    let input =
      """
      enum E {
        case foo(
          input1: Int = 0,
          input2: Int = 0
        )
      }

      enum E {
        case foo(
          input1: Int = 0,
          input2: Int
        )
      }

      """

    let expected =
      """
      enum E {
        case foo(
          input1: Int = 0,
          input2: Int = 0,
        )
      }

      enum E {
        case foo(
          input1: Int = 0,
          input2: Int,
        )
      }

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func alwaysTrailingCommasInAttribute() {
    let input =
      """
      @Foo(
        "input 1",
        "input 2",
        "input 3"
      )
      struct S {}

      """

    let expected =
      """
      @Foo(
        "input 1",
        "input 2",
        "input 3",
      )
      struct S {}

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func alwaysTrailingCommasInMacro() {
    let input =
      """
      struct S {
        #foo(
          "input 1",
          "input 2",
          "input 3"
        )
      }

      """

    let expected =
      """
      struct S {
        #foo(
          "input 1",
          "input 2",
          "input 3",
        )
      }

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func alwaysTrailingCommasInKeyPath() {
    let input =
      #"""
      let value = m[
        x,
        y
      ]

      let keyPath = \Foo.bar[
        x,
        y
      ]

      f(\.[
        x,
        y
      ])

      """#

    let expected =
      #"""
      let value = m[
        x,
        y,
      ]

      let keyPath =
        \Foo.bar[
          x,
          y,
        ]

      f(
        \.[
          x,
          y,
        ])

      """#

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func alwaysTrailingCommasInClosureCapture() {
    let input =
      """
      { 
        [
          capturedValue1,
          capturedValue2
        ] in
      }

      { 
        [
          capturedValue1,
          capturedValue2 = foo 
        ] in
      }

      """

    let expected =
      """
      {
        [
          capturedValue1,
          capturedValue2,
        ] in
      }

      {
        [
          capturedValue1,
          capturedValue2 = foo,
        ] in
      }

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func neverTrailingCommasInGenericParameterList() {
    let input =
      """
      struct S<
        T1,
        T2,
        T3,
      > {}

      struct S<
        T1,
        T2,
        T3: Foo,
      > {}

      """

    let expected =
      """
      struct S<
        T1,
        T2,
        T3
      > {}

      struct S<
        T1,
        T2,
        T3: Foo
      > {}

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func neverTrailingCommasInTuple() {
    let input =
      """
      let velocity = (
        1.66007664274403694e-03,
        7.69901118419740425e-03,
        6.90460016972063023e-05,
      )

      let (
        velocityX,
        velocityY,
        velocityZ,
      ) = velocity

      """

    let expected =
      """
      let velocity = (
        1.66007664274403694e-03,
        7.69901118419740425e-03,
        6.90460016972063023e-05
      )

      let (
        velocityX,
        velocityY,
        velocityZ
      ) = velocity

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: configuration)
  }

  @Test func neverTrailingCommasInFunction() {
    let input =
      """
      func foo(
        input1: Int = 0,
        input2: Int = 0,
      ) {}

      func foo(
        input1: Int = 0,
        input2: Int,
      ) {}

      func foo(
        input1: Int = 0,
        input2: Int...,
      ) {}

      foo(
        input1: 1,
        input2: 1,
      )
      """

    let expected =
      """
      func foo(
        input1: Int = 0,
        input2: Int = 0
      ) {}

      func foo(
        input1: Int = 0,
        input2: Int
      ) {}

      func foo(
        input1: Int = 0,
        input2: Int...
      ) {}

      foo(
        input1: 1,
        input2: 1
      )

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func neverTrailingCommasInInitializer() {
    let input =
      """
      struct S {
        init(
          input1: Int = 0,
          input2: Int = 0,
        ) {}
      }

      """

    let expected =
      """
      struct S {
        init(
          input1: Int = 0,
          input2: Int = 0
        ) {}
      }

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func neverTrailingCommasInEnumeration() {
    let input =
      """
      enum E {
        case foo(
          input1: Int = 0,
          input2: Int = 0,
        )
      }

      enum E {
        case foo(
          input1: Int = 0,
          input2: Int,
        )
      }

      """

    let expected =
      """
      enum E {
        case foo(
          input1: Int = 0,
          input2: Int = 0
        )
      }

      enum E {
        case foo(
          input1: Int = 0,
          input2: Int
        )
      }

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func neverTrailingCommasInAttribute() {
    let input =
      """
      @Foo(
        "input 1",
        "input 2",
        "input 3",
      )
      struct S {}

      """

    let expected =
      """
      @Foo(
        "input 1",
        "input 2",
        "input 3"
      )
      struct S {}

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func neverTrailingCommasInMacro() {
    let input =
      """
      struct S {
        #foo(
          "input 1",
          "input 2",
          "input 3",
        )
      }

      """

    let expected =
      """
      struct S {
        #foo(
          "input 1",
          "input 2",
          "input 3"
        )
      }

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func neverTrailingCommasInKeyPath() {
    let input =
      #"""
      let value = m[
        x,
        y,
      ]

      let keyPath = \Foo.bar[
        x,
        y,
      ]

      f(\.[
        x,
        y,
      ])

      """#

    let expected =
      #"""
      let value = m[
        x,
        y
      ]

      let keyPath =
        \Foo.bar[
          x,
          y
        ]

      f(
        \.[
          x,
          y
        ])

      """#

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func neverTrailingCommasInClosureCapture() {
    let input =
      """
      { 
        [
          capturedValue1,
          capturedValue2,
        ] in
      }

      { 
        [
          capturedValue1,
          capturedValue2 = foo,
        ] in
      }

      """

    let expected =
      """
      {
        [
          capturedValue1,
          capturedValue2
        ] in
      }

      {
        [
          capturedValue1,
          capturedValue2 = foo
        ] in
      }

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test func alwaysMultilineTrailingCommaBehaviorOverridesMultiElementCollectionTrailingCommas() {
    let input =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]

      """

    let expected =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .alwaysUsed
    configuration[MultiElementCollectionTrailingCommas.self] = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test func neverTrailingCommasInMultilineListsOverridesMultiElementCollectionTrailingCommas() {
    let input =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]

      """

    let expected =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3
      ]

      """

    var configuration = Configuration.forTesting
    configuration[MultilineTrailingCommaBehaviorSetting.self] = .neverUsed
    configuration[MultiElementCollectionTrailingCommas.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }
}
