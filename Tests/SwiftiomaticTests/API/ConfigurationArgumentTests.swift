import Testing
import Foundation
@testable import SwiftiomaticKit

@Suite
struct ConfigurationArgumentTests {
    /// The same bytes the tests pass as a file and as an inline string.
    private static let json = """
        {"redundancies":{"dropRedundantThrows":{"rewrite":true,"lint":"warn"}}}
        """

    private func withConfigurationFile<T>(
        _ body: (URL) throws -> T
    ) throws -> T {
        let directory = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: FileManager.default.temporaryDirectory,
            create: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = directory.appendingPathComponent("swiftiomatic.json")
        try Self.json.write(to: url, atomically: true, encoding: .utf8)
        return try body(url)
    }

    @Test func readablePathClassifiesAsFile() throws {
        try withConfigurationFile { url in
            guard case let .file(classified) = ConfigurationArgument(url.path) else {
                Issue.record("expected a file, got \(ConfigurationArgument(url.path))")
                return
            }
            #expect(classified.path == url.path)
        }
    }

    /// Jig issue `59b5ff0b`: the inline form was indistinguishable from a typo, so a bad value ran
    /// to a zero exit.
    @Test func inlineJSONClassifiesAsInlineJSON() throws {
        guard case let .inlineJSON(inline) = ConfigurationArgument(Self.json) else {
            Issue.record("expected inline JSON")
            return
        }

        let fromFile = try withConfigurationFile { try Configuration(contentsOf: $0) }
        #expect(inline == fromFile)
    }

    @Test func malformedJSONClassifiesAsMalformed() {
        guard case .malformed = ConfigurationArgument("{not json") else {
            Issue.record("expected malformed")
            return
        }
    }

    /// Jig issue `5657e482`: a mistyped path reached the JSON decoder, so the run reported a syntax
    /// error in a file it never opened.
    @Test func missingPathClassifiesAsUnreadableFile() {
        let path = "/tmp/no-such-swiftiomatic-config.json"

        guard case let .unreadableFile(reported) = ConfigurationArgument(path) else {
            Issue.record("expected an unreadable file")
            return
        }
        #expect(reported == path)
    }
}
