struct RedundantSetAccessControlConfiguration: RuleConfiguration {
    let id = "redundant_set_access_control"
    let name = "Redundant Access Control for Setter"
    let summary = "Property setter access level shouldn't be explicit if it's the same as the variable access level"
    var nonTriggeringExamples: [Example] {
        [
              Example("private(set) public var foo: Int"),
              Example("public let foo: Int"),
              Example("public var foo: Int"),
              Example("var foo: Int"),
              Example(
                """
                private final class A {
                  private(set) var value: Int
                }
                """,
              ),
              Example(
                """
                fileprivate class A {
                  public fileprivate(set) var value: Int
                }
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                extension Color {
                    public internal(set) static var someColor = Color.anotherColor
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓private(set) private var foo: Int"),
              Example("↓fileprivate(set) fileprivate var foo: Int"),
              Example("↓internal(set) internal var foo: Int"),
              Example("↓public(set) public var foo: Int"),
              Example(
                """
                open class Foo {
                  ↓open(set) open var bar: Int
                }
                """,
              ),
              Example(
                """
                class A {
                  ↓internal(set) var value: Int
                }
                """,
              ),
              Example(
                """
                internal class A {
                  ↓internal(set) var value: Int
                }
                """,
              ),
              Example(
                """
                fileprivate class A {
                  ↓fileprivate(set) var value: Int
                }
                """,
              ),
            ]
    }
}
