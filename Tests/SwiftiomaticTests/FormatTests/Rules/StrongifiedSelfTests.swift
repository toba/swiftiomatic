import Testing

@testable import Swiftiomatic

@Suite struct StrongifiedSelfTests {
  @Test func backtickedSelfConvertedToSelfInGuard() {
    let input = """
      { [weak self] in
          guard let `self` = self else { return }
      }
      """
    let output = """
      { [weak self] in
          guard let self = self else { return }
      }
      """
    let options = FormatOptions(swiftVersion: "4.2")
    testFormatting(
      for: input, output, rule: .strongifiedSelf, options: options,
      exclude: [.wrapConditionalBodies])
  }

  @Test func backtickedSelfConvertedToSelfInIf() {
    let input = """
      { [weak self] in
          if let `self` = self else { print(self) }
      }
      """
    let output = """
      { [weak self] in
          if let self = self else { print(self) }
      }
      """
    let options = FormatOptions(swiftVersion: "4.2")
    testFormatting(
      for: input, output, rule: .strongifiedSelf, options: options,
      exclude: [.wrapConditionalBodies])
  }

  @Test func backtickedSelfNotConvertedIfVersionLessThan4_2() {
    let input = """
      { [weak self] in
          guard let `self` = self else { return }
      }
      """
    let options = FormatOptions(swiftVersion: "4.1.5")
    testFormatting(
      for: input, rule: .strongifiedSelf, options: options,
      exclude: [.wrapConditionalBodies])
  }

  @Test func backtickedSelfNotConvertedIfVersionUnspecified() {
    let input = """
      { [weak self] in
          guard let `self` = self else { return }
      }
      """
    testFormatting(
      for: input, rule: .strongifiedSelf,
      exclude: [.wrapConditionalBodies])
  }

  @Test func backtickedSelfNotConvertedIfNotConditional() {
    let input = """
      nonisolated(unsafe) let `self` = self
      """
    let options = FormatOptions(swiftVersion: "4.2")
    testFormatting(for: input, rule: .strongifiedSelf, options: options)
  }
}
