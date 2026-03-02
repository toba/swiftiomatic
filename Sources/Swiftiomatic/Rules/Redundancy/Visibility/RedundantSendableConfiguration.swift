struct RedundantSendableConfiguration: RuleConfiguration {
    let id = "redundant_sendable"
    let name = "Redundant Sendable"
    let summary = "Sendable conformance is redundant on an actor-isolated type"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("struct S: Sendable {}"),
              Example("class C: Sendable {}"),
              Example("actor A {}"),
              Example("@MainActor struct S {}"),
              Example("@MyActor enum E: Sendable { case a }"),
              Example("@MainActor protocol P: Sendable {}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("@MainActor struct ↓S: Sendable {}"),
              Example("actor ↓A: Sendable {}"),
              Example(
                "@MyActor enum ↓E: Sendable { case a }",
                configuration: ["global_actors": ["MyActor"]],
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("@MainActor struct S: Sendable {}"):
                Example("@MainActor struct S {}"),
              Example("actor A: Sendable /* trailing comment */{}"):
                Example("actor A /* trailing comment */{}"),
              Example(
                "@MyActor enum E: Sendable { case a }",
                configuration: ["global_actors": ["MyActor"]],
              ):
                Example("@MyActor enum E { case a }"),
              Example(
                """
                actor A: B, Sendable, C // comment
                {}
                """,
              ):
                Example(
                  """
                  actor A: B, C // comment
                  {}
                  """,
                ),
              Example("@MainActor struct P: A, Sendable {}"):
                Example("@MainActor struct P: A {}"),
            ]
    }
}
