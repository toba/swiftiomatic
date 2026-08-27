import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseAsyncTimerSequenceTests: RuleTesting {
  private static func message(_ api: String) -> String {
    "'\(api)' schedules outside the task tree, so nothing cancels it with the caller — use 'AsyncTimerSequence'"
  }

  @Test func scheduledTimerFlagged() {
    assertLint(
      UseAsyncTimerSequence.self,
      """
      func start() {
        Timer.1️⃣scheduledTimer(withTimeInterval: 1, repeats: true) { _ in tick() }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("Timer.scheduledTimer"))]
    )
  }

  @Test func timerPublishFlagged() {
    assertLint(
      UseAsyncTimerSequence.self,
      """
      let ticks = Timer.1️⃣publish(every: 1, on: .main, in: .common)
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("Timer.publish"))]
    )
  }

  @Test func dispatchTimerSourceFlagged() {
    assertLint(
      UseAsyncTimerSequence.self,
      """
      func start() {
        let source = DispatchSource.1️⃣makeTimerSource(queue: .main)
        source.resume()
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("DispatchSource.makeTimerSource"))]
    )
  }

  @Test func asyncTimerSequenceNotFlagged() {
    assertLint(
      UseAsyncTimerSequence.self,
      """
      func start() async {
        for await _ in AsyncTimerSequence(interval: .seconds(1), clock: .continuous) {
          tick()
        }
      }
      """,
      findings: []
    )
  }

  @Test func unrelatedPublishNotFlagged() {
    assertLint(
      UseAsyncTimerSequence.self,
      """
      let values = subject.publish(every: 1)
      """,
      findings: []
    )
  }
}
