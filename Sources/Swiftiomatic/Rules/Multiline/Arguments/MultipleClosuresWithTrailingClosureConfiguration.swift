struct MultipleClosuresWithTrailingClosureConfiguration: RuleConfiguration {
    let id = "multiple_closures_with_trailing_closure"
    let name = "Multiple Closures with Trailing Closure"
    let summary = "Trailing closure syntax should not be used when passing more than one closure argument"
    var nonTriggeringExamples: [Example] {
        [
              Example("foo.map { $0 + 1 }"),
              Example("foo.reduce(0) { $0 + $1 }"),
              Example("if let foo = bar.map({ $0 + 1 }) {\n\n}"),
              Example("foo.something(param1: { $0 }, param2: { $0 + 1 })"),
              Example(
                """
                UIView.animate(withDuration: 1.0) {
                    someView.alpha = 0.0
                }
                """,
              ),
              Example("foo.method { print(0) } arg2: { print(1) }"),
              Example("foo.methodWithParenArgs((0, 1), arg2: (0, 1, 2)) { $0 } arg4: { $0 }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("foo.something(param1: { $0 }) ↓{ $0 + 1 }"),
              Example(
                """
                UIView.animate(withDuration: 1.0, animations: {
                    someView.alpha = 0.0
                }) ↓{ _ in
                    someView.removeFromSuperview()
                }
                """,
              ),
              Example("foo.multipleTrailing(arg1: { $0 }) { $0 } arg3: { $0 }"),
              Example("foo.methodWithParenArgs(param1: { $0 }, param2: (0, 1), (0, 1)) { $0 }"),
            ]
    }
}
