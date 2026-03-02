struct RedundantNilCoalescingConfiguration: RuleConfiguration {
    let id = "redundant_nil_coalescing"
    let name = "Redundant Nil Coalescing"
    let summary = "nil coalescing operator is only evaluated if the lhs is nil, coalescing operator with nil as rhs is redundant"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("var myVar: Int?; myVar ?? 0")
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("var myVar: Int? = nil; myVar ↓?? nil")
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("var myVar: Int? = nil; let foo = myVar ↓?? nil"):
                Example("var myVar: Int? = nil; let foo = myVar")
            ]
    }
}
