struct PatternMatchingKeywordsConfiguration: RuleConfiguration {
    let id = "pattern_matching_keywords"
    let name = "Pattern Matching Keywords"
    let summary = "Combine multiple pattern matching bindings by moving keywords out of tuples"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("default"),
              Example("case 1"),
              Example("case bar"),
              Example("case let (x, y)"),
              Example("case .foo(let x)"),
              Example("case let .foo(x, y)"),
              Example("case .foo(let x), .bar(let x)"),
              Example("case .foo(let x, var y)"),
              Example("case var (x, y)"),
              Example("case .foo(var x)"),
              Example("case var .foo(x, y)"),
              Example("case (y, let x, z)"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("case (↓let x,  ↓let y)"),
              Example("case (↓let x,  ↓let y, .foo)"),
              Example("case (↓let x,  ↓let y, _)"),
              Example("case (↓let x,  ↓let y, f())"),
              Example("case (↓let x,  ↓let y, s.f())"),
              Example("case (↓let x,  ↓let y, s.t)"),
              Example("case .foo(↓let x, ↓let y)"),
              Example("case (.yamlParsing(↓let x), .yamlParsing(↓let y))"),
              Example("case (↓var x,  ↓var y)"),
              Example("case .foo(↓var x, ↓var y)"),
              Example("case (.yamlParsing(↓var x), .yamlParsing(↓var y))"),
            ]
    }
}
