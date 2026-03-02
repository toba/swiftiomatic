struct ModifiersOnSameLineConfiguration: RuleConfiguration {
    let id = "modifiers_on_same_line"
    let name = "Modifiers on Same Line"
    let summary = "Modifiers should be on the same line as the declaration keyword"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
                    Example("public var foo: Foo"),
                    Example("@MainActor public private(set) var foo: Foo"),
                    Example("nonisolated func bar() {}"),
                ]
    }
    var triggeringExamples: [Example] {
        [
                    Example(
                        """
                        ↓public
                        private(set)
                        var foo: Foo
                        """,
                    ),
                    Example(
                        """
                        ↓nonisolated
                        func bar() {}
                        """,
                    ),
                ]
    }
    var corrections: [Example: Example] {
        [
                    Example("↓public\nvar foo: Foo"): Example("public var foo: Foo"),
                    Example("↓nonisolated\nfunc bar() {}"): Example("nonisolated func bar() {}"),
                ]
    }
}
