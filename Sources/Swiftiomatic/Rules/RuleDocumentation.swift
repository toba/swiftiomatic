/// User-facing documentation for a single Swiftiomatic rule
struct RuleDocumentation {
    private let ruleType: any Rule.Type

    /// Whether this rule is an opt-in rule
    var isOptInRule: Bool { ruleType.isOptIn }

    /// Whether this rule requires compiler arguments
    var isAnalyzerRule: Bool { ruleType.description.requiresCompilerArguments } // TODO: migrate to configuration

    /// Whether this rule is a linter rule (non-analyzer)
    var isLinterRule: Bool { !isAnalyzerRule }

    /// Whether this rule uses SourceKit
    var usesSourceKit: Bool { ruleType.description.requiresSourceKit } // TODO: migrate to configuration

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
    var ruleName: String { ruleType.description.name } // TODO: migrate to configuration

    /// The identifier of the documented rule
    var ruleIdentifier: String { ruleType.identifier }

    /// The name of the file on disk for this rule documentation
    var fileName: String { "\(ruleType.identifier).md" }

    /// The contents of the file for this rule documentation
    var fileContents: String {
        let description = ruleType.description
        var content = [
            h1(description.name),
            description.description,
            detailsSummary(ruleType.init()),
        ]
        if let formattedRationale = description.formattedRationale {
            content += [h2("Rationale")]
            content.append(formattedRationale)
        }
        let nonTriggeringExamples = description.nonTriggeringExamples.filter {
            !$0.isExcludedFromDocumentation
        }
        if nonTriggeringExamples.isNotEmpty {
            content += [h2("Non Triggering Examples")]
            content += nonTriggeringExamples.map(formattedCode)
        }
        let triggeringExamples = description.triggeringExamples
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

private func detailsSummary(_ rule: some Rule) -> String {
    let ruleDescription = """
    * **Identifier:** `\(type(of: rule).identifier)`
    * **Enabled by default:** \(type(of: rule).isOptIn ? "No" : "Yes")
    * **Supports autocorrection:** \(rule is any CorrectableRule ? "Yes" : "No")
    * **Scope:** \(type(of: rule).ruleScope)
    * **Analyzer rule:** \(type(of: rule).description.requiresCompilerArguments ? "Yes" : "No")
    * **Minimum Swift compiler version:** \(type(of: rule).description.minSwiftVersion.rawValue)
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
