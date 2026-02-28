// Adapted from SwiftLint 0.63.2 CoreTests (MIT license)

import Foundation
import Testing
@testable import Swiftiomatic

@Suite struct SwiftLintFileTests {
    private let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

    init() throws {
        RuleRegistry.registerAllRulesOnce()
        try Data("let i = 2".utf8).write(to: tempFile)
    }

    @Test func fileFromStringUpdate() {
        let file = SwiftLintFile(contents: "let i = 1")

        #expect(file.isVirtual)
        #expect(file.path == nil)
        #expect(file.contents == "let i = 1")

        file.write("let j = 2")

        #expect(file.contents == "let j = 2")

        file.append("2")

        #expect(file.contents == "let j = 22")
    }

    @Test func fileUpdate() {
        let file = SwiftLintFile(path: tempFile.path)!

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

    @Test func fileNotTouchedIfNothingAppended() {
        let file = SwiftLintFile(path: tempFile.path)!
        let initialModificationData = FileManager.default.modificationDate(forFileAtPath: tempFile.path)

        file.append("")

        #expect(initialModificationData == FileManager.default.modificationDate(forFileAtPath: tempFile.path))
    }

    @Test func fileNotTouchedIfNothingNewWritten() {
        let file = SwiftLintFile(path: tempFile.path)!
        let initialModificationData = FileManager.default.modificationDate(forFileAtPath: tempFile.path)

        file.write("let i = 2")

        #expect(initialModificationData == FileManager.default.modificationDate(forFileAtPath: tempFile.path))
    }
}
