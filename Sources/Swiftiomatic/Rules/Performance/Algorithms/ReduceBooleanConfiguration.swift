struct ReduceBooleanConfiguration: RuleConfiguration {
    let id = "reduce_boolean"
    let name = "Reduce Boolean"
    let summary = "Prefer using `.allSatisfy()` or `.contains()` over `reduce(true)` or `reduce(false)`."
    var nonTriggeringExamples: [Example] {
        [
              Example("nums.reduce(0) { $0.0 + $0.1 }"),
              Example("nums.reduce(0.0) { $0.0 + $0.1 }"),
              Example("nums.reduce(initial: true) { $0.0 && $0.1 == 3 }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let allNines = nums.↓reduce(true) { $0.0 && $0.1 == 9 }"),
              Example("let anyNines = nums.↓reduce(false) { $0.0 || $0.1 == 9 }"),
              Example("let allValid = validators.↓reduce(true) { $0 && $1(input) }"),
              Example("let anyValid = validators.↓reduce(false) { $0 || $1(input) }"),
              Example("let allNines = nums.↓reduce(true, { $0.0 && $0.1 == 9 })"),
              Example("let anyNines = nums.↓reduce(false, { $0.0 || $0.1 == 9 })"),
              Example("let allValid = validators.↓reduce(true, { $0 && $1(input) })"),
              Example("let anyValid = validators.↓reduce(false, { $0 || $1(input) })"),
              Example("nums.reduce(into: true) { (r: inout Bool, s) in r = r && (s == 3) }"),
            ]
    }
}
