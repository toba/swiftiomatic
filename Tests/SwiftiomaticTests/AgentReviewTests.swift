import Foundation
import SwiftParser
import SwiftSyntax
import Testing

@testable import Swiftiomatic

@Suite("AgentReviewCheck")
struct AgentReviewTests {
  let fixturePath: String = {
    let thisFile = #filePath
    let dir = (thisFile as NSString).deletingLastPathComponent
    return (dir as NSString).appendingPathComponent("Fixtures/AgentReview.swift")
  }()

  @Test func detectsFireAndForgetTask() throws {
    let source = try String(contentsOfFile: fixturePath, encoding: .utf8)
    let tree = Parser.parse(source: source)
    let check = AgentReviewCheck(filePath: fixturePath)
    check.walk(tree)

    let fireAndForget = check.findings.filter { $0.message.contains("Fire-and-forget") }
    #expect(fireAndForget.count >= 1, "Should detect unassigned Task {}")
  }

  @Test func detectsErrorEnumWithoutLocalizedError() throws {
    let source = try String(contentsOfFile: fixturePath, encoding: .utf8)
    let tree = Parser.parse(source: source)
    let check = AgentReviewCheck(filePath: fixturePath)
    check.walk(tree)

    let errorFindings = check.findings.filter { $0.message.contains("LocalizedError") }
    #expect(errorFindings.count == 1, "Should flag AppError but not GoodError")
    #expect(errorFindings.first?.message.contains("AppError") == true)
  }

  @Test func detectsNonisolatedUnsafe() throws {
    let source = try String(contentsOfFile: fixturePath, encoding: .utf8)
    let tree = Parser.parse(source: source)
    let check = AgentReviewCheck(filePath: fixturePath)
    check.walk(tree)

    let nonisolated = check.findings.filter { $0.message.contains("nonisolated(unsafe)") }
    #expect(nonisolated.count >= 1)
  }
}
