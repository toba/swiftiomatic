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
struct ProtocolDeclTests: LayoutTesting {
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

    assertLayout(input: input, expected: expected, linelength: 30)
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

    assertLayout(input: input, expected: expected, linelength: 50)
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

    assertLayout(input: input, expected: expected, linelength: 60)
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

    assertLayout(input: input, expected: expected, linelength: 30)
  }

  @Test func protocolWithKeepFunctionOutputTogether_overridesExistingArrowNewline() {
    // When KeepFunctionOutputTogether is enabled, an existing discretionary
    // newline before `->` should be ignored — the rule's intent is to keep
    // the return clause attached to `) async throws`.
    let input =
      """
      protocol P {
        func shareMetadata(for share: CKShare, shouldFetchRootRecord: Bool) async throws
          -> ShareMetadata
      }
      """

    let expected =
      """
      protocol P {
        func shareMetadata(
          for share: CKShare, shouldFetchRootRecord: Bool
        ) async throws -> ShareMetadata
      }

      """

    var config = Configuration.forTesting
    config[KeepFunctionOutputTogether.self] = true
    assertLayout(input: input, expected: expected, linelength: 60, configuration: config)
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

    assertLayout(input: input, expected: expected, linelength: 30)
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

    assertLayout(input: input, expected: expected, linelength: 65)
  }

  @Test func emptyProtocol() {
    let input = "protocol Foo {}"
    assertLayout(input: input, expected: input + "\n", linelength: 50)

    let wrapped = """
      protocol Foo {
      }

      """
    assertLayout(input: input, expected: wrapped, linelength: 14)
  }

  @Test func emptyProtocolWithComment() {
    let input = """
      protocol Foo {
        // foo
      }
      """
    assertLayout(input: input, expected: input + "\n", linelength: 50)
  }

  @Test func oneMemberProtocol() {
    let input = "protocol Foo { var bar: Int { get } }"
    assertLayout(input: input, expected: input + "\n", linelength: 50)
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
    config[BeforeEachArgument.self] = true
    assertLayout(input: input, expected: expected, linelength: 30, configuration: config)
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
    config[BeforeEachArgument.self] = false
    assertLayout(input: input, expected: expected, linelength: 30, configuration: config)
  }
}
