struct UnneededParenthesesInClosureArgumentConfiguration: RuleConfiguration {
    let id = "unneeded_parentheses_in_closure_argument"
    let name = "Unneeded Parentheses in Closure Argument"
    let summary = "Parentheses are not needed when declaring closure arguments"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let foo = { (bar: Int) in }"),
              Example("let foo = { bar, _  in }"),
              Example("let foo = { bar in }"),
              Example("let foo = { bar -> Bool in return true }"),
              Example(
                """
                DispatchQueue.main.async { () -> Void in
                    doSomething()
                }
                """,
              ),
              Example(
                """
                registerFilter(name) { any, args throws -> Any? in
                    doSomething(any, args)
                }
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("call(arg: { ↓(bar) in })"),
              Example("call(arg: { ↓(bar, _) in })"),
              Example("let foo = { ↓(bar) -> Bool in return true }"),
              Example("foo.map { ($0, $0) }.forEach { ↓(x, y) in }"),
              Example("foo.bar { [weak self] ↓(x, y) in }"),
              Example(
                """
                [].first { ↓(temp) in
                    [].first { ↓(temp) in
                        [].first { ↓(temp) in
                            _ = temp
                            return false
                        }
                        return false
                    }
                    return false
                }
                """,
              ),
              Example(
                """
                [].first { temp in
                    [].first { ↓(temp) in
                        [].first { ↓(temp) in
                            _ = temp
                            return false
                        }
                        return false
                    }
                    return false
                }
                """,
              ),
              Example(
                """
                registerFilter(name) { ↓(any, args) throws -> Any? in
                    doSomething(any, args)
                }
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("call(arg: { ↓(bar) in })"): Example("call(arg: { bar in })"),
              Example("call(arg: { ↓(bar, _) in })"): Example("call(arg: { bar, _ in })"),
              Example("call(arg: { ↓(bar, _)in })"): Example("call(arg: { bar, _ in })"),
              Example("let foo = { ↓(bar) -> Bool in return true }"):
                Example("let foo = { bar -> Bool in return true }"),
              Example("method { ↓(foo, bar) in }"): Example("method { foo, bar in }"),
              Example("foo.map { ($0, $0) }.forEach { ↓(x, y) in }"): Example(
                "foo.map { ($0, $0) }.forEach { x, y in }",
              ),
              Example("foo.bar { [weak self] ↓(x, y) in }"): Example(
                "foo.bar { [weak self] x, y in }",
              ),
            ]
    }
}
