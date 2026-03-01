import Foundation
import Swiftiomatic

/// Load configuration from the App Group bookmark, falling back to defaults.
func loadConfiguration() -> Configuration {
    guard let defaults = SharedDefaults.suite,
          let bookmark = defaults.data(forKey: SharedDefaults.configBookmarkKey) else {
        return .default
    }
    var stale = false
    guard let url = try? URL(
        resolvingBookmarkData: bookmark,
        options: [],
        bookmarkDataIsStale: &stale
    ), url.startAccessingSecurityScopedResource() else {
        return .default
    }
    defer { url.stopAccessingSecurityScopedResource() }
    return (try? Configuration.loadUnified(from: url.path)) ?? .default
}
