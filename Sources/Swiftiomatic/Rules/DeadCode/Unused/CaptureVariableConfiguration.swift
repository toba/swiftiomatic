struct CaptureVariableConfiguration: RuleConfiguration {
    let id = "capture_variable"
    let name = "Capture Variable"
    let summary = "Non-constant variables should not be listed in a closure's capture list to avoid confusion about closures capturing variables at creation time"
    let isOptIn = true
    let requiresSourceKit = true
    let requiresCompilerArguments = true
    let requiresFileOnDisk = true
    let isCrossFile = true
}
