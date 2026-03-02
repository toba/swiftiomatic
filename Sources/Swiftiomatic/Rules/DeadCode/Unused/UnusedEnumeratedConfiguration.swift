struct UnusedEnumeratedConfiguration: RuleConfiguration {
    let id = "unused_enumerated"
    let name = "Unused Enumerated"
    let summary = "When the index or the item is not used, `.enumerated()` can be removed."
    var nonTriggeringExamples: [Example] {
        [
              Example("for (idx, foo) in bar.enumerated() { }"),
              Example("for (_, foo) in bar.enumerated().something() { }"),
              Example("for (_, foo) in bar.something() { }"),
              Example("for foo in bar.enumerated() { }"),
              Example("for foo in bar { }"),
              Example("for (idx, _) in bar.enumerated().something() { }"),
              Example("for (idx, _) in bar.something() { }"),
              Example("for idx in bar.indices { }"),
              Example("for (section, (event, _)) in data.enumerated() {}"),
              Example("list.enumerated().map { idx, elem in \"\\(idx): \\(elem)\" }"),
              Example("list.enumerated().map { $0 + $1 }"),
              Example("list.enumerated().something().map { _, elem in elem }"),
              Example("list.enumerated().map { ($0.offset, $0.element) }"),
              Example("list.enumerated().map { ($0.0, $0.1) }"),
              Example(
                """
                list.enumerated().map {
                    $1.enumerated().forEach { print($0, $1) }
                    return $0
                }
                """,
              ),
              Example(
                """
                list.enumerated().forEach {
                    f($0)
                    let (i, e) = $0
                    print(i)
                }
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("for (↓_, foo) in bar.enumerated() { }"),
              Example("for (↓_, foo) in abc.bar.enumerated() { }"),
              Example("for (↓_, foo) in abc.something().enumerated() { }"),
              Example("for (idx, ↓_) in bar.enumerated() { }"),
              Example("list.enumerated().map { idx, ↓_ in idx }"),
              Example("list.enumerated().map { ↓_, elem in elem }"),
              Example("list.↓enumerated().forEach { print($0) }"),
              Example("list.↓enumerated().map { $1 }"),
              Example(
                """
                list.enumerated().map {
                    $1.↓enumerated().forEach { print($1) }
                    return $0
                }
                """,
              ),
              Example(
                """
                list.↓enumerated().map {
                    $1.enumerated().forEach { print($0, $1) }
                    return 1
                }
                """,
              ),
              Example(
                """
                list.enumerated().map {
                    $1.enumerated().filter {
                        print($0, $1)
                        $1.↓enumerated().forEach {
                             if $1 == 2 {
                                 return true
                             }
                        }
                        return false
                    }
                    return $0
                }
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                list.↓enumerated().map {
                    $1.forEach { print($0) }
                    return $1
                }
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                list.↓enumerated().forEach {
                    let (i, _) = $0
                }
                """,
              ),
            ]
    }
}
