struct EmptyXCTestMethodConfiguration: RuleConfiguration {
    let id = "empty_xctest_method"
    let name = "Empty XCTest Method"
    let summary = "Empty XCTest method should be avoided"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        EmptyXCTestMethodRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        EmptyXCTestMethodRuleExamples.triggeringExamples
    }
}
