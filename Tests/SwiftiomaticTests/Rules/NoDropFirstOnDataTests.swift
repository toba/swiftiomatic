import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoDropFirstOnDataTests: RuleTesting {
  private static let message =
    "'dropFirst' copies the whole 'Data' buffer, so a parse loop is quadratic — advance an index, or slice once"

  @Test func storedDataPropertyFlagged() {
    assertLint(
      NoDropFirstOnData.self,
      """
      struct Parser {
        var buffer: Data

        mutating func next() -> UInt8? {
          let byte = buffer.first
          buffer = buffer.1️⃣dropFirst()
          return byte
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func dataParameterFlagged() {
    assertLint(
      NoDropFirstOnData.self,
      """
      func parse(_ bytes: Data) -> Data {
        bytes.1️⃣dropFirst(4)
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func dataInitializerFlagged() {
    assertLint(
      NoDropFirstOnData.self,
      """
      func header() -> Data {
        let payload = Data(contentsOf: url)
        return payload.1️⃣dropFirst(8)
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func stringDropFirstNotFlagged() {
    assertLint(
      NoDropFirstOnData.self,
      """
      func trim(_ name: String) -> Substring {
        name.dropFirst()
      }
      """,
      findings: []
    )
  }

  @Test func arrayDropFirstNotFlagged() {
    assertLint(
      NoDropFirstOnData.self,
      """
      func tail(_ items: [Int]) -> ArraySlice<Int> {
        items.dropFirst()
      }
      """,
      findings: []
    )
  }

  @Test func indexAdvanceNotFlagged() {
    assertLint(
      NoDropFirstOnData.self,
      """
      struct Parser {
        var buffer: Data
        var index: Int

        mutating func next() -> UInt8? {
          defer { index += 1 }
          return buffer[index]
        }
      }
      """,
      findings: []
    )
  }
}
