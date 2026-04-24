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
struct SubscriptDeclTests: LayoutTesting {
  @Test func basicSubscriptDeclarations() {
    let input =
      """
      struct MyStruct {
        subscript(index: Int) -> Int {
          return self.values[index]
        }
        subscript(row: Int, col: Int) -> Int {
          return self.values[row][col]
        }
        subscript(index: Int) -> Int {
          get { return self.value[index] }
          set(newValue) { self.value[index] = newValue }
        }
      }
      """

    let expected =
      """
      struct MyStruct {
        subscript(index: Int) -> Int {
          return self.values[index]
        }
        subscript(row: Int, col: Int) -> Int {
          return self.values[row][col]
        }
        subscript(index: Int) -> Int {
          get { return self.value[index] }
          set(newValue) { self.value[index] = newValue }
        }
      }

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func subscriptGenerics_noPackArguments() {
    let input =
      """
      struct MyStruct {
        subscript<T>(index: T) -> Double {
          return 1.23
        }
        subscript<S, T>(row: S, col: T) -> Double {
          return self.values[row][col]
        }
        subscript<LongTypeName1, LongTypeName2, LongTypeName3>(var1: LongTypeName1, var2: LongTypeName2, var3: LongTypeName3) -> Int {
          return self.values[var1][var2][var3]
        }
      }
      """

    let expected =
      """
      struct MyStruct {
        subscript<T>(index: T) -> Double {
          return 1.23
        }
        subscript<S, T>(row: S, col: T) -> Double {
          return self.values[row][col]
        }
        subscript<
          LongTypeName1,
          LongTypeName2,
          LongTypeName3
        >(
          var1: LongTypeName1,
          var2: LongTypeName2,
          var3: LongTypeName3
        ) -> Int {
          return self.values[var1][var2][var3]
        }
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachArgument.self] = true
    assertLayout(input: input, expected: expected, linelength: 50, configuration: config)
  }

  @Test func subscriptGenerics_packArguments() {
    let input =
      """
      struct MyStruct {
        subscript<T>(index: T) -> Double {
          return 1.23
        }
        subscript<S, T>(row: S, col: T) -> Double {
          return self.values[row][col]
        }
        subscript<LongTypeName1, LongTypeName2, LongTypeName3>(var1: LongTypeName1, var2: LongTypeName2, var3: LongTypeName3) -> Int {
          return self.values[var1][var2][var3]
        }
      }
      """

    let expected =
      """
      struct MyStruct {
        subscript<T>(index: T) -> Double {
          return 1.23
        }
        subscript<S, T>(row: S, col: T) -> Double {
          return self.values[row][col]
        }
        subscript<
          LongTypeName1, LongTypeName2, LongTypeName3
        >(
          var1: LongTypeName1, var2: LongTypeName2,
          var3: LongTypeName3
        ) -> Int {
          return self.values[var1][var2][var3]
        }
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachArgument.self] = false
    assertLayout(input: input, expected: expected, linelength: 50, configuration: config)
  }

  @Test func subscriptGenericWhere() {
    let input =
      """
      struct MyStruct {
        subscript<Elements: Collection, Element>(var1: Element, var2: Elements) -> Double where Elements.Element == Element {
          return 1.23
        }
        subscript<Elements: Collection, Element>(var1: Element, var2: Elements) -> Double where Elements.Element == Element, Element: Equatable, Element: P {
          return 1.23
        }
      }
      """

    let expected =
      """
      struct MyStruct {
        subscript<Elements: Collection, Element>(
          var1: Element, var2: Elements
        ) -> Double where Elements.Element == Element {
          return 1.23
        }
        subscript<Elements: Collection, Element>(
          var1: Element, var2: Elements
        ) -> Double
        where
          Elements.Element == Element,
          Element: Equatable, Element: P
        {
          return 1.23
        }
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachArgument.self] = false
    assertLayout(input: input, expected: expected, linelength: 50, configuration: config)
  }

