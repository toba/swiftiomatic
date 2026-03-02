struct ContainsOverRangeNilComparisonConfiguration: RuleConfiguration {
    let id = "contains_over_range_nil_comparison"
    let name = "Contains over Range Comparison to Nil"
    let summary = "Prefer `contains` over `range(of:) != nil` and `range(of:) == nil`"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let range = myString.range(of: \"Test\")"),
              Example("myString.contains(\"Test\")"),
              Example("!myString.contains(\"Test\")"),
              Example("resourceString.range(of: rule.regex, options: .regularExpression) != nil"),
            ]
    }
    var triggeringExamples: [Example] {
        ["!=", "=="].flatMap { comparison in
            [
                Example("↓myString.range(of: \"Test\") \(comparison) nil"),
            ]
        }
    }
}
