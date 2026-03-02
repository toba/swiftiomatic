struct LastWhereConfiguration: RuleConfiguration {
    let id = "last_where"
    let name = "Last Where"
    let summary = "Prefer using `.last(where:)` over `.filter { }.last` in collections"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("kinds.filter(excludingKinds.contains).isEmpty && kinds.last == .identifier"),
              Example("myList.last(where: { $0 % 2 == 0 })"),
              Example("match(pattern: pattern).filter { $0.last == .identifier }"),
              Example("(myList.filter { $0 == 1 }.suffix(2)).last"),
              Example(#"collection.filter("stringCol = '3'").last"#),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓myList.filter { $0 % 2 == 0 }.last"),
              Example("↓myList.filter({ $0 % 2 == 0 }).last"),
              Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).last"),
              Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).last?.something()"),
              Example("↓myList.filter(someFunction).last"),
              Example("↓myList.filter({ $0 % 2 == 0 })\n.last"),
              Example("(↓myList.filter { $0 == 1 }).last"),
            ]
    }
}
