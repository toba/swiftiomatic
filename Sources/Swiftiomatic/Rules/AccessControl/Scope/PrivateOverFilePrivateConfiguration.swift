struct PrivateOverFilePrivateConfiguration: RuleConfiguration {
    let id = "private_over_fileprivate"
    let name = "Private over Fileprivate"
    let summary = "Prefer `private` over `fileprivate` declarations"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("extension String {}"),
              Example("private extension String {}"),
              Example("public protocol P {}"),
              Example("open extension \n String {}"),
              Example("internal extension String {}"),
              Example("package typealias P = Int"),
              Example(
                """
                extension String {
                  fileprivate func Something(){}
                }
                """,
              ),
              Example(
                """
                class MyClass {
                  fileprivate let myInt = 4
                }
                """,
              ),
              Example(
                """
                actor MyActor {
                  fileprivate let myInt = 4
                }
                """,
              ),
              Example(
                """
                class MyClass {
                  fileprivate(set) var myInt = 4
                }
                """,
              ),
              Example(
                """
                struct Outer {
                  struct Inter {
                    fileprivate struct Inner {}
                  }
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓fileprivate enum MyEnum {}"),
              Example(
                """
                ↓fileprivate class MyClass {
                  fileprivate(set) var myInt = 4
                }
                """,
              ),
              Example(
                """
                ↓fileprivate actor MyActor {
                  fileprivate let myInt = 4
                }
                """,
              ),
              Example(
                """
                    ↓fileprivate func f() {}
                    ↓fileprivate var x = 0
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("↓fileprivate enum MyEnum {}"):
                Example("private enum MyEnum {}"),
              Example("↓fileprivate enum MyEnum { fileprivate class A {} }"):
                Example("private enum MyEnum { fileprivate class A {} }"),
              Example("↓fileprivate class MyClass { fileprivate(set) var myInt = 4 }"):
                Example("private class MyClass { fileprivate(set) var myInt = 4 }"),
              Example("↓fileprivate actor MyActor { fileprivate(set) var myInt = 4 }"):
                Example("private actor MyActor { fileprivate(set) var myInt = 4 }"),
            ]
    }
}
