struct RedundantDiscardableLetConfiguration: RuleConfiguration {
    let id = "redundant_discardable_let"
    let name = "Redundant Discardable Let"
    let summary = "Prefer `_ = foo()` over `let _ = foo()` when discarding a result from a function"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("_ = foo()"),
              Example("if let _ = foo() { }"),
              Example("guard let _ = foo() else { return }"),
              Example("let _: ExplicitType = foo()"),
              Example("while let _ = SplashStyle(rawValue: maxValue) { maxValue += 1 }"),
              Example("async let _ = await foo()"),
              Example(
                """
                var body: some View {
                    let _ = foo()
                    if cond {
                        let _ = bar()
                    }
                    return Text("Hello, World!")
                }
                """, configuration: ["ignore_swiftui_view_bodies": true],
              ),
              Example(
                """
                @ViewBuilder
                func bar() -> some View {
                    let _ = foo()
                    Text("Hello, World!")
                }
                """, configuration: ["ignore_swiftui_view_bodies": true],
              ),
              Example(
                """
                #Preview {
                    let _ = foo()
                    Text("Hello, World!")
                }
                """, configuration: ["ignore_swiftui_view_bodies": true],
              ),
              Example(
                """
                static var previews: some View {
                    let _ = foo()
                    #if DEBUG
                    let _ = bar()
                    #else
                    let _ = baz()
                    #endif
                    Text("Hello, World!")
                }
                """, configuration: ["ignore_swiftui_view_bodies": true],
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓let _ = foo()"),
              Example("if _ = foo() { ↓let _ = bar() }"),
              Example(
                """
                var body: some View {
                    ↓let _ = foo()
                    if cond {
                        ↓let _ = bar()
                    }
                    Text("Hello, World!")
                }
                """,
              ),
              Example(
                """
                @ViewBuilder
                func bar() -> some View {
                    ↓let _ = foo()
                    return Text("Hello, World!")
                }
                """,
              ),
              Example(
                """
                #Preview {
                    ↓let _ = foo()
                    return Text("Hello, World!")
                }
                """,
              ),
              Example(
                """
                static var previews: some View {
                    ↓let _ = foo()
                    Text("Hello, World!")
                }
                """,
              ),
              Example(
                """
                var notBody: some View {
                    ↓let _ = foo()
                    Text("Hello, World!")
                }
                """, configuration: ["ignore_swiftui_view_bodies": true],
                isExcludedFromDocumentation: true,
              ),
              Example(
                """
                var body: some NotView {
                    ↓let _ = foo()
                    if cond {
                        ↓let _ = bar()
                    }
                    Text("Hello, World!")
                }
                """, configuration: ["ignore_swiftui_view_bodies": true],
                isExcludedFromDocumentation: true,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("↓let _ = foo()"): Example("_ = foo()"),
              Example("if _ = foo() { ↓let _ = bar() }"): Example("if _ = foo() { _ = bar() }"),
              Example(
                """
                var body: some View {
                    ↓let _ = foo()
                    #if DEBUG
                    ↓let _ = bar()
                    #else
                    ↓let _ = baz()
                    #endif
                    Text("Hello, World!")
                }
                """,
              ): Example(
                """
                var body: some View {
                    _ = foo()
                    #if DEBUG
                    _ = bar()
                    #else
                    _ = baz()
                    #endif
                    Text("Hello, World!")
                }
                """,
              ),
              Example(
                """
                #Preview {
                    ↓let _ = foo()
                    return Text("Hello, World!")
                }
                """,
              ): Example(
                """
                #Preview {
                    _ = foo()
                    return Text("Hello, World!")
                }
                """,
              ),
              Example(
                """
                var body: some View {
                    let _ = foo()
                    return Text("Hello, World!")
                }
                """, configuration: ["ignore_swiftui_view_bodies": true],
              ): Example(
                """
                var body: some View {
                    let _ = foo()
                    return Text("Hello, World!")
                }
                """,
              ),
            ]
    }
}
