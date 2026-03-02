struct ExtensionAccessControlConfiguration: RuleConfiguration {
    let id = "extension_access_control"
    let name = "Extension Access Control"
    let summary = "Members of an extension that share the same access level should have it hoisted to the extension"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                public extension Foo {
                  func bar() {}
                  func baz() {}
                }
                """,
              ),
              Example(
                """
                extension Foo {
                  public func bar() {}
                  internal func baz() {}
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                extension Foo {
                  ↓public func bar() {}
                  public func baz() {}
                }
                """,
              )
            ]
    }
}
