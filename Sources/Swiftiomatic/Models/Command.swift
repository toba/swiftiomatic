import Foundation

/// A command to modify analysis behavior, embedded as comments in source code.
struct Command: Equatable {
    /// The action (verb) to perform when interpreting this command.
    enum Action: String {
        /// The rule(s) associated with this command should be enabled.
        case enable
        /// The rule(s) associated with this command should be disabled.
        case disable
        /// The action string was invalid.
        case invalid

        /// - returns: The inverse action that can cancel out the current action, restoring the engine's
        ///            state prior to the current action.
        package func inverse() -> Self {
            switch self {
                case .enable: return .disable
                case .disable: return .enable
                case .invalid: return .invalid
            }
        }
    }

    /// The modifier for a command, used to modify its scope.
    enum Modifier: String {
        /// The command should only apply to the line preceding its definition.
        case previous
        /// The command should only apply to the same line as its definition.
        case this
        /// The command should only apply to the line following its definition.
        case next
        /// The modifier string was invalid.
        case invalid
    }

    /// Text after this delimiter is not considered part of the rule.
    /// The purpose of this delimiter is to allow commands to be documented in source code.
    ///
    ///     sm:disable:next force_try - Explanation here
    private static let commentDelimiter = " - "

    var isValid: Bool {
        action != .invalid && modifier != .invalid && !ruleIdentifiers.isEmpty
    }

    /// The action (verb) to perform when interpreting this command.
    let action: Action
    /// The identifiers for the rules associated with this command.
    let ruleIdentifiers: Set<RuleIdentifier>
    /// The line in the source file where this command is defined.
    let line: Int
    /// The range of the command in the line (0-based).
    let range: Range<Int>?
    /// This command's modifier, if any.
    let modifier: Modifier?
    /// The comment following this command's `-` delimiter, if any.
    let trailingComment: String?

    /// Creates a command based on the specified parameters.
    ///
    /// - Parameters:
    ///   - action: This command's action.
    ///   - ruleIdentifiers: The identifiers for the rules associated with this command.
    ///   - line: The line in the source file where this command is defined.
    ///   - range: The range of the command in the line (0-based).
    ///   - modifier: This command's modifier, if any.
    ///   - trailingComment: The comment following this command's `-` delimiter, if any.
    init(
        action: Action,
        ruleIdentifiers: Set<RuleIdentifier> = [],
        line: Int = 0,
        range: Range<Int>? = nil,
        modifier: Modifier? = nil,
        trailingComment: String? = nil,
    ) {
        self.action = action
        self.ruleIdentifiers = ruleIdentifiers
        self.line = line
        self.range = range
        self.modifier = modifier
        self.trailingComment = trailingComment
    }

    /// Creates a command based on the specified parameters.
    ///
    /// - Parameters:
    ///   - commandString: The whole command string as found in the code.
    ///   - line: The line in the source file where this command is defined.
    ///   - range: The range of the command in the line (0-based).
    init(commandString: String, line: Int, range: Range<Int>) {
        let scanner = Scanner(string: commandString)
        _ = scanner.scanString("sm:")
        // (enable|disable)(:previous|:this|:next)
        guard let actionAndModifierString = scanner.scanUpToString(" ") else {
            self.init(action: .invalid, line: line, range: range)
            return
        }
        let actionAndModifierScanner = Scanner(string: actionAndModifierString)
        guard let actionString = actionAndModifierScanner.scanUpToString(":"),
              let action = Action(rawValue: actionString)
        else {
            self.init(action: .invalid, line: line, range: range)
            return
        }

        let rawRuleTexts = scanner.scanUpToString(Self.commentDelimiter) ?? ""
        var trailingComment: String?
        if scanner.isAtEnd {
            trailingComment = nil
        } else {
            // Store any text after the comment delimiter as the trailingComment.
            // The addition to currentIndex is to move past the delimiter
            trailingComment = String(
                scanner
                    .string[scanner.currentIndex...]
                    .dropFirst(Self.commentDelimiter.count),
            )
        }
        let ruleTexts = rawRuleTexts.components(separatedBy: .whitespacesAndNewlines).filter {
            let component = $0.trimmingCharacters(in: .whitespaces)
            return component.isNotEmpty && component != "*/"
        }

        let ruleIdentifiers = Set(ruleTexts.map(RuleIdentifier.init(_:)))

        // Modifier
        let hasModifier = actionAndModifierScanner.scanString(":") != nil
        let modifier: Modifier?
        if hasModifier {
            let modifierString = String(
                actionAndModifierScanner.string[actionAndModifierScanner.currentIndex...],
            )
            modifier = Modifier(rawValue: modifierString) ?? .invalid
        } else {
            modifier = nil
        }

        self.init(
            action: action,
            ruleIdentifiers: ruleIdentifiers,
            line: line,
            range: range,
            modifier: modifier,
            trailingComment: trailingComment,
        )
    }

    /// Expands the current command into its fully descriptive form without any modifiers.
    /// If the command doesn't have a modifier, it is returned as-is.
    ///
    /// - returns: The expanded commands.
    package func expand() -> [Self] {
        guard let modifier else {
            return [self]
        }
        switch modifier {
            case .previous:
                return [
                    Self(action: action, ruleIdentifiers: ruleIdentifiers, line: line - 1),
                    Self(
                        action: action.inverse(), ruleIdentifiers: ruleIdentifiers, line: line - 1,
                        range: 0 ..< Int.max,
                    ),
                ]
            case .this:
                return [
                    Self(action: action, ruleIdentifiers: ruleIdentifiers, line: line),
                    Self(
                        action: action.inverse(), ruleIdentifiers: ruleIdentifiers, line: line,
                        range: 0 ..< Int.max,
                    ),
                ]
            case .next:
                return [
                    Self(action: action, ruleIdentifiers: ruleIdentifiers, line: line + 1),
                    Self(
                        action: action.inverse(), ruleIdentifiers: ruleIdentifiers, line: line + 1,
                        range: 0 ..< Int.max,
                    ),
                ]
            case .invalid:
                return []
        }
    }
}
