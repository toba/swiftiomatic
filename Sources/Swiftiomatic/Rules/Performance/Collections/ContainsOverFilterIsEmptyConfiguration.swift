struct ContainsOverFilterIsEmptyConfiguration: RuleConfiguration {
    let id = "contains_over_filter_is_empty"
    let name = "Contains over Filter is Empty"
    let summary = "Prefer `contains` over using `filter(where:).isEmpty`"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [">", "==", "!="].flatMap { operation in
            [
                Example("let result = myList.filter(where: { $0 % 2 == 0 }).count \(operation) 1"),
                Example("let result = myList.filter { $0 % 2 == 0 }.count \(operation) 1"),
            ]
        } + [
            Example("let result = myList.contains(where: { $0 % 2 == 0 })"),
            Example("let result = !myList.contains(where: { $0 % 2 == 0 })"),
            Example("let result = myList.contains(10)"),
        ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let result = ↓myList.filter(where: { $0 % 2 == 0 }).isEmpty"),
              Example("let result = !↓myList.filter(where: { $0 % 2 == 0 }).isEmpty"),
              Example("let result = ↓myList.filter { $0 % 2 == 0 }.isEmpty"),
              Example("let result = ↓myList.filter(where: someFunction).isEmpty"),
            ]
    }
}
