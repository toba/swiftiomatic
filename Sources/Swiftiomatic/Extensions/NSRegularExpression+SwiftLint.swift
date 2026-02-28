import Foundation
import Synchronization

// MARK: - Modern RegularExpression (Swift Regex)

struct RegularExpression: Hashable, Comparable, ExpressibleByStringLiteral, @unchecked Sendable {
    let regex: Regex<AnyRegexOutput>
    package let pattern: String
    private let optionsRaw: UInt

    var numberOfCaptureGroups: Int {
        // Delegate to NSRegularExpression for accurate group counting
        (try? NSRegularExpression(pattern: pattern)).map(\.numberOfCaptureGroups) ?? 0
    }

    init(pattern: String, options: NSRegularExpression.Options? = nil) throws {
        let opts = options ?? [.anchorsMatchLines, .dotMatchesLineSeparators]
        self.pattern = pattern
        self.optionsRaw = opts.rawValue
        self.regex = try Self.compileRegex(pattern: pattern, options: opts)
    }

    init(stringLiteral value: String) {
        // sm:disable:next force_try
        try! self.init(pattern: value)
    }

    static func from(
        pattern: String,
        options: NSRegularExpression.Options? = nil,
        for ruleID: String,
    ) throws(Issue) -> Self {
        do {
            return try Self(pattern: pattern, options: options)
        } catch {
            throw .invalidRegexPattern(ruleID: ruleID, pattern: pattern)
        }
    }

    // MARK: Hashable / Comparable

    func hash(into hasher: inout Hasher) {
        hasher.combine(pattern)
        hasher.combine(optionsRaw)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.pattern == rhs.pattern && lhs.optionsRaw == rhs.optionsRaw
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.pattern < rhs.pattern
    }

    // MARK: Matching

    func firstMatch(in string: String) -> Regex<AnyRegexOutput>.Match? {
        string.firstMatch(of: regex)
    }

    func firstMatch(in string: Substring) -> Regex<AnyRegexOutput>.Match? {
        string.firstMatch(of: regex)
    }

    func hasMatch(in string: String) -> Bool {
        string.firstMatch(of: regex) != nil
    }

    func hasMatch(in string: String, range nsRange: NSRange) -> Bool {
        guard let range = Range(nsRange, in: string) else { return false }
        return string[range].firstMatch(of: regex) != nil
    }

    // MARK: Compilation

    private static func compileRegex(
        pattern: String, options: NSRegularExpression.Options,
    ) throws -> Regex<AnyRegexOutput> {
        var flags = ""
        if options.contains(.anchorsMatchLines) { flags += "m" }
        if options.contains(.dotMatchesLineSeparators) { flags += "s" }
        if options.contains(.caseInsensitive) { flags += "i" }

        if options.contains(.ignoreMetacharacters) {
            let escaped = NSRegularExpression.escapedPattern(for: pattern)
            let fullPattern = flags.isEmpty ? escaped : "(?\(flags))\(escaped)"
            return try Regex(fullPattern)
        }

        let fullPattern = flags.isEmpty ? pattern : "(?\(flags))\(pattern)"
        return try Regex(fullPattern)
    }
}

// MARK: - NSRegularExpression Cache (for SwiftLintFile.match() infrastructure)

private let nsRegexCache = Mutex([NSRegexCacheKey: NSRegularExpression]())

private struct NSRegexCacheKey: Hashable {
    let pattern: String
    let options: NSRegularExpression.Options

    func hash(into hasher: inout Hasher) {
        hasher.combine(pattern)
        hasher.combine(options.rawValue)
    }
}

extension NSRegularExpression {
    static func cached(pattern: String, options: Options? = nil) throws -> NSRegularExpression {
        let options = options ?? [.anchorsMatchLines, .dotMatchesLineSeparators]
        let key = NSRegexCacheKey(pattern: pattern, options: options)
        return try nsRegexCache.withLock { cache in
            if let result = cache[key] {
                return result
            }
            let result = try NSRegularExpression(pattern: pattern, options: options)
            cache[key] = result
            return result
        }
    }

    func matches(
        in stringView: StringView,
        options: NSRegularExpression.MatchingOptions = [],
    ) -> [NSTextCheckingResult] {
        matches(in: stringView.string, options: options, range: stringView.range)
    }

    func matches(
        in stringView: StringView,
        options: NSRegularExpression.MatchingOptions = [],
        range: NSRange,
    ) -> [NSTextCheckingResult] {
        matches(in: stringView.string, options: options, range: range)
    }

    func matches(
        in file: SwiftLintFile,
        options: NSRegularExpression.MatchingOptions = [],
    ) -> [NSTextCheckingResult] {
        matches(in: file.stringView.string, options: options, range: file.stringView.range)
    }
}
