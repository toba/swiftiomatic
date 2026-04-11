import Testing

@testable import SwiftiomaticKit

private let fixturesDirectory = "\(TestResources.path())/FileNameNoSpaceRuleFixtures"

@Suite(.rulesRegistered) struct FileNameNoSpaceRuleTests {
  private func validate(fileName: String, excludedOverride: [String]? = nil) throws
    -> [RuleViolation]
  {
    let file = try #require(
      SwiftSource(path: fixturesDirectory.stringByAppendingPathComponent(fileName)))
    let rule: FileNameNoSpaceRule
    if let excluded = excludedOverride {
      rule = try FileNameNoSpaceRule(configuration: ["excluded": excluded])
    } else {
      rule = FileNameNoSpaceRule()
    }

    return rule.validate(file: file)
  }

  @Test func fileNameDoesNotTrigger() throws {
    #expect(try validate(fileName: "File.swift").isEmpty)
  }

  @Test func fileWithSpaceDoesTrigger() throws {
    #expect(try validate(fileName: "File Name.swift").count == 1)
  }

  @Test func extensionNameDoesNotTrigger() throws {
    #expect(try validate(fileName: "File+Extension.swift").isEmpty)
  }

  @Test func extensionWithSpaceDoesTrigger() throws {
    #expect(try validate(fileName: "File+Test Extension.swift").count == 1)
  }

  @Test func customExcludedList() throws {
    #expect(
      try validate(
        fileName: "File+Test Extension.swift",
        excludedOverride: ["File+Test Extension.swift"],
      ).isEmpty,
    )
  }
}
