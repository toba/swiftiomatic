/// Describes an expected rule violation for test assertions.
///
/// Pair with ``MarkedText`` to verify that a rule emits the correct violations
/// at the correct locations:
///
///     assertLint(TrailingWhitespaceRule.self, """
///         let x = 1  1️⃣
///         let y = 22️⃣
///         """,
///         findings: [
///             FindingSpec("1️⃣", message: "Lines should not have trailing whitespace"),
///         ]
///     )
struct FindingSpec {
  /// The emoji marker identifying the expected violation location.
  let marker: String

  /// The expected violation message text.
  let message: String

  /// Creates a finding spec.
  ///
  /// - Parameters:
  ///   - marker: Emoji marker (e.g. `"1️⃣"`). Defaults to `"1️⃣"`.
  ///   - message: Expected message text. Pass `""` to skip message validation.
  init(_ marker: String = "1️⃣", message: String = "") {
    self.marker = marker
    self.message = message
  }
}
