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
struct RedundantObjcTests: RuleTesting {
  @Test func objcWithIBAction() {
    assertLint(
      RedundantObjc.self,
      """
      1️⃣@objc @IBAction func buttonTapped() {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@objc'; it is implied by another attribute"),
      ]
    )
  }

  @Test func objcWithIBOutlet() {
    assertLint(
      RedundantObjc.self,
      """
      1️⃣@objc @IBOutlet var label: UILabel!
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@objc'; it is implied by another attribute"),
      ]
    )
  }

  @Test func objcWithNSManaged() {
    assertLint(
      RedundantObjc.self,
      """
      1️⃣@objc @NSManaged var name: String
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@objc'; it is implied by another attribute"),
      ]
    )
  }

  @Test func objcWithIBInspectable() {
    assertLint(
      RedundantObjc.self,
      """
      1️⃣@objc @IBInspectable var borderWidth: CGFloat
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@objc'; it is implied by another attribute"),
      ]
    )
  }

  @Test func objcAloneNotFlagged() {
    assertLint(
      RedundantObjc.self,
      """
      @objc func myMethod() {}
      """,
      findings: []
    )
  }

  @Test func objcWithExplicitNameNotFlagged() {
    assertLint(
      RedundantObjc.self,
      """
      @objc(buttonTapped:) @IBAction func buttonTapped(_ sender: Any) {}
      """,
      findings: []
    )
  }

  @Test func ibActionAloneNotFlagged() {
    assertLint(
      RedundantObjc.self,
      """
      @IBAction func buttonTapped() {}
      """,
      findings: []
    )
  }

  @Test func noAttributesNotFlagged() {
    assertLint(
      RedundantObjc.self,
      """
      func myMethod() {}
      """,
      findings: []
    )
  }

  @Test func objcWithGKInspectable() {
    assertLint(
      RedundantObjc.self,
      """
      1️⃣@objc @GKInspectable var speed: Float
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@objc'; it is implied by another attribute"),
      ]
    )
  }
}
