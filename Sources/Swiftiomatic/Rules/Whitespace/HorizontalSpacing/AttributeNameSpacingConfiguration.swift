struct AttributeNameSpacingConfiguration: RuleConfiguration {
    let id = "attribute_name_spacing"
    let name = "Attribute Name Spacing"
    let summary = ""
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("private(set) var foo: Bool = false"),
              Example("fileprivate(set) var foo: Bool = false"),
              Example("@MainActor class Foo {}"),
              Example("func funcWithEscapingClosure(_ x: @escaping () -> Int) {}"),
              Example("@available(*, deprecated)"),
              Example("@MyPropertyWrapper(param: 2) "),
              Example("nonisolated(unsafe) var _value: X?"),
              Example("@testable import SwiftLintCore"),
              Example("func func_type_attribute_with_space(x: @convention(c) () -> Int) {}"),
              Example(
                """
                @propertyWrapper
                struct MyPropertyWrapper {
                    var wrappedValue: Int = 1

                    init(param: Int) {}
                }
                """,
              ),
              Example(
                """
                let closure2 = { @MainActor
                  (a: Int, b: Int) in
                }
                """,
              ),
              Example(
                """
                let closure1 = { @MainActor (a, b) in
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("private ↓(set) var foo: Bool = false"),
              Example("fileprivate ↓(set) var foo: Bool = false"),
              Example("public ↓(set) var foo: Bool = false"),
              Example("  public  ↓(set) var foo: Bool = false"),
              Example("@ ↓MainActor class Foo {}"),
              Example("func funcWithEscapingClosure(_ x: @ ↓escaping () -> Int) {}"),
              Example("func funcWithEscapingClosure(_ x: @escaping↓() -> Int) {}"),
              Example("@available ↓(*, deprecated)"),
              Example("@MyPropertyWrapper ↓(param: 2) let a = 1"),
              Example("nonisolated ↓(unsafe) var _value: X?"),
              Example("@MyProperty ↓() class Foo {}"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("private↓ (set) var foo: Bool = false"): Example(
                "private(set) var foo: Bool = false",
              ),
              Example("fileprivate↓ (set) var foo: Bool = false"): Example(
                "fileprivate(set) var foo: Bool = false",
              ),
              Example("internal↓ (set) var foo: Bool = false"): Example(
                "internal(set) var foo: Bool = false",
              ),
              Example("public↓ (set) var foo: Bool = false"): Example(
                "public(set) var foo: Bool = false",
              ),
              Example("public↓  (set) var foo: Bool = false"): Example(
                "public(set) var foo: Bool = false",
              ),
              Example("@↓ MainActor"): Example("@MainActor"),
              Example("func test(_ x: @↓ escaping () -> Int) {}"): Example(
                "func test(_ x: @escaping () -> Int) {}",
              ),
              Example("func test(_ x: @escaping↓() -> Int) {}"): Example(
                "func test(_ x: @escaping () -> Int) {}",
              ),
              Example("@available↓ (*, deprecated)"): Example("@available(*, deprecated)"),
              Example("@MyPropertyWrapper↓ (param: 2) let a = 1"): Example(
                "@MyPropertyWrapper(param: 2) let a = 1",
              ),
              Example("nonisolated↓ (unsafe) var _value: X?"): Example(
                "nonisolated(unsafe) var _value: X?",
              ),
              Example("@MyProperty↓ () let a = 1"): Example("@MyProperty() let a = 1"),
            ]
    }
}
