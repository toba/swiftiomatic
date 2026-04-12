import Foundation
import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

/// When true, skip expensive variant tests (emoji, shebang, comment, string, disable, severity).
/// Variants run only when `SWIFTIOMATIC_FULL_TESTS=1` is set.
private let fastTests: Bool = ProcessInfo.processInfo.environment["SWIFTIOMATIC_FULL_TESTS"] == nil

// MARK: - File Helpers

private let violationMarker = "↓"

extension SwiftSource {
  static func testFile(
    withContents contents: String,
    persistToDisk: Bool = false,
  ) -> SwiftSource {
    if persistToDisk {
      let url = URL(filePath: NSTemporaryDirectory(), directoryHint: .isDirectory)
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("swift")
      try? Data(contents.utf8).write(to: url)
      return SwiftSource(path: url.path, isTestFile: true)!
    }
    return SwiftSource(contents: contents, isTestFile: true)
  }

  func makeCompilerArguments() async -> [String] {
    let sdk = await macOSSDKPath()
    let frameworks = URL(filePath: sdk, directoryHint: .isDirectory)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Library")
      .appendingPathComponent("Frameworks")
      .path

    return [
      "-F", frameworks,
      "-sdk", sdk,
      "-Xfrontend", "-enable-objc-interop",
      "-j4",
      path!,
    ]
  }
}

// MARK: - String Helpers

extension String {
  func stringByAppendingPathComponent(_ pathComponent: String) -> String {
    URL(filePath: self).appendingPathComponent(pathComponent).filepath
  }
}


let allRuleIdentifiers = Set(RuleRegistry.shared.list.rules.keys)

// MARK: - Configuration Helpers

extension Configuration {
  func applyingConfiguration(from example: Example) -> Configuration {
    guard let exampleConfiguration = example.configuration,
      case .onlyConfiguration(let onlyRules) = rulesMode,
      let firstRule = (onlyRules.first { $0 != "redundant_disable_command" }),
      case let configDict:[_: any Sendable] = [
        "only_rules": onlyRules,
        firstRule: exampleConfiguration,
      ],
      let config = try? Configuration(dict: configDict)
    else { return self }
    return config
  }
}

// Global caches are now internally thread-safe via Mutex (Synchronization framework).
// Each test creates independent SwiftSource instances with unique UUID cache keys,
// so no global serialization lock is needed.

// MARK: - Violation Helpers

func violations(
  _ example: Example,
  config inputConfig: Configuration = Configuration.default,
  requiresFileOnDisk: Bool = false,
) async -> [RuleViolation] {
  let config = inputConfig.applyingConfiguration(from: example)
  let stringStrippingMarkers = example.removingViolationMarkers()
  guard requiresFileOnDisk else {
    let file = SwiftSource.testFile(withContents: stringStrippingMarkers.code)
    let storage = RuleStorage()
    let linter = await Linter(file: file, configuration: config).collect(into: storage)
    return linter.ruleViolations(using: storage)
  }

  let file = SwiftSource.testFile(
    withContents: stringStrippingMarkers.code,
    persistToDisk: true,
  )
  let storage = RuleStorage()
  let collector = Linter(
    file: file,
    configuration: config,
    compilerArguments: await file.makeCompilerArguments(),
  )
  let linter = await collector.collect(into: storage)
  return linter.ruleViolations(using: storage).withoutFiles()
}

extension Collection<String> {
  func violations(config: Configuration = Configuration.default, requiresFileOnDisk: Bool = false)
    async -> [RuleViolation]
  {
    await map { SwiftSource.testFile(withContents: $0, persistToDisk: requiresFileOnDisk) }
      .violations(config: config, requiresFileOnDisk: requiresFileOnDisk)
  }

  func corrections(
    config: Configuration = Configuration.default,
    requiresFileOnDisk: Bool = false,
  ) async -> [String: Int] {
    await map { SwiftSource.testFile(withContents: $0, persistToDisk: requiresFileOnDisk) }
      .corrections(config: config, requiresFileOnDisk: requiresFileOnDisk)
  }
}

extension Collection where Element: SwiftSource {
  func violations(config: Configuration = Configuration.default, requiresFileOnDisk: Bool = false)
    async -> [RuleViolation]
  {
    let storage = RuleStorage()
    // Two-pass: collect all files first so collecting rules see the full set
    var collected = [CollectedLinter]()
    for file in self {
      let linter = Linter(
        file: file, configuration: config,
        compilerArguments: requiresFileOnDisk ? await file.makeCompilerArguments() : [],
      )
      await collected.append(linter.collect(into: storage))
    }
    var violations = [RuleViolation]()
    for linter in collected {
      violations.append(contentsOf: linter.ruleViolations(using: storage))
    }
    return requiresFileOnDisk ? violations.withoutFiles() : violations
  }