  @Test func subscriptGenericWhere_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      struct MyStruct {
        subscript<Elements: Collection, Element>(var1: Element, var2: Elements) -> Double where Elements.Element == Element {
          return 1.23
        }
        subscript<Elements: Collection, Element>(var1: Element, var2: Elements) -> Double where Elements.Element == Element, Element: Equatable, Element: P {
          return 1.23
        }
      }
      """

    let expected =
      """
      struct MyStruct {
        subscript<Elements: Collection, Element>(
          var1: Element, var2: Elements
        ) -> Double where Elements.Element == Element {
          return 1.23
        }
        subscript<Elements: Collection, Element>(
          var1: Element, var2: Elements
        ) -> Double
        where
          Elements.Element == Element,
          Element: Equatable,
          Element: P
        {
          return 1.23
        }
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachArgument.self] = false
    config[BeforeEachGenericRequirement.self] = true
    assertLayout(input: input, expected: expected, linelength: 50, configuration: config)
  }

  @Test func subscriptAttributes() {
    let input =
      """
      struct MyStruct {
        @discardableResult subscript(index: Int) -> Int {
          let a = 123
          return a
        }
        @discardableResult @objc subscript(index: Int) -> Int {
          let a = 123
          return a
        }
        @discardableResult @objc @inlinable subscript(index: Int) -> Int {
          let a = 123
          return a
        }
        @discardableResult @objc
        @inlinable
        @available(swift 4.0)
        subscript(index: Int) -> Int {
          let a = 123
          return a
        }
      }
      """

    let expected =
      """
      struct MyStruct {
        @discardableResult subscript(index: Int) -> Int {
          let a = 123
          return a
        }
        @discardableResult @objc subscript(index: Int) -> Int {
          let a = 123
          return a
        }
        @discardableResult @objc @inlinable subscript(index: Int) -> Int {
          let a = 123
          return a
        }
        @discardableResult @objc
        @inlinable
        @available(swift 4.0)
        subscript(index: Int) -> Int {
          let a = 123
          return a
        }
      }

      """

    assertLayout(input: input, expected: expected, linelength: 70)
  }

  @Test func breaksBeforeOrInsideOutput() {
    let input =
      """
      protocol MyProtocol {
        subscript<R>(index: Int) -> R
      }

      struct MyStruct {
        subscript<R>(index: Int) -> R {
          statement
          statement
        }
      }
      """

    var expected =
      """
      protocol MyProtocol {
        subscript<R>(index: Int)
          -> R
      }

      struct MyStruct {
        subscript<R>(index: Int)
          -> R
        {
          statement
          statement
        }
      }

      """
    assertLayout(input: input, expected: expected, linelength: 26)

    expected =
      """
      protocol MyProtocol {
        subscript<R>(index: Int)
          -> R
      }

      struct MyStruct {
        subscript<R>(index: Int)
          -> R
        {
          statement
          statement
        }
      }

      """
    assertLayout(input: input, expected: expected, linelength: 27)
    assertLayout(input: input, expected: expected, linelength: 30)
  }

  @Test func breaksBeforeOrInsideOutput_prioritizingKeepingOutputTogether() {
    let input =
      """
      protocol MyProtocol {
        subscript<R>(index: Int) -> R
      }

      struct MyStruct {
        subscript<R>(index: Int) -> R {
          statement
          statement
        }
      }
      """

    var expected =
      """
      protocol MyProtocol {
        subscript<R>(
          index: Int
        ) -> R
      }

      struct MyStruct {
        subscript<R>(
          index: Int
        ) -> R {
          statement
          statement
        }
      }

      """
    var config = Configuration.forTesting
    config[KeepFunctionOutputTogether.self] = true
    assertLayout(input: input, expected: expected, linelength: 26, configuration: config)

    expected =
      """
      protocol MyProtocol {
        subscript<R>(
          index: Int
        ) -> R
      }

      struct MyStruct {
        subscript<R>(
          index: Int
        ) -> R {
          statement
          statement
        }
      }

      """
    assertLayout(input: input, expected: expected, linelength: 27, configuration: config)
    assertLayout(input: input, expected: expected, linelength: 30, configuration: config)
  }

  @Test func subscriptFullWrap() {
    let input =
      """
      struct MyStruct {
        @discardableResult @objc
        subscript<ManyElements: Collection, Element>(var1: Element, var2: ManyElements) -> ManyElements.Index? where Element: Foo, Element: Bar, ManyElements.Element == Element {
          get {
            let out = vals[var1][var2]
            return out
          }
          set(newValue) {
            let tmp = compute(newValue)
            vals[var1][var2] = tmp
          }
        }
      }
      """

    let expected =
      """
      struct MyStruct {
        @discardableResult @objc
        subscript<
          ManyElements: Collection,
          Element
        >(
          var1: Element,
          var2: ManyElements
        ) -> ManyElements.Index?
        where
          Element: Foo, Element: Bar,
          ManyElements.Element
            == Element
        {
          get {
            let out = vals[var1][var2]
            return out
          }
          set(newValue) {
            let tmp = compute(newValue)
            vals[var1][var2] = tmp
          }
        }
      }

      """

    assertLayout(input: input, expected: expected, linelength: 34)
  }

  @Test func subscriptFullWrap_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      struct MyStruct {
        @discardableResult @objc
        subscript<ManyElements: Collection, Element>(var1: Element, var2: ManyElements) -> ManyElements.Index? where Element: Foo, Element: Bar, ManyElements.Element == Element {
          get {
            let out = vals[var1][var2]
            return out
          }
          set(newValue) {
            let tmp = compute(newValue)
            vals[var1][var2] = tmp
          }
        }
      }
      """

    let expected =
      """
      struct MyStruct {
        @discardableResult @objc
        subscript<
          ManyElements: Collection,
          Element
        >(
          var1: Element,
          var2: ManyElements
        ) -> ManyElements.Index?
        where
          Element: Foo,
          Element: Bar,
          ManyElements.Element
            == Element
        {
          get {
            let out = vals[var1][var2]
            return out
          }
          set(newValue) {
            let tmp = compute(newValue)
            vals[var1][var2] = tmp
          }
        }
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachGenericRequirement.self] = true
    assertLayout(input: input, expected: expected, linelength: 34, configuration: config)
  }

  @Test func emptySubscript() {
    // The comment inside the struct prevents it from *also* being collapsed onto a single line.
    let input = """
      struct X {
        //
        subscript(i: Int) -> Int {}
      }
      """
    assertLayout(input: input, expected: input + "\n", linelength: 50)

    let wrapped = """
      struct X {
        //
        subscript(i: Int) -> Int {
        }
      }

      """
    assertLayout(input: input, expected: wrapped, linelength: 28)
  }

  @Test func accessorEffectsWithBodyAfter() {
    let input =
      """
      struct X {
        subscript(i: Int) -> T {
          get async throws {
            foo()
            bar()
          }
        }
      }
      """

    assertLayout(input: input, expected: input + "\n", linelength: 80)

    let expected18 =
      """
      struct X {
        subscript(
          i: Int
        ) -> T {
          get
            async throws
          {
            foo()
            bar()
          }
        }
      }

      """

    assertLayout(input: input, expected: expected18, linelength: 18)

    let expected12 =
      """
      struct X {
        subscript(
          i: Int
        ) -> T {
          get
            async
            throws
          {
            foo()
            bar()
          }
        }
      }

      """

    assertLayout(input: input, expected: expected12, linelength: 12)
  }

  @Test func accessorEffectsWithNoBodyAfter() {
    let input =
      """
      protocol P {
        subscript(i: Int) -> T { get async throws }
      }
      """

    assertLayout(input: input, expected: input + "\n", linelength: 80)

    let expected20 =
      """
      protocol P {
        subscript(i: Int)
          -> T
        {
          get async throws
        }
      }

      """

    assertLayout(input: input, expected: expected20, linelength: 20)

    let expected18 =
      """
      protocol P {
        subscript(
          i: Int
        ) -> T {
          get
            async throws
        }
      }

      """

    assertLayout(input: input, expected: expected18, linelength: 18)

    let expected16 =
      """
      protocol P {
        subscript(
          i: Int
        ) -> T {
          get
            async
            throws
        }
      }

      """

    assertLayout(input: input, expected: expected16, linelength: 16)
  }
}
