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
struct UseForLoopNotForEachTests: RuleTesting {
  func test() {
    assertLint(
      UseForLoopNotForEach.self,
      """
      values.1️⃣forEach { $0 * 2 }
      values.map { $0 }.2️⃣forEach { print($0) }
      values.forEach(callback)
      values.forEach { $0 }.chained()
      values.forEach({ $0 }).chained()
      values.3️⃣forEach {
        let arg = $0
        return arg + 1
      }
      values.forEach {
        let arg = $0
        return arg + 1
      } other: {
        42
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "replace use of '.forEach { ... }' with for-in loop"),
        FindingSpec("2️⃣", message: "replace use of '.forEach { ... }' with for-in loop"),
        FindingSpec("3️⃣", message: "replace use of '.forEach { ... }' with for-in loop"),
      ]
    )
  }

  /// `Sequence.forEach` is `rethrows`, so `try receiver.forEach { ... }` with no
  /// `try`/`throw` in the body must be a different (unconditionally throwing)
  /// method — e.g. GRDB `Cursor.forEach`. Skip the rule there.
  func testSkipsThrowingNonSequenceForEach() {
    assertLint(
      UseForLoopNotForEach.self,
      """
      try cursor.forEach { output.append($0) }
      try cursor.forEach { row in
        output.append(row)
      }
      try seq.1️⃣forEach { try transform($0) }
      try seq.2️⃣forEach {
        if bad { throw Err.x }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "replace use of '.forEach { ... }' with for-in loop"),
        FindingSpec("2️⃣", message: "replace use of '.forEach { ... }' with for-in loop"),
      ]
    )
  }
}
