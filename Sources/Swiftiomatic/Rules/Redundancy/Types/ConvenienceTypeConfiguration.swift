struct ConvenienceTypeConfiguration: RuleConfiguration {
    let id = "convenience_type"
    let name = "Convenience Type"
    let summary = "Types used for hosting only static members should be implemented as a caseless enum to avoid instantiation"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                enum Math { // enum
                  public static let pi = 3.14
                }
                """,
              ),
              Example(
                """
                // class with inheritance
                class MathViewController: UIViewController {
                  public static let pi = 3.14
                }
                """,
              ),
              Example(
                """
                @objc class Math: NSObject { // class visible to Obj-C
                  public static let pi = 3.14
                }
                """,
              ),
              Example(
                """
                struct Math { // type with non-static declarations
                  public static let pi = 3.14
                  public let randomNumber = 2
                }
                """,
              ),
              Example("class DummyClass {}"),
              Example(
                """
                class Foo: NSObject { // class with Obj-C class property
                    class @objc let foo = 1
                }
                """,
              ),
              Example(
                """
                class Foo: NSObject { // class with Obj-C static property
                    static @objc let foo = 1
                }
                """,
              ),
              Example(
                """
                class Foo { // @objc class func can't exist on an enum
                   @objc class func foo() {}
                }
                """,
              ),
              Example(
                """
                class Foo { // @objc static func can't exist on an enum
                   @objc static func foo() {}
                }
                """,
              ),
              Example(
                """
                @objcMembers class Foo { // @objc static func can't exist on an enum
                   static func foo() {}
                }
                """,
              ),
              Example(
                """
                final class Foo { // final class, but @objc class func can't exist on an enum
                   @objc class func foo() {}
                }
                """,
              ),
              Example(
                """
                final class Foo { // final class, but @objc static func can't exist on an enum
                   @objc static func foo() {}
                }
                """,
              ),
              Example(
                """
                @globalActor actor MyActor {
                  static let shared = MyActor()
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓struct Math {
                  public static let pi = 3.14
                }
                """,
              ),
              Example(
                """
                ↓struct Math {
                  public static let pi = 3.14
                  @available(*, unavailable) init() {}
                }
                """,
              ),
              Example(
                """
                final ↓class Foo { // final class can't be inherited
                    class let foo = 1
                }
                """,
              ),

              // Intentional false positives. Non-final classes could be
              // subclassed, but we figure it is probably rare enough that it is
              // more important to catch these cases, and manually disable the
              // rule if needed.

              Example(
                """
                ↓class Foo {
                    class let foo = 1
                }
                """,
              ),
              Example(
                """
                ↓class Foo {
                    final class let foo = 1
                }
                """,
              ),
              Example(
                """
                ↓class SomeClass {
                    static func foo() {}
                }
                """,
              ),
            ]
    }
}
