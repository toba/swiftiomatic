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
struct EnumDeclTests: PrettyPrintTesting {
  @Test func basicEnumDeclarations() {
    let input =
      """
      enum MyEnum {
        case firstCase
        case secondCase
      }
      public enum MyEnum {
        case firstCase
        case secondCase
      }
      public enum MyLongerEnum {
        case firstCase
        case secondCase
      }
      """

    let expected =
      """
      enum MyEnum {
        case firstCase
        case secondCase
      }
      public enum MyEnum {
        case firstCase
        case secondCase
      }
      public enum
        MyLongerEnum
      {
        case firstCase
        case secondCase
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23)
  }

  @Test func mixedEnumCaseStyles_noPackArguments() {
    let input =
      """
      enum MyEnum {
        case first
        case second, third
        case fourth(Int)
        case fifth(a: Int, b: Bool)
      }
      enum MyEnum {
        case first
        case second, third, fourth, fifth
        case sixth(Int)
        case seventh(a: Int, b: Bool, c: Double)
      }
      """

    let expected =
      """
      enum MyEnum {
        case first
        case second, third
        case fourth(Int)
        case fifth(a: Int, b: Bool)
      }
      enum MyEnum {
        case first
        case second, third, fourth,
          fifth
        case sixth(Int)
        case seventh(
          a: Int,
          b: Bool,
          c: Double
        )
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachArgument.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
  }

  @Test func mixedEnumCaseStyles_packArguments() {
    let input =
      """
      enum MyEnum {
        case first
        case second, third
        case fourth(Int)
        case fifth(a: Int, b: Bool)
      }
      enum MyEnum {
        case first
        case second, third, fourth, fifth
        case sixth(Int)
        case seventh(a: Int, b: Bool, c: Double)
      }
      """

    let expected =
      """
      enum MyEnum {
        case first
        case second, third
        case fourth(Int)
        case fifth(a: Int, b: Bool)
      }
      enum MyEnum {
        case first
        case second, third, fourth,
          fifth
        case sixth(Int)
        case seventh(
          a: Int, b: Bool, c: Double)
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachArgument.self] = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 31, configuration: config)
  }

  @Test func indirectEnum() {
    let input =
      """
      enum MyEnum {
        indirect case first
        case second
      }
      indirect enum MyEnum {
        case first
        case second
      }
      public indirect enum MyEnum {
        case first
        case second
      }
      """

    let expected =
      """
      enum MyEnum {
        indirect case first
        case second
      }
      indirect enum MyEnum {
        case first
        case second
      }
      public indirect enum MyEnum {
        case first
        case second
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  @Test func genericEnumDeclarations() {
    let input =
      """
      enum MyEnum<T> {
        case firstCase
        case secondCase
      }
      enum MyEnum<T, S> {
        case firstCase
        case secondCase
      }
      enum MyEnum<One, Two, Three, Four> {
        case firstCase
        case secondCase
      }
      """

    let expected =
      """
      enum MyEnum<T> {
        case firstCase
        case secondCase
      }
      enum MyEnum<T, S> {
        case firstCase
        case secondCase
      }
      enum MyEnum<
        One, Two, Three, Four
      > {
        case firstCase
        case secondCase
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachArgument.self] = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
  }

  @Test func enumInheritance() {
    let input =
      """
      enum MyEnum: ProtoOne {
        case firstCase
        case secondCase
      }
      enum MyEnum: ProtoOne, ProtoTwo {
        case firstCase
        case secondCase
      }
      enum MyEnum: ProtoOne, ProtoTwo, ProtoThree {
        case firstCase
        case secondCase
      }
      """

    let expected =
      """
      enum MyEnum: ProtoOne {
        case firstCase
        case secondCase
      }
      enum MyEnum: ProtoOne, ProtoTwo {
        case firstCase
        case secondCase
      }
      enum MyEnum: ProtoOne, ProtoTwo,
        ProtoThree
      {
        case firstCase
        case secondCase
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  @Test func enumWhereClause() {
    let input =
      """
      enum MyEnum<S, T> where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T> where S: Collection, T: ReallyLongEnumName {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T> where S: Collection, T: ReallyLongEnumName, U: AnotherLongEnum {
        case firstCase
        let B: Double
      }
      """

    let expected =
      """
      enum MyEnum<S, T> where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>
      where S: Collection, T: ReallyLongEnumName {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>
      where
        S: Collection, T: ReallyLongEnumName, U: AnotherLongEnum
      {
        case firstCase
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  @Test func enumWhereClause_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      enum MyEnum<S, T> where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T> where S: Collection, T: ReallyLongEnumName {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T> where S: Collection, T: ReallyLongEnumName, U: AnotherLongEnum, W: AnotherReallyLongEnumName {
        case firstCase
        let B: Double
      }
      """

    let expected =
      """
      enum MyEnum<S, T> where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>
      where S: Collection, T: ReallyLongEnumName {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>
      where
        S: Collection,
        T: ReallyLongEnumName,
        U: AnotherLongEnum,
        W: AnotherReallyLongEnumName
      {
        case firstCase
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachGenericRequirement.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60, configuration: config)
  }

  @Test func enumWhereClauseWithInheritance() {
    let input =
      """
      enum MyEnum<S, T>: ProtoOne where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol, T: ReallyLongEnumName, U: LongerEnumName, W: AnotherReallyLongEnumName {
        case firstCase
        let B: Double
      }
      """

    let expected =
      """
      enum MyEnum<S, T>: ProtoOne where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo
      where S: Collection, T: Protocol {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo
      where
        S: Collection, T: Protocol, T: ReallyLongEnumName,
        U: LongerEnumName, W: AnotherReallyLongEnumName
      {
        case firstCase
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  @Test func enumWhereClauseWithInheritance_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      enum MyEnum<S, T>: ProtoOne where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol, T: ReallyLongEnumName, U: LongerEnumName, W: AnotherReallyLongEnumName {
        case firstCase
        let B: Double
      }
      """

    let expected =
      """
      enum MyEnum<S, T>: ProtoOne where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo
      where S: Collection, T: Protocol {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo
      where
        S: Collection,
        T: Protocol,
        T: ReallyLongEnumName,
        U: LongerEnumName,
        W: AnotherReallyLongEnumName
      {
        case firstCase
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachGenericRequirement.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60, configuration: config)
  }

  @Test func enumAttributes() {
    let input =
      """
      @dynamicMemberLookup public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @objc public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @objc @objcMembers public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @available(swift 4.0)
      public enum MyEnum {
        case firstCase
        let B: Double
      }
      """

    let expected =
      """
      @dynamicMemberLookup public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @objc public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @objc @objcMembers
      public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @available(swift 4.0)
      public enum MyEnum {
        case firstCase
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 55)
  }

  @Test func enumFullWrap() {
    let input =
      """
      public enum MyEnum<BaseCollection, SecondCollection>: MyContainerProtocolOne, MyContainerProtocolTwo, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection: P, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        case firstCase
        let B: Double
      }
      """

    let expected =

      """
      public enum MyEnum<
        BaseCollection, SecondCollection
      >: MyContainerProtocolOne, MyContainerProtocolTwo,
        SomeoneElsesContainerProtocol,
        SomeFrameworkContainerProtocol
      where
        BaseCollection: Collection, BaseCollection: P,
        BaseCollection.Element: Equatable,
        BaseCollection.Element: SomeOtherProtocol
      {
        case firstCase
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachArgument.self] = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  @Test func enumFullWrap_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      public enum MyEnum<BaseCollection, SecondCollection>: MyContainerProtocolOne, MyContainerProtocolTwo, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection: P, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        case firstCase
        let B: Double
      }
      """

    let expected =

      """
      public enum MyEnum<
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
        case firstCase
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachArgument.self] = false
    config[BeforeEachGenericRequirement.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  @Test func emptyEnum() {
    let input = "enum Foo {}"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)

    let wrapped = """
      enum Foo {
      }

      """
    assertPrettyPrintEqual(input: input, expected: wrapped, linelength: 10)
  }

  @Test func emptyEnumWithComment() {
    let input = """
      enum Foo {
        // foo
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  @Test func oneMemberEnum() {
    let input = "enum Foo { var bar: Int }"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  @Test func enumWithPrioritizeKeepingFunctionOutputTogetherFlag() {
    let input = """
      enum Error {
        case alreadyOpen(Int)
      }

      """
    var config = Configuration.forTesting
    config[PrioritizeKeepingFunctionOutputTogether.self] = true
    assertPrettyPrintEqual(input: input, expected: input, linelength: 50, configuration: config)
  }
}
