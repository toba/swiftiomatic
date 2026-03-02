struct ShorthandOperatorConfiguration: RuleConfiguration {
    let id = "shorthand_operator"
    let name = "Shorthand Operator"
    let summary = "Prefer shorthand operators (+=, -=, *=, /=) over doing the operation and assigning"
    var nonTriggeringExamples: [Example] {
        [
              Example("foo -= 1"),
              Example("foo += variable"),
              Example("foo *= bar.method()"),
              Example("self.foo = foo / 1"),
              Example("foo = self.foo + 1"),
              Example("page = ceilf(currentOffset * pageWidth)"),
              Example("foo = aMethod(foo / bar)"),
              Example("foo = aMethod(bar + foo)"),
              Example(
                """
                public func -= (lhs: inout Foo, rhs: Int) {
                    lhs = lhs - rhs
                }
                """,
              ),
              Example("var helloWorld = \"world!\"\n helloWorld = \"Hello, \" + helloWorld"),
              Example("angle = someCheck ? angle : -angle"),
              Example("seconds = seconds * 60 + value"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓foo = foo * 1"),
              Example("↓foo = foo / aVariable"),
              Example("↓foo = foo - bar.method()"),
              Example("↓foo.aProperty = foo.aProperty - 1"),
              Example("↓self.aProperty = self.aProperty * 1"),
              Example("↓n = n + i / outputLength"),
              Example("↓n = n - i / outputLength"),
            ]
    }
}
