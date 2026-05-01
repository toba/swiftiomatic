//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftiomaticKit
import Synchronization

/// Loads formatter configurations, caching them in memory so that multiple operations in the same
/// directory do not repeatedly hit the file system.
final class ConfigurationLoader: Sendable {
    /// The cache of previously loaded configurations, keyed by absolute config-file path.
    private let cache = Mutex<[String: Configuration]>([:])

    /// Returns the configuration found by walking up the file tree from `url` . This function works
    /// for both files and directories.
    ///
    /// If no configuration file was found during the search, this method returns nil.
    ///
    /// - Throws: If a configuration file was found but an error occurred loading it.
    func configuration(forPath url: URL) throws -> Configuration? {
        guard let configurationFileURL = Configuration.url(forConfigurationFileApplyingTo: url)
        else { return nil }
        return try configuration(at: configurationFileURL)
    }

    /// Returns the configuration associated with the configuration file at the given URL.
    ///
    /// - Throws: If an error occurred loading the configuration.
    func configuration(at url: URL) throws -> Configuration {
        let cacheKey = url.absoluteURL.standardized.path
        // Hold the lock across the load so concurrent callers for the same key don't each
        // parse the file independently (matches upstream SwiftFormat #2521 behavior). Parsing
        // a JSON5 config is fast and `Configuration(contentsOf:)` does not recurse into this
        // cache, so the lock cannot deadlock.
        return try cache.withLock { cache throws in
            if let cached = cache[cacheKey] { return cached }
            let configuration = try Configuration(contentsOf: url)
            cache[cacheKey] = configuration
            return configuration
        }
    }
}
