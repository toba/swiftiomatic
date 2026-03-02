struct PrefixedTopLevelConstantConfiguration: RuleConfiguration {
    let id = "prefixed_toplevel_constant"
    let name = "Prefixed Top-Level Constant"
    let summary = "Top-level constants should be prefixed by `k`"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("private let kFoo = 20.0"),
              Example("public let kFoo = false"),
              Example("internal let kFoo = \"Foo\""),
              Example("let kFoo = true"),
              Example("let Foo = true", configuration: ["only_private": true]),
              Example(
                """
                struct Foo {
                    let bar = 20.0
                }
                """,
              ),
              Example("private var foo = 20.0"),
              Example("public var foo = false"),
              Example("internal var foo = \"Foo\""),
              Example("var foo = true"),
              Example("var foo = true, bar = true"),
              Example("var foo = true, let kFoo = true"),
              Example(
                """
                let
                    kFoo = true
                """,
              ),
              Example(
                """
                var foo: Int {
                    return a + b
                }
                """,
              ),
              Example(
                """
                let kFoo = {
                    return a + b
                }()
                """,
              ),
              Example(
                """
                var foo: String {
                    let bar = ""
                    return bar
                }
                """,
              ),
              Example(
                """
                if condition() {
                    let result = somethingElse()
                    print(result)
                    exit()
                }
                """,
              ),
              Example(
                #"""
                [1, 2, 3, 1000, 4000].forEach { number in
                    let isSmall = number < 10
                    if isSmall {
                        print("\(number) is a small number")
                    }
                }
                """#,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("private let ↓Foo = 20.0"),
              Example("public let ↓Foo = false"),
              Example("internal let ↓Foo = \"Foo\""),
              Example("let ↓Foo = true"),
              Example("let ↓foo = 2, ↓bar = true"),
              Example(
                """
                let
                    ↓foo = true
                """,
              ),
              Example(
                """
                let ↓foo = {
                    return a + b
                }()
                """,
              ),
            ]
    }
}
