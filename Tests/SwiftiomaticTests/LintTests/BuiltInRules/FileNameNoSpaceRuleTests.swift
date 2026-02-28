import SourceKittenFramework
import Testing

@testable import Swiftiomatic

private let fixturesDirectory = "\(TestResources.path())/FileNameNoSpaceRuleFixtures"

@Suite struct FileNameNoSpaceRuleTests {
  init() { RuleRegistry.registerAllRulesOnce() }

  private func validate(fileName: String, excludedOverride: [String]? = nil) throws
    -> [StyleViolation]
  {
    let file = SwiftLintFile(path: fixturesDirectory.stringByAppendingPathComponent(fileName))!
    let rule: FileNameNoSpaceRule
    if let excluded = excludedOverride {
      rule = try FileNameNoSpaceRule(configuration: ["excluded": excluded])
    } else {
      rule = FileNameNoSpaceRule()
    }

    return rule.validate(file: file)
  }

  @Test func fileNameDoesntTrigger() throws {
    #expect(try validate(fileName: "File.swift").isEmpty)
  }

  @Test func fileWithSpaceDoesTrigger() throws {
    #expect(try validate(fileName: "File Name.swift").count == 1)
  }

  @Test func extensionNameDoesntTrigger() throws {
    #expect(try validate(fileName: "File+Extension.swift").isEmpty)
  }

  @Test func extensionWithSpaceDoesTrigger() throws {
    #expect(try validate(fileName: "File+Test Extension.swift").count == 1)
  }

  @Test func customExcludedList() throws {
    #expect(
      try validate(
        fileName: "File+Test Extension.swift",
        excludedOverride: ["File+Test Extension.swift"]
      ).isEmpty)
  }
}
