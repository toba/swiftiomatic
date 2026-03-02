struct RedundantInternalConfiguration: RuleConfiguration {
    let id = "redundant_internal"
    let name = "Redundant Internal"
    let summary = "Declarations are internal by default; the `internal` modifier is redundant"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("class Foo {}"),
              Example("let bar: String"),
              Example("internal import Foundation"),
              Example(
                """
                public extension String {
                  internal func foo() {}
                }
                """,
              ),
              Example(
                """
                package extension String {
                  internal func foo() {}
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓internal class Foo {}"),
              Example("↓internal let bar: String"),
              Example("↓internal func baaz() {}"),
              Example("↓internal init() {}"),
              Example(
                """
                extension String {
                  ↓internal func foo() {}
                }
                """,
              ),
              Example(
                """
                internal extension String {
                  ↓internal func foo() {}
                }
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("↓internal class Foo {}"): Example("class Foo {}"),
              Example("↓internal let bar: String"): Example("let bar: String"),
              Example(
                """
                extension String {
                  ↓internal func foo() {}
                }
                """,
              ): Example(
                """
                extension String {
                  func foo() {}
                }
                """,
              ),
            ]
    }
}
