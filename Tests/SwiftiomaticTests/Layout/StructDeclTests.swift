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
struct StructDeclTests: LayoutTesting {
  @Test func basicStructDeclarations() {
    let input =
      """
      struct MyStruct {
        let A: Int
        let B: Bool
      }
      public struct MyStruct {
        let A: Int
        let B: Bool
      }
      public struct MyLongerStruct {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      struct MyStruct {
        let A: Int
        let B: Bool
      }
      public struct MyStruct {
        let A: Int
        let B: Bool
      }
      public struct
        MyLongerStruct
      {
        let A: Int
        let B: Bool
      }

      """

    assertLayout(input: input, expected: expected, linelength: 25)
  }

  @Test func genericStructDeclarations_noPackArguments() {
    let input =
      """
      struct MyStruct<T> {
        let A: Int
        let B: Bool
      }
      struct MyStruct<T, S> {
        let A: Int
        let B: Bool
      }
      struct MyStruct<One, Two, Three, Four> {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      struct MyStruct<T> {
        let A: Int
        let B: Bool
      }
      struct MyStruct<T, S> {
        let A: Int
        let B: Bool
      }
      struct MyStruct<
        One,
        Two,
        Three,
        Four
      > {
        let A: Int
        let B: Bool
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachArgument.self] = true
    assertLayout(input: input, expected: expected, linelength: 30, configuration: config)
  }

  @Test func genericStructDeclarations_packArguments() {
    let input =
      """
      struct MyStruct<T> {
        let A: Int
        let B: Bool
      }
      struct MyStruct<T, S> {
        let A: Int
        let B: Bool
      }
      struct MyStruct<One, Two, Three, Four> {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      struct MyStruct<T> {
        let A: Int
        let B: Bool
      }
      struct MyStruct<T, S> {
        let A: Int
        let B: Bool
      }
      struct MyStruct<
        One, Two, Three, Four
      > {
        let A: Int
        let B: Bool
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachArgument.self] = false
    assertLayout(input: input, expected: expected, linelength: 30, configuration: config)
  }

  @Test func structInheritance() {
    let input =
      """
      struct MyStruct: ProtoOne {
        let A: Int
        let B: Bool
      }
      struct MyStruct: ProtoOne, ProtoTwo {
        let A: Int
        let B: Bool
      }
      struct MyStruct: ProtoOne, ProtoTwo, ProtoThree {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      struct MyStruct: ProtoOne {
        let A: Int
        let B: Bool
      }
      struct MyStruct: ProtoOne, ProtoTwo {
        let A: Int
        let B: Bool
      }
      struct MyStruct: ProtoOne, ProtoTwo,
        ProtoThree
      {
        let A: Int
        let B: Bool
      }

      """

    assertLayout(input: input, expected: expected, linelength: 40)
  }

  @Test func structWhereClause() {
    let input =
      """
      struct MyStruct<S, T> where S: Collection {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T> where S: Collection, T: ReallyLongStructName {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T> where S: Collection, T: ReallyLongStructName, U: AnotherLongStruct {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      struct MyStruct<S, T> where S: Collection {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T>
      where S: Collection, T: ReallyLongStructName {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T>
      where
        S: Collection, T: ReallyLongStructName,
        U: AnotherLongStruct
      {
        let A: Int
        let B: Double
      }

      """

    assertLayout(input: input, expected: expected, linelength: 60)
  }

  @Test func structWhereClause_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      struct MyStruct<S, T> where S: Collection {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T> where S: Collection, T: ReallyLongStructName {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T> where S: Collection, T: ReallyLongStructName, U: AnotherLongStruct {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      struct MyStruct<S, T> where S: Collection {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T>
      where S: Collection, T: ReallyLongStructName {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T>
      where
        S: Collection,
        T: ReallyLongStructName,
        U: AnotherLongStruct
      {
        let A: Int
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachGenericRequirement.self] = true
    assertLayout(input: input, expected: expected, linelength: 60, configuration: config)
  }

  @Test func structWhereClauseWithInheritance() {
    let input =
      """
      struct MyStruct<S, T>: ProtoOne where S: Collection {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol, T: ReallyLongProtocolName, U: LongerProtocolName {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      struct MyStruct<S, T>: ProtoOne where S: Collection {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T>: ProtoOne, ProtoTwo
      where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T>: ProtoOne, ProtoTwo
      where
        S: Collection, T: Protocol, T: ReallyLongProtocolName,
        U: LongerProtocolName
      {
        let A: Int
        let B: Double
      }

      """

    assertLayout(input: input, expected: expected, linelength: 60)
  }

  @Test func structWhereClauseWithInheritance_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      struct MyStruct<S, T>: ProtoOne where S: Collection {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol, T: ReallyLongProtocolName, U: LongerProtocolName {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      struct MyStruct<S, T>: ProtoOne where S: Collection {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T>: ProtoOne, ProtoTwo
      where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      struct MyStruct<S, T>: ProtoOne, ProtoTwo
      where
        S: Collection,
        T: Protocol,
        T: ReallyLongProtocolName,
        U: LongerProtocolName
      {
        let A: Int
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachGenericRequirement.self] = true
    assertLayout(input: input, expected: expected, linelength: 60, configuration: config)
  }

  @Test func structAttributes() {
    let input =
      """
      @dynamicMemberLookup public struct MyStruct {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc public struct MyStruct {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc @objcMembers public struct MyStruct {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @available(swift 4.0)
      public struct MyStruct {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      @dynamicMemberLookup public struct MyStruct {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc public struct MyStruct {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc @objcMembers
      public struct MyStruct {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @available(swift 4.0)
      public struct MyStruct {
        let A: Int
        let B: Double
      }

      """

    assertLayout(input: input, expected: expected, linelength: 60)
  }

  @Test func structFullWrap() {
    let input =
      """
      public struct MyContainer<BaseCollection, SecondCollection>: MyContainerProtocolOne, MyContainerProtocolTwo, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection: P, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      public struct MyContainer<
        BaseCollection, SecondCollection
      >: MyContainerProtocolOne, MyContainerProtocolTwo,
        SomeoneElsesContainerProtocol,
        SomeFrameworkContainerProtocol
      where
        BaseCollection: Collection, BaseCollection: P,
        BaseCollection.Element: Equatable,
        BaseCollection.Element: SomeOtherProtocol
      {
        let A: Int
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachArgument.self] = false
    assertLayout(input: input, expected: expected, linelength: 50, configuration: config)
  }

  @Test func structFullWrap_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      public struct MyContainer<BaseCollection, SecondCollection>: MyContainerProtocolOne, MyContainerProtocolTwo, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection: P, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        let A: Int
        let B: Double
      }
      """

    let expected =

      """
      public struct MyContainer<
        BaseCollection, SecondCollection
      >: MyContainerProtocolOne, MyContainerProtocolTwo,
        SomeoneElsesContainerProtocol,
        SomeFrameworkContainerProtocol
      where
        BaseCollection: Collection,
        BaseCollection: P,
        BaseCollection.Element: Equatable,
        BaseCollection.Element: SomeOtherProtocol
      {
        let A: Int
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachArgument.self] = false
    config[BeforeEachGenericRequirement.self] = true
    assertLayout(input: input, expected: expected, linelength: 50, configuration: config)
  }

  @Test func emptyStruct() {
    let input = "struct Foo {}"
    assertLayout(input: input, expected: input + "\n", linelength: 50)

    let wrapped = """
      struct Foo {
      }

      """
    assertLayout(input: input, expected: wrapped, linelength: 12)
  }

  @Test func emptyStructWithComment() {
    let input = """
      struct Foo {
        // foo
      }
      """
    assertLayout(input: input, expected: input + "\n", linelength: 50)
  }

  @Test func oneMemberStruct() {
    let input = "struct Foo { var bar: Int }"
    assertLayout(input: input, expected: input + "\n", linelength: 50)
  }
}
