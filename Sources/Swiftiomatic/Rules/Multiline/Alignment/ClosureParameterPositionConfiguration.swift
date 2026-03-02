struct ClosureParameterPositionConfiguration: RuleConfiguration {
    let id = "closure_parameter_position"
    let name = "Closure Parameter Position"
    let summary = "Closure parameters should be on the same line as opening brace"
    var nonTriggeringExamples: [Example] {
        [
              Example("[1, 2].map { $0 + 1 }"),
              Example("[1, 2].map({ $0 + 1 })"),
              Example("[1, 2].map { number in\n number + 1 \n}"),
              Example("[1, 2].map { number -> Int in\n number + 1 \n}"),
              Example("[1, 2].map { (number: Int) -> Int in\n number + 1 \n}"),
              Example("[1, 2].map { [weak self] number in\n number + 1 \n}"),
              Example("[1, 2].something(closure: { number in\n number + 1 \n})"),
              Example("let isEmpty = [1, 2].isEmpty()"),
              Example(
                """
                rlmConfiguration.migrationBlock.map { rlmMigration in
                    return { migration, schemaVersion in
                        rlmMigration(migration.rlmMigration, schemaVersion)
                    }
                }
                """,
              ),
              Example(
                """
                let mediaView: UIView = { [weak self] index in
                   return UIView()
                }(index)
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                [1, 2].map {
                    ↓number in
                    number + 1
                }
                """,
              ),
              Example(
                """
                [1, 2].map {
                    ↓number -> Int in
                    number + 1
                }
                """,
              ),
              Example(
                """
                [1, 2].map {
                    (↓number: Int) -> Int in
                    number + 1
                }
                """,
              ),
              Example(
                """
                [1, 2].map {
                    [weak ↓self] ↓number in
                    number + 1
                }
                """,
              ),
              Example(
                """
                [1, 2].map { [weak self]
                    ↓number in
                    number + 1
                }
                """,
              ),
              Example(
                """
                [1, 2].map({
                    ↓number in
                    number + 1
                })
                """,
              ),
              Example(
                """
                [1, 2].something(closure: {
                    ↓number in
                    number + 1
                })
                """,
              ),
              Example(
                """
                [1, 2].reduce(0) {
                    ↓sum, ↓number in
                    number + sum
                })
                """,
              ),
              Example(
                """
                f.completionHandler = {
                    ↓thing in
                    doStuff()
                }
                """,
              ),
              Example(
                """
                foo {
                    [weak ↓self] in
                    self?.bar()
                }
                """,
              ),
            ]
    }
}
