import Testing

@testable import SwiftiomaticKit

private let fixturesDirectory = "\(TestResources.path())/FileHeaderRuleFixtures"

@Suite(.rulesRegistered) struct FileHeaderRuleTests {
  private func validate(fileName: String, using configuration: Any) throws -> [RuleViolation] {
    let file = try #require(
      SwiftSource(path: fixturesDirectory.stringByAppendingPathComponent(fileName)))
    let rule = try FileHeaderRule(configuration: configuration)
    return rule.validate(file: file)
  }

  // MARK: - Default configuration

  @Test func noViolationForCopyrightInCode() async {
    await assertNoViolation(
      FileHeaderRule.self,
      """
      let foo = "Copyright"
      """)
  }

  @Test func noViolationForCopyrightInTrailingComment() async {
    await assertNoViolation(
      FileHeaderRule.self,
      """
      let foo = 2 // Copyright
      """)
  }

  @Test func violationForCopyrightInHeader() async {
    await assertLint(
      FileHeaderRule.self,
      """
      // 1️⃣Copyright
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func violationForCopyrightInMultiLineHeader() async {
    await assertLint(
      FileHeaderRule.self,
      """
      //
      // 1️⃣Copyright
      """,
      findings: [FindingSpec("1️⃣")])
  }

  // MARK: - Required string

  @Test func requiredStringNoViolation() async {
    await assertNoViolation(
      FileHeaderRule.self,
      "// **Header",
      configuration: ["required_string": "**Header"])
  }

  @Test func requiredStringWithPrecedingCommentNoViolation() async {
    await assertNoViolation(
      FileHeaderRule.self,
      "//\n// **Header",
      configuration: ["required_string": "**Header"])
  }

  @Test func requiredStringMissingViolation() async {
    await assertViolates(
      FileHeaderRule.self,
      "// Copyright\n",
      configuration: ["required_string": "**Header"])
  }

  @Test func requiredStringInCodeNoMatch() async {
    await assertViolates(
      FileHeaderRule.self,
      """
      let foo = "**Header"
      """,
      configuration: ["required_string": "**Header"])
  }

  @Test func requiredStringInTrailingCommentNoMatch() async {
    await assertViolates(
      FileHeaderRule.self,
      """
      let foo = 2 // **Header
      """,
      configuration: ["required_string": "**Header"])
  }

  // MARK: - Required pattern

  @Test func requiredPatternNoViolation() async {
    await assertNoViolation(
      FileHeaderRule.self,
      "// Copyright \u{00A9} 2016 Realm",
      configuration: ["required_pattern": "\\d{4} Realm"])
  }

  @Test func requiredPatternMissingYearViolation() async {
    await assertViolates(
      FileHeaderRule.self,
      "// Copyright\n",
      configuration: ["required_pattern": "\\d{4} Realm"])
  }

  @Test func requiredPatternWrongYearViolation() async {
    await assertViolates(
      FileHeaderRule.self,
      "// Copyright \u{00A9} foo Realm",
      configuration: ["required_pattern": "\\d{4} Realm"])
  }

  @Test func requiredPatternWrongCompanyViolation() async {
    await assertViolates(
      FileHeaderRule.self,
      "// Copyright \u{00A9} 2016 MyCompany",
      configuration: ["required_pattern": "\\d{4} Realm"])
  }

  // MARK: - Required string with URL comment

  @Test func requiredURLStringNoViolation() async {
    await assertNoViolation(
      FileHeaderRule.self,
      "/* Check this url: https://github.com/realm/SwiftLint */",
      configuration: [
        "required_string": "/* Check this url: https://github.com/realm/SwiftLint */"
      ])
  }

  @Test func requiredURLStringMismatchViolation() async {
    await assertViolates(
      FileHeaderRule.self,
      "/* Check this url: https://github.com/apple/swift */",
      configuration: [
        "required_string": "/* Check this url: https://github.com/realm/SwiftLint */"
      ])
  }

  // MARK: - Forbidden string

  @Test func forbiddenStringNotInHeaderNoViolation() async {
    await assertNoViolation(
      FileHeaderRule.self,
      "// Copyright\n",
      configuration: ["forbidden_string": "**All rights reserved."])
  }

  @Test func forbiddenStringInCodeNoViolation() async {
    await assertNoViolation(
      FileHeaderRule.self,
      """
      let foo = "**All rights reserved."
      """,
      configuration: ["forbidden_string": "**All rights reserved."])
  }

  @Test func forbiddenStringInHeaderViolation() async {
    await assertViolates(
      FileHeaderRule.self,
      "// **All rights reserved.",
      configuration: ["forbidden_string": "**All rights reserved."])
  }

  @Test func forbiddenStringInMultiLineHeaderViolation() async {
    await assertViolates(
      FileHeaderRule.self,
      "//\n// **All rights reserved.",
      configuration: ["forbidden_string": "**All rights reserved."])
  }

  // MARK: - Forbidden pattern

  @Test func forbiddenPatternNotMatchingNoViolation() async {
    await assertNoViolation(
      FileHeaderRule.self,
      "// Copyright\n",
      configuration: ["forbidden_pattern": "\\s\\w+\\.swift"])
  }

  @Test func forbiddenPatternDifferentExtensionNoViolation() async {
    await assertNoViolation(
      FileHeaderRule.self,
      "// FileHeaderRuleTests.m\n",
      configuration: ["forbidden_pattern": "\\s\\w+\\.swift"])
  }

  @Test func forbiddenPatternMatchViolation() async {
    await assertViolates(
      FileHeaderRule.self,
      "// FileHeaderRuleTests.swift",
      configuration: ["forbidden_pattern": "\\s\\w+\\.swift"])
  }

  // MARK: - Forbidden pattern with doc comment

  @Test func forbiddenPatternDocCommentNoViolation() async {
    await assertNoViolation(
      FileHeaderRule.self,
      """
      /// This is great tool with tests.
      class GreatTool {}
      """,
      configuration: ["forbidden_pattern": "[tT]ests"])
  }

  @Test func forbiddenPatternNoHeaderNoViolation() async {
    await assertNoViolation(
      FileHeaderRule.self,
      "class GreatTool {}",
      configuration: ["forbidden_pattern": "[tT]ests"])
  }

  @Test func forbiddenPatternInHeaderViolation() async {
    await assertViolates(
      FileHeaderRule.self,
      "// FileHeaderRuleTests.swift",
      configuration: ["forbidden_pattern": "[tT]ests"])
  }

  // MARK: - CURRENT_FILENAME placeholder — required string

  @Test func requiredStringFilenameMatchNoViolation() throws {
    let configuration = ["required_string": "// CURRENT_FILENAME"]
    #expect(
      try validate(fileName: "FileNameMatchingSimple.swift", using: configuration).isEmpty)
  }

  @Test func requiredStringFilenameCaseMismatchViolation() throws {
    let configuration = ["required_string": "// CURRENT_FILENAME"]
    #expect(
      try validate(fileName: "FileNameCaseMismatch.swift", using: configuration).count == 1)
  }

  @Test func requiredStringFilenameMismatchViolation() throws {
    let configuration = ["required_string": "// CURRENT_FILENAME"]
    #expect(
      try validate(fileName: "FileNameMismatch.swift", using: configuration).count == 1)
  }

  @Test func requiredStringFilenameMissingViolation() throws {
    let configuration = ["required_string": "// CURRENT_FILENAME"]
    #expect(
      try validate(fileName: "FileNameMissing.swift", using: configuration).count == 1)
  }

  // MARK: - CURRENT_FILENAME placeholder — forbidden string

  @Test func forbiddenStringFilenameNoMatchNoViolation() throws {
    let configuration = ["forbidden_string": "// CURRENT_FILENAME"]
    #expect(try validate(fileName: "FileNameCaseMismatch.swift", using: configuration).isEmpty)
    #expect(try validate(fileName: "FileNameMismatch.swift", using: configuration).isEmpty)
    #expect(try validate(fileName: "FileNameMissing.swift", using: configuration).isEmpty)
  }

  @Test func forbiddenStringFilenameMatchViolation() throws {
    let configuration = ["forbidden_string": "// CURRENT_FILENAME"]
    #expect(
      try validate(fileName: "FileNameMatchingSimple.swift", using: configuration).count == 1)
  }

  // MARK: - CURRENT_FILENAME placeholder — required pattern

  @Test func requiredPatternFilenameSimpleNoViolation() throws {
    let configuration1 = ["required_pattern": "// CURRENT_FILENAME\n.*\\d{4}"]
    #expect(
      try validate(fileName: "FileNameMatchingSimple.swift", using: configuration1).isEmpty)
  }

  @Test func requiredPatternFilenameComplexNoViolation() throws {
    let configuration2 = [
      "required_pattern": "// Copyright \u{00A9} \\d{4}\n// File: \"CURRENT_FILENAME\""
    ]
    #expect(
      try validate(fileName: "FileNameMatchingComplex.swift", using: configuration2).isEmpty)
  }

  @Test func requiredPatternFilenameMismatchViolation() throws {
    let configuration = ["required_pattern": "// CURRENT_FILENAME\n.*\\d{4}"]
    #expect(
      try validate(fileName: "FileNameCaseMismatch.swift", using: configuration).count == 1)
    #expect(try validate(fileName: "FileNameMismatch.swift", using: configuration).count == 1)
    #expect(try validate(fileName: "FileNameMissing.swift", using: configuration).count == 1)
  }

  // MARK: - CURRENT_FILENAME placeholder — forbidden pattern

  @Test func forbiddenPatternFilenameSimpleNoViolation() throws {
    let configuration1 = ["forbidden_pattern": "// CURRENT_FILENAME\n.*\\d{4}"]
    #expect(try validate(fileName: "FileNameCaseMismatch.swift", using: configuration1).isEmpty)
    #expect(try validate(fileName: "FileNameMismatch.swift", using: configuration1).isEmpty)
    #expect(try validate(fileName: "FileNameMissing.swift", using: configuration1).isEmpty)
  }

  @Test func forbiddenPatternFilenameComplexNoViolation() throws {
    let configuration2 =
      ["forbidden_pattern": "//.*(\\s|\")CURRENT_FILENAME(\\s|\").*"]
    #expect(try validate(fileName: "FileNameCaseMismatch.swift", using: configuration2).isEmpty)
    #expect(try validate(fileName: "FileNameMismatch.swift", using: configuration2).isEmpty)
    #expect(try validate(fileName: "FileNameMissing.swift", using: configuration2).isEmpty)
  }

  @Test func forbiddenPatternFilenameSimpleMatchViolation() throws {
    let configuration = ["forbidden_pattern": "// CURRENT_FILENAME\n.*\\d{4}"]
    #expect(
      try validate(fileName: "FileNameMatchingSimple.swift", using: configuration).count == 1)
  }

  @Test func forbiddenPatternFilenameComplexMatchViolation() throws {
    let configuration =
      ["forbidden_pattern": "//.*(\\s|\")CURRENT_FILENAME(\\s|\").*"]
    #expect(
      try validate(fileName: "FileNameMatchingComplex.swift", using: configuration).count == 1)
  }

  // MARK: - Forbidden pattern "." (header should be empty)

  @Test func emptyHeaderNoViolation() throws {
    let configuration = ["forbidden_pattern": "."]
    #expect(try validate(fileName: "FileHeaderEmpty.swift", using: configuration).isEmpty)
  }

  @Test func documentedTypeNoViolation() throws {
    let configuration = ["forbidden_pattern": "."]
    #expect(try validate(fileName: "DocumentedType.swift", using: configuration).isEmpty)
  }

  @Test func headerShouldBeEmptyViolation() throws {
    let configuration = ["forbidden_pattern": "."]
    #expect(
      try validate(fileName: "FileNameCaseMismatch.swift", using: configuration).count == 1)
    #expect(try validate(fileName: "FileNameMismatch.swift", using: configuration).count == 1)
    #expect(try validate(fileName: "FileNameMissing.swift", using: configuration).count == 1)
  }

  // MARK: - Simple pattern

  @Test func simplePatternNoViolation() async {
    await assertNoViolation(
      FileHeaderRule.self,
      """
      // Test

      enum Test {}
      """,
      configuration: [
        "required_pattern": #"""
        \/\/ Test

        """#
      ])
  }

  @Test func simplePatternTrailingNewlineNoViolation() async {
    await assertNoViolation(
      FileHeaderRule.self,
      """
      // Test

      """,
      configuration: [
        "required_pattern": #"""
        \/\/ Test

        """#
      ])
  }

  // MARK: - Complex pattern

  @Test func complexPatternNoViolation() async {
    await assertNoViolation(
      FileHeaderRule.self,
      """
      //
      //  Test.swift
      //  Dummy App
      //
      //  Created by Alice Bob on 3.9.2025.
      //  Copyright \u{00A9} 2025 Dummy Corporation. All rights reserved.
      //

      enum Test {}
      """,
      configuration: [
        "required_pattern": #"""
        \/\/
        \/\/  Test\.swift
        \/\/  .*?
        \/\/
        \/\/  Created by .*? on \d{1,2}[\.\/]\d{1,2}[\.\/]\d{2,4}\.
        \/\/  Copyright © \d{4} Dummy Corporation\. All rights reserved\.
        \/\/

        """#
      ])
  }
}
