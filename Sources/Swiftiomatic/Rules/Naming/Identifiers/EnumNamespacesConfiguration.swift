struct EnumNamespacesConfiguration: RuleConfiguration {
    let id = "enum_namespaces"
    let name = "Enum Namespaces"
    let summary = "Types hosting only static members should be enums to prevent instantiation"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                enum Constants {
                  static let foo = "foo"
                }
                """,
              ),
              Example(
                """
                struct Foo {
                  let bar: Int
                }
                """,
              ),
              Example(
                """
                struct Foo {
                  static let bar = 1
                  init() {}
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓struct Constants {
                  static let foo = "foo"
                  static let bar = "bar"
                }
                """,
              ),
              Example(
                """
                final ↓class Constants {
                  static let foo = "foo"
                }
                """,
              ),
            ]
    }
}
