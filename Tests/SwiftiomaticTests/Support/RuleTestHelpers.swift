import Testing

@testable import Swiftiomatic

// MARK: - assertLint

/// Assert that a lint rule emits the expected violations at marked locations.
///
/// Uses emoji markers (1️⃣, 2️⃣, ...) to pinpoint where violations should occur.
/// If `findings` is empty, asserts the source triggers no violations.
///
///     assertLint(ForceUnwrappingRule.self, """
///         let x = 1️⃣a!
///         let y = b
///         """,
///         findings: [
///             FindingSpec("1️⃣", message: "Force unwrapping should be avoided"),
///         ]
///     )
func assertLint<R: Rule>(
  _ ruleType: R.Type,
  _ markedSource: String,
  findings: [FindingSpec] = [],
  configuration: [String: any Sendable]? = nil,
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) async {
  _ = _ensureRulesRegistered

  let marked = MarkedText(markedSource)
  let source = marked.textWithoutMarkers

  let config = makeSingleRuleConfig(R.self, ruleConfiguration: configuration)
  guard let config else {
    Issue.record("Failed to create configuration for \(R.id)", sourceLocation: sourceLocation)
    return
  }

  let file = SwiftSource.testFile(withContents: source)
  let storage = RuleStorage()
  let linter = await Linter(file: file, configuration: config).collect(into: storage)
  let violations = linter.ruleViolations(using: storage)

  assertFindings(
    expected: findings,
    markerLocations: marked.markers,
    violations: violations,
    source: source,
    sourceLocation: sourceLocation
  )
}

/// Assert that the source produces no violations for the given rule.
///
///     assertNoViolation(ForceUnwrappingRule.self, "let x = a ?? b")
func assertNoViolation<R: Rule>(
  _ ruleType: R.Type,
  _ source: String,
  configuration: [String: any Sendable]? = nil,
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) async {
  await assertLint(
    ruleType,
    source,
    findings: [],
    configuration: configuration,
    sourceLocation: sourceLocation
  )
}

// MARK: - assertFormatting

/// Assert that a correctable rule transforms `input` into `expected` and emits the expected findings.
///
/// Validates both the corrected output AND the findings. If `findings` is empty,
/// only the correction is checked.
///
///     assertFormatting(TrailingWhitespaceRule.self,
///         input: "let x = 1  1️⃣\n",
///         expected: "let x = 1\n",
///         findings: [
///             FindingSpec("1️⃣", message: "Lines should not have trailing whitespace"),
///         ]
///     )
func assertFormatting<R: Rule>(
  _ ruleType: R.Type,
  input markedInput: String,
  expected: String,
  findings: [FindingSpec] = [],
  configuration: [String: any Sendable]? = nil,
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) async {
  _ = _ensureRulesRegistered

  let marked = MarkedText(markedInput)
  let originalSource = marked.textWithoutMarkers

  let config = makeSingleRuleConfig(R.self, ruleConfiguration: configuration)
  guard let config else {
    Issue.record("Failed to create configuration for \(R.id)", sourceLocation: sourceLocation)
    return
  }

  // First pass: check violations
  let file = SwiftSource.testFile(withContents: originalSource, persistToDisk: true)
  let storage = RuleStorage()
  let linter = await Linter(file: file, configuration: config).collect(into: storage)
  let violations = linter.ruleViolations(using: storage)

  if !findings.isEmpty {
    assertFindings(
      expected: findings,
      markerLocations: marked.markers,
      violations: violations,
      source: originalSource,
      sourceLocation: sourceLocation
    )
  }

  // Second pass: apply corrections iteratively until stable
  await $parserDiagnosticsDisabledForTests.withValue(true) {
    var source = originalSource
    for _ in 0..<10 {
      let corrFile = SwiftSource.testFile(withContents: source, persistToDisk: true)
      let corrStorage = RuleStorage()
      let corrLinter = await Linter(file: corrFile, configuration: config)
        .collect(into: corrStorage)
      let corrections = corrLinter.correct(using: corrStorage)
      let corrected = corrFile.contents
      if corrections.isEmpty || corrected == source {
        break
      }
      source = corrected
    }

    #expect(source == expected, sourceLocation: sourceLocation)
  }
}

// MARK: - assertViolates

