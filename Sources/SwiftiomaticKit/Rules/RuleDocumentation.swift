import Foundation

/// User-facing documentation for a single Swiftiomatic rule
struct RuleDocumentation {
  private let ruleType: any Rule.Type

  /// Whether this rule is an opt-in rule
  var isOptInRule: Bool { ruleType.isOptIn }

  /// Whether this rule requires compiler arguments
  var isAnalyzerRule: Bool { ruleType.runsWithCompilerArguments }

  /// Whether this rule is a linter rule (non-analyzer)
  var isLinterRule: Bool { !isAnalyzerRule }

  /// Whether this rule uses SourceKit
  var usesSourceKit: Bool { ruleType.runsWithSourceKit }

  /// Whether this rule is disabled by default
  var isDisabledByDefault: Bool { ruleType.isOptIn }

  /// Whether this rule is enabled by default
  var isEnabledByDefault: Bool { !isDisabledByDefault }

  /// Create a ``RuleDocumentation`` instance from a ``Rule`` type
  ///
  /// - Parameters:
  ///   - ruleType: A subtype of the ``Rule`` protocol to document.
  init(_ ruleType: any Rule.Type) { self.ruleType = ruleType }

  /// The name of the documented rule
  var ruleName: String { ruleType.ruleName }

  /// The identifier of the documented rule
  var ruleIdentifier: String { ruleType.identifier }

  /// The name of the file on disk for this rule documentation
  var fileName: String { "\(ruleType.identifier).md" }

  /// The contents of the file for this rule documentation
  var fileContents: String {
    var content = [
      h1(ruleType.ruleName),
      ruleType.ruleSummary,
      detailsSummary(ruleType.init()),
    ]
    if let rationale = ruleType.ruleRationale {
      content += [h2("Rationale")]
      content.append(rationale.formattedRationale)
    }
    let nonTriggeringExamples = ruleType.ruleNonTriggeringExamples.filter {
      !$0.isExcludedFromDocumentation
    }
    if nonTriggeringExamples.isNotEmpty {
      content += [h2("Non Triggering Examples")]
      content += nonTriggeringExamples.map(formattedCode)
    }
    let triggeringExamples = ruleType.ruleTriggeringExamples
      .filter { !$0.isExcludedFromDocumentation }
    if triggeringExamples.isNotEmpty {
      content += [h2("Triggering Examples")]
      content += triggeringExamples.map(formattedCode)
    }
    return content.joined(separator: "\n\n")
  }

  private func formattedCode(_ example: Example) -> String {
    if let config = example.configuration,
      let configuredRule = try? ruleType.init(configuration: config)
    {
      let configDescription = configuredRule.createConfigurationDescription(
        exclusiveOptions: Set(config.keys),
      )
      return """
        ```swift
        //
        // \(configDescription.yaml().linesPrefixed(with: "// "))
        //

        \(example.code)

        ```
        """
    }
    return """
      ```swift
      \(example.code)
      ```
      """
  }
}

private func h1(_ text: String) -> String {
  "# \(text)"
}

private func h2(_ text: String) -> String {
  "## \(text)"
}

// MARK: - Rationale Formatting

extension String {
  var formattedRationale: String {
    formattedRationale(forConsole: false)
  }

  var consoleRationale: String {
    formattedRationale(forConsole: true)
  }

  private func formattedRationale(forConsole: Bool) -> String {
    var insideMultilineString = false
    return components(separatedBy: "\n").compactMap { line -> String? in
      if line.contains("```") {
        if insideMultilineString {
          insideMultilineString = false
          return forConsole ? nil : line
        }
        insideMultilineString = true
        if line.hasSuffix("```") {
          return forConsole ? nil : (line + "swift")
        }
      }
      return line.indent(by: (insideMultilineString && forConsole) ? 4 : 0)
    }.joined(separator: "\n")
  }
}

private func detailsSummary(_ rule: some Rule) -> String {
  let ruleDescription = """
    * **Identifier:** `\(type(of: rule).identifier)`
    * **Enabled by default:** \(type(of: rule).isOptIn ? "No" : "Yes")
    * **Supports autocorrection:** \(type(of: rule).isCorrectable ? "Yes" : "No")
    * **Scope:** \(type(of: rule).ruleScope)
    * **Analyzer rule:** \(type(of: rule).runsWithCompilerArguments ? "Yes" : "No")
    * **Minimum Swift compiler version:** \(type(of: rule).ruleMinSwiftVersion.rawValue)
    """
  let description = rule.createConfigurationDescription()
  if description.hasContent {
    return ruleDescription + """

      * **Default configuration:**
        \(description.markdown().linesPrefixed(with: "  "))
      """
  }
  return ruleDescription
}
