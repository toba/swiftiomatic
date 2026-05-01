@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseContinuousClockNotDateTests: RuleTesting {
  @Test func dateTimeIntervalSinceCall() {
    assertLint(
      UseContinuousClockNotDate.self,
      """
      let start = Date()
      let elapsed = 1️⃣Date().timeIntervalSince(start)
      """,
      findings: [
        FindingSpec("1️⃣", message: "elapsed time uses 'Date()' — prefer 'ContinuousClock.now' + 'duration(to:)' (monotonic, allocation-free)"),
      ]
    )
  }

  @Test func dateTimeIntervalSinceNowProperty() {
    assertLint(
      UseContinuousClockNotDate.self,
      """
      let elapsed = 1️⃣Date().timeIntervalSinceNow
      """,
      findings: [
        FindingSpec("1️⃣", message: "elapsed time uses 'Date()' — prefer 'ContinuousClock.now' + 'duration(to:)' (monotonic, allocation-free)"),
      ]
    )
  }

  @Test func dateAloneUntouched() {
    assertLint(
      UseContinuousClockNotDate.self,
      """
      let now = Date()
      """,
      findings: []
    )
  }

  @Test func dateWithArgumentsUntouched() {
    assertLint(
      UseContinuousClockNotDate.self,
      """
      let elapsed = Date(timeIntervalSinceReferenceDate: 0).timeIntervalSinceNow
      """,
      findings: []
    )
  }

  @Test func continuousClockUntouched() {
    assertLint(
      UseContinuousClockNotDate.self,
      """
      let start = ContinuousClock.now
      let elapsed = start.duration(to: .now)
      """,
      findings: []
    )
  }
}
