struct SortedFirstLastConfiguration: RuleConfiguration {
    let id = "sorted_first_last"
    let name = "Min or Max over Sorted First or Last"
    let summary = "Prefer using `min()` or `max()` over `sorted().first` or `sorted().last`"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let min = myList.min()"),
              Example("let min = myList.min(by: { $0 < $1 })"),
              Example("let min = myList.min(by: >)"),
              Example("let max = myList.max()"),
              Example("let max = myList.max(by: { $0 < $1 })"),
              Example("let message = messages.sorted(byKeyPath: #keyPath(Message.timestamp)).last"),
              Example(
                #"let message = messages.sorted(byKeyPath: "timestamp", ascending: false).first"#,
              ),
              Example("myList.sorted().firstIndex(of: key)"),
              Example("myList.sorted().lastIndex(of: key)"),
              Example("myList.sorted().firstIndex(where: someFunction)"),
              Example("myList.sorted().lastIndex(where: someFunction)"),
              Example("myList.sorted().firstIndex { $0 == key }"),
              Example("myList.sorted().lastIndex { $0 == key }"),
              Example("myList.sorted().first(where: someFunction)"),
              Example("myList.sorted().last(where: someFunction)"),
              Example("myList.sorted().first { $0 == key }"),
              Example("myList.sorted().last { $0 == key }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓myList.sorted().first"),
              Example("↓myList.sorted(by: { $0.description < $1.description }).first"),
              Example("↓myList.sorted(by: >).first"),
              Example("↓myList.map { $0 + 1 }.sorted().first"),
              Example("↓myList.sorted(by: someFunction).first"),
              Example("↓myList.map { $0 + 1 }.sorted { $0.description < $1.description }.first"),
              Example("↓myList.sorted().last"),
              Example("↓myList.sorted().last?.something()"),
              Example("↓myList.sorted(by: { $0.description < $1.description }).last"),
              Example("↓myList.map { $0 + 1 }.sorted().last"),
              Example("↓myList.sorted(by: someFunction).last"),
              Example("↓myList.map { $0 + 1 }.sorted { $0.description < $1.description }.last"),
              Example("↓myList.map { $0 + 1 }.sorted { $0.first < $1.first }.last"),
            ]
    }
}
