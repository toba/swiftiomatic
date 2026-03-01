import Testing

@testable import Swiftiomatic

@Suite struct RedundantGetTests {
  @Test func removeSingleLineIsolatedGet() {
    let input = """
      var foo: Int { get { return 5 } }
      """
    let output = """
      var foo: Int { return 5 }
      """
    testFormatting(
      for: input, output, rule: .redundantGet,
      exclude: [
        .wrapFunctionBodies,
        .wrapPropertyBodies,
      ],
    )
  }

  @Test func removeMultilineIsolatedGet() {
    let input = """
      var foo: Int {
          get {
              return 5
          }
      }
      """
    let output = """
      var foo: Int {
          return 5
      }
      """
    testFormatting(for: input, [output], rules: [.redundantGet, .indent])
  }

  @Test func noRemoveMultilineGetSet() {
    let input = """
      var foo: Int {
          get { return 5 }
          set { foo = newValue }
      }
      """
    testFormatting(for: input, rule: .redundantGet)
  }

  @Test func noRemoveAttributedGet() {
    let input = """
      var enabled: Bool { @objc(isEnabled) get { true } }
      """
    testFormatting(
      for: input, rule: .redundantGet, exclude: [.wrapFunctionBodies, .wrapPropertyBodies],
    )
  }

  @Test func removeSubscriptGet() {
    let input = """
      subscript(_ index: Int) {
          get {
              return lookup(index)
          }
      }
      """
    let output = """
      subscript(_ index: Int) {
          return lookup(index)
      }
      """
    testFormatting(for: input, [output], rules: [.redundantGet, .indent])
  }

  @Test func getNotRemovedInFunction() {
    let input = """
      func foo() {
          get {
              self.lookup(index)
          }
      }
      """
    testFormatting(for: input, rule: .redundantGet)
  }

  @Test func effectfulGetNotRemoved() {
    let input = """
      var foo: Int {
          get async throws {
              try await getFoo()
          }
      }
      """
    testFormatting(for: input, rule: .redundantGet)
  }
}
