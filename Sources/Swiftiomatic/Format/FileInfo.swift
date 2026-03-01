import Foundation

/// Placeholder keys for file header template substitution
enum ReplacementKey: String, CaseIterable {
    case fileName = "file"
    case currentYear = "year"
    case createdDate = "created"
    case createdYear = "created.year"
    case author
    case authorName = "author.name"
    case authorEmail = "author.email"

    var placeholder: String {
        "{\(rawValue)}"
    }
}

/// Controls how file headers are managed during formatting
enum FileHeaderMode: Equatable, RawRepresentable, ExpressibleByStringLiteral {
    case ignore
    case replace(String)

    init(stringLiteral value: String) {
        self.init(rawValue: value)!
    }

    init?(rawValue: String) {
        switch rawValue.lowercased() {
            case "ignore", "keep", "preserve":
                self = .ignore
            case "strip", "":
                self = .replace("")
            default:
                // Normalize the header
                let header = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
                let isMultiline = header.hasPrefix("/*")
                var lines = header.components(separatedBy: "\\n")
                lines = lines.map {
                    var line = $0
                    if !isMultiline, !line.hasPrefix("//") {
                        line = "//\(line.isEmpty ? "" : " ")\(line)"
                    }
                    return line
                }
                while lines.last?.isEmpty == true {
                    lines.removeLast()
                }
                self = .replace(lines.joined(separator: "\n"))
        }
    }

    var rawValue: String {
        switch self {
            case .ignore:
                return "ignore"
            case let .replace(string):
                return string.isEmpty ? "strip" : string.replacingOccurrences(of: "\n", with: "\\n")
        }
    }

    var needsGitInfo: Bool {
        guard case let .replace(str) = self else {
            return false
        }
        let keys: [ReplacementKey] = [
            .createdDate,
            .createdYear,
            .author,
            .authorName,
            .authorEmail,
        ]
        return keys.contains(where: { str.contains($0.placeholder) })
    }
}

/// Options that control how template placeholders are resolved (date format, time zone)
struct ReplacementOptions: CustomStringConvertible {
    var dateFormat: DateFormat
    var timeZone: FormatTimeZone

    init(dateFormat: DateFormat, timeZone: FormatTimeZone) {
        self.dateFormat = dateFormat
        self.timeZone = timeZone
    }

    init(_ options: FormatOptions) {
        self.init(dateFormat: options.dateFormat, timeZone: options.timeZone)
    }

    var description: String { "\(dateFormat)@\(timeZone)" }
}

/// A replacement value for a file header placeholder, either a fixed string or a dynamic closure
enum ReplacementType: Equatable, CustomStringConvertible {
    case constant(String)
    case dynamic((FileInfo, ReplacementOptions) -> String?)

    init?(_ value: String?) {
        guard let val = value else { return nil }
        self = .constant(val)
    }

    static func == (lhs: ReplacementType, rhs: ReplacementType) -> Bool {
        switch (lhs, rhs) {
            case let (.constant(lhsVal), .constant(rhsVal)):
                lhsVal == rhsVal
            case let (.dynamic(lhsClosure), .dynamic(rhsClosure)):
                lhsClosure as AnyObject === rhsClosure as AnyObject
            default:
                false
        }
    }

    /// Resolves the replacement value using the given file info and options
    ///
    /// - Parameters:
    ///   - info: Metadata about the file being formatted.
    ///   - options: Date and time zone settings for dynamic replacements.
    func resolve(_ info: FileInfo, _ options: ReplacementOptions) -> String? {
        switch self {
            case let .constant(value): value
            case let .dynamic(fn): fn(info, options)
        }
    }

    var description: String {
        switch self {
            case let .constant(value): value
            case .dynamic: "dynamic"
        }
    }
}

/// Metadata about a source file used for constructing header comments
struct FileInfo: Equatable, CustomStringConvertible {
    nonisolated(unsafe) static var defaultReplacements: [ReplacementKey: ReplacementType] = [
        .createdDate: .dynamic { info, options in
            info.creationDate?.format(
                with: options.dateFormat,
                timeZone: options.timeZone,
            )
        },
        .createdYear: .dynamic { info, _ in info.creationDate?.yearString },
        .currentYear: .constant(Date.currentYear),
    ]

    let filePath: String?
    var creationDate: Date?
    var replacements: [ReplacementKey: ReplacementType] = Self.defaultReplacements

    var fileName: String? {
        filePath.map { URL(fileURLWithPath: $0).lastPathComponent }
    }

    init(
        filePath: String? = nil,
        creationDate: Date? = nil,
        replacements: [ReplacementKey: ReplacementType] = [:],
    ) {
        self.filePath = filePath
        self.creationDate = creationDate
        self.replacements[.fileName] = fileName.map { .constant($0) }
        self.replacements.merge(replacements, uniquingKeysWith: { $1 })
    }

    var description: String {
        replacements
            .sorted(by: { $0.key.rawValue < $1.key.rawValue })
            .map { "\($0)=\($1)" }
            .joined(separator: ";")
    }

    /// Whether a non-nil replacement value exists for the given key
    ///
    /// - Parameters:
    ///   - key: The placeholder key to check.
    ///   - options: Format options providing date/time zone settings.
    func hasReplacement(for key: ReplacementKey, options: FormatOptions) -> Bool {
        replacements[key]?.resolve(self, ReplacementOptions(options)) != nil
    }
}

/// Format to use when printing dates in file headers
enum DateFormat: Equatable, RawRepresentable, CustomStringConvertible {
    case dayMonthYear
    case iso
    case monthDayYear
    case system
    case custom(String)

    init?(rawValue: String) {
        switch rawValue {
            case "dmy": self = .dayMonthYear
            case "iso": self = .iso
            case "mdy": self = .monthDayYear
            case "system": self = .system
            default: self = .custom(rawValue)
        }
    }

    var rawValue: String {
        switch self {
            case .dayMonthYear: return "dmy"
            case .iso: return "iso"
            case .monthDayYear: return "mdy"
            case .system: return "system"
            case let .custom(str): return str
        }
    }

    var description: String { rawValue }
}

/// Time zone to use when printing dates in file headers
enum FormatTimeZone: Equatable, RawRepresentable, CustomStringConvertible {
    case system
    case abbreviation(String)
    case identifier(String)

    static let utcNames = ["utc", "gmt"]

    init?(rawValue: String) {
        if Self.utcNames.contains(rawValue.lowercased()) {
            self = .identifier("UTC")
        } else if TimeZone.knownTimeZoneIdentifiers.contains(rawValue) {
            self = .identifier(rawValue)
        } else if TimeZone.abbreviationDictionary.keys.contains(rawValue) {
            self = .abbreviation(rawValue)
        } else if rawValue == Self.system.rawValue {
            self = .system
        } else {
            return nil
        }
    }

    var rawValue: String {
        switch self {
            case .system: "system"
            case let .abbreviation(abbreviation): abbreviation
            case let .identifier(identifier): identifier
        }
    }

    var timeZone: TimeZone? {
        switch self {
            case .system: TimeZone.current
            case let .abbreviation(abbreviation): TimeZone(abbreviation: abbreviation)
            case let .identifier(identifier): TimeZone(identifier: identifier)
        }
    }

    var description: String { rawValue }
}
