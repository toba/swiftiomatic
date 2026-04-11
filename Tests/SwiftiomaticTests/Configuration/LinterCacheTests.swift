import Foundation
import Synchronization
import Testing

@testable import SwiftiomaticKit

private struct CacheTestHelper {
  fileprivate let configuration: Configuration

  private let ruleList: RuleList
  private let cache: LinterCache

  private var fileManager: TestFileManager {
    cache.fileManager as! TestFileManager
  }

  fileprivate init(dict: [String: Any], cache: LinterCache) {
    ruleList = RuleList(rules: RuleWithLevelsMock.self)
    configuration = try! Configuration(dict: dict, ruleList: ruleList)
    self.cache = cache
  }

  fileprivate func makeViolations(file: String) -> [RuleViolation] {
    touch(file: file)
    return [
      RuleViolation(
        ruleType: RuleWithLevelsMock.self,
        severity: .warning,
        location: Location(file: file, line: 10, column: 2),
        reason: "Something is not right",
      ),
      RuleViolation(
        ruleType: RuleWithLevelsMock.self,
        severity: .error,
        location: Location(file: file, line: 5, column: nil),
        reason: "Something is wrong",
      ),
    ]
  }

  fileprivate func makeConfig(dict: [String: Any]) -> Configuration {
    try! Configuration(dict: dict, ruleList: ruleList)
  }

  fileprivate func touch(file: String) {
    fileManager.stubbedModificationDateByPath.withLock { $0[file] = Date() }
  }

  fileprivate func remove(file: String) {
    fileManager.stubbedModificationDateByPath.withLock { $0[file] = nil }
  }

  fileprivate func fileCount() -> Int {
    fileManager.stubbedModificationDateByPath.withLock { $0.count }
  }
}

private final class TestFileManager: Sendable, LintableFileDiscovering {
  fileprivate func filesToLint(
    inPath _: String,
    rootDirectory _: String? = nil,
    excluder _: Excluder,
  ) -> [String] {
    []
  }

  fileprivate let stubbedModificationDateByPath = Mutex([String: Date]())

  fileprivate func modificationDate(forFileAtPath path: String) -> Date? {
    stubbedModificationDateByPath.withLock { $0[path] }
  }
}

@Suite(.rulesRegistered) final class LinterCacheTests {
  // MARK: Test Helpers

  private var cache = LinterCache(fileManager: TestFileManager())

  private func makeCacheTestHelper(dict: [String: Any]) -> CacheTestHelper {
    CacheTestHelper(dict: dict, cache: cache)
  }

  private func cacheAndValidate(
    violations: [RuleViolation],
    forFile: String,
    configuration: Configuration,
    file _: StaticString = #filePath,
    line _: UInt = #line,
  ) {
    cache.cache(violations: violations, forFile: forFile, configuration: configuration)
    cache = cache.flushed()
    #expect(cache.violations(forFile: forFile, configuration: configuration)! == violations)
  }

  private func cacheAndValidateNoViolationsTwoFiles(
    configuration: Configuration,
    file: StaticString = #filePath,
    line: UInt = #line,
  ) {
    let (file1, file2) = ("file1.swift", "file2.swift")
    let fileManager = cache.fileManager as! TestFileManager
    fileManager.stubbedModificationDateByPath.withLock { $0 = [file1: Date(), file2: Date()] }

    cacheAndValidate(
      violations: [], forFile: file1, configuration: configuration, file: file, line: line,
    )
    cacheAndValidate(
      violations: [], forFile: file2, configuration: configuration, file: file, line: line,
    )
  }

  private func validateNewConfigDoesNotHitCache(
    dict: [String: Any],
    initialConfig: Configuration,
    file _: StaticString = #filePath,
    line _: UInt = #line,
  ) throws {
    let newConfig = try Configuration(dict: dict)
    let (file1, file2) = ("file1.swift", "file2.swift")

    #expect(cache.violations(forFile: file1, configuration: newConfig) == nil)
    #expect(cache.violations(forFile: file2, configuration: newConfig) == nil)

    #expect(cache.violations(forFile: file1, configuration: initialConfig)! == [])
    #expect(cache.violations(forFile: file2, configuration: initialConfig)! == [])
  }

  // MARK: Cache Reuse

  // Two subsequent lints with no changes reuses cache
  @Test func unchangedFilesReusesCache() {
    let helper = makeCacheTestHelper(dict: ["only_rules": ["mock"]])
    let file = "foo.swift"
    let violations = helper.makeViolations(file: file)

    cacheAndValidate(violations: violations, forFile: file, configuration: helper.configuration)
    helper.touch(file: file)

    #expect(cache.violations(forFile: file, configuration: helper.configuration) == nil)
  }

