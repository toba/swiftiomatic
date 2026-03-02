struct SwiftTestingTestCaseNamesConfiguration: RuleConfiguration {
    let id = "swift_testing_test_case_names"
    let name = "Swift Testing Test Case Names"
    let summary = "In Swift Testing, `@Test` methods should not have a `test` prefix"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                @Test func myFeatureWorks() {}
                """),
              Example(
                """
                func testSomething() {}
                """),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                @Test func ↓testMyFeatureWorks() {}
                """),
            ]
    }
}
