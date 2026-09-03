import Foundation

/// What one `--configuration` value names.
///
/// The flag takes a file path or the configuration JSON itself. Classifying the value up front
/// separates configuration the tool understands from a caller's typo, which has to fail the run
/// rather than fall through to the discovered project configuration.
package enum ConfigurationArgument {
    /// A readable file on disk.
    case file(URL)
    /// Configuration data written on the command line.
    case inlineJSON(Configuration)
    /// A path naming no file the tool can open.
    case unreadableFile(path: String)
    /// Data the decoder rejects.
    case malformed(any Error)

    /// Classifies one `--configuration` value.
    ///
    /// A readable path is tried first, because a file name is never valid configuration data. A
    /// value that opens with a brace is the JSON form, so the decoder's own error describes it. A
    /// value that does not is a path, and reporting it as bad JSON would name a syntax error in a
    /// file the tool never opened.
    ///
    /// - Parameter value: The raw string the caller passed to `--configuration` .
    package init(_ value: String) {
        let url = URL(fileURLWithPath: value)

        if FileManager.default.isReadableFile(atPath: url.path) {
            self = .file(url)
            return
        }

        guard value.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") else {
            self = .unreadableFile(path: value)
            return
        }

        do {
            self = try .inlineJSON(Configuration(data: Data(value.utf8)))
        } catch {
            self = .malformed(error)
        }
    }
}
