struct ApplicationMainConfiguration: RuleConfiguration {
    let id = "application_main"
    let name = "Application Main"
    let summary = "Replace `@UIApplicationMain` and `@NSApplicationMain` with `@main`"
    let scope: Scope = .suggest
}
