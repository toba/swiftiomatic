struct PrivateUnitTestConfiguration: RuleConfiguration {
    let id = "private_unit_test"
    let name = "Private Unit Test"
    let summary = "Unit tests marked private are silently skipped"
    let isCorrectable = true
}
