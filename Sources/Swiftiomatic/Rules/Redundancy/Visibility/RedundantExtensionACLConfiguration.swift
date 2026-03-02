struct RedundantExtensionACLConfiguration: RuleConfiguration {
    let id = "redundant_extension_acl"
    let name = "Redundant Extension ACL"
    let summary = "Access control modifiers on extension members are redundant when they match the extension's ACL"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                public extension URL {
                  func queryParameter(_ name: String) -> String { "" }
                }
                """,
              ),
              Example(
                """
                public extension URL {
                  internal func internalMethod() {}
                }
                """,
              ),
              Example(
                """
                extension URL {
                  public func publicMethod() {}
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                public extension URL {
                  ↓public func queryParameter(_ name: String) -> String { "" }
                }
                """,
              ),
              Example(
                """
                private extension URL {
                  ↓fileprivate func foo() {}
                }
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example(
                """
                public extension URL {
                  ↓public func queryParameter(_ name: String) -> String { "" }
                }
                """,
              ): Example(
                """
                public extension URL {
                  func queryParameter(_ name: String) -> String { "" }
                }
                """,
              )
            ]
    }
}
