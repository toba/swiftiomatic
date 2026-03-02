struct OverrideInExtensionConfiguration: RuleConfiguration {
    let id = "override_in_extension"
    let name = "Override in Extension"
    let summary = "Extensions shouldn't override declarations"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("extension Person {\n  var age: Int { return 42 }\n}"),
              Example("extension Person {\n  func celebrateBirthday() {}\n}"),
              Example("class Employee: Person {\n  override func celebrateBirthday() {}\n}"),
              Example(
                """
                class Foo: NSObject {}
                extension Foo {
                    override var description: String { return "" }
                }
                """,
              ),
              Example(
                """
                struct Foo {
                    class Bar: NSObject {}
                }
                extension Foo.Bar {
                    override var description: String { return "" }
                }
                """,
              ),
              Example(
                """
                @objc
                @implementation
                extension Person {
                    override func celebrateBirthday() {}
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("extension Person {\n  override ↓var age: Int { return 42 }\n}"),
              Example("extension Person {\n  override ↓func celebrateBirthday() {}\n}"),
            ]
    }
}
