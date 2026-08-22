import Foundation
@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagRecursiveObservationTrackingTests: RuleTesting {
  @Test func recursiveOnChangeFlagged() {
    assertLint(
      FlagRecursiveObservationTracking.self,
      """
      func observe() {
        1️⃣withObservationTracking {
          _ = model.value
        } onChange: {
          observe()
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'withObservationTracking' onChange calls enclosing 'observe' — infinite re-tracking. Use 'Observations' AsyncSequence."),
      ]
    )
  }

  @Test func selfRecursiveOnChangeFlagged() {
    assertLint(
      FlagRecursiveObservationTracking.self,
      """
      func track() {
        1️⃣withObservationTracking {
          _ = model.value
        } onChange: {
          self.track()
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'withObservationTracking' onChange calls enclosing 'track' — infinite re-tracking. Use 'Observations' AsyncSequence."),
      ]
    )
  }

  @Test func nonRecursiveOnChangeNotFlagged() {
    assertLint(
      FlagRecursiveObservationTracking.self,
      """
      func observe() {
        withObservationTracking {
          _ = model.value
        } onChange: {
          print("changed")
        }
      }
      """,
      findings: []
    )
  }

  @Test func recursiveOnChangeInTestDirectoryNotFlagged() {
    assertLint(
      FlagRecursiveObservationTracking.self,
      """
      @Sendable func track() {
        withObservationTracking {
          _ = store.value
        } onChange: {
          notifications.withLock { $0 += 1 }
          track()
        }
      }
      """,
      findings: [],
      assumingFileURL: URL(fileURLWithPath: "/pkg/Core/Tests/Storage/FetchStoreTests.swift")
    )
  }

  @Test func recursiveOnChangeInTestFileNameNotFlagged() {
    assertLint(
      FlagRecursiveObservationTracking.self,
      """
      func track() {
        withObservationTracking {
          _ = store.value
        } onChange: {
          track()
        }
      }
      """,
      findings: [],
      assumingFileURL: URL(fileURLWithPath: "/pkg/Sources/FetchStoreTests.swift")
    )
  }

  @Test func outsideAFunctionNotFlagged() {
    assertLint(
      FlagRecursiveObservationTracking.self,
      """
      withObservationTracking {
        _ = model.value
      } onChange: {
        somethingElse()
      }
      """,
      findings: []
    )
  }
}
