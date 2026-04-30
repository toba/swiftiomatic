import CryptoKit
import Foundation
import Synchronization

/// On-disk cache of lint findings keyed by `(file content hash, configuration fingerprint)`.
///
/// Linting a file is content-addressed: identical bytes through the same rule set with the same
/// configuration will always produce identical findings. The cache turns a no-change `sm lint`
/// run from "lint every file" into "hash every file and replay stored findings".
///
/// Layout under the cache root:
///   `<root>/<fingerprint[..16]>/<fileKey>.json`
///
/// `fingerprint` invalidates the entire subtree for a given `(rule set + configuration)`. Stale
/// fingerprint subdirectories from prior rule/config versions are simply orphaned — `swift package
/// clean` removes them along with the rest of `.build`.
package final class LintCache: Sendable {
    /// One emitted diagnostic preserved across runs. `Finding.category` is a protocol-typed value
    /// that isn't directly Codable, so the cache stores the flattened primitives that
    /// `DiagnosticsEngine` ultimately consumes.
    package struct Entry: Codable, Sendable {
        package enum Severity: String, Codable, Sendable { case error, warn, no }

        package struct Location: Codable, Sendable {
            package var file: String
            package var line: Int
            package var column: Int

            package init(file: String, line: Int, column: Int) {
                self.file = file
                self.line = line
                self.column = column
            }
        }

        package struct Note: Codable, Sendable {
            package var message: String
            package var location: Location?

            package init(message: String, location: Location?) {
                self.message = message
                self.location = location
            }
        }

        /// Human-readable category string (e.g. `"NoBlockComments"`). Equivalent to
        /// `"\(finding.category)"` at capture time.
        package var category: String

        /// Severity as configured for the rule that emitted the finding.
        package var severity: Severity

        /// Finding message text.
        package var message: String

        /// Optional source location of the main finding.
        package var location: Location?

        /// Notes attached to the finding.
        package var notes: [Note]

        package init(
            category: String,
            severity: Severity,
            message: String,
            location: Location?,
            notes: [Note]
        ) {
            self.category = category
            self.severity = severity
            self.message = message
            self.location = location
            self.notes = notes
        }
    }

    /// On-disk record for one file. Empty `entries` means "linted clean".
    package struct Record: Codable, Sendable {
        /// Bumped whenever the on-disk schema changes incompatibly.
        package static let currentVersion = 1

        package var version: Int
        package var entries: [Entry]

        package init(version: Int = Self.currentVersion, entries: [Entry]) {
            self.version = version
            self.entries = entries
        }
    }

    /// A binary-stable identifier for the rule set compiled into this `sm`.
    ///
    /// Computed once per process from sorted rule type names. When the binary gains, loses, or
    /// renames a rule the value changes, which combined with the per-configuration JSON hash
    /// produces a new fingerprint and orphans every prior cache subtree.
    private static let ruleSetIdentifier: String = {
        var hasher = SHA256()
        hasher.update(data: Data("rules.v1\n".utf8))
        let names = ConfigurationRegistry.allRuleTypes
            .map { String(reflecting: $0) }
            .sorted()
        for name in names {
            hasher.update(data: Data(name.utf8))
            hasher.update(data: Data([0]))
        }
        return hexEncode(hasher.finalize())
    }()

    /// Memoized fingerprint for the most recently seen configuration. The vast majority of runs
    /// see one configuration applied to many files; caching the encode + hash makes the per-file
    /// path a pointer comparison + memcmp.
    private struct FingerprintEntry: Sendable {
        var configuration: Configuration
        var fingerprint: String
    }
    private let lastFingerprint = Mutex<FingerprintEntry?>(nil)

    /// Shared encoder/decoder protected by a Mutex. Avoids the per-call init cost (date strategies,
    /// userInfo, output formatting) on the hot lookup/store path.
    private let coders = Mutex<Coders>(Coders())
    private struct Coders {
        var fingerprintEncoder: JSONEncoder = {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            return encoder
        }()
        var recordEncoder = JSONEncoder()
        var recordDecoder = JSONDecoder()
    }

    /// Root of the cache tree. Created lazily on first write.
    package let root: URL

    /// Creates a cache rooted at the given directory. The directory is created on first write.
    package init(root: URL) {
        self.root = root
    }

    /// Convenience: a cache rooted under `<cwd>/.build/sm-lint-cache/` if `.build` exists, else
    /// under `<cwd>/.build/sm-lint-cache/` anyway (the directory is created on demand).
    package convenience init() {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        self.init(root: cwd.appendingPathComponent(".build/sm-lint-cache", isDirectory: true))
    }

    /// SHA-256 of file content, hex-encoded.
    package static func contentHash(of source: String) -> String {
        hexEncode(SHA256.hash(data: Data(source.utf8)))
    }

    /// Returns `true` if the `SM_LINT_NO_CACHE` environment variable disables caching.
    /// Any non-empty value other than `"0"` counts as on.
    package static var disabledByEnvironment: Bool {
        guard let raw = ProcessInfo.processInfo.environment["SM_LINT_NO_CACHE"] else { return false }
        return !raw.isEmpty && raw != "0"
    }

    /// Whether `lint` for a given file URL plus options should be served by the cache. Cache values
    /// are whole-file findings, so per-line/offset selections, stdin, and `--ignore-unparsable-files`
    /// runs all bypass it.
    package static func isCacheEligible(
        url: URL,
        lines: [ClosedRange<Int>],
        offsets: [Range<Int>],
        ignoreUnparsableFiles: Bool
    ) -> Bool {
        lines.isEmpty
            && offsets.isEmpty
            && !ignoreUnparsableFiles
            && url.isFileURL
            && url.path != "<stdin>"
    }

    /// Combined fingerprint of `(rule set + configuration + cache schema version)`.
    ///
    /// Memoizes the result for the most recently seen `Configuration`. A different value triggers
    /// a re-encode + re-hash; a repeated value returns the cached string.
    package func fingerprint(for configuration: Configuration) -> String {
        if let memo = lastFingerprint.withLock({ $0 }), memo.configuration == configuration {
            return memo.fingerprint
        }

        var hasher = SHA256()
        hasher.update(data: Data("sm-lint-cache.v\(Record.currentVersion)\n".utf8))
        hasher.update(data: Data(Self.ruleSetIdentifier.utf8))
        hasher.update(data: Data([0]))

        let encoded = coders.withLock { try? $0.fingerprintEncoder.encode(configuration) }
        if let json = encoded {
            hasher.update(data: json)
        }

        let fp = Self.hexEncode(hasher.finalize())
        lastFingerprint.withLock { $0 = FingerprintEntry(configuration: configuration, fingerprint: fp) }
        return fp
    }

    /// Returns the on-disk path for the cached record of the given file, under the given fingerprint.
    private func recordURL(fingerprint: String, fileKey: String) -> URL {
        // Truncate fingerprint to 16 chars for shorter paths; collisions are not security-relevant
        // (worst case: false sharing across different binaries/configs, which the per-file
        // contentHash inside the key still rejects).
        let prefix = String(fingerprint.prefix(16))
        return root.appendingPathComponent(prefix, isDirectory: true)
            .appendingPathComponent("\(fileKey).json", isDirectory: false)
    }

    /// Per-file cache key combining absolute path and content hash. If either changes, the lookup
    /// misses.
    private func fileKey(absolutePath: String, contentHash: String) -> String {
        var hasher = SHA256()
        hasher.update(data: Data(absolutePath.utf8))
        hasher.update(data: Data([0]))
        hasher.update(data: Data(contentHash.utf8))
        return Self.hexEncode(hasher.finalize())
    }

    /// Looks up cached findings for the given file. Returns `nil` on any miss (including
    /// unreadable or malformed cache files — corruption is treated as a miss, not a crash).
    package func lookup(absolutePath: String, contentHash: String, fingerprint: String) -> Record? {
        let url = recordURL(
            fingerprint: fingerprint,
            fileKey: fileKey(absolutePath: absolutePath, contentHash: contentHash)
        )
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoded = coders.withLock { try? $0.recordDecoder.decode(Record.self, from: data) }
        guard let record = decoded, record.version == Record.currentVersion else { return nil }
        return record
    }

    /// Persists findings for the given file. Writes are atomic (write-then-rename) so concurrent
    /// readers either see the previous record or the new one, never a half-written file.
    package func store(
        absolutePath: String,
        contentHash: String,
        fingerprint: String,
        record: Record
    ) {
        let url = recordURL(
            fingerprint: fingerprint,
            fileKey: fileKey(absolutePath: absolutePath, contentHash: contentHash)
        )
        let directory = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true)

        let encoded = coders.withLock { try? $0.recordEncoder.encode(record) }
        guard let data = encoded else { return }
        try? data.write(to: url, options: [.atomic])
    }

    /// Encodes raw bytes as a lowercase hex string in a single allocation. Avoids the
    /// `digest.map { String(format: "%02x", $0) }.joined()` pattern, which allocates a
    /// `String` per byte plus an intermediate array.
    static func hexEncode<S: Sequence>(_ bytes: S) -> String where S.Element == UInt8 {
        let table: StaticString = "0123456789abcdef"
        return table.withUTF8Buffer { hex in
            var result = ""
            result.reserveCapacity(64)
            for byte in bytes {
                result.append(Character(Unicode.Scalar(hex[Int(byte >> 4)])))
                result.append(Character(Unicode.Scalar(hex[Int(byte & 0x0F)])))
            }
            return result
        }
    }
}

extension LintCache.Entry.Location {
    /// Round-trips a `Finding.Location` through the cache schema.
    package init(_ findingLocation: Finding.Location) {
        self.init(
            file: findingLocation.file,
            line: findingLocation.line,
            column: findingLocation.column
        )
    }

    /// Materializes the cached location as a `Finding.Location`.
    package var asFindingLocation: Finding.Location {
        Finding.Location(file: file, line: line, column: column)
    }
}

extension LintCache.Entry.Severity {
    package init(_ severity: Lint) {
        self =
            switch severity {
            case .error: .error
            case .warn: .warn
            case .no: .no
            }
    }

    package var asLint: Lint {
        switch self {
        case .error: .error
        case .warn: .warn
        case .no: .no
        }
    }
}
