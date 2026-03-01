/// Public API surface for consumers outside the Swift package (e.g. Xcode Source Editor Extension).
/// Internal types remain `package` — this file exposes only what external targets need.
public enum SwiftiomaticLib {
    /// Format Swift source code using the default rules and options.
    public static func format(_ source: String) throws -> String {
        try FormatEngine().format(source)
    }
}
