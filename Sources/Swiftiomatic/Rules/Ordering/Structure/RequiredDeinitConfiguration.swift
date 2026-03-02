struct RequiredDeinitConfiguration: RuleConfiguration {
    let id = "required_deinit"
    let name = "Required Deinit"
    let summary = "Classes should have an explicit deinit method"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                class Apple {
                    deinit { }
                }
                """,
              ),
              Example("enum Banana { }"),
              Example("protocol Cherry { }"),
              Example("struct Damson { }"),
              Example(
                """
                class Outer {
                    deinit { print("Deinit Outer") }
                    class Inner {
                        deinit { print("Deinit Inner") }
                    }
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓class Apple { }"),
              Example("↓class Banana: NSObject, Equatable { }"),
              Example(
                """
                ↓class Cherry {
                    // deinit { }
                }
                """,
              ),
              Example(
                """
                ↓class Damson {
                    func deinitialize() { }
                }
                """,
              ),
              Example(
                """
                class Outer {
                    func hello() -> String { return "outer" }
                    deinit { }
                    ↓class Inner {
                        func hello() -> String { return "inner" }
                    }
                }
                """,
              ),
              Example(
                """
                ↓class Outer {
                    func hello() -> String { return "outer" }
                    class Inner {
                        func hello() -> String { return "inner" }
                        deinit { }
                    }
                }
                """,
              ),
            ]
    }
}
