struct DiscouragedNoneNameConfiguration: RuleConfiguration {
    let id = "discouraged_none_name"
    let name = "Discouraged None Name"
    let summary = "Enum cases and static members named `none` are discouraged as they can conflict with `Optional<T>.none`."
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              // Should not trigger unless exactly matches "none"
              Example(
                """
                enum MyEnum {
                    case nOne
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case _none
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case none_
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case none(Any)
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case nonenone
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    class var nonenone: MyClass { MyClass() }
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    static var nonenone = MyClass()
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    static let nonenone = MyClass()
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    static var nonenone = MyStruct()
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    static let nonenone = MyStruct()
                }
                """,
              ),

              // Should not trigger if not an enum case or static/class member
              Example(
                """
                struct MyStruct {
                    let none = MyStruct()
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    var none = MyStruct()
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    let none = MyClass()
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    var none = MyClass()
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                enum MyEnum {
                    case ↓none
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case a, ↓none
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case ↓none, b
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case a, ↓none, b
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case a
                    case ↓none
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case ↓none
                    case b
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case a
                    case ↓none
                    case b
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    ↓static let none = MyClass()
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    ↓static let none: MyClass = MyClass()
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    ↓static var none: MyClass = MyClass()
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    ↓class var none: MyClass { MyClass() }
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    ↓static var none = MyStruct()
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    ↓static var none: MyStruct = MyStruct()
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    ↓static var none = MyStruct()
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    ↓static var none: MyStruct = MyStruct()
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    ↓static var a = MyStruct(), none = MyStruct()
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    ↓static var none = MyStruct(), a = MyStruct()
                }
                """,
              ),
            ]
    }
}
