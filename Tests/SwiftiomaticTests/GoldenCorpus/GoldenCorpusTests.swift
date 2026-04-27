import Foundation
@testable import SwiftiomaticKit
import Testing

/// Locks in byte-identical output of `RewriteCoordinator` against a curated corpus.
///
/// Every fixture under `Inputs/` is formatted with the default configuration and compared
/// to the snapshot under `Snapshots/`. Drift fails the test with a unified diff.
///
/// Regenerate snapshots intentionally by setting `SWIFTIOMATIC_UPDATE_GOLDEN=1` in the
/// environment. Missing snapshots are written on first run and the test records an
/// "Issue" so CI surfaces unreviewed fixtures.
@Suite
struct GoldenCorpusTests {
    @Test(arguments: GoldenCorpus.fixtures)
    func formatMatchesSnapshot(_ fixture: GoldenCorpus.Fixture) throws {
        try check(fixture: fixture)
    }

    private func check(fixture: GoldenCorpus.Fixture) throws {
        let source = try String(contentsOf: fixture.input, encoding: .utf8)
        var actual = ""
        let coordinator = RewriteCoordinator(configuration: Configuration())
        do {
            try coordinator.format(
                source: source,
                assumingFileURL: fixture.input,
                selection: .infinite,
                to: &actual
            )
        } catch {
            Issue.record("formatter threw for \(fixture.name): \(error)")
            return
        }

        let updateMode = ProcessInfo.processInfo.environment["SWIFTIOMATIC_UPDATE_GOLDEN"] == "1"
        let fm = FileManager.default

        if updateMode || !fm.fileExists(atPath: fixture.snapshot.path) {
            try actual.write(to: fixture.snapshot, atomically: true, encoding: .utf8)
            if !updateMode {
                Issue.record(
                    "wrote new snapshot for \(fixture.name); review and commit it"
                )
            }
            return
        }

        let expected = try String(contentsOf: fixture.snapshot, encoding: .utf8)
        if expected != actual {
            Issue.record(
                Comment(rawValue: GoldenCorpus.diff(expected: expected, actual: actual, name: fixture.name))
            )
        }
    }
}

/// Discovery + utilities for the golden-corpus fixtures.
///
/// Fixtures live next to this test file:
/// - `Inputs/<name>.swift.fixture` — the source to format
/// - `Snapshots/<name>.swift.golden` — the expected formatted output
///
/// The `.fixture` / `.golden` extensions keep SPM from trying to compile the inputs as
/// Swift sources or the snapshots as resources — no Package.swift change needed.
enum GoldenCorpus {
    struct Fixture: Sendable, CustomStringConvertible {
        let name: String
        let input: URL
        let snapshot: URL
        var description: String { name }
    }

    static let directory: URL = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

    static let fixtures: [Fixture] = {
        let inputsDir = directory.appendingPathComponent("Inputs", isDirectory: true)
        let snapshotsDir = directory.appendingPathComponent("Snapshots", isDirectory: true)
        let entries =
            (try? FileManager.default.contentsOfDirectory(
                at: inputsDir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )) ?? []
        return
            entries
            .filter { $0.lastPathComponent.hasSuffix(".swift.fixture") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { url in
                let base = url.lastPathComponent.replacingOccurrences(of: ".swift.fixture", with: "")
                return Fixture(
                    name: base,
                    input: url,
                    snapshot: snapshotsDir.appendingPathComponent("\(base).swift.golden")
                )
            }
    }()

    /// Minimal line-oriented diff. Real `diff(1)` output isn't worth a dependency for a
    /// debugging aid that's only consumed when something has already gone wrong.
    static func diff(expected: String, actual: String, name: String) -> String {
        let expectedLines = expected.split(separator: "\n", omittingEmptySubsequences: false)
        let actualLines = actual.split(separator: "\n", omittingEmptySubsequences: false)
        var lines: [String] = ["snapshot drift in \(name):"]
        let maxCount = max(expectedLines.count, actualLines.count)
        for i in 0..<maxCount {
            let e = i < expectedLines.count ? String(expectedLines[i]) : "<eof>"
            let a = i < actualLines.count ? String(actualLines[i]) : "<eof>"
            if e != a {
                lines.append("  L\(i + 1): - \(e)")
                lines.append("  L\(i + 1): + \(a)")
            }
        }
        lines.append(
            "(set SWIFTIOMATIC_UPDATE_GOLDEN=1 to regenerate snapshots after a deliberate change)"
        )
        return lines.joined(separator: "\n")
    }
}
