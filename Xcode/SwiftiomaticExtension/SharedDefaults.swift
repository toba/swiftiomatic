import Foundation

/// Shared UserDefaults keys for communication between the host app and the extension.
enum SharedDefaults {
    static let suiteName = "group.app.toba.swiftiomatic"
    static var suite: UserDefaults? { UserDefaults(suiteName: suiteName) }
    static let configYAMLKey = "configYAML"
    static let configPathKey = "configPath"
}

