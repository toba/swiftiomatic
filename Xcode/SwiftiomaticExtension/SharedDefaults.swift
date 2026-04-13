import Foundation

/// Shared UserDefaults between the host app and the extension.
///
/// Uses a plain suite name (not an App Group) so it works without provisioning.
/// Any process under the same user account can read/write this suite.
enum SharedDefaults {
    static let suiteName = "app.toba.swiftiomatic"
    static var suite: UserDefaults? { UserDefaults(suiteName: suiteName) }
    static let configYAMLKey = "configYAML"
}

