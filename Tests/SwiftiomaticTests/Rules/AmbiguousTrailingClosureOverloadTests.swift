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

@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct AmbiguousTrailingClosureOverloadTests: RuleTesting {
  @Test func ambiguousOverloads() {
    assertLint(
      AmbiguousTrailingClosureOverload.self,
      """
      func 1️⃣strong(mad: () -> Int) {}
      func 2️⃣strong(bad: (Bool) -> Bool) {}
      func 3️⃣strong(sad: (String) -> Bool) {}

      class A {
        static func 4️⃣the(cheat: (Int) -> Void) {}
        class func 5️⃣the(sneak: (Int) -> Void) {}
        func 6️⃣the(kingOfTown: () -> Void) {}
        func 7️⃣the(cheatCommandos: (Bool) -> Void) {}
        func 8️⃣the(brothersStrong: (String) -> Void) {}
      }

      struct B {
        func 9️⃣hom(estar: () -> Int) {}
        func 🔟hom(sar: () -> Bool) {}

        static func baleeted(_ f: () -> Void) {}
        func baleeted(_ f: () -> Void) {}
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "rename 'strong(mad:)' so it is no longer ambiguous when called with a trailing closure",
          notes: [
            NoteSpec("2️⃣", message: "ambiguous overload 'strong(bad:)' is here"),
            NoteSpec("3️⃣", message: "ambiguous overload 'strong(sad:)' is here"),
          ]
        ),
        FindingSpec(
          "4️⃣",
          message: "rename 'the(cheat:)' so it is no longer ambiguous when called with a trailing closure",
          notes: [
            NoteSpec("5️⃣", message: "ambiguous overload 'the(sneak:)' is here")
          ]
        ),
        FindingSpec(
          "6️⃣",
          message: "rename 'the(kingOfTown:)' so it is no longer ambiguous when called with a trailing closure",
          notes: [
            NoteSpec("7️⃣", message: "ambiguous overload 'the(cheatCommandos:)' is here"),
            NoteSpec("8️⃣", message: "ambiguous overload 'the(brothersStrong:)' is here"),
          ]
        ),
        FindingSpec(
          "9️⃣",
          message: "rename 'hom(estar:)' so it is no longer ambiguous when called with a trailing closure",
          notes: [
            NoteSpec("🔟", message: "ambiguous overload 'hom(sar:)' is here")
          ]
        ),
      ]
    )
  }
}