  @Test func configFileReorderedReusesCache() {
    let helper = makeCacheTestHelper(dict: ["only_rules": ["mock"], "disabled_rules": [Any]()])
    let file = "foo.swift"
    let violations = helper.makeViolations(file: file)

    cacheAndValidate(violations: violations, forFile: file, configuration: helper.configuration)
    let configuration2 = helper.makeConfig(dict: [
      "disabled_rules": [Any](), "only_rules": ["mock"],
    ])
    #expect(cache.violations(forFile: file, configuration: configuration2) == violations)
  }

  @Test func configFileWhitespaceAndCommentsChangedOrAddedOrRemovedReusesCache() throws {
    let helper = try makeCacheTestHelper(dict: YamlParser.parse("only_rules:\n  - mock"))
    let file = "foo.swift"
    let violations = helper.makeViolations(file: file)

    cacheAndValidate(violations: violations, forFile: file, configuration: helper.configuration)
    let configuration2 = helper.makeConfig(dict: [
      "disabled_rules": [Any](), "only_rules": ["mock"],
    ])
    #expect(cache.violations(forFile: file, configuration: configuration2) == violations)
    let configYamlWithComment =
      try YamlParser
      .parse("# comment1\nonly_rules:\n  - mock # comment2")
    let configuration3 = helper.makeConfig(dict: configYamlWithComment)
    #expect(cache.violations(forFile: file, configuration: configuration3) == violations)
    #expect(cache.violations(forFile: file, configuration: helper.configuration) == violations)
  }

  @Test func configFileUnrelatedKeysChangedOrAddedOrRemovedReusesCache() {
    let helper = makeCacheTestHelper(dict: ["only_rules": ["mock"], "reporter": "json"])
    let file = "foo.swift"
    let violations = helper.makeViolations(file: file)

    cacheAndValidate(violations: violations, forFile: file, configuration: helper.configuration)
    let configuration2 = helper.makeConfig(dict: ["only_rules": ["mock"], "reporter": "xcode"])
    #expect(cache.violations(forFile: file, configuration: configuration2) == violations)
    let configuration3 = helper.makeConfig(dict: ["only_rules": ["mock"]])
    #expect(cache.violations(forFile: file, configuration: configuration3) == violations)
  }

  // MARK: Sing-File Cache Invalidation

