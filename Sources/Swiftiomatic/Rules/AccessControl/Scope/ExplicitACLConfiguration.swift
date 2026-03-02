struct ExplicitACLConfiguration: RuleConfiguration {
    let id = "explicit_acl"
    let name = "Explicit ACL"
    let summary = "All declarations should specify Access Control Level keywords explicitly"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("internal enum A {}"),
              Example("public final class B {}"),
              Example("private struct C {}"),
              Example("internal enum A { internal enum B {} }"),
              Example("internal final class Foo {}"),
              Example(
                """
                internal
                class Foo {
                  private let bar = 5
                }
                """,
              ),
              Example("internal func a() { let a =  }"),
              Example("private func a() { func innerFunction() { } }"),
              Example("private enum Foo { enum Bar { } }"),
              Example("private struct C { let d = 5 }"),
              Example(
                """
                internal protocol A {
                  func b()
                }
                """,
              ),
              Example(
                """
                internal protocol A {
                  var b: Int
                }
                """,
              ),
              Example("internal class A { deinit {} }"),
              Example("extension A: Equatable {}"),
              Example("extension A {}"),
              Example(
                """
                extension Foo {
                    internal func bar() {}
                }
                """,
              ),
              Example(
                """
                internal enum Foo {
                    case bar
                }
                """,
              ),
              Example(
                """
                extension Foo {
                    public var isValid: Bool {
                        let result = true
                        return result
                    }
                }
                """,
              ),
              Example(
                """
                extension Foo {
                    private var isValid: Bool {
                        get {
                            return true
                        }
                        set(newValue) {
                            print(newValue)
                        }
                    }
                }
                """,
              ),
              Example(
                """
                private extension Foo {
                    var isValid: Bool { true }
                    struct S {
                        let b = 2
                    }
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓enum A {}"),
              Example("final ↓class B {}"),
              Example("internal struct C { ↓let d = 5 }"),
              Example("public struct C { private(set) ↓var d = 5 }"),
              Example("internal struct C { static ↓let d = 5 }"),
              Example("public struct C { ↓let d = 5 }"),
              Example("public struct C { ↓init() }"),
              Example("static ↓func a() {}"),
              Example("internal let a = 0\n↓func b() {}"),
              Example(
                """
                extension Foo {
                    ↓func bar() {}
                    static ↓func baz() {}
                }
                """,
              ),
              Example(
                """
                public extension E {
                    let a = 1
                    struct S {
                        ↓let b = 2
                    }
                }
                """,
              ),
            ]
    }
}