/// Assert that the given source triggers at least one violation for the rule.
/// Does not check violation positions or messages — just that the rule fires.
func assertViolates<R: Rule>(
  _ ruleType: R.Type,
  _ source: String,
  configuration: [String: any Sendable]? = nil,
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) async {
  _ = _ensureRulesRegistered

  let config = makeSingleRuleConfig(R.self, ruleConfiguration: configuration)
  guard let config else {
    Issue.record("Failed to create configuration for \(R.id)", sourceLocation: sourceLocation)
    return
  }

  let file = SwiftSource.testFile(withContents: source)
  let storage = RuleStorage()
  let linter = await Linter(file: file, configuration: config).collect(into: storage)
  let violations = linter.ruleViolations(using: storage)

  #expect(
    !violations.isEmpty,
    "Expected at least one violation from \(R.id) but got none",
    sourceLocation: sourceLocation
  )
}

// MARK: - Finding Assertion

private func assertFindings(
  expected specs: [FindingSpec],
  markerLocations: [String: Int],
  violations: [RuleViolation],
  source: String,
  sourceLocation: Testing.SourceLocation
) {
  var remaining = violations

  for spec in specs {
    guard let utf8Offset = markerLocations[spec.marker] else {
      Issue.record(
        "Marker '\(spec.marker)' was not found in the input",
        sourceLocation: sourceLocation
      )
      continue
    }

    let (expectedLine, expectedColumn) = lineAndColumn(
      in: source, atUTF8Offset: utf8Offset
    )

    // Find a violation at the expected location
    guard
      let index = remaining.firstIndex(where: {
        $0.location.line == expectedLine
          && $0.location.column == expectedColumn
      })
    else {
      Issue.record(
        """
        Expected violation '\(spec.message)' at marker '\(spec.marker)' \
        (line:\(expectedLine) col:\(expectedColumn)) \
        but none was emitted
        """,
        sourceLocation: sourceLocation
      )
      continue
    }

    let matched = remaining.remove(at: index)

    // Validate message if specified
    if !spec.message.isEmpty {
      #expect(
        matched.reason.text == spec.message,
        """
        Violation at marker '\(spec.marker)' had wrong message.
        Expected: \(spec.message)
        Actual:   \(matched.reason.text)
        """,
        sourceLocation: sourceLocation
      )
    }
  }

  // Report unexpected violations
  for unexpected in remaining {
    let loc = unexpected.location
    Issue.record(
      """
      Unexpected violation: '\(unexpected.reason.text)' \
      at line:\(loc.line ?? 0) col:\(loc.column ?? 0) \
      [\(unexpected.ruleIdentifier)]
      """,
      sourceLocation: sourceLocation
    )
  }
}

// MARK: - Helpers

private let _ensureRulesRegistered: Void = {
  RuleRegistry.registerAllRulesOnce()
}()

private func makeSingleRuleConfig<R: Rule>(
  _ ruleType: R.Type,
  ruleConfiguration: [String: any Sendable]? = nil
) -> Configuration? {
  if let ruleConfiguration {
    return makeConfig(ruleConfiguration, R.id)
  }
  return makeConfig(nil, R.id)
}

/// Convert a UTF-8 byte offset to 1-based line and column in the given source string.
private func lineAndColumn(in source: String, atUTF8Offset offset: Int) -> (line: Int, column: Int)
{
  var line = 1
  var columnBytes = 0
  var currentByte = 0

  for byte in source.utf8 {
    if currentByte == offset {
      return (line, columnBytes + 1)
    }
    if byte == UInt8(ascii: "\n") {
      line += 1
      columnBytes = 0
    } else {
      columnBytes += 1
    }
    currentByte += 1
  }
  // Offset at end of string
  return (line, columnBytes + 1)
}

/// Line-by-line diff for readable test output.
private func lineDiff(actual: String, expected: String) -> String {
  let actualLines = actual.components(separatedBy: "\n")
  let expectedLines = expected.components(separatedBy: "\n")
  let difference = actualLines.difference(from: expectedLines)

  guard !difference.isEmpty else { return "(no diff)" }

  var insertions = [Int: String]()
  var removals = [Int: String]()

  for change in difference {
    switch change {
    case .insert(let offset, let element, _):
      insertions[offset] = element
    case .remove(let offset, let element, _):
      removals[offset] = element
    }
  }

  var result = "Actual (+) vs Expected (-):\n"
  var expectedLine = 0
  var actualLine = 0

  while expectedLine < expectedLines.count || actualLine < actualLines.count {
    if let removal = removals[expectedLine] {
      result += "-\(removal)\n"
      expectedLine += 1
    } else if let insertion = insertions[actualLine] {
      result += "+\(insertion)\n"
      actualLine += 1
    } else if expectedLine < expectedLines.count {
      result += " \(expectedLines[expectedLine])\n"
      expectedLine += 1
      actualLine += 1
    } else {
      break
    }
  }
  return result
}
