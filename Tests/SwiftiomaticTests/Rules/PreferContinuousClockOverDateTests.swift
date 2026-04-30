@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferContinuousClockOverDateTests: RuleTesting {
  @Test func dateTimeIntervalSinceCall() {
    assertLint(
      PreferContinuousClockOverDate.self,
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
      PreferContinuousClockOverDate.self,
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
      PreferContinuousClockOverDate.self,
      """
      let now = Date()
      """,
      findings: []
    )
  }

  @Test func dateWithArgumentsUntouched() {
    assertLint(
      PreferContinuousClockOverDate.self,
      """
      let elapsed = Date(timeIntervalSinceReferenceDate: 0).timeIntervalSinceNow
      """,
      findings: []
    )
  }

  @Test func continuousClockUntouched() {
    assertLint(
      PreferContinuousClockOverDate.self,
      """
      let start = ContinuousClock.now
      let elapsed = start.duration(to: .now)
      """,
      findings: []
    )
  }
}
