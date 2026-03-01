import XCTest
@testable import SwiftLintBuiltInRulesTests

extension AttributesRuleTests {
    static var allTests: [(String, (AttributesRuleTests) -> () throws -> Void)] = [
        ("testAttributesWithDefaultConfiguration", testAttributesWithDefaultConfiguration),
        ("testAttributesWithAlwaysOnSameLine", testAttributesWithAlwaysOnSameLine),
        ("testAttributesWithAlwaysOnLineAbove", testAttributesWithAlwaysOnLineAbove),
    ]
}
