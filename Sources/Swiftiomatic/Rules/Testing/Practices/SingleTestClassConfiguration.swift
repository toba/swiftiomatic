struct SingleTestClassConfiguration: RuleConfiguration {
    let id = "single_test_class"
    let name = "Single Test Class"
    let summary = "Test files should contain a single QuickSpec or XCTestCase class."
    let isOptIn = true
}
