import Testing

@testable import Swiftiomatic

extension TokenizerTests {
  // MARK: Numbers

  @Test func zero() {
    let input = "0"
    let output: [Token] = [.number("0", .integer)]
    #expect(tokenize(input) == output)
  }

  @Test func smallInteger() {
    let input = "5"
    let output: [Token] = [.number("5", .integer)]
    #expect(tokenize(input) == output)
  }

  @Test func largeInteger() {
    let input = "12345678901234567890"
    let output: [Token] = [.number("12345678901234567890", .integer)]
    #expect(tokenize(input) == output)
  }

  @Test func negativeInteger() {
    let input = "-7"
    let output: [Token] = [
      .operator("-", .prefix),
      .number("7", .integer),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func invalidInteger() {
    let input = "123abc"
    let output: [Token] = [
      .number("123", .integer),
      .error("abc"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func smallFloat() {
    let input = "0.2"
    let output: [Token] = [.number("0.2", .decimal)]
    #expect(tokenize(input) == output)
  }

  @Test func largeFloat() {
    let input = "1234.567890"
    let output: [Token] = [.number("1234.567890", .decimal)]
    #expect(tokenize(input) == output)
  }

  @Test func negativeFloat() {
    let input = "-0.34"
    let output: [Token] = [
      .operator("-", .prefix),
      .number("0.34", .decimal),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func exponential() {
    let input = "1234e5"
    let output: [Token] = [.number("1234e5", .decimal)]
    #expect(tokenize(input) == output)
  }

  @Test func positiveExponential() {
    let input = "0.123e+4"
    let output: [Token] = [.number("0.123e+4", .decimal)]
    #expect(tokenize(input) == output)
  }

  @Test func negativeExponential() {
    let input = "0.123e-4"
    let output: [Token] = [.number("0.123e-4", .decimal)]
    #expect(tokenize(input) == output)
  }

  @Test func capitalExponential() {
    let input = "0.123E-4"
    let output: [Token] = [.number("0.123E-4", .decimal)]
    #expect(tokenize(input) == output)
  }

  @Test func invalidExponential() {
    let input = "123.e5"
    let output: [Token] = [
      .number("123", .integer),
      .operator(".", .infix),
      .identifier("e5"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func leadingZeros() {
    let input = "0005"
    let output: [Token] = [.number("0005", .integer)]
    #expect(tokenize(input) == output)
  }

  @Test func binary() {
    let input = "0b101010"
    let output: [Token] = [.number("0b101010", .binary)]
    #expect(tokenize(input) == output)
  }

  @Test func octal() {
    let input = "0o52"
    let output: [Token] = [.number("0o52", .octal)]
    #expect(tokenize(input) == output)
  }

  @Test func hex() {
    let input = "0x2A"
    let output: [Token] = [.number("0x2A", .hex)]
    #expect(tokenize(input) == output)
  }

  @Test func hexadecimalPower() {
    let input = "0xC3p0"
    let output: [Token] = [.number("0xC3p0", .hex)]
    #expect(tokenize(input) == output)
  }

  @Test func capitalHexadecimalPower() {
    let input = "0xC3P0"
    let output: [Token] = [.number("0xC3P0", .hex)]
    #expect(tokenize(input) == output)
  }

  @Test func negativeHexadecimalPower() {
    let input = "0xC3p-5"
    let output: [Token] = [.number("0xC3p-5", .hex)]
    #expect(tokenize(input) == output)
  }

  @Test func floatHexadecimalPower() {
    let input = "0xC.3p0"
    let output: [Token] = [.number("0xC.3p0", .hex)]
    #expect(tokenize(input) == output)
  }

  @Test func floatNegativeHexadecimalPower() {
    let input = "0xC.3p-5"
    let output: [Token] = [.number("0xC.3p-5", .hex)]
    #expect(tokenize(input) == output)
  }

  @Test func underscoresInInteger() {
    let input = "1_23_4_"
    let output: [Token] = [.number("1_23_4_", .integer)]
    #expect(tokenize(input) == output)
  }

  @Test func underscoresInFloat() {
    let input = "0_.1_2_"
    let output: [Token] = [.number("0_.1_2_", .decimal)]
    #expect(tokenize(input) == output)
  }

  @Test func underscoresInExponential() {
    let input = "0.1_2_e-3"
    let output: [Token] = [.number("0.1_2_e-3", .decimal)]
    #expect(tokenize(input) == output)
  }

  @Test func underscoresInBinary() {
    let input = "0b0000_0000_0001"
    let output: [Token] = [.number("0b0000_0000_0001", .binary)]
    #expect(tokenize(input) == output)
  }

  @Test func underscoresInOctal() {
    let input = "0o123_456"
    let output: [Token] = [.number("0o123_456", .octal)]
    #expect(tokenize(input) == output)
  }

  @Test func underscoresInHex() {
    let input = "0xabc_def"
    let output: [Token] = [.number("0xabc_def", .hex)]
    #expect(tokenize(input) == output)
  }

  @Test func underscoresInHexadecimalPower() {
    let input = "0xabc_p5"
    let output: [Token] = [.number("0xabc_p5", .hex)]
    #expect(tokenize(input) == output)
  }

  @Test func underscoresInFloatHexadecimalPower() {
    let input = "0xa.bc_p5"
    let output: [Token] = [.number("0xa.bc_p5", .hex)]
    #expect(tokenize(input) == output)
  }

  @Test func noLeadingUnderscoreInInteger() {
    let input = "_12345"
    let output: [Token] = [.identifier("_12345")]
    #expect(tokenize(input) == output)
  }

  @Test func noLeadingUnderscoreInHex() {
    let input = "0x_12345"
    let output: [Token] = [.error("0x_12345")]
    #expect(tokenize(input) == output)
  }

  @Test func hexPropertyAccess() {
    let input = "0x123.ee"
    let output: [Token] = [
      .number("0x123", .hex),
      .operator(".", .infix),
      .identifier("ee"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func invalidHexadecimal() {
    let input = "0x123.0"
    let output: [Token] = [
      .error("0x123.0")
    ]
    #expect(tokenize(input) == output)
  }

  @Test func anotherInvalidHexadecimal() {
    let input = "0x123.0p"
    let output: [Token] = [
      .error("0x123.0p")
    ]
    #expect(tokenize(input) == output)
  }

  @Test func invalidOctal() {
    let input = "0o1235678"
    let output: [Token] = [
      .number("0o123567", .octal),
      .error("8"),
    ]
    #expect(tokenize(input) == output)
  }

}
