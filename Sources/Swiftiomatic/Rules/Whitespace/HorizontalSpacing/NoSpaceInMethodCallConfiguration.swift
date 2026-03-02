struct NoSpaceInMethodCallConfiguration: RuleConfiguration {
    let id = "no_space_in_method_call"
    let name = "No Space in Method Call"
    let summary = "Don't add a space between the method name and the parentheses"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("foo()"),
              Example("object.foo()"),
              Example("object.foo(1)"),
              Example("object.foo(value: 1)"),
              Example("object.foo { print($0 }"),
              Example("list.sorted { $0.0 < $1.0 }.map { $0.value }"),
              Example("self.init(rgb: (Int) (colorInt))"),
              Example(
                """
                Button {
                    print("Button tapped")
                } label: {
                    Text("Button")
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("foo↓ ()"),
              Example("object.foo↓ ()"),
              Example("object.foo↓ (1)"),
              Example("object.foo↓ (value: 1)"),
              Example("object.foo↓ () {}"),
              Example("object.foo↓     ()"),
              Example("object.foo↓     (value: 1) { x in print(x) }"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("foo↓ ()"): Example("foo()"),
              Example("object.foo↓ ()"): Example("object.foo()"),
              Example("object.foo↓ (1)"): Example("object.foo(1)"),
              Example("object.foo↓ (value: 1)"): Example("object.foo(value: 1)"),
              Example("object.foo↓ () {}"): Example("object.foo() {}"),
              Example("object.foo↓     ()"): Example("object.foo()"),
            ]
    }
}
