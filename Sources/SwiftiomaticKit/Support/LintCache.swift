import CryptoKit
import Foundation
import Synchronization
import TobaConcurrency

/// On-disk cache of lint findings keyed by `(file content hash, configuration fingerprint)` .
///
/// Linting a file is content-addressed: identical bytes through the same rule set with the same
/// configuration will always produce identical findings. The cache turns a no-change `sm lint` run
/// from "lint every file" into "hash every file and replay stored findings".
///
/// Layout under the cache root: `<root>/<fingerprint[..16]>/<fileKey>.json`
///
/// `fingerprint` invalidates the entire subtree for a given `(rule set + configuration)` . Stale
/// fingerprint subdirectories from prior rule/config versions are simply orphaned —
/// `swift package clean` removes them along with the rest of `.build` .
///
/// **Concurrent writers**: two `sm lint` processes linting the same file with the same
/// configuration will land on the same record path. `store(_:)` writes with `.atomic`
/// (write-then-rename), so readers always see either the previous record or the new one, never a
/// torn file. When both writers race, the last `rename` wins; both inputs are by construction
/// equivalent (same content hash + same fingerprint ⇒ same findings), so the surviving record is
/// always valid. This is documented because there is no inter-process lock; future consumers should
/// not assume one.
package final class LintCache: Sendable {
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

        /// What the note's location matched. Optional so that records written before the field
        /// existed still decode.
        package var role: EvidenceRole?

        package init(message: String, location: Location?, role: EvidenceRole? = nil) {
            self.message = message
            self.location = location
            self.role = role
        }
    }

    /// One emitted diagnostic preserved across runs. `Finding.category` is a protocol-typed value
    /// that isn't directly Codable, so the cache stores the flattened primitives that
    /// `DiagnosticsEngine` ultimately consumes.
    package struct Entry: Codable, Sendable {
        /// Human-readable category string (e.g. `"NoBlockComments"` ). Equivalent to
        /// `"\(finding.category)"` at capture time.
        package var category: String

        /// Severity as configured for the rule that emitted the finding.
        ///
        /// Stored as the live `Lint` value directly. The string raw values ( `error` , `warn` ,
        /// `no` ) match the prior `Entry.Severity` shape, so cache records written under v1 still
        /// decode.
        package var severity: Lint

        /// Finding message text.
        package var message: String

        /// Optional source location of the main finding.
        package var location: Location?

        /// Notes attached to the finding.
        package var notes: [Note]

        package init(
            category: String,
            severity: Lint,
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
        ///
        /// Version 2 stores the linted file of a location as an empty path. Version 1 records hold
        /// the path relative to the working directory of the run that wrote them. Version 3 adds
        /// the project index keys that the findings depend on.
        package static let currentVersion = 3

        package var version: Int
        package var entries: [Entry]

        /// The keys of the project index that the lint of the file read, such as `type:Book` .
        /// Empty when the findings depend on the file alone.
        package var dependencies: [String]

        /// The `ProjectIndex.digest(of:from:)` of `dependencies` when the record was written. A
        /// lookup whose current digest differs is a miss.
        package var dependencyDigest: String?

        package init(
            version: Int = Self.currentVersion,
            entries: [Entry],
            dependencies: [String] = [],
            dependencyDigest: String? = nil
        ) {
            self.version = version
            self.entries = entries
            self.dependencies = dependencies
            self.dependencyDigest = dependencyDigest
        }
    }

    /// A binary-stable identifier for the rule set compiled into this `sm` .
    ///
    /// Computed once per process from sorted rule type names plus the running executable's (path,
    /// size, mtime). When the binary gains, loses, or renames a rule, *or* when the executable is
    /// rebuilt with no surface change but altered rule logic, the value changes, which combined
    /// with the per-configuration JSON hash produces a new fingerprint and orphans every prior
    /// cache subtree.
    private static let ruleSetIdentifier: String = {
        var hasher = SHA256()
        hasher.update(data: Data("rules.v2\n".utf8))
        let names = ConfigurationRegistry.allRuleTypes
            .map { String(reflecting: $0) }
            .sorted()
        for name in names {
            hasher.update(data: Data(name.utf8))
            hasher.update(data: Data([0]))
        }
        // Mix in the running executable's identity so that rebuilding `sm` (which can change rule
        // logic without changing rule names) invalidates the cache. Resolve the executable via
        // `Bundle.main.executablePath` rather than `CommandLine.arguments[0]` so that bare
        // invocations like `sm lint …` (argv[0] = "sm") still hit a real file. Without this,
        // `attributesOfItem(atPath: "sm")` fails when cwd has no `sm` file, so size/mtime drop out
        // of the digest, the fingerprint becomes stable across rebuilds, and stale findings from a
        // previous build are returned.
        if let exePath = Bundle.main.executablePath
            ?? CommandLine.arguments.first,
           let attrs = try? FileManager.default.attributesOfItem(atPath: exePath)
        {
            hasher.update(data: Data(exePath.utf8))
            hasher.update(data: Data([0]))

            if let size = attrs[.size] as? NSNumber {
                hasher.update(data: Data("\(size.uint64Value)".utf8))
                hasher.update(data: Data([0]))
            }
            if let mtime = attrs[.modificationDate] as? Date {
                hasher.update(data: Data("\(mtime.timeIntervalSince1970)".utf8))
                hasher.update(data: Data([0]))
            }
        }
        return hexEncode(hasher.finalize())
    }()

    /// Fingerprints memoized by a caller key, such as the path of the configuration file.
    ///
    /// Most runs apply one configuration to many files. A key lookup costs one hash of a short
    /// string. The earlier memo compared whole `Configuration` values for each file.
    private let fingerprints = Mutex<[String: String]>([:])

    /// Root of the cache tree. Created lazily on first write.
    package let root: URL

    /// Creates a cache rooted at the given directory. The directory is created on first write.
    package init(root: URL) { self.root = root }

    /// Creates a cache at the root that ``defaultRoot(startingAt:)`` resolves for `startPath` .
    ///
    /// - Parameter startPath: A file or directory the run touches. Defaults to the working
    ///   directory.
    package convenience init(startingAt startPath: String? = nil) {
        self.init(root: Self.defaultRoot(
            startingAt: startPath ?? FileManager.default.currentDirectoryPath))
    }

    /// Resolves the cache root for a run that starts at the given file or directory
    ///
    /// Walks up to the nearest `Package.swift` and answers `<package root>/.build/sm-lint-cache` .
    /// One repository then holds one cache, and the rooted `/.build` ignore rule every package
    /// already carries covers it. A run started deep inside `Sources/` writes to the package root,
    /// not beside the file it lints.
    ///
    /// Without a `Package.swift` above the start path no ignore rule covers any candidate inside
    /// the tree, so the cache goes to the user cache directory instead.
    package static func defaultRoot(startingAt startPath: String) -> URL {
        var directory = URL(fileURLWithPath: startPath).standardizedFileURL
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: directory.path, isDirectory: &isDirectory
        )
        if !exists || !isDirectory.boolValue { directory = directory.deletingLastPathComponent() }

        while true {
            let manifest = directory.appendingPathComponent("Package.swift", isDirectory: false)

            if FileManager.default.fileExists(atPath: manifest.path) {
                return directory.appendingPathComponent(".build/sm-lint-cache", isDirectory: true)
            }
            let parent = directory.deletingLastPathComponent().standardizedFileURL
            if parent.path == directory.path { break }
            directory = parent
        }

        return userCacheRoot
    }

    /// Fallback root under the user cache directory, used when no package encloses the run.
    private static let userCacheRoot: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return caches.appendingPathComponent("sm/lint-cache", isDirectory: true)
    }()

    /// SHA-256 of the UTF-8 bytes of the source, hex-encoded.
    ///
    /// A native string gives its bytes through a borrowed span, so the hash makes no copy. Only a
    /// bridged string that has no contiguous UTF-8 storage is copied.
    package static func contentHash(of source: String) -> String {
        if source.isContiguousUTF8 { return contentHash(of: source.utf8.span) }
        var copy = source
        copy.makeContiguousUTF8()
        return contentHash(of: copy.utf8.span)
    }

    /// SHA-256 of the given bytes, hex-encoded. The bytes do not have to be valid UTF-8.
    package static func contentHash(of bytes: Span<UInt8>) -> String {
        bytes.withUnsafeBytes { hexEncode(SHA256.hash(data: $0)) }
    }

    /// Returns `true` if the `SM_LINT_NO_CACHE` environment variable disables caching. Any
    /// non-empty value other than `"0"` counts as on.
    package static var disabledByEnvironment: Bool {
        guard let raw = ProcessInfo.processInfo.environment["SM_LINT_NO_CACHE"] else {
            return false
        }
        return !raw.isEmpty && raw != "0"
    }

    /// Whether `lint` for a given file URL plus options should be served by the cache. Cache values
    /// are whole-file findings, so per-line/offset selections, stdin, and
    /// `--ignore-unparsable-files` runs all bypass it.
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

    /// Combined fingerprint of `(rule set + configuration + cache schema version)` .
    ///
    /// This form does not use the memo. It encodes and hashes the configuration on each call.
    package func fingerprint(for configuration: Configuration) -> String {
        var hasher = SHA256()
        hasher.update(data: Data("sm-lint-cache.v\(Record.currentVersion)\n".utf8))
        hasher.update(data: Data(Self.ruleSetIdentifier.utf8))
        hasher.update(data: Data([0]))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        if let json = try? encoder.encode(configuration) { hasher.update(data: json) }

        return Self.hexEncode(hasher.finalize())
    }

    /// Combined fingerprint of `(rule set + configuration + cache schema version)` , memoized by
    /// the given key.
    ///
    /// The caller must give the same configuration for the same key during the life of this
    /// cache. The path of the loaded configuration file, or a fixed name for the default
    /// configuration, satisfies this rule, because the configuration loader keeps one value for
    /// each path.
    ///
    /// - Parameters:
    ///   - configuration: The configuration to fingerprint on a memo miss.
    ///   - key: The memo key.
    package func fingerprint(for configuration: Configuration, key: String) -> String {
        if let memo = fingerprints.withLock({ $0[key] }) { return memo }
        // The encode runs outside the lock. Two workers can compute the same value one time
        // each. Both values are equal, so the second write is harmless.
        let fingerprint = fingerprint(for: configuration)
        fingerprints.withLock { $0[key] = fingerprint }
        return fingerprint
    }

    /// Returns the on-disk path for the cached record of the given file, under the given
    /// fingerprint.
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

    /// Looks up cached findings for the given file. Returns `nil` on any miss (including unreadable
    /// or malformed cache files — corruption is treated as a miss, not a crash).
    package func lookup(absolutePath: String, contentHash: String, fingerprint: String) -> Record? {
        let url = recordURL(
            fingerprint: fingerprint,
            fileKey: fileKey(absolutePath: absolutePath, contentHash: contentHash)
        )
        guard let data = try? Data(contentsOf: url),
              // A decoder for each call. A shared decoder needs a lock, and then all the workers
              // of a parallel run wait on that one lock.
              let record = try? JSONDecoder().decode(Record.self, from: data),
              record.version == Record.currentVersion
        else { return nil }
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
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        // An encoder for each call, for the same reason as the decoder in `lookup` .
        guard let data = try? JSONEncoder().encode(record) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    /// Encodes raw bytes as a lowercase hex string in a single allocation. Avoids the
    /// `digest.map { String(format: "%02x", $0) }.joined()` pattern, which allocates a `String` per
    /// byte plus an intermediate array.
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

package extension LintCache.Location {
    /// Round-trips a `Finding.Location` through the cache schema.
    ///
    /// A location in the linted file stores an empty path. The displayed path of the linted file
    /// depends on the working directory, but the record key does not. The replay supplies the path
    /// of the current run.
    ///
    /// - Parameters:
    ///   - findingLocation: The location to store.
    ///   - lintedFile: The displayed path of the file that the run lints.
    init(_ findingLocation: Finding.Location, lintedFile: String) {
        self.init(
            file: findingLocation.file == lintedFile ? "" : findingLocation.file,
            line: findingLocation.line,
            column: findingLocation.column
        )
    }

    /// Materializes the cached location as a `Finding.Location` .
    ///
    /// - Parameter lintedFile: The displayed path of the file that the current run lints. It
    ///   replaces the empty path that marks the linted file.
    func asFindingLocation(lintedFile: String) -> Finding.Location {
        Finding.Location(file: file.isEmpty ? lintedFile : file, line: line, column: column)
    }
}
