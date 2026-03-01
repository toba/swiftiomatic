import Testing

@testable import Swiftiomatic

@Suite struct NumberFormattingTests {
  // hex case

  @Test func lowercaseLiteralConvertedToUpper() {
    let input = """
      let foo = 0xabcd
      """
    let output = """
      let foo = 0xABCD
      """
    testFormatting(for: input, output, rule: .numberFormatting)
  }

  @Test func mixedCaseLiteralConvertedToUpper() {
    let input = """
      let foo = 0xaBcD
      """
    let output = """
      let foo = 0xABCD
      """
    testFormatting(for: input, output, rule: .numberFormatting)
  }

  @Test func uppercaseLiteralConvertedToLower() {
    let input = """
      let foo = 0xABCD
      """
    let output = """
      let foo = 0xabcd
      """
    let options = FormatOptions(uppercaseHex: false)
    testFormatting(for: input, output, rule: .numberFormatting, options: options)
  }

  @Test func pInExponentialNotConvertedToUpper() {
    let input = """
      let foo = 0xaBcDp5
      """
    let output = """
      let foo = 0xABCDp5
      """
    testFormatting(for: input, output, rule: .numberFormatting)
  }

  @Test func pInExponentialNotConvertedToLower() {
    let input = """
      let foo = 0xaBcDP5
      """
    let output = """
      let foo = 0xabcdP5
      """
    let options = FormatOptions(uppercaseHex: false, uppercaseExponent: true)
    testFormatting(for: input, output, rule: .numberFormatting, options: options)
  }

  // exponent case

  @Test func lowercaseExponent() {
    let input = """
      let foo = 0.456E-5
      """
    let output = """
      let foo = 0.456e-5
      """
    testFormatting(for: input, output, rule: .numberFormatting)
  }

  @Test func uppercaseExponent() {
    let input = """
      let foo = 0.456e-5
      """
    let output = """
      let foo = 0.456E-5
      """
    let options = FormatOptions(uppercaseExponent: true)
    testFormatting(for: input, output, rule: .numberFormatting, options: options)
  }

  @Test func uppercaseHexExponent() {
    let input = """
      let foo = 0xFF00p54
      """
    let output = """
      let foo = 0xFF00P54
      """
    let options = FormatOptions(uppercaseExponent: true)
    testFormatting(for: input, output, rule: .numberFormatting, options: options)
  }

  @Test func uppercaseGroupedHexExponent() {
    let input = """
      let foo = 0xFF00_AABB_CCDDp54
      """
    let output = """
      let foo = 0xFF00_AABB_CCDDP54
      """
    let options = FormatOptions(uppercaseExponent: true)
    testFormatting(for: input, output, rule: .numberFormatting, options: options)
  }

  // decimal grouping

  @Test func defaultDecimalGrouping() {
    let input = """
      let foo = 1234_56_78
      """
    let output = """
      let foo = 12_345_678
      """
    testFormatting(for: input, output, rule: .numberFormatting)
  }

  @Test func ignoreDecimalGrouping() {
    let input = """
      let foo = 1234_5_678
      """
    let options = FormatOptions(decimalGrouping: .ignore)
    testFormatting(for: input, rule: .numberFormatting, options: options)
  }

  @Test func noDecimalGrouping() {
    let input = """
      let foo = 1234_5_678
      """
    let output = """
      let foo = 12345678
      """
    let options = FormatOptions(decimalGrouping: .none)
    testFormatting(for: input, output, rule: .numberFormatting, options: options)
  }

  @Test func decimalGroupingThousands() {
    let input = """
      let foo = 1234
      """
    let output = """
      let foo = 1_234
      """
    let options = FormatOptions(decimalGrouping: .group(3, 3))
    testFormatting(for: input, output, rule: .numberFormatting, options: options)
  }