  // Two subsequent lints with a file touch in between causes just that one
  // file to be re-linted, with the cache used for all other files
  @Test func changedFileCausesJustThatFileToBeLintWithCacheUsedForAllOthers() {
    let helper = makeCacheTestHelper(dict: ["only_rules": ["mock"], "reporter": "json"])
    let (file1, file2) = ("file1.swift", "file2.swift")
    let violations1 = helper.makeViolations(file: file1)
    let violations2 = helper.makeViolations(file: file2)

    cacheAndValidate(
      violations: violations1,
      forFile: file1,
      configuration: helper.configuration,
    )
    cacheAndValidate(
      violations: violations2,
      forFile: file2,
      configuration: helper.configuration,
    )
    helper.touch(file: file2)
    #expect(
      cache
        .violations(forFile: file1, configuration: helper.configuration) == violations1)
    #expect(cache.violations(forFile: file2, configuration: helper.configuration) == nil)
  }

  @Test func fileRemovedPreservesThatFileInTheCacheAndDoesNotCauseAnyOtherFilesToBeLinted() {
    let helper = makeCacheTestHelper(dict: ["only_rules": ["mock"], "reporter": "json"])
    let (file1, file2) = ("file1.swift", "file2.swift")
    let violations1 = helper.makeViolations(file: file1)
    let violations2 = helper.makeViolations(file: file2)

    cacheAndValidate(
      violations: violations1,
      forFile: file1,
      configuration: helper.configuration,
    )
    cacheAndValidate(
      violations: violations2,
      forFile: file2,
      configuration: helper.configuration,
    )
    #expect(helper.fileCount() == 2)
    helper.remove(file: file2)
    #expect(
      cache
        .violations(forFile: file1, configuration: helper.configuration) == violations1)
    #expect(helper.fileCount() == 1)
  }

  // MARK: All-File Cache Invalidation

  @Test func disabledRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted() throws {
    let initialConfig = try Configuration(dict: ["disabled_rules": ["nesting"]])
    cacheAndValidateNoViolationsTwoFiles(configuration: initialConfig)

    // Change
    try validateNewConfigDoesNotHitCache(
      dict: ["disabled_rules": ["todo"]], initialConfig: initialConfig,
    )
    // Addition
    try validateNewConfigDoesNotHitCache(
      dict: ["disabled_rules": ["nesting", "todo"]], initialConfig: initialConfig,
    )
    // Removal
    try validateNewConfigDoesNotHitCache(
      dict: ["disabled_rules": [Any]()], initialConfig: initialConfig,
    )
  }

  @Test func optInRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted() throws {
    let initialConfig = try Configuration(dict: ["opt_in_rules": ["attributes"]])
    cacheAndValidateNoViolationsTwoFiles(configuration: initialConfig)

    // Change
    try validateNewConfigDoesNotHitCache(
      dict: ["opt_in_rules": ["empty_count"]], initialConfig: initialConfig,
    )
    // Rules addition
    try validateNewConfigDoesNotHitCache(
      dict: ["opt_in_rules": ["attributes", "empty_count"]],
      initialConfig: initialConfig,
    )
    // Removal
    try validateNewConfigDoesNotHitCache(
      dict: ["opt_in_rules": [Any]()], initialConfig: initialConfig,
    )
  }

  @Test func enabledRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted() throws {
    let initialConfig = try Configuration(dict: ["enabled_rules": ["attributes"]])
    cacheAndValidateNoViolationsTwoFiles(configuration: initialConfig)

    // Change
    try validateNewConfigDoesNotHitCache(
      dict: ["enabled_rules": ["empty_count"]], initialConfig: initialConfig,
    )
    // Addition
    try validateNewConfigDoesNotHitCache(
      dict: ["enabled_rules": ["attributes", "empty_count"]],
      initialConfig: initialConfig,
    )
    // Removal
    try validateNewConfigDoesNotHitCache(
      dict: ["enabled_rules": [Any]()], initialConfig: initialConfig,
    )
  }

  @Test func onlyRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted() throws {
    let initialConfig = try Configuration(dict: ["only_rules": ["nesting"]])
    cacheAndValidateNoViolationsTwoFiles(configuration: initialConfig)

    // Change
    try validateNewConfigDoesNotHitCache(
      dict: ["only_rules": ["todo"]], initialConfig: initialConfig,
    )
    // Addition
    try validateNewConfigDoesNotHitCache(
      dict: ["only_rules": ["nesting", "todo"]], initialConfig: initialConfig,
    )
    // Removal
    try validateNewConfigDoesNotHitCache(
      dict: ["only_rules": [Any]()],
      initialConfig: initialConfig,
    )
  }

  @Test func ruleConfigurationChangedOrAddedOrRemovedCausesAllFilesToBeReLinted() {
    let helper = makeCacheTestHelper(dict: ["mock": [10, 20]])
    cacheAndValidateNoViolationsTwoFiles(configuration: helper.configuration)

    let (file1, file2) = ("file1.swift", "file2.swift")

    // Change
    let changedConfig = helper.makeConfig(dict: ["mock": [5, 15]])
    #expect(cache.violations(forFile: file1, configuration: changedConfig) == nil)
    #expect(cache.violations(forFile: file2, configuration: changedConfig) == nil)

    // Original still cached
    #expect(cache.violations(forFile: file1, configuration: helper.configuration)! == [])
    #expect(cache.violations(forFile: file2, configuration: helper.configuration)! == [])

    // Removal (back to defaults, different from [10, 20])
    let defaultConfig = helper.makeConfig(dict: [:])
    #expect(cache.violations(forFile: file1, configuration: defaultConfig) == nil)
    #expect(cache.violations(forFile: file2, configuration: defaultConfig) == nil)
  }

  @Test func swiftVersionChangedRemovedCausesAllFilesToBeReLinted() {
    let fileManager = TestFileManager()
    cache = LinterCache(fileManager: fileManager)
    let helper = makeCacheTestHelper(dict: [:])
    let file = "foo.swift"
    let violations = helper.makeViolations(file: file)

    cacheAndValidate(violations: violations, forFile: file, configuration: helper.configuration)
    let thisSwiftVersionCache = cache

    let differentSwiftVersion = SwiftVersion(rawValue: "5.0.0")
    cache = LinterCache(fileManager: fileManager, swiftVersion: differentSwiftVersion)

    #expect(
      thisSwiftVersionCache
        .violations(forFile: file, configuration: helper.configuration) != nil,
    )
    #expect(cache.violations(forFile: file, configuration: helper.configuration) == nil)
  }
}
