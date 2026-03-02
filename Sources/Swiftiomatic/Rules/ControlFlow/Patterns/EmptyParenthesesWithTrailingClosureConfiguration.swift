struct EmptyParenthesesWithTrailingClosureConfiguration: RuleConfiguration {
    let id = "empty_parentheses_with_trailing_closure"
    let name = "Empty Parentheses with Trailing Closure"
    let summary = "When using trailing closures, empty parentheses should be avoided after the method call"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("[1, 2].map { $0 + 1 }"),
              Example("[1, 2].map({ $0 + 1 })"),
              Example("[1, 2].reduce(0) { $0 + $1 }"),
              Example("[1, 2].map { number in\n number + 1 \n}"),
              Example("let isEmpty = [1, 2].isEmpty()"),
              Example(
                """
                UIView.animateWithDuration(0.3, animations: {
                   self.disableInteractionRightView.alpha = 0
                }, completion: { _ in
                   ()
                })
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("[1, 2].map↓() { $0 + 1 }"),
              Example("[1, 2].map↓( ) { $0 + 1 }"),
              Example("[1, 2].map↓() { number in\n number + 1 \n}"),
              Example("[1, 2].map↓(  ) { number in\n number + 1 \n}"),
              Example("func foo() -> [Int] {\n    return [1, 2].map↓() { $0 + 1 }\n}"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("[1, 2].map↓() { $0 + 1 }"): Example("[1, 2].map { $0 + 1 }"),
              Example("[1, 2].map↓( ) { $0 + 1 }"): Example("[1, 2].map { $0 + 1 }"),
              Example("[1, 2].map↓() { number in\n number + 1 \n}"):
                Example("[1, 2].map { number in\n number + 1 \n}"),
              Example("[1, 2].map↓(  ) { number in\n number + 1 \n}"):
                Example("[1, 2].map { number in\n number + 1 \n}"),
              Example("func foo() -> [Int] {\n    return [1, 2].map↓() { $0 + 1 }\n}"):
                Example("func foo() -> [Int] {\n    return [1, 2].map { $0 + 1 }\n}"),
              Example("class C {\n#if true\nfunc f() {\n[1, 2].map↓() { $0 + 1 }\n}\n#endif\n}"):
                Example("class C {\n#if true\nfunc f() {\n[1, 2].map { $0 + 1 }\n}\n#endif\n}"),
            ]
    }
}
