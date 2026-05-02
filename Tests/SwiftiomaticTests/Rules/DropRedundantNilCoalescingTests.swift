@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DropRedundantNilCoalescingTests: RuleTesting {
  @Test func basicCoalesceNil() {
    assertFormatting(
      DropRedundantNilCoalescing.self,
      input: """
        let result = x 1️⃣?? nil
        """,
      expected: """
        let result = x
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '?? nil'; the value is unchanged"),
      ]
    )
  }

  @Test func memberAccessLHS() {
    assertFormatting(
      DropRedundantNilCoalescing.self,
      input: """
        let r = obj.value 1️⃣?? nil
        """,
      expected: """
        let r = obj.value
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '?? nil'; the value is unchanged"),
      ]
    )
  }

  @Test func nonNilRHSNotFlagged() {
    assertFormatting(
      DropRedundantNilCoalescing.self,
      input: """
        let result = x ?? 0
        """,
      expected: """
        let result = x ?? 0
        """,
      findings: []
    )
  }

  @Test func otherOperatorNotFlagged() {
    assertFormatting(
      DropRedundantNilCoalescing.self,
      input: """
        let result = x + nil
        """,
      expected: """
        let result = x + nil
        """,
      findings: []
    )
  }

  @Test func findingLocationOnLaterLine() {
    // Regression for bug `7l3-lzx`: when the `?? nil` lives many lines into a file,
    // the finding must point at the actual `??` token, not at line 1/2 (which would
    // happen if the diagnose is anchored to the post-rewrite, detached subtree).
    assertFormatting(
      DropRedundantNilCoalescing.self,
      input: """
        import GRDB
        import SwiftUI
        import CloudKit

        /// A shared record.
        ///
        /// See <doc:CloudKitSharing> for more info.
        public struct SharedRecord {
            let container: Any
            public let share: String

            public func compute() -> String? {
                let value: String? = nil
                return value 1️⃣?? nil
            }
        }
        """,
      expected: """
        import GRDB
        import SwiftUI
        import CloudKit

        /// A shared record.
        ///
        /// See <doc:CloudKitSharing> for more info.
        public struct SharedRecord {
            let container: Any
            public let share: String

            public func compute() -> String? {
                let value: String? = nil
                return value
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '?? nil'; the value is unchanged"),
      ]
    )
  }

  @Test func functionCallLHSNotFlagged() {
    // Regression for bug `kna-m0s`: `?? nil` after a function/method call may be
    // flattening a double optional (T?? -> T?), e.g. when fetchOne returns T? and
    // T is itself Optional. Stripping it breaks compilation, so leave it alone.
    assertFormatting(
      DropRedundantNilCoalescing.self,
      input: """
        let share = try CloudRecord
            .where { $0.recordName.eq(recordName) }
            .select { $0.share }
            .fetchOne(db)
            ?? nil
        """,
      expected: """
        let share = try CloudRecord
            .where { $0.recordName.eq(recordName) }
            .select { $0.share }
            .fetchOne(db)
            ?? nil
        """,
      findings: []
    )
  }

  @Test func tryOptionalLHSNotFlagged() {
    // `(try? foo()) ?? nil` flattens T?? from try? when foo() returns T?.
    assertFormatting(
      DropRedundantNilCoalescing.self,
      input: """
        let value = try? compute() ?? nil
        """,
      expected: """
        let value = try? compute() ?? nil
        """,
      findings: []
    )
  }

  @Test func subscriptLHSNotFlagged() {
    // Dictionary subscript on optional values returns T?? where T is the value type.
    assertFormatting(
      DropRedundantNilCoalescing.self,
      input: """
        let v = dict[key] ?? nil
        """,
      expected: """
        let v = dict[key] ?? nil
        """,
      findings: []
    )
  }

  @Test func nestedExpression() {
    assertFormatting(
      DropRedundantNilCoalescing.self,
      input: """
        return f(x 1️⃣?? nil)
        """,
      expected: """
        return f(x)
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '?? nil'; the value is unchanged"),
      ]
    )
  }
}
