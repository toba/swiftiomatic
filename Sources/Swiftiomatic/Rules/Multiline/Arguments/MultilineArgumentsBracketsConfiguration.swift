struct MultilineArgumentsBracketsConfiguration: RuleConfiguration {
    let id = "multiline_arguments_brackets"
    let name = "Multiline Arguments Brackets"
    let summary = "Multiline arguments should have their surrounding brackets in a new line"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                foo(param1: "Param1", param2: "Param2", param3: "Param3")
                """,
              ),
              Example(
                """
                foo(
                    param1: "Param1", param2: "Param2", param3: "Param3"
                )
                """,
              ),
              Example(
                """
                func foo(
                    param1: "Param1",
                    param2: "Param2",
                    param3: "Param3"
                )
                """,
              ),
              Example(
                """
                foo { param1, param2 in
                    print("hello world")
                }
                """,
              ),
              Example(
                """
                foo(
                    bar(
                        x: 5,
                        y: 7
                    )
                )
                """,
              ),
              Example(
                """
                AlertViewModel.AlertAction(title: "some title", style: .default) {
                    AlertManager.shared.presentNextDebugAlert()
                }
                """,
              ),
              Example(
                """
                views.append(ViewModel(title: "MacBook", subtitle: "M1", action: { [weak self] in
                    print("action tapped")
                }))
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                public final class Logger {
                    public static let shared = Logger(outputs: [
                        OSLoggerOutput(),
                        ErrorLoggerOutput()
                    ])
                }
                """,
              ),
              Example(
                """
                let errors = try self.download([
                    (description: description, priority: priority),
                ])
                """,
              ),
              Example(
                """
                return SignalProducer({ observer, _ in
                    observer.sendCompleted()
                }).onMainQueue()
                """,
              ),
              Example(
                """
                SomeType(a: [
                    1, 2, 3
                ], b: [1, 2])
                """,
              ),
              Example(
                """
                SomeType(
                  a: 1
                ) { print("completion") }
                """,
              ),
              Example(
                """
                SomeType(
                  a: 1
                ) {
                  print("completion")
                }
                """,
              ),
              Example(
                """
                SomeType(
                  a: .init() { print("completion") }
                )
                """,
              ),
              Example(
                """
                SomeType(
                  a: .init() {
                    print("completion")
                  }
                )
                """,
              ),
              Example(
                """
                SomeType(
                  a: 1
                ) {} onError: {}
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                foo(↓param1: "Param1", param2: "Param2",
                         param3: "Param3"
                )
                """,
              ),
              Example(
                """
                foo(
                    param1: "Param1",
                    param2: "Param2",
                    param3: "Param3"↓)
                """,
              ),
              Example(
                """
                foo(↓param1: "Param1",
                    param2: "Param2",
                    param3: "Param3"↓)
                """,
              ),
              Example(
                """
                foo(↓bar(
                    x: 5,
                    y: 7
                )
                )
                """,
              ),
              Example(
                """
                foo(
                    bar(
                        x: 5,
                        y: 7
                )↓)
                """,
              ),
              Example(
                """
                SomeOtherType(↓a: [
                        1, 2, 3
                    ],
                    b: "two"↓)
                """,
              ),
              Example(
                """
                SomeOtherType(
                  a: 1↓) {}
                """,
              ),
              Example(
                """
                SomeOtherType(
                  a: 1↓) {
                  print("completion")
                }
                """,
              ),
              Example(
                """
                views.append(ViewModel(
                    title: "MacBook", subtitle: "M1", action: { [weak self] in
                    print("action tapped")
                }↓))
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
}
