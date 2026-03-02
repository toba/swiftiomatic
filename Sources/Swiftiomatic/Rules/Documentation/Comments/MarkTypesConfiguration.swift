struct MarkTypesConfiguration: RuleConfiguration {
    let id = "mark_types"
    let name = "Mark Types"
    let summary = "Top-level types and extensions should have MARK comments for organization"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                // MARK: - Foo
                class Foo {}
                """,
              ),
              Example(
                """
                import Foundation
                struct Foo {}
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓class Foo {}
                class Bar {}
                """,
              )
            ]
    }
}
