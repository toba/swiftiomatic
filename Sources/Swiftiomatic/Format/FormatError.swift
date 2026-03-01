import Foundation

/// An enumeration of the types of error that may be thrown by SwiftFormat
enum FormatError: Error, CustomStringConvertible, LocalizedError {
    case reading(String)
    case writing(String)
    case parsing(String)
    case options(String)

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
