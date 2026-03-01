extension Configuration {
    /// The style of indentation used in a Swift project
    public enum IndentationStyle: Hashable, Sendable {
        /// Indent using tabs
        case tabs
        /// Indent using spaces with `count` spaces per indentation level
        case spaces(count: Int)

        /// The default indentation style if none is explicitly provided
        static let `default` = spaces(count: 4)

        /// Create an indentation style based on an untyped configuration value
        ///
        /// - Parameters:
        ///   - object: The configuration value (an `Int` for spaces or the string `"tabs"`).
        init?(_ object: Any?) {
            switch object {
                case let value as Int: self = .spaces(count: value)
                case let value as String where value == "tabs": self = .tabs
                default: return nil
            }
        }
    }
}
