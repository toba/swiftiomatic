import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct LineEndingTests {
  @Test func carriageReturnDoesNotCauseError() async {
    #expect(
      await violations(
        Example(
          "// sm:disable:next blanket_disable_command\r\n"
            + "// sm:disable all\r\nprint(123)\r\n",
        ),
      ).isEmpty,
    )
  }
}
