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

import Swiftiomatic
import Testing

@Suite
struct PatternBindingTests: PrettyPrintTesting {
  @Test func bindingIncludingTypeAnnotation() {
    let input =
      """
      let someObject: Foo = object
      let someObject: (foo: Foo, bar: SomeVeryLongTypeNameThatDefinitelyBreaks, baz: Baz) = foo(a, b, c, d)
      """

    let expected =
      """
      let someObject: Foo = object
      let someObject:
        (
          foo: Foo,
          bar:
            SomeVeryLongTypeNameThatDefinitelyBreaks,
          baz: Baz
        ) = foo(a, b, c, d)

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  @Test func ignoresDiscretionaryNewlineAfterColon() {
    let input =
      """
      let someObject:
        Foo = object
      let someObject:
        Foo = longerObjectName
      """

    let expected =
      """
      let someObject: Foo = object
      let someObject: Foo =
        longerObjectName

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 28)
  }

  @Test func groupingIncludesTrailingComma() {
    let input =
      """
      let foo =  veryLongCondition
        ? firstOption
        : secondOption,
        bar = bar()
      """

    let expected =
      """
      let
        foo =
          veryLongCondition
          ? firstOption
          : secondOption,
        bar = bar()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 18)
  }
}