  func corrections(
    config: Configuration = Configuration.default,
    requiresFileOnDisk: Bool = false,
  ) async -> [String: Int] {
    let storage = RuleStorage()
    var collected = [CollectedLinter]()
    for file in self {
      let linter = Linter(
        file: file,
        configuration: config,
        compilerArguments: requiresFileOnDisk ? await file.makeCompilerArguments() : [],
      )
      await collected.append(linter.collect(into: storage))
    }
    var corrections = [String: Int]()
    for linter in collected {
      for (ruleName, numberOfCorrections) in linter.correct(using: storage) {
        corrections[ruleName] = numberOfCorrections
      }
    }
    return corrections
  }
}

extension Collection<RuleViolation> {
  fileprivate func withoutFiles() -> [RuleViolation] {
    map { violation in
      let locationWithoutFile = Location(
        file: nil, line: violation.location.line,
        column: violation.location.column,
      )
      return violation.with(location: locationWithoutFile)
    }
  }
}

extension Collection<Example> {
  func removingViolationMarkers() -> [Element] {
    map { $0.removingViolationMarkers() }
  }
}

// MARK: - Single-Rule Violations

/// Build a config for a single rule and return violations.
func ruleViolations(
  _ example: Example,
  rule identifier: String,
  configuration: Any? = nil,
) async throws -> [RuleViolation] {
  let config = try #require(makeConfig(configuration, identifier))
  return await violations(example, config: config)
}

// MARK: - Config Builder

func makeConfig(
  _ ruleConfiguration: Any?,
  _ identifier: String,
  skipDisableCommandTests: Bool = false,
) -> Configuration? {
  let redundantDisableCommandRuleIdentifier = RedundantDisableCommandRule.identifier
  let identifiers: Set<String> =
    skipDisableCommandTests
    ? [identifier]
    : [identifier, redundantDisableCommandRuleIdentifier]

  if let ruleConfiguration, let ruleType = RuleRegistry.shared.rule(forID: identifier) {
    return (try? ruleType.init(configuration: ruleConfiguration)).flatMap { configuredRule in
      let rules =
        skipDisableCommandTests
        ? [configuredRule]
        : [
          configuredRule,
          RedundantDisableCommandRule(),
        ]
      return Configuration(
        rulesMode: .onlyConfiguration(identifiers),
        allRulesWrapped: rules.map {
          ConfiguredRule(
            rule: $0,
            initializedWithNonEmptyConfiguration: false,
          )
        },
      )
    }
  }
  return Configuration(rulesMode: .onlyConfiguration(identifiers))
}

// MARK: - Rendering

private func cleanedContentsAndMarkerOffsets(from contents: String) -> (String, [Int]) {
  var contents = contents.bridge()
  var markerOffsets = [Int]()
  var markerRange = contents.range(of: violationMarker)
  while markerRange.location != NSNotFound {
    markerOffsets.append(markerRange.location)
    contents = contents.replacingCharacters(in: markerRange, with: "").bridge()
    markerRange = contents.range(of: violationMarker)
  }
  return (contents.bridge(), markerOffsets.sorted())
}

private func render(violations: [RuleViolation], in contents: String) -> String {
  var contents = StringView(contents).lines.map(\.content)
  for violation in violations.sorted(by: { $0.location > $1.location }) {
    guard let line = violation.location.line,
      let character = violation.location.column
    else { continue }

    let message =
      String(repeating: " ", count: character - 1) + "^ "
      + [
        "\(violation.severity.rawValue): ",
        "\(violation.ruleName) Violation: ",
        violation.reason.text,
        " (\(violation.ruleIdentifier))",
      ].joined()
    if line >= contents.count {
      contents.append(message)
    } else {
      contents.insert(message, at: line)
    }
  }
  return """
    ```
    \(contents.joined(separator: "\n"))
    ```
    """
}

private func render(locations: [Location], in contents: String) -> String {
  var contents = StringView(contents).lines.map(\.content)
  for location in locations.sorted(by: >) {
    guard let line = location.line, let character = location.column else { continue }
    let content = NSMutableString(string: contents[line - 1])
    content.insert("↓", at: character - 1)
    contents[line - 1] = content.bridge()
  }
  return """
    ```
    \(contents.joined(separator: "\n"))
    ```
    """
}

