@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseBorrowAccessorNotUnderscoreReadTests: RuleTesting {
  private static let borrow =
    "'_read' runs as a coroutine — a body that only yields stored storage can be a 'borrow' accessor instead (SE-0507)"
  private static let mutate =
    "'_modify' runs as a coroutine — a body that only yields stored storage can be a 'mutate' accessor instead (SE-0507)"

  @Test func readOfStoredPropertyFlagged() {
    assertLint(
      UseBorrowAccessorNotUnderscoreRead.self,
      """
      struct Wrapper {
        var _element: Int
        var element: Int {
          1️⃣_read { yield _element }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.borrow)]
    )
  }

  @Test func modifyOfStoredPropertyFlagged() {
    assertLint(
      UseBorrowAccessorNotUnderscoreRead.self,
      """
      struct Wrapper {
        var _element: Int
        var element: Int {
          1️⃣_modify { yield &_element }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.mutate)]
    )
  }

  @Test func readAndModifyPairBothFlagged() {
    assertLint(
      UseBorrowAccessorNotUnderscoreRead.self,
      """
      struct Wrapper {
        var _element: Int
        var element: Int {
          1️⃣_read { yield _element }
          2️⃣_modify { yield &_element }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.borrow),
        FindingSpec("2️⃣", message: Self.mutate),
      ]
    )
  }

  @Test func memberChainFlagged() {
    assertLint(
      UseBorrowAccessorNotUnderscoreRead.self,
      """
      struct Wrapper {
        var element: Int {
          1️⃣_read { yield self._storage.value }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.borrow)]
    )
  }

  @Test func yieldOfComputedValueNotFlagged() {
    assertLint(
      UseBorrowAccessorNotUnderscoreRead.self,
      """
      struct Wrapper {
        var element: Int {
          _read { yield makeTemporary() }
        }
      }
      """,
      findings: []
    )
  }

  @Test func yieldOfSubscriptNotFlagged() {
    assertLint(
      UseBorrowAccessorNotUnderscoreRead.self,
      """
      struct Wrapper {
        var element: Int {
          _read { yield _storage[0] }
        }
      }
      """,
      findings: []
    )
  }

  @Test func bodyWithExtraStatementNotFlagged() {
    assertLint(
      UseBorrowAccessorNotUnderscoreRead.self,
      """
      struct Wrapper {
        var element: Int {
          _read {
            lock.lock()
            yield _element
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func plainGetterNotFlagged() {
    assertLint(
      UseBorrowAccessorNotUnderscoreRead.self,
      """
      struct Wrapper {
        var _element: Int
        var element: Int { _element }
      }
      """,
      findings: []
    )
  }

  @Test func borrowAccessorNotFlagged() {
    assertLint(
      UseBorrowAccessorNotUnderscoreRead.self,
      """
      struct Wrapper {
        var _element: Int
        var element: Int {
          borrow { return _element }
        }
      }
      """,
      findings: []
    )
  }
}
