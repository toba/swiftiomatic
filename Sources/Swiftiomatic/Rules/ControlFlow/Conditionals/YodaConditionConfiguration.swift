struct YodaConditionConfiguration: RuleConfiguration {
    let id = "yoda_condition"
    let name = "Yoda Condition"
    let summary = "The constant literal should be placed on the right-hand side of the comparison operator"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("if foo == 42 {}"),
              Example("if foo <= 42.42 {}"),
              Example("guard foo >= 42 else { return }"),
              Example("guard foo != \"str str\" else { return }"),
              Example("while foo < 10 { }"),
              Example("while foo > 1 { }"),
              Example("while foo + 1 == 2 {}"),
              Example("if optionalValue?.property ?? 0 == 2 {}"),
              Example("if foo == nil {}"),
              Example("if flags & 1 == 1 {}"),
              Example("if true {}", isExcludedFromDocumentation: true),
              Example("if true == false || b, 2 != 3 {}", isExcludedFromDocumentation: true),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("if ↓42 == foo {}"),
              Example("if ↓42.42 >= foo {}"),
              Example("guard ↓42 <= foo else { return }"),
              Example("guard ↓\"str str\" != foo else { return }"),
              Example("while ↓10 > foo { }"),
              Example("while ↓1 < foo { }"),
              Example("if ↓nil == foo {}"),
              Example("while ↓1 > i + 5 {}"),
              Example("if ↓200 <= i && i <= 299 || ↓600 <= i {}"),
            ]
    }
}
