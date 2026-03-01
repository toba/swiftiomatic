import Foundation
import Testing

@testable import Swiftiomatic

@Suite("CaseIterableUsageRule")
struct CaseIterableUsageTests {
    let fixturePath: String = {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("SuggestFixtures/CaseIterableUsage.swift")
            .path
    }()

    @Test func detectsCaseIterableWithoutAllCases() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = CaseIterableUsageRule()

        // CollectingRule: first collect, then validate
        let info = rule.collectInfo(for: file)
        let collectedInfo: [SwiftSource: CaseIterableContribution] = [file: info]
        let violations = rule.validate(file: file, collectedInfo: collectedInfo)

        // Should flag Status (no .allCases reference)
        #expect(violations.contains { $0.reason.contains("Status") })
    }

    @Test func doesNotFlagCaseIterableWithAllCases() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = CaseIterableUsageRule()

        let info = rule.collectInfo(for: file)
        let collectedInfo: [SwiftSource: CaseIterableContribution] = [file: info]
        let violations = rule.validate(file: file, collectedInfo: collectedInfo)

        // Should NOT flag Direction (has .allCases reference)
        #expect(!violations.contains { $0.reason.contains("Direction") })
    }

    @Test func doesNotFlagNonCaseIterableEnums() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = CaseIterableUsageRule()

        let info = rule.collectInfo(for: file)
        let collectedInfo: [SwiftSource: CaseIterableContribution] = [file: info]
        let violations = rule.validate(file: file, collectedInfo: collectedInfo)

        // Should NOT flag Color (not CaseIterable)
        #expect(!violations.contains { $0.reason.contains("Color") })
    }
}
