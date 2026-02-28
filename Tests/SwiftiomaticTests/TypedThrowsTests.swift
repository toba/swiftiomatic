import Foundation
import SwiftParser
import SwiftSyntax
import Testing

@testable import Swiftiomatic

@Suite("TypedThrowsCheck")
struct TypedThrowsTests {
  let fixturePath: String = {
    let thisFile = #filePath
    let dir = (thisFile as NSString).deletingLastPathComponent
    return (dir as NSString).appendingPathComponent("Fixtures/TypedThrows.swift")
  }()

  @Test func detectsUntypedThrowsWithSingleErrorType() throws {
    let source = try String(contentsOfFile: fixturePath, encoding: .utf8)
    let tree = Parser.parse(source: source)
    let check = TypedThrowsCheck(filePath: fixturePath)
    check.walk(tree)

    // Should find parse() and validate() — both throw only ParseError
    let messages = check.findings.map(\.message)
    #expect(messages.contains { $0.contains("parse") && $0.contains("ParseError") })
    #expect(messages.contains { $0.contains("validate") && $0.contains("ParseError") })
  }

  @Test func ignoresAlreadyTypedThrows() throws {
    let source = try String(contentsOfFile: fixturePath, encoding: .utf8)
    let tree = Parser.parse(source: source)
    let check = TypedThrowsCheck(filePath: fixturePath)
    check.walk(tree)

    let messages = check.findings.map(\.message)
    #expect(!messages.contains { $0.contains("strictParse") })
  }

  @Test func ignoresMultipleErrorTypes() throws {
    let source = try String(contentsOfFile: fixturePath, encoding: .utf8)
    let tree = Parser.parse(source: source)
    let check = TypedThrowsCheck(filePath: fixturePath)
    check.walk(tree)

    let messages = check.findings.map(\.message)
    #expect(!messages.contains { $0.contains("fetchAndParse") })
  }
}
