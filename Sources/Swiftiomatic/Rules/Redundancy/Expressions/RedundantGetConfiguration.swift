struct RedundantGetConfiguration: RuleConfiguration {
    let id = "redundant_get"
    let name = "Redundant Get"
    let summary = "Computed read-only properties should avoid using the `get` keyword"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                var foo: Int {
                    return 5
                }
                """,
              ),
              Example(
                """
                var foo: Int {
                    get { return 5 }
                    set { _foo = newValue }
                }
                """,
              ),
              Example(
                """
                var enabled: Bool { @objc(isEnabled) get { true } }
                """,
              ),
              Example(
                """
                var foo: Int {
                    get async throws {
                        try await getFoo()
                    }
                }
                """,
              ),
              Example(
                """
                func foo() {
                    get {
                        self.lookup(index)
                    }
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                var foo: Int {
                    ↓get {
                        return 5
                    }
                }
                """,
              ),
              Example("var foo: Int { ↓get { return 5 } }"),
              Example(
                """
                subscript(_ index: Int) {
                    ↓get {
                        return lookup(index)
                    }
                }
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example(
                """
                var foo: Int {
                    ↓get {
                        return 5
                    }
                }
                """,
              ): Example(
                """
                var foo: Int {
                    return 5
                }
                """,
              ),
              Example("var foo: Int { ↓get { return 5 } }"): Example(
                "var foo: Int { return 5 }",
              ),
              Example(
                """
                subscript(_ index: Int) {
                    ↓get {
                        return lookup(index)
                    }
                }
                """,
              ): Example(
                """
                subscript(_ index: Int) {
                    return lookup(index)
                }
                """,
              ),
            ]
    }
}
