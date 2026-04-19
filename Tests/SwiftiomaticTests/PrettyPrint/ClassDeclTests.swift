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
struct ClassDeclTests: PrettyPrintTesting {
  @Test func basicClassDeclarations() {
    let input =
      """
      class MyClass {
        let A: Int
        let B: Bool
      }
      public class MyClass {
        let A: Int
        let B: Bool
      }
      public class MyLongerClass {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      class MyClass {
        let A: Int
        let B: Bool
      }
      public class MyClass {
        let A: Int
        let B: Bool
      }
      public class
        MyLongerClass
      {
        let A: Int
        let B: Bool
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }

  @Test func genericClassDeclarations_noPackArguments() {
    let input =
      """
      class MyClass<T> {
        let A: Int
        let B: Bool
      }
      class MyClass<T, S> {
        let A: Int
        let B: Bool
      }
      class MyClass<One, Two, Three, Four> {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      class MyClass<T> {
        let A: Int
        let B: Bool
      }
      class MyClass<T, S> {
        let A: Int
        let B: Bool
      }
      class MyClass<
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
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
  }

  @Test func genericClassDeclarations_packArguments() {
    let input =
      """
      class MyClass<T> {
        let A: Int
        let B: Bool
      }
      class MyClass<T, S> {
        let A: Int
        let B: Bool
      }
      class MyClass<One, Two, Three, Four> {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      class MyClass<T> {
        let A: Int
        let B: Bool
      }
      class MyClass<T, S> {
        let A: Int
        let B: Bool
      }
      class MyClass<
        One, Two, Three, Four
      > {
        let A: Int
        let B: Bool
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachArgument.self] = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
  }

  @Test func classInheritance() {
    let input =
      """
      class MyClass: SuperOne {
        let A: Int
        let B: Bool
      }
      class MyClass: SuperOne, SuperTwo {
        let A: Int
        let B: Bool
      }
      class MyClass: SuperOne, SuperTwo, SuperThree {
        let A: Int
        let B: Bool
      }
      class MyClass:
        SuperOne, SuperTwo, SuperThree {
        let A: Int
        let B: Bool
      }
      class MyClassWhoseNameIsVeryLong: SuperOne, SuperTwo, SuperThree {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      class MyClass: SuperOne {
        let A: Int
        let B: Bool
      }
      class MyClass: SuperOne, SuperTwo {
        let A: Int
        let B: Bool
      }
      class MyClass: SuperOne, SuperTwo,
        SuperThree
      {
        let A: Int
        let B: Bool
      }
      class MyClass:
        SuperOne, SuperTwo, SuperThree
      {
        let A: Int
        let B: Bool
      }
      class MyClassWhoseNameIsVeryLong:
        SuperOne, SuperTwo, SuperThree
      {
        let A: Int
        let B: Bool
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  @Test func classWhereClause() {
    let input =
      """
      class MyClass<S, T> where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T> where S: Collection, T: ReallyLongClassName {
        let A: Int
        let B: Double
      }
      class MyClass<S, T> where S: Collection, T: ReallyLongClassName, U: LongerClassName {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      class MyClass<S, T> where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>
      where S: Collection, T: ReallyLongClassName {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>
      where
        S: Collection, T: ReallyLongClassName, U: LongerClassName
      {
        let A: Int
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  @Test func classWhereClause_lineBreakAfterGenericWhereClause() {
    let input =
      """
      class MyClass<S, T> where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T> where S: Collection, T: ReallyLongClassName {
        let A: Int
        let B: Double
      }
      class MyClass<S, T> where S: Collection, T: ReallyLongClassName, U: LongerClassName, W: AnotherLongClassName {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      class MyClass<S, T> where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>
      where S: Collection, T: ReallyLongClassName {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>
      where
        S: Collection,
        T: ReallyLongClassName,
        U: LongerClassName,
        W: AnotherLongClassName
      {
        let A: Int
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachGenericRequirement.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60, configuration: config)
  }

  @Test func classWhereClauseWithInheritance() {
    let input =
      """
      class MyClass<S, T>: SuperOne where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>: SuperOne, SuperTwo where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      class MyClass<S, T>: SuperOne where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>: SuperOne, SuperTwo
      where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  @Test func classWhereClauseWithInheritance_lineBreakAfterGenericWhereClause() {
    let input =
      """
      class MyClass<S, T>: SuperOne where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>: SuperOne, SuperTwo where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>: SuperOne, SuperTwo where S: Collection, T: Protocol, T: ReallyLongClassName, U: LongerClassName {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      class MyClass<S, T>: SuperOne where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>: SuperOne, SuperTwo
      where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>: SuperOne, SuperTwo
      where
        S: Collection,
        T: Protocol,
        T: ReallyLongClassName,
        U: LongerClassName
      {
        let A: Int
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachGenericRequirement.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60, configuration: config)
  }

  @Test func classAttributes() {
    let input =
      """
      @dynamicMemberLookup public class MyClass {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc public class MyClass {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc @objcMembers public class MyClass {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @available(swift 4.0)
      public class MyClass {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      @dynamicMemberLookup public class MyClass {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc public class MyClass {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc @objcMembers
      public class MyClass {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @available(swift 4.0)
      public class MyClass {
        let A: Int
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 55)
  }

  @Test func classFullWrap() {
    let input =
      """
      public class MyContainer<BaseCollection, SecondCollection>: MyContainerSuperclass, MyContainerProtocol, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection: P, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        let A: Int
        let B: Double
      }
      """

    let expected =

      """
      public class MyContainer<
        BaseCollection, SecondCollection
      >: MyContainerSuperclass, MyContainerProtocol,
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
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  @Test func classFullWrap_lineBreakAfterGenericWhereClause() {
    let input =
      """
      public class MyContainer<BaseCollection, SecondCollection>: MyContainerSuperclass, MyContainerProtocol, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection: P, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        let A: Int
        let B: Double
      }
      """

    let expected =

      """
      public class MyContainer<
        BaseCollection, SecondCollection
      >: MyContainerSuperclass, MyContainerProtocol,
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
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  @Test func emptyClass() {
    let input = "class Foo {}"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)

    let wrapped = """
      class Foo {
      }

      """
    assertPrettyPrintEqual(input: input, expected: wrapped, linelength: 11)
  }

  @Test func emptyClassWithComment() {
    let input = """
      class Foo {
        // foo
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  @Test func oneMemberClass() {
    let input = "class Foo { var bar: Int }"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  @Test func basicActorDeclarations() {
    let input =
      """
      actor MyActor {
        let A: Int
        let B: Bool
      }
      public actor MyActor {
        let A: Int
        let B: Bool
      }
      public actor MyLongerActor {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      actor MyActor {
        let A: Int
        let B: Bool
      }
      public actor MyActor {
        let A: Int
        let B: Bool
      }
      public actor
        MyLongerActor
      {
        let A: Int
        let B: Bool
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }
}
