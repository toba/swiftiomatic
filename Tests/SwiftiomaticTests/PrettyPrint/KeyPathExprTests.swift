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
struct KeyPathExprTests: PrettyPrintTesting {
  @Test func simple() {
    let input =
      #"""
      let x = \.foo
      let y = \.foo.bar
      let z = a.map(\.foo.bar)
      """#

    let expected =
      #"""
      let x = \.foo
      let y = \.foo.bar
      let z = a.map(\.foo.bar)

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  @Test func withType() {
    let input =
      #"""
      let x = \Type.foo
      let y = \Type.foo.bar
      let z = a.map(\Type.foo.bar)
      """#

    let expected =
      #"""
      let x = \Type.foo
      let y = \Type.foo.bar
      let z = a.map(\Type.foo.bar)

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  @Test func optionalUnwrap() {
    let input =
      #"""
      let x = \.foo?
      let y = \.foo!.bar
      let z = a.map(\.foo!.bar)
      """#

    let expected80 =
      #"""
      let x = \.foo?
      let y = \.foo!.bar
      let z = a.map(\.foo!.bar)

      """#

    assertPrettyPrintEqual(input: input, expected: expected80, linelength: 80)

    let expected11 =
      #"""
      let x =
        \.foo?
      let y =
        \.foo!
        .bar
      let z =
        a.map(
          \.foo!
            .bar)

      """#

    assertPrettyPrintEqual(input: input, expected: expected11, linelength: 11)
  }

  @Test func `subscript`() {
    let input =
      #"""
      let x = \.foo[0]
      let y = \.foo[0].bar
      let z = a.map(\.foo[0].bar)
      """#

    let expected =
      #"""
      let x = \.foo[0]
      let y = \.foo[0].bar
      let z = a.map(\.foo[0].bar)

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  @Test func implicitSelfUnwrap() {
    let input =
      #"""
      let x = \.?.foo
      let y = \.?.foo.bar
      let z = a.map(\.?.foo.bar)
      """#

    let expected80 =
      #"""
      let x = \.?.foo
      let y = \.?.foo.bar
      let z = a.map(\.?.foo.bar)

      """#

    assertPrettyPrintEqual(input: input, expected: expected80, linelength: 80)

    let expected11 =
      #"""
      let x =
        \.?.foo
      let y =
        \.?.foo
        .bar
      let z =
        a.map(
          \.?.foo
            .bar)

      """#

    assertPrettyPrintEqual(input: input, expected: expected11, linelength: 11)
  }

  @Test func wrapping() {
    let input =
      #"""
      let x = \ReallyLongType.reallyLongProperty.anotherLongProperty
      let x = \.reeeeallyLongProperty.anotherLongProperty
      let x = \.longProperty.a.b.c[really + long + expression]
      let x = \.longProperty.a.b.c[really + long + expression].anotherLongProperty
      let x = \.longProperty.a.b.c[label:really + long + expression].anotherLongProperty
      """#

    let expected =
      #"""
      let x =
        \ReallyLongType
        .reallyLongProperty
        .anotherLongProperty
      let x =
        \.reeeeallyLongProperty
        .anotherLongProperty
      let x =
        \.longProperty.a.b.c[
          really + long
            + expression]
      let x =
        \.longProperty.a.b.c[
          really + long
            + expression
        ].anotherLongProperty
      let x =
        \.longProperty.a.b.c[
          label: really
            + long
            + expression
        ].anotherLongProperty

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23)
  }
}
