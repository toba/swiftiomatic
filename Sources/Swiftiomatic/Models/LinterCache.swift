import Foundation
import Synchronization

private enum LinterCacheError: Error {
  case noLocation
}

private struct FileCacheEntry: Codable {
  let violations: [RuleViolation]
  let lastModification: Date
  let swiftVersion: SwiftVersion
}

private struct FileCache: Codable {
  var entries: [String: FileCacheEntry]

  static var empty: Self {
    Self(entries: [:])
  }
}

/// A persisted cache for storing and retrieving linter results.
final class LinterCache {
  private typealias Encoder = PropertyListEncoder
  private typealias Decoder = PropertyListDecoder
  private typealias Cache = [String: FileCache]

  private static let fileExtension = "plist"

  private struct CacheState {
    var readCache: Cache
    var writeCache: Cache
  }

  private let state: Mutex<CacheState>
  let fileManager: any LintableFileDiscovering
  private let location: URL?
  private let swiftVersion: SwiftVersion

  init(
    fileManager: some LintableFileDiscovering = FileManager.default,
    swiftVersion: SwiftVersion = .current,
  ) {
    location = nil
    self.fileManager = fileManager
    state = Mutex(CacheState(readCache: Cache(), writeCache: Cache()))
    self.swiftVersion = swiftVersion
  }

  /// Creates a `LinterCache` by specifying a configuration and a file manager.
  ///
  /// - parameter configuration: The configuration for which this cache will be used.
  /// - parameter fileManager:   The file manager to use to read lintable file information.
  init(
    configuration: Configuration,
    fileManager: some LintableFileDiscovering = FileManager.default
  ) {
    location = configuration.cacheURL
    state = Mutex(CacheState(readCache: Cache(), writeCache: Cache()))
    self.fileManager = fileManager
    swiftVersion = .current
  }

  private init(
    cache: Cache, location: URL?, fileManager: some LintableFileDiscovering,
    swiftVersion: SwiftVersion,
  ) {
    state = Mutex(CacheState(readCache: cache, writeCache: Cache()))
    self.location = location
    self.fileManager = fileManager
    self.swiftVersion = swiftVersion
  }

  func cache(
    violations: [RuleViolation], forFile file: String, configuration: Configuration,
  ) {
    guard let lastModification = fileManager.modificationDate(forFileAtPath: file) else {
      return
    }

    let configurationDescription = configuration.cacheDescription

    state.withLock { state in
      var filesCache = state.writeCache[configurationDescription] ?? .empty
      filesCache.entries[file] = FileCacheEntry(
        violations: violations, lastModification: lastModification,
        swiftVersion: swiftVersion,
      )
      state.writeCache[configurationDescription] = filesCache
    }
  }

  func violations(forFile file: String, configuration: Configuration) -> [RuleViolation]? {
    guard let lastModification = fileManager.modificationDate(forFileAtPath: file),
      let entry = fileCache(cacheDescription: configuration.cacheDescription).entries[file],
      entry.lastModification == lastModification,
      entry.swiftVersion == swiftVersion
    else {
      return nil
    }

    return entry.violations
  }

  /// Persists the cache to disk.
  ///
  /// - throws: Throws if the linter cache doesn't have a `location` value, if the cache couldn't be serialized, or if
  ///           the contents couldn't be written to disk.
  func save() throws {
    guard let url = location else {
      throw LinterCacheError.noLocation
    }
    let (writeCache, readCache) = state.withLock { state in
      (state.writeCache, state.readCache)
    }
    guard writeCache.isNotEmpty else {
      return
    }

    let encoder = Encoder()
    for (description, writeFileCache) in writeCache where writeFileCache.entries.isNotEmpty {
      let fileCacheEntries = readCache[description]?.entries.merging(writeFileCache.entries) {
        _, write in write
      }
      let fileCache = fileCacheEntries.map(FileCache.init) ?? writeFileCache
      let data = try encoder.encode(fileCache)
      let file = url.appendingPathComponent(description)
        .appendingPathExtension(Self.fileExtension)
      try data.write(to: file, options: .atomic)
    }
  }

  func flushed() -> LinterCache {
    Self(
      cache: mergeCaches(), location: location, fileManager: fileManager,
      swiftVersion: swiftVersion,
    )
  }

  private func fileCache(cacheDescription: String) -> FileCache {
    // Fast path: check cache under lock
    if let cached = state.withLock({ $0.readCache[cacheDescription] }) {
      return cached
    }

    guard let location else {
      return .empty
    }

    // Slow path: file I/O outside the lock
    let file = location.appendingPathComponent(cacheDescription).appendingPathExtension(
      Self.fileExtension,
    )
    let data = try? Data(contentsOf: file)
    let fileCache = data.flatMap { try? Decoder().decode(FileCache.self, from: $0) } ?? .empty

    state.withLock { $0.readCache[cacheDescription] = fileCache }
    return fileCache
  }

  private func mergeCaches() -> Cache {
    state.withLock { state in
      state.readCache.merging(state.writeCache) { read, write in
        FileCache(entries: read.entries.merging(write.entries) { _, write in write })
      }
    }
  }
}
