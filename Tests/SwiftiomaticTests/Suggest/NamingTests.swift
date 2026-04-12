import Foundation
import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite("NamingHeuristicsRule")
struct NamingTests {
  @Test func detectsBoolNotReadingAsAssertion() throws {
    let violations = try suggestViolations(NamingHeuristicsRule(), fixture: "Naming")

    let boolFindings = violations.filter { $0.reason.contains("assertion") }
    // Should flag 'enabled' but not 'isEnabled', 'hasError', 'canEdit'
    #expect(boolFindings.contains { $0.reason.contains("'enabled'") })
    #expect(!boolFindings.contains { $0.reason.contains("'isEnabled'") })
  }

  @Test func detectsFactoryMethodWithoutMakePrefix() throws {
    let violations = try suggestViolations(NamingHeuristicsRule(), fixture: "Naming")

    let factoryFindings = violations.filter { $0.reason.contains("Factory") }
    #expect(factoryFindings.contains { $0.reason.contains("createWidget") })
    #expect(factoryFindings.contains { $0.reason.contains("newInstance") })
    #expect(!factoryFindings.contains { $0.reason.contains("makeWidget") })
  }

  @Test func detectsMutatingMethodWithEdSuffix() throws {
    let violations = try suggestViolations(NamingHeuristicsRule(), fixture: "Naming")

    let mutatingFindings = violations.filter { $0.reason.contains("Mutating method") }
    #expect(mutatingFindings.count >= 1)
    #expect(mutatingFindings.contains { $0.reason.contains("sorted") })
  }
}
