import Foundation

/// Errors that can occur during formatting or linting
enum FormatError: Error, CustomStringConvertible, LocalizedError {
    case reading(String)
    case writing(String)
    case parsing(String)
    case options(String)

    /// Creates an ``options`` error for an unrecognized CLI argument value
    ///
    /// Includes a "did you mean?" suggestion when a close match exists.
    ///
    /// - Parameters:
    ///   - option: The invalid value that was provided.
    ///   - argumentName: The CLI argument name (without leading dashes).
    ///   - validOptions: All accepted values for this argument.
    static func invalidOption(
        _ option: String,
        for argumentName: String,
        with validOptions: [String],
    ) -> Self {
        let message = "Unsupported --\(argumentName) value '\(option)'"

        guard let match = option.bestMatch(in: validOptions) else {
            return .options("\(message). Valid options are \(validOptions.formattedList())")
        }
        return .options("\(message). Did you mean '\(match)'?")
    }

    var description: String {
        switch self {
            case let .reading(string),
                 let .writing(string),
                 let .parsing(string),
                 let .options(string):
                return string
        }
    }

    var localizedDescription: String {
        "Error: \(description)."
    }
}
