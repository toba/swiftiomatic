struct ImplicitlyUnwrappedOptionalConfiguration: RuleConfiguration {
    let id = "implicitly_unwrapped_optional"
    let name = "Implicitly Unwrapped Optional"
    let summary = "Implicitly unwrapped optionals should be avoided when possible"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("@IBOutlet private var label: UILabel!"),
              Example("@IBOutlet var label: UILabel!"),
              Example("@IBOutlet var label: [UILabel!]"),
              Example("if !boolean {}"),
              Example("let int: Int? = 42"),
              Example("let int: Int? = nil"),
              Example(
                """
                class MyClass {
                    @IBOutlet
                    weak var bar: SomeObject!
                }
                """, configuration: ["mode": "all_except_iboutlets"],
                isExcludedFromDocumentation: true,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let label: ↓UILabel!"),
              Example("let IBOutlet: ↓UILabel!"),
              Example("let labels: [↓UILabel!]"),
              Example("var ints: [↓Int!] = [42, nil, 42]"),
              Example("let label: ↓IBOutlet!"),
              Example("let int: ↓Int! = 42"),
              Example("let int: ↓Int! = nil"),
              Example("var int: ↓Int! = 42"),
              Example("let collection: AnyCollection<↓Int!>"),
              Example("func foo(int: ↓Int!) {}"),
              Example(
                """
                class MyClass {
                    weak var bar: ↓SomeObject!
                }
                """,
              ),
            ]
    }
}
