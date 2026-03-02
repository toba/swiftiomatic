struct RedundantViewBuilderConfiguration: RuleConfiguration {
    let id = "redundant_view_builder"
    let name = "Redundant ViewBuilder"
    let summary = "`@ViewBuilder` is redundant on the `body` property of View/ViewModifier or on single-expression bodies"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                struct MyView: View {
                  var body: some View {
                    Text("Hello")
                  }
                }
                """,
              ),
              Example(
                """
                struct MyView: View {
                  @ViewBuilder
                  var content: some View {
                    if showText {
                      Text("Hello")
                    }
                    Text("World")
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
                struct MyView: View {
                  ↓@ViewBuilder
                  var body: some View {
                    Text("Hello")
                  }
                }
                """,
              ),
              Example(
                """
                struct MyView: View {
                  ↓@ViewBuilder
                  var content: some View {
                    Text("Hello")
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
                struct MyView: View {
                  ↓@ViewBuilder
                  var body: some View {
                    Text("Hello")
                  }
                }
                """,
              ): Example(
                """
                struct MyView: View {
                  var body: some View {
                    Text("Hello")
                  }
                }
                """,
              )
            ]
    }
}
