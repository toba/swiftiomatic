import Testing

@testable import Swiftiomatic

@Suite struct AnyObjectProtocolTests {
  @Test func classReplacedByAnyObject() {
    let input = """
      protocol Foo: class {}
      """
    let output = """
      protocol Foo: AnyObject {}
      """
    let options = FormatOptions(swiftVersion: "4.1")
    testFormatting(for: input, output, rule: .anyObjectProtocol, options: options)
  }

  @Test func classReplacedByAnyObjectWithOtherProtocols() {
    let input = """
      protocol Foo: class, Codable {}
      """
    let output = """
      protocol Foo: AnyObject, Codable {}
      """
    let options = FormatOptions(swiftVersion: "4.1")
    testFormatting(for: input, output, rule: .anyObjectProtocol, options: options)
  }

  @Test func classReplacedByAnyObjectImmediatelyAfterImport() {
    let input = """
      import Foundation
      protocol Foo: class {}
      """
    let output = """
      import Foundation
      protocol Foo: AnyObject {}
      """
    let options = FormatOptions(swiftVersion: "4.1")
    testFormatting(
      for: input, output, rule: .anyObjectProtocol, options: options,
      exclude: [.blankLineAfterImports])
  }

  @Test func classDeclarationNotReplacedByAnyObject() {
    let input = """
      class Foo: Codable {}
      """
    let options = FormatOptions(swiftVersion: "4.1")
    testFormatting(for: input, rule: .anyObjectProtocol, options: options)
  }

  @Test func classImportNotReplacedByAnyObject() {
    let input = """
      import class Foo.Bar
      """
    let options = FormatOptions(swiftVersion: "4.1")
    testFormatting(for: input, rule: .anyObjectProtocol, options: options)
  }

  @Test func classNotReplacedByAnyObjectIfSwiftVersionLessThan4_1() {
    let input = """
      protocol Foo: class {}
      """
    let options = FormatOptions(swiftVersion: "4.0")
    testFormatting(for: input, rule: .anyObjectProtocol, options: options)
  }
}
