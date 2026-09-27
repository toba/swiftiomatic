import Foundation
@testable import SwiftiomaticKit
import Testing

/// A throwaway directory tree, removed when the test releases it.
private final class TemporaryTree {
    let root: URL

    init() throws {
        root = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: FileManager.default.temporaryDirectory,
            create: true
        )
    }

    deinit { try? FileManager.default.removeItem(at: root) }

    @discardableResult
    func directory(_ path: String) throws -> URL {
        let url = root.appendingPathComponent(path, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @discardableResult
    func file(_ path: String, _ text: String = "{}\n") throws -> URL {
        let url = root.appendingPathComponent(path, isDirectory: false)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(text.utf8).write(to: url)
        return url
    }
}

@Suite struct ConfigurationDiscoveryTests {
    /// The cached walk gives the same result as the uncached walk for files, directories, and
    /// paths that do not exist.
    @Test func cachedLookupMatchesUncachedWalk() throws {
        let tree = try TemporaryTree()
        try tree.file("swiftiomatic.json")
        try tree.file("Sources/A/swiftiomatic.json")
        let paths = [
            try tree.file("Sources/A/One.swift", "let a = 1\n"),
            try tree.file("Sources/A/Two.swift", "let b = 2\n"),
            try tree.file("Sources/A/Deep/Three.swift", "let c = 3\n"),
            try tree.file("Sources/B/Four.swift", "let d = 4\n"),
            try tree.directory("Sources/A"),
            try tree.directory("Sources/B"),
            tree.root,
            tree.root.appendingPathComponent("Sources/B/Missing.swift"),
        ]
        let discovery = ConfigurationDiscovery()

        // Two passes: the second pass reads only the cache.
        for _ in 0..<2 {
            for path in paths {
                #expect(
                    discovery.configurationFileURL(applyingTo: path)?.standardizedFileURL
                        == Configuration.url(forConfigurationFileApplyingTo: path)?
                        .standardizedFileURL,
                    "path: \(path.path)"
                )
            }
        }
    }

    /// A directory with no configuration above it gives `nil`, from the walk and from the cache.
    @Test func directoryWithoutConfigurationGivesNil() throws {
        let tree = try TemporaryTree()
        let file = try tree.file("Bare/Thing.swift", "let x = 1\n")
        // The system temporary directory can have a configuration above it on some machines. The
        // expected value comes from the uncached walk, so the test is correct on all of them.
        let expected = Configuration.url(forConfigurationFileApplyingTo: file)
        let discovery = ConfigurationDiscovery()

        #expect(discovery.configurationFileURL(applyingTo: file) == expected)
        #expect(discovery.configurationFileURL(applyingTo: file) == expected)
        #expect(
            discovery.configurationFileURL(applyingTo: file.deletingLastPathComponent())
                == expected
        )
    }

    /// Sibling files share one cached result. After the first lookup, a new configuration file in
    /// the directory does not change the result, because the result comes from the cache.
    @Test func siblingFilesReuseCachedLookup() throws {
        let tree = try TemporaryTree()
        let configuration = try tree.file("swiftiomatic.json")
        let first = try tree.file("Pkg/One.swift", "let a = 1\n")
        let second = try tree.file("Pkg/Two.swift", "let b = 2\n")
        let discovery = ConfigurationDiscovery()

        #expect(
            discovery.configurationFileURL(applyingTo: first)?.standardizedFileURL
                == configuration.standardizedFileURL
        )

        try tree.file("Pkg/swiftiomatic.json")

        #expect(
            discovery.configurationFileURL(applyingTo: second)?.standardizedFileURL
                == configuration.standardizedFileURL
        )
    }
}
