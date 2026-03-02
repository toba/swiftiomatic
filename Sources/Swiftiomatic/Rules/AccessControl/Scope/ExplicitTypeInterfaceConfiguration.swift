struct ExplicitTypeInterfaceConfiguration: RuleConfiguration {
    let id = "explicit_type_interface"
    let name = "Explicit Type Interface"
    let summary = "Properties should have a type interface"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                class Foo {
                  var myVar: Int? = 0
                }
                """,
              ),
              Example(
                """
                class Foo {
                  let myVar: Int? = 0, s: String = ""
                }
                """,
              ),
              Example(
                """
                class Foo {
                  static var myVar: Int? = 0
                }
                """,
              ),
              Example(
                """
                class Foo {
                  class var myVar: Int? = 0
                }
                """,
              ),
              Example(
                """
                func f() {
                    if case .failure(let error) = errorCompletion {}
                }
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                class Foo {
                  var ↓myVar = 0
                }
                """,
              ),
              Example(
                """
                class Foo {
                  let ↓mylet = 0
                }
                """,
              ),
              Example(
                """
                class Foo {
                  static var ↓myStaticVar = 0
                }
                """,
              ),
              Example(
                """
                class Foo {
                  class var ↓myClassVar = 0
                }
                """,
              ),
              Example(
                """
                class Foo {
                  let ↓myVar = Int(0), ↓s = ""
                }
                """,
              ),
              Example(
                """
                class Foo {
                  let ↓myVar = Set<Int>(0)
                }
                """,
              ),
            ]
    }
}
