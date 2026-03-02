struct EmptyStringConfiguration: RuleConfiguration {
    let id = "empty_string"
    let name = "Empty String"
    let summary = "Prefer checking `isEmpty` over comparing `string` to an empty string literal"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("myString.isEmpty"),
              Example("!myString.isEmpty"),
              Example("\"\"\"\nfoo==\n\"\"\""),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(#"myString↓ == """#),
              Example(#"myString↓ != """#),
              Example(#"myString↓=="""#),
              Example(##"myString↓ == #""#"##),
              Example(###"myString↓ == ##""##"###),
            ]
    }
}
