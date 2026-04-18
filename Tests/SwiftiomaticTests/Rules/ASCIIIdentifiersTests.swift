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
struct IdentifiersMustBeASCIITests: RuleTesting {
  @Test func invalidIdentifiers() {
    assertLint(
      ASCIIIdentifiers.self,
      """
      let Te$t = 1
      var 1️⃣fo😎o = 2
      let 2️⃣Δx = newX - previousX
      var 3️⃣🤩😆 = 20
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove non-ASCII characters from 'fo😎o': 😎"),
        // TODO: It would be nice to allow Δ (among other mathematically meaningful symbols) without
        // a lot of special cases; investigate this.
        FindingSpec("2️⃣", message: "remove non-ASCII characters from 'Δx': Δ"),
        FindingSpec("3️⃣", message: "remove non-ASCII characters from '🤩😆': 🤩, 😆"),
      ]
    )
  }
}