// MARK: - Correction Assertion

private func assertCorrection(
  _ before: Example, expected: Example, config: Configuration,
  sourceLocation: Testing.SourceLocation = #_sourceLocation,
) async {
  let (cleanedBefore, _) = cleanedContentsAndMarkerOffsets(from: before.code)
  let file = SwiftSource.testFile(withContents: cleanedBefore)
  let storage = RuleStorage()
  let collector = Linter(file: file, configuration: config)
  let linter = await collector.collect(into: storage)
  let corrections = linter.correct(using: storage)
  #expect(
    corrections.count >= (before.code != expected.code ? 1 : 0),
    "Expected corrections",
    sourceLocation: sourceLocation,
  )
  #expect(
    file.contents == expected.code,
    "File contents don't match expected",
    sourceLocation: sourceLocation,
  )
}

extension String {
  fileprivate func toStringLiteral() -> String {
    "\"" + replacingOccurrences(of: "\n", with: "\\n") + "\""
  }
}

// MARK: - Test Correction

private func testCorrection(
  _ correction: (Example, Example),
  configuration: Configuration,
  shouldTestMultiByteOffsets: Bool,
) async {
  var config = configuration
  if let correctionConfiguration = correction.0.configuration,
    case .onlyConfiguration(let onlyRules) = configuration.rulesMode,
    let ruleToConfigure = (onlyRules.first { $0 != RedundantDisableCommandRule.identifier }),
    case let configDict:[_: any Sendable] = [
      "only_rules": onlyRules,
      ruleToConfigure: correctionConfiguration,
    ],
    let newConfig = try? Configuration(dict: configDict)
  {
    config = newConfig
  }

  await assertCorrection(correction.0, expected: correction.1, config: config)
  if shouldTestMultiByteOffsets, correction.0.shouldTestMultiByteOffsets {
    await assertCorrection(
      addEmoji(correction.0),
      expected: addEmoji(correction.1),
      config: config,
    )
  }
}

private func addEmoji(_ example: Example) -> Example {
  example.with(code: "/* 👨‍👩‍👧‍👦👨‍👩‍👧‍👦👨‍👩‍👧‍👦 */\n\(example.code)")
}

private func addShebang(_ example: Example) -> Example {
  example.with(code: "#!/usr/bin/env swift\n\(example.code)")
}

// MARK: - verifyRule (standalone function)

/// Ensures rules are registered before any lint test runs.
/// Uses the shared `_testSetup` from TestTraits.swift.

func verifyRule(
  _ ruleType: (some Rule).Type,
  ruleConfiguration: Any? = nil,
  commentDoesNotViolate: Bool = true,
  stringDoesNotViolate: Bool = true,
  skipCommentTests: Bool = false,
  skipStringTests: Bool = false,
  skipDisableCommandTests: Bool = false,
  shouldTestMultiByteOffsets: Bool = true,
  testShebang: Bool = true,
  sourceLocation: Testing.SourceLocation = #_sourceLocation,
) async {
  await verifyRule(
    TestExamples(from: ruleType),
    ruleConfiguration: ruleConfiguration,
    commentDoesNotViolate: commentDoesNotViolate,
    stringDoesNotViolate: stringDoesNotViolate,
    skipCommentTests: skipCommentTests,
    skipStringTests: skipStringTests,
    skipDisableCommandTests: skipDisableCommandTests,
    shouldTestMultiByteOffsets: shouldTestMultiByteOffsets,
    testShebang: testShebang,
    sourceLocation: sourceLocation,
  )
}

