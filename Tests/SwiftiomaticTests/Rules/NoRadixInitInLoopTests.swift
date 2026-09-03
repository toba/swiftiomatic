@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoRadixInitInLoopTests: RuleTesting {
  private static let uint8Message =
    "'UInt8(_:radix:)' on a slice inside a loop parses a sign and validates every digit on each call, and it accepts a leading '+' or '-' — read the digit through a 256-entry lookup table"
  private static let uint16Message =
    "'UInt16(_:radix:)' on a slice inside a loop parses a sign and validates every digit on each call, and it accepts a leading '+' or '-' — read the digit through a 256-entry lookup table"

  /// The shape `Data.init?(hexString:)` carried in Toba Core before issue 2680d6a4 rewrote it.
  @Test func radixInitOnBoundSliceInWhileBody() {
    assertLint(
      NoRadixInitInLoop.self,
      """
      while index != hexString.endIndex {
        let offset = hexString.index(index, offsetBy: 2)
        let byteString = hexString[index..<offset]
        guard let byte = 1️⃣UInt8(byteString, radix: 16) else { return nil }
        data.append(byte)
        index = offset
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.uint8Message)]
    )
  }

  /// The shape `UUID.init?(hexString:)` carried in Toba Core before issue 79d2f04d rewrote it. The
  /// parse sits in a nested function the loop calls.
  @Test func radixInitInNestedFunctionCalledFromLoop() {
    assertLint(
      NoRadixInitInLoop.self,
      """
      init?(hexString hex: String) {
        func range(for pos: Int) -> Range<String.Index> {
          hex.index(hex.startIndex, offsetBy: pos * 2)..<hex.index(hex.startIndex, offsetBy: pos * 2 + 2)
        }
        func parse(_ pos: Int) -> UInt8? { 1️⃣UInt8(hex[range(for: pos)], radix: 16) }
        for position in 0..<16 {
          guard let byte = parse(position) else { return nil }
          bytes.append(byte)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.uint8Message)]
    )
  }

  /// Two nested functions share the name `parse`. A flat name-to-declaration map lets one
  /// overwrite the other, so the loop in `decodeHex` would resolve to a body it never calls.
  @Test func sameNameResolvesToTheCallersOwnHelper() {
    assertLint(
      NoRadixInitInLoop.self,
      """
      func decodeHex(_ hex: String) {
        func parse(_ i: Int) -> UInt8? { 1️⃣UInt8(hex[lower(i)..<upper(i)], radix: 16) }
        for i in 0..<16 { _ = parse(i) }
      }

      func countUp(_ text: String) {
        func parse(_ i: Int) -> UInt8? { UInt8(text, radix: 10) }
        for i in 0..<16 { _ = parse(i) }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.uint8Message)]
    )
  }

  /// The loop's own helper is harmless, and the parsing helper of the same name sits in a scope
  /// this loop cannot reach. Reporting here would name a parse the loop never runs.
  @Test func sameNameDoesNotReachAnotherScopesHelper() {
    assertLint(
      NoRadixInitInLoop.self,
      """
      func countUp(_ text: String) {
        func parse(_ i: Int) -> UInt8? { UInt8(text, radix: 10) }
        for i in 0..<16 { _ = parse(i) }
      }

      func makeReader(_ hex: String) -> (Int) -> UInt8? {
        func parse(_ i: Int) -> UInt8? { UInt8(hex[lower(i)..<upper(i)], radix: 16) }
        return parse
      }
      """,
      findings: []
    )
  }

  @Test func radixInitOnSliceMethodResult() {
    assertLint(
      NoRadixInitInLoop.self,
      """
      for field in fields {
        let value = 1️⃣UInt16(field.prefix(4), radix: 16)
        emit(value)
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.uint16Message)]
    )
  }

  /// The rewrite reads the digits through a span, so nothing is reported.
  @Test func spanReadNotFlagged() {
    assertLint(
      NoRadixInitInLoop.self,
      """
      for index in 0..<raw.count {
        raw[index] = digits.hexByte(at: index * 2, nibbles: &nibbles)
      }
      """,
      findings: []
    )
  }

  @Test func singleRadixParseOutsideLoopNotFlagged() {
    assertLint(
      NoRadixInitInLoop.self,
      """
      let byte = UInt8(hex[lower..<upper], radix: 16)
      """,
      findings: []
    )
  }

  /// A whole string is not a slice, so parsing one per iteration reports nothing.
  @Test func radixInitOnWholeStringNotFlagged() {
    assertLint(
      NoRadixInitInLoop.self,
      """
      for token in tokens {
        let value = Int(token, radix: 16)
        emit(value)
      }
      """,
      findings: []
    )
  }

  /// Without a radix the initializer is a plain decimal read, which the rule does not cover.
  @Test func plainIntegerInitNotFlagged() {
    assertLint(
      NoRadixInitInLoop.self,
      """
      for row in rows {
        let value = Int(row[0..<2])
        emit(value)
      }
      """,
      findings: []
    )
  }
}
