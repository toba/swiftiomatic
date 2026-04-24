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
struct ExtensionDeclTests: LayoutTesting {
  @Test func basicExtensionDeclarations() {
    let input =
      """
      extension MyExtension {
        let A: Int
        let B: Bool
      }
      public extension MyExtension {
        let A: Int
        let B: Bool
      }
      public extension MyLongerExtension {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      extension MyExtension {
        let A: Int
        let B: Bool
      }
      public extension MyExtension {
        let A: Int
        let B: Bool
      }
      public extension
        MyLongerExtension
      {
        let A: Int
        let B: Bool
      }

      """

    assertLayout(input: input, expected: expected, linelength: 33)
  }

  @Test func extensionInheritance() {
    let input =
      """
      extension MyExtension: ProtoOne {
        let A: Int
        let B: Bool
      }
      extension MyExtension: ProtoOne, ProtoTwo {
        let A: Int
        let B: Bool
      }
      extension MyExtension: ProtoOne, ProtoTwo, ProtoThree {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      extension MyExtension: ProtoOne {
        let A: Int
        let B: Bool
      }
      extension MyExtension: ProtoOne, ProtoTwo {
        let A: Int
        let B: Bool
      }
      extension MyExtension: ProtoOne, ProtoTwo,
        ProtoThree
      {
        let A: Int
        let B: Bool
      }

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func extensionWhereClause() {
    let input =
      """
      extension MyExtension where S: Collection {
        let A: Int
        let B: Double
      }
      extension MyExtension where S: Collection, T: ReallyLongExtensionName {
        let A: Int
        let B: Double
      }
      extension MyExtension where S: Collection, T: ReallyLongExtensionName, U: AnotherLongExtension {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      extension MyExtension where S: Collection {
        let A: Int
        let B: Double
      }
      extension MyExtension
      where S: Collection, T: ReallyLongExtensionName {
        let A: Int
        let B: Double
      }
      extension MyExtension
      where
        S: Collection, T: ReallyLongExtensionName, U: AnotherLongExtension
      {
        let A: Int
        let B: Double
      }

      """

    assertLayout(input: input, expected: expected, linelength: 70)
  }

  @Test func extensionWhereClause_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      extension MyExtension where S: Collection {
        let A: Int
        let B: Double
      }
      extension MyExtension where S: Collection, T: ReallyLongExtensionName {
        let A: Int
        let B: Double
      }
      extension MyExtension where S: Collection, T: ReallyLongExtensionName, U: AnotherLongExtension, W: AnotherReallyLongExtensionName {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      extension MyExtension where S: Collection {
        let A: Int
        let B: Double
      }
      extension MyExtension
      where S: Collection, T: ReallyLongExtensionName {
        let A: Int
        let B: Double
      }
      extension MyExtension
      where
        S: Collection,
        T: ReallyLongExtensionName,
        U: AnotherLongExtension,
        W: AnotherReallyLongExtensionName
      {
        let A: Int
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachGenericRequirement.self] = true
    assertLayout(input: input, expected: expected, linelength: 70, configuration: config)
  }

  @Test func extensionWhereClauseWithInheritance() {
    let input =
      """
      extension MyExtension: ProtoOne where S: Collection {
        let A: Int
        let B: Double
      }
      extension MyExtension: ProtoOne, ProtoTwo where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      extension MyExtension: ProtoOne, ProtoTwo where S: Collection, T: Protocol, T: ReallyLongExtensionName, U: LongerExtensionName {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      extension MyExtension: ProtoOne where S: Collection {
        let A: Int
        let B: Double
      }
      extension MyExtension: ProtoOne, ProtoTwo
      where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      extension MyExtension: ProtoOne, ProtoTwo
      where
        S: Collection, T: Protocol, T: ReallyLongExtensionName,
        U: LongerExtensionName
      {
        let A: Int
        let B: Double
      }

      """

    assertLayout(input: input, expected: expected, linelength: 70)
  }

  @Test func extensionWhereClauseWithInheritance_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      extension MyExtension: ProtoOne where S: Collection {
        let A: Int
        let B: Double
      }
      extension MyExtension: ProtoOne, ProtoTwo where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      extension MyExtension: ProtoOne, ProtoTwo where S: Collection, T: Protocol, T: ReallyLongExtensionName, U: LongerExtensionName {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      extension MyExtension: ProtoOne where S: Collection {
        let A: Int
        let B: Double
      }
      extension MyExtension: ProtoOne, ProtoTwo
      where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      extension MyExtension: ProtoOne, ProtoTwo
      where
        S: Collection,
        T: Protocol,
        T: ReallyLongExtensionName,
        U: LongerExtensionName
      {
        let A: Int
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config[BeforeEachGenericRequirement.self] = true
    assertLayout(input: input, expected: expected, linelength: 70, configuration: config)
  }

  @Test func extensionAttributes() {
    let input =
      """
      @dynamicMemberLookup public extension MyExtension {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc public extension MyExtension {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc @objcMembers public extension MyExtension {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup
      @available(swift 4.0)
      public extension MyExtension {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      @dynamicMemberLookup public extension MyExtension {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc public extension MyExtension {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc @objcMembers
      public extension MyExtension {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup
      @available(swift 4.0)
      public extension MyExtension {
        let A: Int
        let B: Double
      }

      """

    assertLayout(input: input, expected: expected, linelength: 60)
  }

  @Test func extensionFullWrap() {
    let input =
      """
      public extension MyContainer: MyContainerProtocolOne, MyContainerProtocolTwo, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection: P, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        let A: Int
        let B: Double
      }
      """

    let expected =

      """
      public extension MyContainer:
        MyContainerProtocolOne, MyContainerProtocolTwo,
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

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func extensionFullWrap_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      public extension MyContainer: MyContainerProtocolOne, MyContainerProtocolTwo, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection: P, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        let A: Int
        let B: Double
      }
      """

    let expected =

      """
      public extension MyContainer:
        MyContainerProtocolOne, MyContainerProtocolTwo,
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
    config[BeforeEachGenericRequirement.self] = true
    assertLayout(input: input, expected: expected, linelength: 50, configuration: config)
  }

  @Test func emptyExtension() {
    let input = "extension Foo {}"
    assertLayout(input: input, expected: input + "\n", linelength: 50)

    let wrapped = """
      extension Foo {
      }

      """
    assertLayout(input: input, expected: wrapped, linelength: 15)
  }

  @Test func emptyExtensionWithComment() {
    let input = """
      extension Foo {
        // foo
      }
      """
    assertLayout(input: input, expected: input + "\n", linelength: 50)
  }

  @Test func oneMemberExtension() {
    let input = "extension Foo { var bar: Int { return 0 } }"
    assertLayout(input: input, expected: input + "\n", linelength: 50)
  }
}
