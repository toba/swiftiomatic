import Foundation
import Testing

@testable import Swiftiomatic

/// A test case for parameterized `testFormatting(for:_:rule:)` tests.
///
/// When `output` is `nil`, the test asserts no change (input is already formatted).
struct FormatCase: CustomTestStringConvertible, Sendable {
  let testDescription: String
  let input: String
  let output: String?

  init(_ label: String, input: String, output: String? = nil) {
    self.testDescription = label
    self.input = input
    self.output = output
  }
}

// Eagerly initialize format globals to avoid lazy-init races during parallel tests.
private let _initFormatGlobals: Void = {
  _ = FormatRules.all
  _ = Descriptors.all
}()

/// When true, skip expensive "all rules" interaction checks and lint verification.
/// Set `SWIFTIOMATIC_FAST_TESTS=1` to enable.
private let fastTests: Bool = ProcessInfo.processInfo.environment["SWIFTIOMATIC_FAST_TESTS"] != nil

func testFormatting(
  for input: String,
  _ output: String? = nil,
  rule: FormatRule,
  options: FormatOptions = .default,
  exclude: [FormatRule] = [],
  sourceLocation: SourceLocation = #_sourceLocation,
) {
  testFormatting(
    for: input, output.map { [$0] } ?? [], rules: [rule],
    options: options, exclude: exclude, sourceLocation: sourceLocation,
  )
}

func testFormatting(
  for input: String,
  _ outputs: [String] = [],
  rules: [FormatRule],
  options: FormatOptions = .default,
  exclude: [FormatRule] = [],
  sourceLocation: SourceLocation = #_sourceLocation,
) {
  _ = _initFormatGlobals
  var options = options
  if options.timeout == FormatOptions.default.timeout {
    options.timeout = 120
  }

  // Check swift versions updated
  if options.swiftVersion != .undefined {
    let maxVersion = Version(rawValue: swiftVersions.last!)!
    #expect(
      options.swiftVersion <= maxVersion,
      "Swift version '\(options.swiftVersion)' not found in swiftVersions array",
      sourceLocation: sourceLocation,
    )
  }

  if !outputs.isEmpty, input == outputs.first, input == outputs.last {
    Issue.record("Redundant output parameter (input == output)", sourceLocation: sourceLocation)
  }
  precondition((0...2).contains(outputs.count), "Only 0, 1 or 2 output parameters permitted")
  precondition(Set(exclude).intersection(rules).isEmpty, "Cannot exclude rule under test")
  let output = outputs.first ?? input
  let output2 = outputs.last ?? input

  // 1. Core assertion: single-rule format produces expected output
  let formatResult: (output: String, changes: [Swiftiomatic.Formatter.Change])
  do {
    formatResult = try format(input, rules: rules, options: options)
  } catch {
    Issue.record("Failed to format input, threw error \(error)", sourceLocation: sourceLocation)
    return
  }
  #expect(formatResult.output == output, sourceLocation: sourceLocation)

  if input != output, formatResult.output == output {
    #expect(
      !formatResult.changes.isEmpty,
      """
      Rules applied changes but unexpectedly produced no `Swiftiomatic.Formatter.Change`s. \
      This would result in no messages being printed when running with --lint. \
      This can happen in cases where a rule only moves lines, but doesn't modify their contents. \
      You can fix this by using `formatter.moveTokens`.
      """, sourceLocation: sourceLocation,
    )
  }

  // 2. Idempotence: re-formatting output with same rules produces no change
  if input != output {
    do {
      #expect(
        try format(output, rules: rules, options: options).output
          == output, sourceLocation: sourceLocation,
      )
    } catch {
      Issue.record("Failed to re-format output: \(error)", sourceLocation: sourceLocation)
    }
    // 3. Disable command: disabled rule produces no change
    if !input.hasPrefix("#!") {
      for rule in rules {
        let disabled = "// sm:disable \(rule)\n\(input)"
        do {
          #expect(
            try format(disabled, rules: [rule], options: options).output
              == disabled, "Failed to disable \(rule) rule",
            sourceLocation: sourceLocation,
          )
        } catch {
          Issue.record(
            "Failed to format with disabled rule: \(error)",
            sourceLocation: sourceLocation,
          )
        }
      }
    }
  }

  // Skip expensive cross-rule interaction checks in fast mode
  guard !fastTests else { return }

  let defaultExclusions =
    FormatRules.deprecated + [
      .linebreakAtEndOfFile,
      .organizeDeclarations,
      .extensionAccessControl,
      .markTypes,
      .blockComments,
      .unusedPrivateDeclarations,
      .preferFinalClasses,
    ]
  let exclude = exclude + defaultExclusions.filter { !rules.contains($0) }

  // 4. All-rules interaction: formatting with all rules produces expected output2
  do {
    #expect(
      try format(input, rules: FormatRules.all(except: exclude), options: options).output
        == output2, sourceLocation: sourceLocation,
    )
  } catch {
    Issue.record("Failed to format with all rules: \(error)", sourceLocation: sourceLocation)
  }
  if input != output2, output != output2 {
    do {
      #expect(
        try format(output2, rules: FormatRules.all(except: exclude), options: options)
          .output
          == output2,
        sourceLocation: sourceLocation,
      )
    } catch {
      Issue.record("Failed to re-format output2: \(error)", sourceLocation: sourceLocation)
    }
  }

  // 5. Lint verification: formatted output produces no lint warnings
  #if os(macOS)
    do {
      #expect(
        try lint(output, rules: rules, options: options) == [],
        sourceLocation: sourceLocation,
      )
      #expect(
        try lint(output2, rules: FormatRules.all(except: exclude), options: options)
          == [], sourceLocation: sourceLocation,
      )
    } catch {
      Issue.record("Lint check failed: \(error)", sourceLocation: sourceLocation)
    }
  #endif
}
