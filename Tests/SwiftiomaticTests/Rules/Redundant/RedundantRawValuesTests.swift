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
struct RedundantRawValuesTests: RuleTesting {
  @Test func basicRedundantRawValue() {
    assertFormatting(
      RedundantRawValues.self,
      input: """
        enum Direction: String {
          case north 1️⃣= "north"
          case south 2️⃣= "south"
        }
        """,
      expected: """
        enum Direction: String {
          case north
          case south
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant raw value for 'north'; it matches the case name"),
        FindingSpec("2️⃣", message: "remove redundant raw value for 'south'; it matches the case name"),
      ]
    )
  }

  @Test func nonMatchingRawValueIsNotModified() {
    assertFormatting(
      RedundantRawValues.self,
      input: """
        enum Direction: String {
          case north = "North"
          case south = "SOUTH"
        }
        """,
      expected: """
        enum Direction: String {
          case north = "North"
          case south = "SOUTH"
        }
        """,
      findings: []
    )
  }

  @Test func mixedCases() {
    assertFormatting(
      RedundantRawValues.self,
      input: """
        enum Fruit: String {
          case apple 1️⃣= "apple"
          case banana = "yellow_banana"
          case cherry 2️⃣= "cherry"
        }
        """,
      expected: """
        enum Fruit: String {
          case apple
          case banana = "yellow_banana"
          case cherry
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant raw value for 'apple'; it matches the case name"),
        FindingSpec("2️⃣", message: "remove redundant raw value for 'cherry'; it matches the case name"),
      ]
    )
  }

  @Test func nonStringEnumIsNotModified() {
    assertFormatting(
      RedundantRawValues.self,
      input: """
        enum Code: Int {
          case ok = 200
          case notFound = 404
        }
        """,
      expected: """
        enum Code: Int {
          case ok = 200
          case notFound = 404
        }
        """,
      findings: []
    )
  }

  @Test func enumWithoutRawTypeIsNotModified() {
    assertFormatting(
      RedundantRawValues.self,
      input: """
        enum Foo {
          case bar
          case baz
        }
        """,
      expected: """
        enum Foo {
          case bar
          case baz
        }
        """,
      findings: []
    )
  }

  @Test func multipleCasesOnOneLine() {
    assertFormatting(
      RedundantRawValues.self,
      input: """
        enum Color: String {
          case red 1️⃣= "red", green 2️⃣= "green", blue 3️⃣= "blue"
        }
        """,
      expected: """
        enum Color: String {
          case red, green, blue
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant raw value for 'red'; it matches the case name"),
        FindingSpec("2️⃣", message: "remove redundant raw value for 'green'; it matches the case name"),
        FindingSpec("3️⃣", message: "remove redundant raw value for 'blue'; it matches the case name"),
      ]
    )
  }

  @Test func stringInterpolationIsNotModified() {
    assertFormatting(
      RedundantRawValues.self,
      input: """
        enum Foo: String {
          case bar = "bar\\(something)"
        }
        """,
      expected: """
        enum Foo: String {
          case bar = "bar\\(something)"
        }
        """,
      findings: []
    )
  }

  @Test func noRawValuesIsNotModified() {
    assertFormatting(
      RedundantRawValues.self,
      input: """
        enum Direction: String {
          case north
          case south
        }
        """,
      expected: """
        enum Direction: String {
          case north
          case south
        }
        """,
      findings: []
    )
  }
}
