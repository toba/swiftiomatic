import Foundation
import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct SwiftSourceTests {
  private let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(
    UUID().uuidString,
  )

  init() throws {
    try Data("let i = 2".utf8).write(to: tempFile)
  }

  @Test func fileFromStringUpdate() {
    let file = SwiftSource(contents: "let i = 1")

    #expect(file.isVirtual)
    #expect(file.path == nil)
    #expect(file.contents == "let i = 1")

    file.write("let j = 2")

    #expect(file.contents == "let j = 2")

    file.append("2")

    #expect(file.contents == "let j = 22")
  }

  @Test func fileUpdate() throws {
    let file = try #require(SwiftSource(path: tempFile.path))

    #expect(!(file.isVirtual))
    #expect(file.path != nil)
    #expect(file.contents == "let i = 2")

    file.write("let j = 2")

    #expect(file.contents == "let j = 2")
    #expect(FileManager.default.contents(atPath: tempFile.path) == Data("let j = 2".utf8))

    file.append("2")

    #expect(file.contents == "let j = 22")
    #expect(FileManager.default.contents(atPath: tempFile.path) == Data("let j = 22".utf8))
  }

  @Test func fileNotTouchedIfNothingAppended() throws {
    let file = try #require(SwiftSource(path: tempFile.path))
    let initialModificationData = FileManager.default
      .modificationDate(forFileAtPath: tempFile.path)

    file.append("")

    #expect(
      initialModificationData
        == FileManager.default
        .modificationDate(forFileAtPath: tempFile.path),
    )
  }

  @Test func fileNotTouchedIfNothingNewWritten() throws {
    let file = try #require(SwiftSource(path: tempFile.path))
    let initialModificationData = FileManager.default
      .modificationDate(forFileAtPath: tempFile.path)

    file.write("let i = 2")

    #expect(
      initialModificationData
        == FileManager.default
        .modificationDate(forFileAtPath: tempFile.path),
    )
  }
}
