import XCTest
import SwiftiomaticSyntax

@testable import SwiftLintBuiltInRulesTests

extension AttributePlacementRuleTests {
  static var allTests: [(String, (AttributePlacementRuleTests) -> () throws -> Void)] = [
    ("testAttributesWithDefaultConfiguration", testAttributesWithDefaultConfiguration),
    ("testAttributesWithAlwaysOnSameLine", testAttributesWithAlwaysOnSameLine),
    ("testAttributesWithAlwaysOnLineAbove", testAttributesWithAlwaysOnLineAbove),
  ]
}
