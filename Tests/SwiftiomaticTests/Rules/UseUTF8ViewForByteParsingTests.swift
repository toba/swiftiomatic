@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseUTF8ViewForByteParsingTests: RuleTesting {
  private static let hexMessage =
    "'hex' is walked by 'index(_:offsetBy:)' and its slices feed a byte parse — read it once through 'withUTF8' and index the UTF-8 span"
  private static let hexStringMessage =
    "'hexString' is walked by 'index(_:offsetBy:)' and its slices feed a byte parse — read it once through 'withUTF8' and index the UTF-8 span"

  /// The shape `Data.init?(hexString:)` carried in Toba Core before issue 2680d6a4 rewrote it.
  @Test func indexWalkInWhileBody() {
    assertLint(
      UseUTF8ViewForByteParsing.self,
      """
      init?(hexString: String) {
        var index = hexString.startIndex
        while index != hexString.endIndex {
          let offset = 1️⃣hexString.index(index, offsetBy: 2)
          let byteString = hexString[index..<offset]
          guard let byte = UInt8(byteString, radix: 16) else { return nil }
          data.append(byte)
          index = offset
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.hexStringMessage)]
    )
  }

  /// The shape `UUID.init?(hexString:)` carried in Toba Core before issue 79d2f04d rewrote it. The
  /// walk and the parse both sit in nested functions the loop calls.
  @Test func indexWalkInNestedFunctionCalledFromLoop() {
    assertLint(
      UseUTF8ViewForByteParsing.self,
      """
      init?(hexString hex: String) {
        func range(for pos: Int) -> Range<String.Index> {
          1️⃣hex.index(hex.startIndex, offsetBy: pos * 2)..<hex.index(hex.startIndex, offsetBy: pos * 2 + 2)
        }
        func parse(_ pos: Int) -> UInt8? { UInt8(hex[range(for: pos)], radix: 16) }
        for position in 0..<16 {
          guard let byte = parse(position) else { return nil }
          bytes.append(byte)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.hexMessage)]
    )
  }

  /// The rewrite reads the digits through a span, so nothing is reported.
  @Test func spanReadNotFlagged() {
    assertLint(
      UseUTF8ViewForByteParsing.self,
      """
      init?(hexString hex: String) {
        var hex = hex
        guard let raw = hex.withUTF8({ UUID.rawBytes(parsingHex: $0.span) }) else { return nil }
        self.init(uuid: raw)
      }
      """,
      findings: []
    )
  }

  @Test func singleSliceOutsideLoopNotFlagged() {
    assertLint(
      UseUTF8ViewForByteParsing.self,
      """
      let next = hex.index(hex.startIndex, offsetBy: 2)
      let byte = UInt8(hex[hex.startIndex..<next], radix: 16)
      """,
      findings: []
    )
  }

  /// A grapheme walk is the right tool for prose, so a walk whose slices never reach a byte parse
  /// stays silent.
  @Test func proseWalkNotFlagged() {
    assertLint(
      UseUTF8ViewForByteParsing.self,
      """
      while cursor != text.endIndex {
        let stop = text.index(cursor, offsetBy: 1)
        words.append(String(text[cursor..<stop]))
        cursor = stop
      }
      """,
      findings: []
    )
  }

  /// The walked string and the parsed string differ, so the two shapes are unrelated.
  @Test func walkOnDifferentStringNotFlagged() {
    assertLint(
      UseUTF8ViewForByteParsing.self,
      """
      while more {
        let stop = label.index(cursor, offsetBy: 1)
        let byte = UInt8(digits[lower..<upper], radix: 16)
        emit(stop, byte)
      }
      """,
      findings: []
    )
  }
}
