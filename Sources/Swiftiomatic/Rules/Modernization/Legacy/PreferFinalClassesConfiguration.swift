struct PreferFinalClassesConfiguration: RuleConfiguration {
    let id = "prefer_final_classes"
    let name = "Prefer Final Classes"
    let summary = "Classes should be marked `final` unless designed for subclassing"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example("final class Foo {}"),
              Example("open class Foo {}"),
              Example("class Foo: NSObject {}"),
              Example(
                """
                /// Base class for all handlers
                class BaseHandler {}
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓class Foo {}"),
              Example("↓class Foo { func bar() {} }"),
            ]
    }
}
