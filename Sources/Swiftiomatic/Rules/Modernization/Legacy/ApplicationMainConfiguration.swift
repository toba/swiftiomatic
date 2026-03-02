struct ApplicationMainConfiguration: RuleConfiguration {
    let id = "application_main"
    let name = "Application Main"
    let summary = "Replace `@UIApplicationMain` and `@NSApplicationMain` with `@main`"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                @main
                class AppDelegate: UIResponder, UIApplicationDelegate {}
                """),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓@UIApplicationMain
                class AppDelegate: UIResponder, UIApplicationDelegate {}
                """),
            ]
    }
}
