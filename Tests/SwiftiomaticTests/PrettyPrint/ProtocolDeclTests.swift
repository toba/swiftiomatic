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
struct ProtocolDeclTests: PrettyPrintTesting {
  @Test func basicProtocolDeclarations() {
    let input =
      """
      protocol MyProtocol {
        var A: Int { get set }
        var B: Bool { get }
      }
      protocol MyProtocol {
        var VeryLongVariable: Int { get set }
        var B: Bool { get }
      }
      public protocol MyProtocol {
        var A: Int { get set }
        var B: Bool { get }
      }
      public protocol MyLongerProtocol {
        var A: Int { get set }
        var B: Bool { get }
      }
      """

    let expected =
      """
      protocol MyProtocol {
        var A: Int { get set }
        var B: Bool { get }
      }
      protocol MyProtocol {
        var VeryLongVariable: Int {
          get set
        }
        var B: Bool { get }
      }
      public protocol MyProtocol {
        var A: Int { get set }
        var B: Bool { get }
      }
      public protocol
        MyLongerProtocol
      {
        var A: Int { get set }
        var B: Bool { get }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  @Test func protocolInheritance() {
    let input =
      """
      protocol MyProtocol: ProtoOne {
        var A: Int { get set }
        var B: Bool { get }
      }
      protocol MyProtocol: ProtoOne, ProtoTwo {
        var A: Int { get set }
        var B: Bool { get }
      }
      protocol MyProtocol: ProtoOne, ProtoTwo, ProtoThree {
        var A: Int { get set }
        var B: Bool { get }
      }
      """

    let expected =
      """
      protocol MyProtocol: ProtoOne {
        var A: Int { get set }
        var B: Bool { get }
      }
      protocol MyProtocol: ProtoOne, ProtoTwo {
        var A: Int { get set }
        var B: Bool { get }
      }
      protocol MyProtocol: ProtoOne, ProtoTwo,
        ProtoThree
      {
        var A: Int { get set }
        var B: Bool { get }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  @Test func protocolAttributes() {
    let input =
      """
      @dynamicMemberLookup public protocol MyProtocol {
        var A: Int { get set }
        var B: Double { get }
      }
      @dynamicMemberLookup @objc public protocol MyProtocol {
        var A: Int { get set }
        var B: Double { get }
      }
      @dynamicMemberLookup @objc @objcMembers public protocol MyProtocol {
        var A: Int { get set }
        var B: Double { get }
      }
      @dynamicMemberLookup
      @available(swift 4.0)
      public protocol MyProtocol {
        var A: Int { get set }
        var B: Double { get }
      }
      """

    let expected =
      """
      @dynamicMemberLookup public protocol MyProtocol {
        var A: Int { get set }
        var B: Double { get }
      }
      @dynamicMemberLookup @objc public protocol MyProtocol {
        var A: Int { get set }
        var B: Double { get }
      }
      @dynamicMemberLookup @objc @objcMembers
      public protocol MyProtocol {
        var A: Int { get set }
        var B: Double { get }
      }
      @dynamicMemberLookup
      @available(swift 4.0)
      public protocol MyProtocol {
        var A: Int { get set }
        var B: Double { get }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  @Test func protocolWithFunctions() {
    let input =
      """
      protocol MyProtocol {
        func foo(bar: Int) -> Int
        func reallyLongName(reallyLongLabel: Int, anotherLongLabel: Bool) -> Float
        func doAProtoThing(first: Foo, second s: Bar)
        func doAThing(first: Foo) -> ResultType
        func doSomethingElse(firstArg: Foo, second secondArg: Bar, third thirdArg: Baz)
        func doStuff(firstArg: Foo, second second: Bar, third third: Baz) -> Output
      }
      """

    let expected =
      """
      protocol MyProtocol {
        func foo(bar: Int) -> Int
        func reallyLongName(
          reallyLongLabel: Int,
          anotherLongLabel: Bool
        ) -> Float
        func doAProtoThing(
          first: Foo, second s: Bar)
        func doAThing(first: Foo)
          -> ResultType
        func doSomethingElse(
          firstArg: Foo,
          second secondArg: Bar,
          third thirdArg: Baz)
        func doStuff(
          firstArg: Foo,
          second second: Bar,
          third third: Baz
        ) -> Output
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  @Test func protocolWithInitializers() {
    let input =
      """
      protocol MyProtocol {
        init(bar: Int)
        init(reallyLongLabel: Int, anotherLongLabel: Bool)
      }
      """

    let expected =
      """
      protocol MyProtocol {
        init(bar: Int)
        init(
          reallyLongLabel: Int,
          anotherLongLabel: Bool)
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  @Test func protocolWithAssociatedtype() {
    let input =
      """
      protocol MyProtocol {
        var A: Int
        associatedtype TypeOne
        associatedtype TypeTwo: AnotherType
        associatedtype TypeThree: SomeType where TypeThree.Item == Item
        @available(swift 4.0)
        associatedtype TypeFour
      }
      """

    let expected =
      """
      protocol MyProtocol {
        var A: Int
        associatedtype TypeOne
        associatedtype TypeTwo: AnotherType
        associatedtype TypeThree: SomeType where TypeThree.Item == Item
        @available(swift 4.0)
        associatedtype TypeFour
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 65)
  }

  @Test func emptyProtocol() {
    let input = "protocol Foo {}"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)

    let wrapped = """
      protocol Foo {
      }

      """
    assertPrettyPrintEqual(input: input, expected: wrapped, linelength: 14)
  }

  @Test func emptyProtocolWithComment() {
    let input = """
      protocol Foo {
        // foo
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  @Test func oneMemberProtocol() {
    let input = "protocol Foo { var bar: Int { get } }"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  @Test func primaryAssociatedTypes_noPackArguments() {
    let input =
      """
      protocol MyProtocol<T> {
        var a: Int { get }
        var b: Bool { get }
      }
      protocol MyProtocol<T, S> {
        var a: Int { get }
        var b: Bool { get }
      }
      protocol MyProtocol<One, Two, Three, Four> {
        var a: Int { get }
        var b: Bool { get }
      }
      """

    let expected =
      """
      protocol MyProtocol<T> {
        var a: Int { get }
        var b: Bool { get }
      }
      protocol MyProtocol<T, S> {
        var a: Int { get }
        var b: Bool { get }
      }
      protocol MyProtocol<
        One,
        Two,
        Three,
        Four
      > {
        var a: Int { get }
        var b: Bool { get }
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
  }

  @Test func primaryAssociatedTypes_packArguments() {
    let input =
      """
      protocol MyProtocol<T> {
        var a: Int { get }
        var b: Bool { get }
      }
      protocol MyProtocol<T, S> {
        var a: Int { get }
        var b: Bool { get }
      }
      protocol MyProtocol<One, Two, Three, Four> {
        var a: Int { get }
        var b: Bool { get }
      }
      """

    let expected =
      """
      protocol MyProtocol<T> {
        var a: Int { get }
        var b: Bool { get }
      }
      protocol MyProtocol<T, S> {
        var a: Int { get }
        var b: Bool { get }
      }
      protocol MyProtocol<
        One, Two, Three, Four
      > {
        var a: Int { get }
        var b: Bool { get }
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
  }
}