  @Test func exponentialGrouping() {
    let input = """
      let foo = 1234e5678
      """
    let output = """
      let foo = 1_234e5678
      """
    let options = FormatOptions(decimalGrouping: .group(3, 3))
    testFormatting(for: input, output, rule: .numberFormatting, options: options)
  }

  @Test func zeroGrouping() {
    let input = """
      let foo = 1234
      """
    let options = FormatOptions(decimalGrouping: .group(0, 0))
    testFormatting(for: input, rule: .numberFormatting, options: options)
  }

  // binary grouping

  @Test func defaultBinaryGrouping() {
    let input = """
      let foo = 0b11101000_00111111
      """
    let output = """
      let foo = 0b1110_1000_0011_1111
      """
    testFormatting(for: input, output, rule: .numberFormatting)
  }

  @Test func ignoreBinaryGrouping() {
    let input = """
      let foo = 0b1110_10_00
      """
    let options = FormatOptions(binaryGrouping: .ignore)
    testFormatting(for: input, rule: .numberFormatting, options: options)
  }

  @Test func noBinaryGrouping() {
    let input = """
      let foo = 0b1110_10_00
      """
    let output = """
      let foo = 0b11101000
      """
    let options = FormatOptions(binaryGrouping: .none)
    testFormatting(for: input, output, rule: .numberFormatting, options: options)
  }

  @Test func binaryGroupingCustom() {
    let input = """
      let foo = 0b110011
      """
    let output = """
      let foo = 0b11_00_11
      """
    let options = FormatOptions(binaryGrouping: .group(2, 2))
    testFormatting(for: input, output, rule: .numberFormatting, options: options)
  }

  // hex grouping

  @Test func defaultHexGrouping() {
    let input = """
      let foo = 0xFF01FF01AE45
      """
    let output = """
      let foo = 0xFF01_FF01_AE45
      """
    testFormatting(for: input, output, rule: .numberFormatting)
  }

  @Test func customHexGrouping() {
    let input = """
      let foo = 0xFF00p54
      """
    let output = """
      let foo = 0xFF_00p54
      """
    let options = FormatOptions(hexGrouping: .group(2, 2))
    testFormatting(for: input, output, rule: .numberFormatting, options: options)
  }

  // octal grouping

  @Test func defaultOctalGrouping() {
    let input = """
      let foo = 0o123456701234
      """
    let output = """
      let foo = 0o1234_5670_1234
      """
    testFormatting(for: input, output, rule: .numberFormatting)
  }

  @Test func customOctalGrouping() {
    let input = """
      let foo = 0o12345670
      """
    let output = """
      let foo = 0o12_34_56_70
      """
    let options = FormatOptions(octalGrouping: .group(2, 2))
    testFormatting(for: input, output, rule: .numberFormatting, options: options)
  }

  // fraction grouping

  @Test func ignoreFractionGrouping() {
    let input = """
      let foo = 1.234_5_678
      """
    let options = FormatOptions(decimalGrouping: .ignore, fractionGrouping: true)
    testFormatting(for: input, rule: .numberFormatting, options: options)
  }

  @Test func noFractionGrouping() {
    let input = """
      let foo = 1.234_5_678
      """
    let output = """
      let foo = 1.2345678
      """
    let options = FormatOptions(decimalGrouping: .none, fractionGrouping: true)
    testFormatting(for: input, output, rule: .numberFormatting, options: options)
  }

  @Test func fractionGroupingThousands() {
    let input = """
      let foo = 12.34_56_78
      """
    let output = """
      let foo = 12.345_678
      """
    let options = FormatOptions(decimalGrouping: .group(3, 3), fractionGrouping: true)
    testFormatting(for: input, output, rule: .numberFormatting, options: options)
  }

  @Test func hexFractionGrouping() {
    let input = """
      let foo = 0x12.34_56_78p56
      """
    let output = """
      let foo = 0x12.34_5678p56
      """
    let options = FormatOptions(hexGrouping: .group(4, 4), fractionGrouping: true)
    testFormatting(for: input, output, rule: .numberFormatting, options: options)
  }
}
