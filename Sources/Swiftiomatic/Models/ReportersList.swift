/// The reporters list containing all the reporters built into SwiftLint.
nonisolated(unsafe) let reportersList: [any Reporter.Type] = [
    CSVReporter.self,
    CheckstyleReporter.self,
    CodeClimateReporter.self,
    EmojiReporter.self,
    GitHubActionsLoggingReporter.self,
    GitLabJUnitReporter.self,
    HTMLReporter.self,
    JSONReporter.self,
    JUnitReporter.self,
    MarkdownReporter.self,
    RelativePathReporter.self,
    SARIFReporter.self,
    SonarQubeReporter.self,
    SummaryReporter.self,
    XcodeReporter.self,
]
