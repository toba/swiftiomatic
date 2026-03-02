struct OneDeclarationPerFileConfiguration: RuleConfiguration {
    let id = "one_declaration_per_file"
    let name = "One Declaration per File"
    let summary = "Only a single declaration is allowed in a file"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                actor Foo {}
                """,
              ),
              Example(
                """
                class Foo {}
                extension Foo {}
                """,
              ),
              Example(
                """
                struct S {
                    struct N {}
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                class Foo {}
                ↓class Bar {}
                """,
              ),
              Example(
                """
                protocol Foo {}
                ↓enum Bar {}
                """,
              ),
              Example(
                """
                struct Foo {}
                ↓struct Bar {}
                """,
              ),
            ]
    }
}
