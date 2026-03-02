struct DuplicatedKeyInDictionaryLiteralConfiguration: RuleConfiguration {
    let id = "duplicated_key_in_dictionary_literal"
    let name = "Duplicated Key in Dictionary Literal"
    let summary = "Dictionary literals with duplicated keys will crash at runtime"
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                [
                    1: "1",
                    2: "2"
                ]
                """,
              ),
              Example(
                """
                [
                    "1": 1,
                    "2": 2
                ]
                """,
              ),
              Example(
                """
                [
                    foo: "1",
                    bar: "2"
                ]
                """,
              ),
              Example(
                """
                [
                    UUID(): "1",
                    UUID(): "2"
                ]
                """,
              ),
              Example(
                """
                [
                    #line: "1",
                    #line: "2"
                ]
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                [
                    1: "1",
                    2: "2",
                    ↓1: "one"
                ]
                """,
              ),
              Example(
                """
                [
                    "1": 1,
                    "2": 2,
                    ↓"2": 2
                ]
                """,
              ),
              Example(
                """
                [
                    foo: "1",
                    bar: "2",
                    baz: "3",
                    ↓foo: "4",
                    zaz: "5"
                ]
                """,
              ),
              Example(
                """
                [
                    .one: "1",
                    .two: "2",
                    .three: "3",
                    ↓.one: "1",
                    .four: "4",
                    .five: "5"
                ]
                """,
              ),
            ]
    }
}
