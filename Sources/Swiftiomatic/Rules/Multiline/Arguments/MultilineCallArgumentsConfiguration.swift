struct MultilineCallArgumentsConfiguration: RuleConfiguration {
    let id = "multiline_call_arguments"
    let name = "Multiline Call Arguments"
    let summary = "Call should have each parameter on a separate line"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                foo(
                param1: "param1",
                    param2: false,
                    param3: []
                )
                """,
                configuration: ["max_number_of_single_line_parameters": 2],
              ),
              Example(
                """
                foo(param1: 1,
                    param2: false,
                    param3: [])
                """,
                configuration: ["max_number_of_single_line_parameters": 1],
              ),
              Example(
                "foo(param1: 1, param2: false)",
                configuration: ["max_number_of_single_line_parameters": 2],
              ),
              Example(
                "Enum.foo(param1: 1, param2: false)",
                configuration: ["max_number_of_single_line_parameters": 2],
              ),
              Example("foo(param1: 1)", configuration: ["allows_single_line": false]),
              Example("Enum.foo(param1: 1)", configuration: ["allows_single_line": false]),
              Example(
                "Enum.foo(param1: 1, param2: 2, param3: 3)",
                configuration: ["allows_single_line": true],
              ),
              Example(
                """
                foo(
                    param1: 1,
                    param2: 2,
                    param3: 3
                )
                """,
                configuration: ["allows_single_line": false],
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                "↓foo(param1: 1, param2: false, param3: [])",
                configuration: ["max_number_of_single_line_parameters": 2],
              ),
              Example(
                "↓Enum.foo(param1: 1, param2: false, param3: [])",
                configuration: ["max_number_of_single_line_parameters": 2],
              ),
              Example(
                """
                ↓foo(param1: 1, param2: false,
                        param3: [])
                """,
                configuration: ["max_number_of_single_line_parameters": 3],
              ),
              Example(
                """
                ↓Enum.foo(param1: 1, param2: false,
                        param3: [])
                """,
                configuration: ["max_number_of_single_line_parameters": 3],
              ),
              Example("↓foo(param1: 1, param2: false)", configuration: ["allows_single_line": false]),
              Example(
                "↓Enum.foo(param1: 1, param2: false)",
                configuration: ["allows_single_line": false],
              ),
            ]
    }
}
