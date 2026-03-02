struct FirstWhereConfiguration: RuleConfiguration {
    let id = "first_where"
    let name = "First Where"
    let summary = "Prefer using `.first(where:)` over `.filter { }.first` in collections"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("kinds.filter(excludingKinds.contains).isEmpty && kinds.first == .identifier"),
              Example("myList.first(where: { $0 % 2 == 0 })"),
              Example("match(pattern: pattern).filter { $0.first == .identifier }"),
              Example("(myList.filter { $0 == 1 }.suffix(2)).first"),
              Example(#"collection.filter("stringCol = '3'").first"#),
              Example(
                #"realm?.objects(User.self).filter(NSPredicate(format: "email ==[c] %@", email)).first"#,
              ),
              Example(
                #"if let pause = timeTracker.pauses.filter("beginDate < %@", beginDate).first { print(pause) }"#,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓myList.filter { $0 % 2 == 0 }.first"),
              Example("↓myList.filter({ $0 % 2 == 0 }).first"),
              Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).first"),
              Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).first?.something()"),
              Example("↓myList.filter(someFunction).first"),
              Example("↓myList.filter({ $0 % 2 == 0 })\n.first"),
              Example("(↓myList.filter { $0 == 1 }).first"),
              Example(#"↓myListOfDict.filter { dict in dict["1"] }.first"#),
              Example(#"↓myListOfDict.filter { $0["someString"] }.first"#),
            ]
    }
}
