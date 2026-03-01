import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct ExampleTests {
  @Test func equatableDoesNotLookAtFile() {
    let first = Example("foo", file: "a", line: 1)
    let second = Example("foo", file: "b", line: 1)
    #expect(first == second)
  }

  @Test func equatableDoesNotLookAtLine() {
    let first = Example("foo", file: "a", line: 1)
    let second = Example("foo", file: "a", line: 2)
    #expect(first == second)
  }

  @Test func equatableLooksAtCode() {
    let first = Example("a", file: "a", line: 1)
    let second = Example("a", file: "x", line: 2)
    let third = Example("c", file: "y", line: 2)
    #expect(first == second)
    #expect(first != third)
  }

  @Test func multiByteOffsets() {
    #expect(Example("").shouldTestMultiByteOffsets)
    #expect(Example("", shouldTestMultiByteOffsets: true).shouldTestMultiByteOffsets)
    #expect(!(Example("", shouldTestMultiByteOffsets: false).shouldTestMultiByteOffsets))
  }

  @Test func removingViolationMarkers() {
    let example = Example("\u{2193}T\u{2193}E\u{2193}S\u{2193}T")
    #expect(example.removingViolationMarkers() == Example("TEST"))
  }

  @Test func comparable() {
    #expect(Example("a") < Example("b"))
  }

  @Test func withCode() {
    let original = Example("original code")
    #expect(original.file != nil)
    #expect(original.line != nil)

    let new = original.with(code: "new code")
    #expect(new.code == "new code")
    #expect(new.file != nil)
    #expect(new.line != nil)

    // When modifying the code, it's important that the file and line
    // numbers remain intact
    #expect(new.file.description == original.file.description)
    #expect(new.line == original.line)
  }
}
