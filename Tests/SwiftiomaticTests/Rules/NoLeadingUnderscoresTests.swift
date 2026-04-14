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

@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoLeadingUnderscoresTests: RuleTesting {
  @Test func vars() {
    assertLint(
      NoLeadingUnderscores.self,
      """
      let 1️⃣_foo = foo
      var good_name = 20
      var 2️⃣_badName, okayName, 3️⃣_wor_sEName = 20
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the leading '_' from the name '_foo'"),
        FindingSpec("2️⃣", message: "remove the leading '_' from the name '_badName'"),
        FindingSpec("3️⃣", message: "remove the leading '_' from the name '_wor_sEName'"),
      ]
    )
  }

  @Test func classes() {
    assertLint(
      NoLeadingUnderscores.self,
      """
      class Foo { let 1️⃣_foo = foo }
      class 2️⃣_Bar {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the leading '_' from the name '_foo'"),
        FindingSpec("2️⃣", message: "remove the leading '_' from the name '_Bar'"),
      ]
    )
  }

  @Test func enums() {
    assertLint(
      NoLeadingUnderscores.self,
      """
      enum Foo {
        case 1️⃣_case1
        case case2, 2️⃣_case3
        case caseWithAssociatedValues(3️⃣_value: Int, otherValue: String)
        let 4️⃣_foo = foo
      }
      enum 5️⃣_Bar {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the leading '_' from the name '_case1'"),
        FindingSpec("2️⃣", message: "remove the leading '_' from the name '_case3'"),
        FindingSpec("3️⃣", message: "remove the leading '_' from the name '_value'"),
        FindingSpec("4️⃣", message: "remove the leading '_' from the name '_foo'"),
        FindingSpec("5️⃣", message: "remove the leading '_' from the name '_Bar'"),
      ]
    )
  }

  @Test func protocols() {
    assertLint(
      NoLeadingUnderscores.self,
      """
      protocol Foo {
        associatedtype 1️⃣_Quux
        associatedtype Florb
        var 2️⃣_foo: Int { get set }
      }
      protocol 3️⃣_Bar {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the leading '_' from the name '_Quux'"),
        FindingSpec("2️⃣", message: "remove the leading '_' from the name '_foo'"),
        FindingSpec("3️⃣", message: "remove the leading '_' from the name '_Bar'"),
      ]
    )
  }

  @Test func structs() {
    assertLint(
      NoLeadingUnderscores.self,
      """
      struct Foo { let 1️⃣_foo = foo }
      struct 2️⃣_Bar {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the leading '_' from the name '_foo'"),
        FindingSpec("2️⃣", message: "remove the leading '_' from the name '_Bar'"),
      ]
    )
  }

  @Test func functions() {
    assertLint(
      NoLeadingUnderscores.self,
      """
      func 1️⃣_foo<T1, 2️⃣_T2: Equatable>(_ ok: Int, 3️⃣_notOK: Int, _ok 4️⃣_butNotThisOne: Int) {}
      func bar() {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the leading '_' from the name '_foo'"),
        FindingSpec("2️⃣", message: "remove the leading '_' from the name '_T2'"),
        FindingSpec("3️⃣", message: "remove the leading '_' from the name '_notOK'"),
        FindingSpec("4️⃣", message: "remove the leading '_' from the name '_butNotThisOne'"),
      ]
    )
  }

  @Test func initializerArguments() {
    assertLint(
      NoLeadingUnderscores.self,
      """
      struct X {
        init<T1, 1️⃣_T2: Equatable>(_ ok: Int, 2️⃣_notOK: Int, _ok 3️⃣_butNotThisOne: Int) {}
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the leading '_' from the name '_T2'"),
        FindingSpec("2️⃣", message: "remove the leading '_' from the name '_notOK'"),
        FindingSpec("3️⃣", message: "remove the leading '_' from the name '_butNotThisOne'"),
      ]
    )
  }

  @Test func precedenceGroups() {
    assertLint(
      NoLeadingUnderscores.self,
      """
      precedencegroup FooPrecedence {
        associativity: left
        higherThan: BarPrecedence
      }
      precedencegroup 1️⃣_FooPrecedence {
        associativity: left
        higherThan: BarPrecedence
      }
      infix operator <> : _BazPrecedence
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the leading '_' from the name '_FooPrecedence'")
      ]
    )
  }

  @Test func typealiases() {
    assertLint(
      NoLeadingUnderscores.self,
      """
      typealias Foo = _Foo
      typealias 1️⃣_Bar = Bar
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the leading '_' from the name '_Bar'")
      ]
    )
  }

  @Test func identifiersAreIgnoredAtUsage() {
    assertLint(
      NoLeadingUnderscores.self,
      """
      let x = _y + _z
      _foo(_bar)
      """,
      findings: []
    )
  }
}
