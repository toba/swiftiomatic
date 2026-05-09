@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RequireSubprocessTeardownSequenceTests: RuleTesting {
  private static let missing =
    "'Subprocess.run' without 'platformOptions:' can orphan the child on cancellation — pass 'PlatformOptions(teardownSequence: [...])'"
  private static let defaultOptions =
    "default 'PlatformOptions()' has no teardown sequence — pass 'PlatformOptions(teardownSequence: [...])' to avoid orphaned children on cancellation"

  @Test func missingPlatformOptionsFlagged() {
    assertLint(
      RequireSubprocessTeardownSequence.self,
      """
      let result = try await 1️⃣Subprocess.run(.path("/bin/echo"), arguments: ["hi"])
      """,
      findings: [FindingSpec("1️⃣", message: Self.missing)]
    )
  }

  @Test func defaultPlatformOptionsFlagged() {
    assertLint(
      RequireSubprocessTeardownSequence.self,
      """
      let result = try await Subprocess.run(
        .path("/bin/echo"),
        1️⃣platformOptions: PlatformOptions()
      )
      """,
      findings: [FindingSpec("1️⃣", message: Self.defaultOptions)]
    )
  }

  @Test func explicitTeardownSequenceNotFlagged() {
    assertLint(
      RequireSubprocessTeardownSequence.self,
      """
      let result = try await Subprocess.run(
        .path("/bin/echo"),
        platformOptions: PlatformOptions(teardownSequence: [.gracefulShutDown(allowedDuration: .seconds(1))])
      )
      """,
      findings: []
    )
  }

  @Test func customPlatformOptionsValueNotFlagged() {
    assertLint(
      RequireSubprocessTeardownSequence.self,
      """
      let result = try await Subprocess.run(.path("/bin/echo"), platformOptions: opts)
      """,
      findings: []
    )
  }

  @Test func unrelatedRunNotFlagged() {
    assertLint(
      RequireSubprocessTeardownSequence.self,
      """
      Foo.run()
      """,
      findings: []
    )
  }
}
