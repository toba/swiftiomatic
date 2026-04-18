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
struct AvoidRetroactiveConformancesTests: RuleTesting {
  @Test func retroactiveConformanceIsDiagnosed() {
    assertLint(
      NoRetroactiveConformances.self,
      """
      extension Int: 1️⃣@retroactive Identifiable {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "do not declare retroactive conformances")
      ]
    )
  }
}
