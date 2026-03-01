import Foundation

/// Errors produced by Source Editor Extension commands.
enum FormatCommandError: Error, LocalizedError, CustomNSError {
    case unsupportedContentType(String)
    case formatFailed(underlying: any Error)
    case noSelection
    case lintSummary(count: Int, summary: String)

    var errorDescription: String? {
        switch self {
            case let .unsupportedContentType(uti):
                "Swiftiomatic only works with Swift source files (received \(uti))."
            case let .formatFailed(underlying):
                "Formatting failed: \(underlying.localizedDescription)"
            case .noSelection:
                "No text is selected."
            case let .lintSummary(count, summary):
                "\(count) issue\(count == 1 ? "" : "s") found:\n\(summary)"
        }
    }

    static var errorDomain: String { "com.toba.swiftiomatic.extension" }

    var errorCode: Int {
        switch self {
            case .unsupportedContentType: 1
            case .formatFailed: 2
            case .noSelection: 3
            case .lintSummary: 4
        }
    }

    var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: errorDescription ?? "Unknown error"]
    }
}
