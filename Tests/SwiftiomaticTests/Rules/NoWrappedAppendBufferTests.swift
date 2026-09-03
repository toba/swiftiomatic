@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoWrappedAppendBufferTests: RuleTesting {
  private static let dataMessage =
    "'data' is filled by 'append' in a loop and then copied into a second buffer — write the bytes into the final buffer once"
  private static let bytesMessage =
    "'bytes' is filled by 'append' in a loop and then copied into a second buffer — write the bytes into the final buffer once"

  /// The shape `Data.init?(hexString:)` carried in Toba Core before issue 2680d6a4 rewrote it.
  @Test func arrayWrappedInData() {
    assertLint(
      NoWrappedAppendBuffer.self,
      """
      init?(hexString: String) {
        1️⃣var data = Bytes()
        data.reserveCapacity(length / 2)
        while index != hexString.endIndex {
          data.append(byte)
        }
        self = Data(data)
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.dataMessage)]
    )
  }

  /// The shape `UUID.init?(hexString:)` carried in Toba Core before issue 79d2f04d rewrote it. The
  /// array is read element by element into a fixed-size tuple.
  @Test func arrayReadIntoTuple() {
    assertLint(
      NoWrappedAppendBuffer.self,
      """
      init?(hexString hex: String) {
        1️⃣var bytes = [UInt8]()
        bytes.reserveCapacity(16)
        for position in 0..<16 {
          guard let byte = parse(position) else { return nil }
          bytes.append(byte)
        }
        self.init(uuid: (bytes[0], bytes[1], bytes[2], bytes[3]))
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.bytesMessage)]
    )
  }

  /// An inner declaration shadows the outer one of the same name, so each is judged on the
  /// references its own scope holds.
  @Test func innerDeclarationShadowsOuter() {
    assertLint(
      NoWrappedAppendBuffer.self,
      """
      func decode() {
        var bytes = [UInt8]()
        bytes.append(0)
        store = bytes
        if flag {
          1️⃣var bytes = [UInt8]()
          for byte in source { bytes.append(byte) }
          self = Data(bytes)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.bytesMessage)]
    )
  }

  /// The rewrite fills the final buffer directly, so nothing is reported.
  @Test func directBufferFillNotFlagged() {
    assertLint(
      NoWrappedAppendBuffer.self,
      """
      init?(hexString: String) {
        var bytes = Data(count: digitCount / 2)
        bytes.withUnsafeMutableBytes { raw in
          for index in 0..<raw.count { raw[index] = digits.hexByte(at: index * 2) }
        }
        self = bytes
      }
      """,
      findings: []
    )
  }

  /// The array is the result of the function, so the second buffer is the caller's business.
  @Test func returnedArrayNotFlagged() {
    assertLint(
      NoWrappedAppendBuffer.self,
      """
      func decode() -> [UInt8] {
        var bytes = [UInt8]()
        for byte in source { bytes.append(byte) }
        return bytes
      }
      """,
      findings: []
    )
  }

  /// The array is handed to another caller, so it is doing its job.
  @Test func passedArrayNotFlagged() {
    assertLint(
      NoWrappedAppendBuffer.self,
      """
      func decode() {
        var bytes = [UInt8]()
        for byte in source { bytes.append(byte) }
        write(bytes)
        self = Data(bytes)
      }
      """,
      findings: []
    )
  }

  /// Without a loop the array is filled once, so the wrap costs one copy rather than a copy per
  /// step.
  @Test func appendOutsideLoopNotFlagged() {
    assertLint(
      NoWrappedAppendBuffer.self,
      """
      func decode() {
        var bytes = [UInt8]()
        bytes.append(0)
        self = Data(bytes)
      }
      """,
      findings: []
    )
  }

  /// Nothing wraps the array, so the rule reports nothing.
  @Test func unwrappedArrayNotFlagged() {
    assertLint(
      NoWrappedAppendBuffer.self,
      """
      func decode() {
        var bytes = [UInt8]()
        for byte in source { bytes.append(byte) }
        store = bytes
      }
      """,
      findings: []
    )
  }
}
