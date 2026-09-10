import Testing
import Foundation
@testable import SwiftiomaticKit

/// A throwaway directory holding a `Package.swift`, removed when the test releases it.
private final class TemporaryPackage {
    let root: URL

    init() throws {
        root = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: FileManager.default.temporaryDirectory,
            create: true
        )
        try Data("// swift-tools-version: 6.4\n".utf8)
            .write(to: root.appendingPathComponent("Package.swift", isDirectory: false))
    }

    deinit { try? FileManager.default.removeItem(at: root) }
}

@Suite struct LintCacheTests {
    @Test func hexEncodeMatchesStringFormat() {
        let bytes: [UInt8] = [0x00, 0x0f, 0x10, 0xab, 0xff]
        let expected = bytes.map { String(format: "%02x", $0) }.joined()
        #expect(LintCache.hexEncode(bytes) == expected)
    }

    @Test func hexEncodeEmpty() { #expect(LintCache.hexEncode([UInt8]()) == "") }

    @Test func contentHashIsLowercaseHex() {
        let hash = LintCache.contentHash(of: "let x = 1\n")
        #expect(hash.count == 64)
        #expect(hash.allSatisfy { "0123456789abcdef".contains($0) })
    }

    @Test func cacheEligibleRejectsNonFileURL() {
        let url = URL(string: "https://example.com/foo.swift")!
        #expect(
            !LintCache.isCacheEligible(
                url: url, lines: [], offsets: [], ignoreUnparsableFiles: false
            )
        )
    }

    @Test func cacheEligibleRejectsLines() {
        let url = URL(fileURLWithPath: "/tmp/x.swift")
        #expect(
            !LintCache.isCacheEligible(
                url: url, lines: [1...3], offsets: [], ignoreUnparsableFiles: false
            )
        )
    }

    @Test func cacheEligibleRejectsIgnoreUnparsable() {
        let url = URL(fileURLWithPath: "/tmp/x.swift")
        #expect(
            !LintCache.isCacheEligible(
                url: url, lines: [], offsets: [], ignoreUnparsableFiles: true
            )
        )
    }

    @Test func cacheEligibleAcceptsRegularFile() {
        let url = URL(fileURLWithPath: "/tmp/x.swift")
        #expect(LintCache.isCacheEligible(
            url: url, lines: [], offsets: [], ignoreUnparsableFiles: false
        ))
    }

    /// `LintCache.Entry.severity` is now `Lint` directly (M2). The on-disk JSON shape must still
    /// match the v1 schema's string raw values (`"error"`, `"warn"`, `"no"`) so existing cache
    /// subtrees keep decoding.
    @Test func entrySeveritySerializesAsRawString() throws {
        let entry = LintCache.Entry(
            category: "Foo",
            severity: .warn,
            message: "msg",
            location: nil,
            notes: []
        )
        let data = try JSONEncoder().encode(entry)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("\"severity\":\"warn\""))
    }

    /// Schema round-trip: encoding then decoding an `Entry` yields the same value.
    @Test func entryRoundTripsThroughJSON() throws {
        let original = LintCache.Entry(
            category: "NoBlockComments",
            severity: .error,
            message: "remove block comment",
            location: LintCache.Location(file: "/x.swift", line: 3, column: 5),
            notes: [
                LintCache.Note(
                    message: "see also",
                    location: LintCache.Location(file: "/x.swift", line: 4, column: 1)
                )
            ]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LintCache.Entry.self, from: data)
        #expect(decoded.category == original.category)
        #expect(decoded.severity == original.severity)
        #expect(decoded.message == original.message)
        #expect(decoded.location?.file == original.location?.file)
        #expect(decoded.location?.line == original.location?.line)
        #expect(decoded.location?.column == original.location?.column)
        #expect(decoded.notes.count == 1)
        #expect(decoded.notes[0].message == "see also")
    }

    /// The cache belongs to the package, not to the directory the run started in. A run started
    /// inside `Sources/` must still write to `<package root>/.build`, where the rooted ignore rule
    /// covers it.
    @Test func defaultRootResolvesToNearestPackageRoot() throws {
        let package = try TemporaryPackage()
        let nested = package.root
            .appendingPathComponent("Sources/TobaData/CloudKit", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)

        let resolved = LintCache.defaultRoot(startingAt: nested.path)
        let expected = package.root
            .appendingPathComponent(".build/sm-lint-cache", isDirectory: true)
        #expect(resolved.standardizedFileURL == expected.standardizedFileURL)
    }

    /// The start path names a file as often as a directory, because the caller passes the first
    /// linted path straight through.
    @Test func defaultRootAcceptsAFilePath() throws {
        let package = try TemporaryPackage()
        let nested = package.root.appendingPathComponent("Sources/A", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        let file = nested.appendingPathComponent("Thing.swift", isDirectory: false)
        try Data("let x = 1\n".utf8).write(to: file)

        let resolved = LintCache.defaultRoot(startingAt: file.path)
        let expected = package.root
            .appendingPathComponent(".build/sm-lint-cache", isDirectory: true)
        #expect(resolved.standardizedFileURL == expected.standardizedFileURL)
    }

    /// Without a `Package.swift` above the start path there is no root that an ignore rule covers,
    /// so the cache goes outside the tree rather than into it.
    @Test func defaultRootStaysOutsideAnUnpackagedTree() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("sm-lint-cache-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let resolved = LintCache.defaultRoot(startingAt: directory.path).standardizedFileURL
        #expect(!resolved.path.hasPrefix(directory.standardizedFileURL.path))
    }

    /// M4 invariant on the cache schema side: `Lint` decodes the same raw strings the old
    /// `Entry.Severity` produced, so v1 records remain readable.
    @Test func entryDecodesV1SeverityRawStrings() throws {
        let v1 = #"""
            {
              "category": "Foo",
              "severity": "error",
              "message": "m",
              "notes": []
            }
            """#
        let decoded = try JSONDecoder().decode(LintCache.Entry.self, from: Data(v1.utf8))
        #expect(decoded.severity == .error)
        #expect(decoded.category == "Foo")
        #expect(decoded.message == "m")
        #expect(decoded.location == nil)
        #expect(decoded.notes.isEmpty)
    }
}