func verifyRule(
  _ examples: TestExamples,
  ruleConfiguration: Any? = nil,
  commentDoesNotViolate: Bool = true,
  stringDoesNotViolate: Bool = true,
  skipCommentTests: Bool = false,
  skipStringTests: Bool = false,
  skipDisableCommandTests: Bool = false,
  shouldTestMultiByteOffsets: Bool = true,
  testShebang: Bool = true,
  sourceLocation: Testing.SourceLocation = #_sourceLocation,
) async {
  _ = _testSetup

  guard examples.minSwiftVersion <= .current else { return }

  guard
    let config = makeConfig(
      ruleConfiguration,
      examples.identifier,
      skipDisableCommandTests: skipDisableCommandTests,
    )
  else {
    Testing.Issue.record("Failed to create configuration", sourceLocation: sourceLocation)
    return
  }

  let disableCommands: [String]
  if skipDisableCommandTests {
    disableCommands = []
  } else {
    disableCommands = ["// sm:disable \(examples.identifier)\n"]
  }

  await verifyLint(
    examples,
    config: config,
    commentDoesNotViolate: commentDoesNotViolate,
    stringDoesNotViolate: stringDoesNotViolate,
    skipCommentTests: skipCommentTests,
    skipStringTests: skipStringTests,
    disableCommands: disableCommands,
    shouldTestMultiByteOffsets: shouldTestMultiByteOffsets,
    testShebang: testShebang,
    sourceLocation: sourceLocation,
  )
  await verifyCorrections(
    examples,
    config: config,
    disableCommands: disableCommands,
    shouldTestMultiByteOffsets: shouldTestMultiByteOffsets,
  )
}

// MARK: - verifyLint

func verifyLint(
  _ examples: TestExamples,
  config: Configuration,
  commentDoesNotViolate: Bool = true,
  stringDoesNotViolate: Bool = true,
  skipCommentTests: Bool = false,
  skipStringTests: Bool = false,
  disableCommands: [String] = [],
  shouldTestMultiByteOffsets: Bool = true,
  testShebang: Bool = true,
  sourceLocation: Testing.SourceLocation = #_sourceLocation,
) async {
  func verify(triggers: [Example], nonTriggers: [Example]) async {
    await verifyExamples(
      triggers: triggers, nonTriggers: nonTriggers, configuration: config,
      requiresFileOnDisk: examples.requiresFileOnDisk,
    )
  }
  func makeViolations(_ example: Example) async -> [RuleViolation] {
    await violations(
      example, config: config, requiresFileOnDisk: examples.requiresFileOnDisk,
    )
  }

  let focused = examples.focused()
  let (triggers, nonTriggers) = (
    focused.triggeringExamples,
    focused.nonTriggeringExamples,
  )
  await verify(triggers: triggers, nonTriggers: nonTriggers)

  // Skip expensive variant tests in fast mode
  guard !fastTests else { return }

  if shouldTestMultiByteOffsets {
    await verify(
      triggers: triggers.filter(\.shouldTestMultiByteOffsets).map(addEmoji),
      nonTriggers: nonTriggers.filter(\.shouldTestMultiByteOffsets).map(addEmoji),
    )
  }

  if testShebang {
    await verify(
      triggers: triggers.filter(\.shouldTestMultiByteOffsets).map(addShebang),
      nonTriggers: nonTriggers.filter(\.shouldTestMultiByteOffsets).map(addShebang),
    )
  }

  // Comment doesn't violate
  if !skipCommentTests {
    let triggersToCheck = triggers.filter(\.shouldTestWrappingInComment)
    var commentViolationCount = 0
    for trigger in triggersToCheck {
      commentViolationCount += await makeViolations(
        trigger.with(code: "/*\n  " + trigger.code + "\n */"),
      ).count
    }
    #expect(
      commentViolationCount == (commentDoesNotViolate ? 0 : triggersToCheck.count),
      "Violation(s) still triggered when code was nested inside a comment",
      sourceLocation: sourceLocation,
    )
  }

  // String doesn't violate
  if !skipStringTests {
    let triggersToCheck = triggers.filter(\.shouldTestWrappingInString)
    var stringViolationCount = 0
    for trigger in triggersToCheck {
      stringViolationCount += await makeViolations(
        trigger.with(code: trigger.code.toStringLiteral()),
      ).count
    }
    #expect(
      stringViolationCount == (stringDoesNotViolate ? 0 : triggersToCheck.count),
      "Violation(s) still triggered when code was nested inside a string literal",
      sourceLocation: sourceLocation,
    )
  }

  // Disabled rule doesn't violate and disable command isn't redundant
  for command in disableCommands {
    let disabledTriggers =
      triggers
      .filter(\.shouldTestDisableCommand)
      .map { $0.with(code: command + $0.code) }

    for trigger in disabledTriggers {
      let violationsPartitionedByType = await makeViolations(trigger)
        .partitioned { $0.ruleIdentifier == RedundantDisableCommandRule.identifier }

      #expect(
        violationsPartitionedByType.first.isEmpty,
        "Violation(s) still triggered although rule was disabled",
      )
      #expect(
        violationsPartitionedByType.second.isEmpty,
        "Disable command was redundant since no violations(s) triggered",
      )
    }
  }

  // Severity can be changed — skip when variant tests are skipped (batch mode)
  guard !disableCommands.isEmpty else { return }
  let ruleType = RuleRegistry.shared.rule(forID: examples.identifier)
  if ruleType?.init().options is (any SeverityBasedRuleOptions),
    let example = triggers.first(where: { $0.configuration == nil })
  {
    let withWarning = Example(example.code, configuration: ["severity": "warning"])
    let warningViolations = await violations(withWarning, config: config)
    #expect(
      warningViolations.allSatisfy { $0.severity == .warning },
      "Violation severity cannot be changed to warning",
    )

    let withError = Example(example.code, configuration: ["severity": "error"])
    let errorViolations = await violations(withError, config: config)
    #expect(
      errorViolations.allSatisfy { $0.severity == .error },
      "Violation severity cannot be changed to error",
    )
  }
}

