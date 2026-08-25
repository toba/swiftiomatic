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

@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseSynthesizedInitializerTests: RuleTesting {
  private static let message =
    "remove this explicit initializer, which is identical to the compiler-synthesized initializer"

  @Test func memberwiseInitializerIsDiagnosed() {
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        internal let address: String

        1️⃣init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        )
      ]
    )
  }

  @Test func nestedMemberwiseInitializerIsDiagnosed() {
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct MyContainer {
        public struct Person {
          public var name: String

          1️⃣init(name: String) {
            self.name = name
          }
        }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        )
      ]
    )
  }

  @Test func internalMemberwiseInitializerIsDiagnosed() {
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        internal let address: String

        1️⃣internal init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        )
      ]
    )
  }

  @Test func memberwiseInitializerWithDefaultArgumentIsDiagnosed() {
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct Person {

        public var name: String = "John Doe"
        let phoneNumber: String
        internal let address: String

        1️⃣init(name: String = "John Doe", phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        )
      ]
    )
  }

  @Test func customInitializerVoidsSynthesizedInitializerWarning() {
    // The compiler won't create a memberwise initializer when there are any other initializers.
    // It's valid to have a memberwise initializer when there are any custom initializers.
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        private let address: String

        init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }

        init(name: String, address: String) {
          self.name = name
          self.phoneNumber = "1234578910"
          self.address = address
        }
      }
      """,
      findings: []
    )
  }

  @Test func memberwiseInitializerWithDefaultArgument() {
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        let address: String

        init(name: String = "Jane Doe", phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  @Test func memberwiseInitializerWithNonMatchingDefaultValues() {
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct Person {

        public var name: String = "John Doe"
        let phoneNumber: String
        let address: String

        init(name: String = "Jane Doe", phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  @Test func memberwiseInitializerMissingDefaultValues() {
    // When the initializer doesn't contain a matching default argument, then it isn't equivalent to
    // the synthesized memberwise initializer.
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct Person {

        public var name: String
        var phoneNumber: String = "+15555550101"
        let address: String

        init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  @Test func customInitializerWithMismatchedTypes() {
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct Person {

        public var name: String
        var phoneNumber: String?
        let address: String

        init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  @Test func customInitializerWithExtraParameters() {
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct Person {

        public var name: String
        var phoneNumber: String?
        let address: String

        init(name: String, phoneNumber: String?, address: String, anotherArg: Int) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  @Test func customInitializerWithExtraStatements() {
    assertLint(
      UseSynthesizedInit.self,
      #"""
      public struct Person {

        public var name: String
        var phoneNumber: String?
        let address: String

        init(name: String, phoneNumber: String?, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber

          print("phoneNumber: \(self.phoneNumber)")
        }
      }
      """#,
      findings: []
    )
  }

  @Test func failableMemberwiseInitializerIsNotDiagnosed() {
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        let address: String

        init?(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  @Test func throwingMemberwiseInitializerIsNotDiagnosed() {
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        let address: String

        init(name: String, phoneNumber: String, address: String) throws {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  @Test func publicMemberwiseInitializerIsNotDiagnosed() {
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        let address: String

        public init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  // MARK: - SE-0502: a private property with an initial value leaves the memberwise initializer

  @Test func initWorkingAroundPrivateDefaultIsDiagnosed() {
    // SE-0502 drops `count` from the memberwise initializer, because it is less accessible than
    // the rest and carries an initial value. The synthesized initializer is therefore
    // `init(phoneNumber:address:)` at internal, which this hand-written one duplicates.
    assertLint(
      UseSynthesizedInit.self,
      """
      struct Person {

        let phoneNumber: String
        let address: String
        private var count = 0

        1️⃣init(phoneNumber: String, address: String) {
          self.phoneNumber = phoneNumber
          self.address = address
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func initWorkingAroundPrivateOptionalIsDiagnosed() {
    // A private optional with no written value is still default-initialised to nil, so SE-0502
    // drops it too.
    assertLint(
      UseSynthesizedInit.self,
      """
      struct Person {

        let phoneNumber: String
        private var cache: String?

        1️⃣init(phoneNumber: String) {
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func privateDefaultStillInInitIsNotDiagnosed() {
    // The initializer keeps the dropped property as a parameter, so it does not match the
    // synthesized one.
    assertLint(
      UseSynthesizedInit.self,
      """
      struct Person {

        let phoneNumber: String
        private var count = 0

        init(phoneNumber: String, count: Int) {
          self.phoneNumber = phoneNumber
          self.count = count
        }
      }
      """,
      findings: []
    )
  }

  @Test func privatePropertyWithoutInitialValueKeepsInitPrivate() {
    // `address` has no initial value, so SE-0502 leaves it in and the synthesized initializer
    // stays private. An internal initializer therefore does not match.
    assertLint(
      UseSynthesizedInit.self,
      """
      struct Person {

        let phoneNumber: String
        private let address: String

        init(phoneNumber: String, address: String) {
          self.phoneNumber = phoneNumber
          self.address = address
        }
      }
      """,
      findings: []
    )
  }

  @Test func allPrivatePropertiesKeepInitPrivate() {
    // Nothing is less accessible than the rest, so nothing is dropped and the initializer is
    // private.
    assertLint(
      UseSynthesizedInit.self,
      """
      struct Person {

        private var phoneNumber: String = ""
        private var address: String = ""

        1️⃣private init(phoneNumber: String = "", address: String = "") {
          self.phoneNumber = phoneNumber
          self.address = address
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func privateSetDetailDoesNotLowerInitLevel() {
    // `private(set)` restricts the setter alone, so it neither lowers the initializer's access
    // level nor drops the property.
    assertLint(
      UseSynthesizedInit.self,
      """
      struct Person {

        let phoneNumber: String
        private(set) var address: String = ""

        1️⃣init(phoneNumber: String, address: String = "") {
          self.phoneNumber = phoneNumber
          self.address = address
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func defaultMemberwiseInitializerIsNotDiagnosed() {
    // `address` carries no initial value, so SE-0502 leaves it in the memberwise initializer and
    // the initializer stays private. An initializer with default access control (i.e. internal) is
    // therefore not equivalent to the synthesized one.
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct Person {

        let phoneNumber: String
        private let address: String

        init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  @Test func privateMemberwiseInitializerWithPrivateMemberIsDiagnosed() {
    // The synthesized initializer is private when any member is private, so a private initializer
    // is equivalent to the synthesized initializer.
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct Person {

        let phoneNumber: String
        private let address: String

        1️⃣private init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        )
      ]
    )
  }

  @Test func fileprivateMemberwiseInitializerWithFileprivateMemberIsDiagnosed() {
    // The synthesized initializer is fileprivate when any member is fileprivate, so a fileprivate
    // initializer is equivalent to the synthesized initializer.
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct Person {

        let phoneNumber: String
        fileprivate let address: String

        1️⃣fileprivate init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        )
      ]
    )
  }

  @Test func customSetterAccessLevel() {
    // When a property has a different access level for its setter, the setter's access level
    // doesn't change the access level of the synthesized initializer.
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct Person {
        let phoneNumber: String
        private(set) let address: String

        1️⃣init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }

      public struct Person2 {
        fileprivate let phoneNumber: String
        private(set) let address: String

        2️⃣fileprivate init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }

      public struct Person3 {
        fileprivate(set) let phoneNumber: String
        private(set) let address: String

        3️⃣init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }

      public struct Person4 {
        private fileprivate(set) let phoneNumber: String
        private(set) let address: String

        init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        ),
        FindingSpec(
          "2️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        ),
        FindingSpec(
          "3️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        ),
      ]
    )
  }

  @Test func memberwiseInitializerWithAttributeIsNotDiagnosed() {
    assertLint(
      UseSynthesizedInit.self,
      """
      public struct Person {
        let phoneNumber: String
        let address: String

        @inlinable init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }
}
