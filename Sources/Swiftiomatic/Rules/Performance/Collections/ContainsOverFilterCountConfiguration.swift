struct ContainsOverFilterCountConfiguration: RuleConfiguration {
    let id = "contains_over_filter_count"
    let name = "Contains over Filter Count"
    let summary = "Prefer `contains` over comparing `filter(where:).count` to 0"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [">", "==", "!="].flatMap { operation in
            [
                Example("let result = myList.filter(where: { $0 % 2 == 0 }).count \(operation) 1"),
                Example("let result = myList.filter { $0 % 2 == 0 }.count \(operation) 1"),
                Example("let result = myList.filter(where: { $0 % 2 == 0 }).count \(operation) 01"),
            ]
        } + [
            Example("let result = myList.contains(where: { $0 % 2 == 0 })"),
            Example("let result = !myList.contains(where: { $0 % 2 == 0 })"),
            Example("let result = myList.contains(10)"),
        ]
    }
    var triggeringExamples: [Example] {
        [">", "==", "!="].flatMap { operation in
            [
                Example("let result = ↓myList.filter(where: { $0 % 2 == 0 }).count \(operation) 0"),
                Example("let result = ↓myList.filter { $0 % 2 == 0 }.count \(operation) 0"),
                Example("let result = ↓myList.filter(where: someFunction).count \(operation) 0"),
            ]
        }
    }
}