// MARK: - verifyCorrections

func verifyCorrections(
  _ examples: TestExamples,
  config: Configuration,
  disableCommands: [String],
  shouldTestMultiByteOffsets: Bool,
  parserDiagnosticsDisabledForTests: Bool = true,
) async {
  let focused = examples.focused()

  await $parserDiagnosticsDisabledForTests.withValue(parserDiagnosticsDisabledForTests) {
    // corrections
    for correction in focused.corrections {
      await testCorrection(
        correction,
        configuration: config,
        shouldTestMultiByteOffsets: !fastTests && shouldTestMultiByteOffsets,
      )
    }
    // make sure strings that don't trigger aren't corrected
    for nonTriggeringExample in focused.nonTriggeringExamples {
      await testCorrection(
        (nonTriggeringExample, nonTriggeringExample),
        configuration: config,
        shouldTestMultiByteOffsets: !fastTests && shouldTestMultiByteOffsets,
      )
    }

    // Skip disable command correction tests in fast mode
    guard !fastTests else { return }

    // "disable" commands do not correct
    for (before, _) in focused.corrections {
      for command in disableCommands {
        let beforeDisabled = command + before.code
        let expectedCleaned =
          before
          .with(code: cleanedContentsAndMarkerOffsets(from: beforeDisabled).0)
        await assertCorrection(expectedCleaned, expected: expectedCleaned, config: config)
      }
    }
  }
}

// MARK: - verifyExamples

private func verifyExamples(
  triggers: [Example],
  nonTriggers: [Example],
  configuration config: Configuration,
  requiresFileOnDisk: Bool,
) async {
  // Non-triggering examples must not violate
  for nonTrigger in nonTriggers {
    let unexpectedViolations = await violations(
      nonTrigger, config: config,
      requiresFileOnDisk: requiresFileOnDisk,
    )
    #expect(
      unexpectedViolations.isEmpty,
      "Non-triggering example had violations: \(unexpectedViolations)",
    )
  }

  // Triggering examples must violate at marked locations
  for trigger in triggers {
    let triggerViolations = await violations(
      trigger, config: config,
      requiresFileOnDisk: requiresFileOnDisk,
    )

    let (cleanTrigger, markerOffsets) = cleanedContentsAndMarkerOffsets(from: trigger.code)
    if markerOffsets.isEmpty {
      #expect(
        !triggerViolations.isEmpty,
        "Marker-less triggering example produced 0 violations: '\(trigger)'",
      )
      continue
    }
    let file = SwiftSource.testFile(withContents: cleanTrigger)
    let expectedLocations = markerOffsets.map { Location(file: file, characterOffset: $0) }

    let violationsAtUnexpectedLocation =
      triggerViolations
      .filter { !expectedLocations.contains($0.location) }
    #expect(
      violationsAtUnexpectedLocation.isEmpty,
      "Violations at unexpected locations: \(violationsAtUnexpectedLocation)",
    )

    let violatedLocations = triggerViolations.map(\.location)
    let locationsWithoutViolation =
      expectedLocations
      .filter { !violatedLocations.contains($0) }
    #expect(
      locationsWithoutViolation.isEmpty,
      "Expected violations not found at: \(locationsWithoutViolation)",
    )

    #expect(
      triggerViolations.count == expectedLocations.count,
      "Expected \(expectedLocations.count) violations, got \(triggerViolations.count) for '\(trigger)'",
    )
    for (triggerViolation, expectedLocation) in zip(triggerViolations, expectedLocations) {
      #expect(
        triggerViolation.location == expectedLocation,
        "'\(trigger)' violation didn't match expected location.",
      )
    }
  }
}
