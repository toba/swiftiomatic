import Foundation

enum SwiftLintError: LocalizedError {
    case usageError(description: String)

    var errorDescription: String? {
        switch self {
            case let .usageError(description):
                return description
        }
    }
}
