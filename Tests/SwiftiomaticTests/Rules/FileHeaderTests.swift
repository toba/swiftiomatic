@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FileHeaderTests: RuleTesting {

  private func clearConfig() -> Configuration {
    var c = Configuration.forTesting(enabledRule: FileHeader.self.key)
    c[FileHeader.self].text = ""
    return c
  }

  private func headerConfig(_ text: String) -> Configuration {
    var c = Configuration.forTesting(enabledRule: FileHeader.self.key)
    c[FileHeader.self].text = text
    return c
  }

  // MARK: - Clear header

  @Test func stripHeader() {
    assertFormatting(
      FileHeader.self,
      input: """
        //
        //  test.swift
        //  SwiftFormat
        //
        //  Created by Nick Lockwood on 08/11/2016.
        //  Copyright © 2016 Nick Lockwood. All rights reserved.
        //

        /// func
        1️⃣func foo() {}
        """,
      expected: """
        /// func
        func foo() {}
        """,
      findings: [FindingSpec("1️⃣", message: "update file header to match configured text")],
      configuration: clearConfig())
  }

  @Test func stripHeaderWithURL() {
    assertFormatting(
      FileHeader.self,
      input: """
        //
        //  RulesTests+General.swift
        //  SwiftFormatTests
        //
        //  Created by Nick Lockwood on 02/10/2021.
        //  Copyright © 2021 Nick Lockwood. All rights reserved.
        //  https://some.example.com
        //

        /// func
        1️⃣func foo() {}
        """,
      expected: """
        /// func
        func foo() {}
        """,
      findings: [FindingSpec("1️⃣", message: "update file header to match configured text")],
      configuration: clearConfig())
  }

  @Test func stripMultilineBlockCommentHeader() {
    assertFormatting(
      FileHeader.self,
      input: """
        /****************************/
        /* Created by Nick Lockwood */
        /****************************/


        /// func
        1️⃣func foo() {}
        """,
      expected: """
        /// func
        func foo() {}
        """,
      findings: [FindingSpec("1️⃣", message: "update file header to match configured text")],
      configuration: clearConfig())
  }

  @Test func noStripDocComment() {
    assertFormatting(
      FileHeader.self,
      input: """

        /// func
        func foo() {}
        """,
      expected: """

        /// func
        func foo() {}
        """,
      findings: [],
      configuration: clearConfig())
  }

  @Test func noChangeWhenNoHeaderAndClearing() {
    assertFormatting(
      FileHeader.self,
      input: """
        func foo() {}
        """,
      expected: """
        func foo() {}
        """,
      findings: [],
      configuration: clearConfig())
  }

  // MARK: - Set header

  @Test func setSingleLineHeader() {
    assertFormatting(
      FileHeader.self,
      input: """
        //
        //  test.swift
        //  SwiftFormat
        //
        //  Created by Nick Lockwood on 08/11/2016.
        //  Copyright © 2016 Nick Lockwood. All rights reserved.
        //

        /// func
        1️⃣func foo() {}
        """,
      expected: """
        // Hello World

        /// func
        func foo() {}
        """,
      findings: [FindingSpec("1️⃣", message: "update file header to match configured text")],
      configuration: headerConfig("// Hello World"))
  }

  @Test func setMultilineHeader() {
    assertFormatting(
      FileHeader.self,
      input: """
        //
        //  test.swift
        //  SwiftFormat
        //
        //  Created by Nick Lockwood on 08/11/2016.
        //  Copyright © 2016 Nick Lockwood. All rights reserved.
        //

        /// func
        1️⃣func foo() {}
        """,
      expected: """
        // Hello
        // World

        /// func
        func foo() {}
        """,
      findings: [FindingSpec("1️⃣", message: "update file header to match configured text")],
      configuration: headerConfig("// Hello\n// World"))
  }

  @Test func setBlockCommentHeader() {
    assertFormatting(
      FileHeader.self,
      input: """
        //
        //  test.swift
        //

        /// func
        1️⃣func foo() {}
        """,
      expected: """
        /*--- Hello ---*/
        /*--- World ---*/

        /// func
        func foo() {}
        """,
      findings: [FindingSpec("1️⃣", message: "update file header to match configured text")],
      configuration: headerConfig("/*--- Hello ---*/\n/*--- World ---*/"))
  }

  @Test func addHeaderWhenNoneExists() {
    assertFormatting(
      FileHeader.self,
      input: """
        1️⃣func foo() {}
        """,
      expected: """
        // Copyright 2024

        func foo() {}
        """,
      findings: [FindingSpec("1️⃣", message: "update file header to match configured text")],
      configuration: headerConfig("// Copyright 2024"))
  }

  @Test func addHeaderBeforeImport() {
    assertFormatting(
      FileHeader.self,
      input: """
        1️⃣import Foundation

        func foo() {}
        """,
      expected: """
        // Copyright 2024

        import Foundation

        func foo() {}
        """,
      findings: [FindingSpec("1️⃣", message: "update file header to match configured text")],
      configuration: headerConfig("// Copyright 2024"))
  }

  @Test func noChangeWhenHeaderAlreadyCorrect() {
    assertFormatting(
      FileHeader.self,
      input: """
        // Hello World

        func foo() {}
        """,
      expected: """
        // Hello World

        func foo() {}
        """,
      findings: [],
      configuration: headerConfig("// Hello World"))
  }

  @Test func noChangeWhenMultilineHeaderAlreadyCorrect() {
    assertFormatting(
      FileHeader.self,
      input: """
        // Hello
        // World

        func foo() {}
        """,
      expected: """
        // Hello
        // World

        func foo() {}
        """,
      findings: [],
      configuration: headerConfig("// Hello\n// World"))
  }

  @Test func noChangeWhenHeaderOnlyFileMatchesConfig() {
    assertFormatting(
      FileHeader.self,
      input: """
        // foobar
        """,
      expected: """
        // foobar
        """,
      findings: [],
      configuration: headerConfig("// foobar"))
  }

  // MARK: - Blank line handling

  @Test func addBlankLineAfterHeaderIfMissing() {
    assertFormatting(
      FileHeader.self,
      input: """
        // Header comment
        1️⃣class Foo {}
        """,
      expected: """
        // Header comment

        class Foo {}
        """,
      findings: [FindingSpec("1️⃣", message: "update file header to match configured text")],
      configuration: headerConfig("// Header comment"))
  }

  @Test func preserveBlankLineAfterReplace() {
    assertFormatting(
      FileHeader.self,
      input: """
        // Old header

        1️⃣class Foo {}
        """,
      expected: """
        // New header

        class Foo {}
        """,
      findings: [FindingSpec("1️⃣", message: "update file header to match configured text")],
      configuration: headerConfig("// New header"))
  }

  @Test func preserveDocCommentAfterClear() {
    assertFormatting(
      FileHeader.self,
      input: """
        // Header

        /// Doc comment
        1️⃣class Foo {}
        """,
      expected: """
        /// Doc comment
        class Foo {}
        """,
      findings: [FindingSpec("1️⃣", message: "update file header to match configured text")],
      configuration: clearConfig())
  }

  // MARK: - Inactive

  @Test func noChangeWhenTextIsNil() {
    assertFormatting(
      FileHeader.self,
      input: """
        // Some header

        func foo() {}
        """,
      expected: """
        // Some header

        func foo() {}
        """,
      findings: [],
      configuration: Configuration.forTesting(enabledRule: FileHeader.self.key))
  }

  // MARK: - Update header

  @Test func updateHeaderYear() {
    assertFormatting(
      FileHeader.self,
      input: """
        // Copyright (c) 2010-2023 Foobar
        //
        // SPDX-License-Identifier: EPL-2.0

        1️⃣class Foo {}
        """,
      expected: """
        // Copyright (c) 2010-2024 Foobar
        //
        // SPDX-License-Identifier: EPL-2.0

        class Foo {}
        """,
      findings: [FindingSpec("1️⃣", message: "update file header to match configured text")],
      configuration: headerConfig(
        "// Copyright (c) 2010-2024 Foobar\n//\n// SPDX-License-Identifier: EPL-2.0"))
  }

  @Test func replaceMultilineWithSingleLine() {
    assertFormatting(
      FileHeader.self,
      input: """
        // Header line1
        // Header line2

        1️⃣class Foo {}
        """,
      expected: """
        // New single line

        class Foo {}
        """,
      findings: [FindingSpec("1️⃣", message: "update file header to match configured text")],
      configuration: headerConfig("// New single line"))
  }

  @Test func replaceSingleLineWithMultiline() {
    assertFormatting(
      FileHeader.self,
      input: """
        // Header comment

        1️⃣class Foo {}
        """,
      expected: """
        // Header line1
        // Header line2

        class Foo {}
        """,
      findings: [FindingSpec("1️⃣", message: "update file header to match configured text")],
      configuration: headerConfig("// Header line1\n// Header line2"))
  }
}
