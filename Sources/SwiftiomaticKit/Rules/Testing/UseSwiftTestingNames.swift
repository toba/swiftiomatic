import SwiftSyntax

/// Normalize Swift Testing `@Test` function names according to the configured `style`.
///
/// In Swift Testing, test methods are identified by the `@Test` attribute, not by a naming
/// convention, so the conventional `test` prefix is redundant. Two styles are offered:
///
/// - `.standardIdentifier` (default) — strip the `test` prefix, producing an idiomatic camelCase
///   identifier (`testFooBar` → `fooBar`). A backticked name keeps its backticks only when it
///   carries a space (`` `test foo bar` `` → `` `foo bar` ``); otherwise it becomes a plain
///   identifier (`` `testFooBar` `` → `fooBar`). The rename is skipped when the remainder would be
///   empty, start with a digit, be a Swift keyword, or collide with an existing identifier in
///   scope.
/// - `.rawIdentifier` — convert the camelCase name into a backtick-wrapped raw identifier whose
///   words are space-separated and lowercased (`testFooBar` → `` `foo bar` ``). A leading `test`
///   word is dropped. A backticked name is rewritten too when it carries spaces or single
///   underscores (`` `test_foo_bar` `` → `` `foo bar` ``), and it loses its backticks when one word
///   remains. A backticked camelCase name and a name with a double underscore are left untouched,
///   and so is a function whose `@Test` names the test explicitly (`@Test("foo bar")`). Swift
///   Testing derives an implicit display name from a raw identifier, and it rejects a test that
///   declares both names.
///
/// Lint: A warning is raised for `@Test` functions whose name does not match the configured style.
///
/// Rewrite: The function name is rewritten to the configured style.
final class UseSwiftTestingNames: StaticFormatRule<SwiftTestingNamesConfiguration>,
    @unchecked Sendable
{
    static let rewriteOrder = 910

    override class var group: ConfigurationGroup? { .testing }
    override class var defaultValue: SwiftTestingNamesConfiguration {
        var config = SwiftTestingNamesConfiguration()
        config.rewrite = false
        config.lint = .no
        return config
    }

    /// Per-file mutable state held as a typed lazy property on `Context` .
    final class State {
        var importsTesting = false
        var allIdentifiers = Set<String>()
    }

    private static let swiftKeywords: Set<String> = [
        "init", "deinit", "subscript", "nil", "true", "false", "self", "Self",
        "super", "class", "struct", "enum", "protocol", "extension", "func",
        "var", "let", "import", "return", "throw", "throws", "catch", "try",
        "if", "else", "for", "while", "do", "switch", "case", "default",
        "break", "continue", "fallthrough", "where", "guard", "in", "as", "is",
        "async", "await", "some", "any", "repeat", "defer", "typealias",
        "associatedtype", "operator", "precedencegroup", "inout", "static",
    ]

    // MARK: - Pre-scan

    static func willEnter(_ node: SourceFileSyntax, context: Context) {
        let state = context.swiftTestingTestCaseNamesState

        for stmt in node.statements {
            if let importDecl = stmt.item.as(ImportDeclSyntax.self),
                importDecl.path.first?.name.text == "Testing" { state.importsTesting = true }
        }
        for token in node.tokens(viewMode: .sourceAccurate) {
            if case let .identifier(name) = token.tokenKind { state.allIdentifiers.insert(name) }
        }
    }

    // MARK: - Static transform

    static func transform(
        _ node: FunctionDeclSyntax,
        original _: FunctionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        let state = context.swiftTestingTestCaseNamesState
        guard state.importsTesting,
              node.hasAttribute("Test", inModule: "Testing") else { return DeclSyntax(node) }

        guard case let .identifier(rawIdent) = node.name.tokenKind else { return DeclSyntax(node) }

        switch context.configuration[UseSwiftTestingNames.self].style {
            case .standardIdentifier:
                return standardIdentifierTransform(node, rawIdent: rawIdent, context: context)
            case .rawIdentifier:
                return rawIdentifierTransform(node, rawIdent: rawIdent, context: context)
        }
    }

    // MARK: - Standard identifier (strip `test` prefix)

    private static func standardIdentifierTransform(
        _ node: FunctionDeclSyntax,
        rawIdent: String,
        context: Context
    ) -> DeclSyntax {
        let state = context.swiftTestingTestCaseNamesState

        let isBackticked = rawIdent.hasPrefix("`") && rawIdent.hasSuffix("`")
        let bareName = isBackticked ? String(rawIdent.dropFirst().dropLast()) : rawIdent

        let lowerName = bareName.lowercased()
        guard lowerName.hasPrefix("test") else { return DeclSyntax(node) }

        let newIdentifier: String

        if isBackticked, bareName.dropFirst(4).hasPrefix(" ") {
            // `test feature works` stays a raw identifier. Only the leading word is redundant.
            let trimmed = String(bareName.dropFirst(5))
            guard !trimmed.isEmpty else { return DeclSyntax(node) }
            newIdentifier = "`\(trimmed)`"
        } else if isBackticked {
            // `testFeature` and `test_feature` carry no space, so the name becomes a plain
            // identifier once the prefix and any leading underscore go.
            var remainder = String(bareName.dropFirst(4))
            while remainder.hasPrefix("_") { remainder = String(remainder.dropFirst()) }
            guard let first = remainder.first, first.isLetter else { return DeclSyntax(node) }
            remainder = first.lowercased() + remainder.dropFirst()
            guard remainder.isBareIdentifier else { return DeclSyntax(node) }
            if Self.swiftKeywords.contains(remainder) { return DeclSyntax(node) }
            if state.allIdentifiers.contains(remainder) { return DeclSyntax(node) }
            newIdentifier = remainder
        } else {
            let afterTest = bareName.dropFirst(4)
            guard !afterTest.isEmpty, let first = afterTest.first else { return DeclSyntax(node) }
            if first.isNumber { return DeclSyntax(node) }

            let remainder = first.lowercased() + afterTest.dropFirst()
            if Self.swiftKeywords.contains(remainder) { return DeclSyntax(node) }
            if state.allIdentifiers.contains(remainder) { return DeclSyntax(node) }
            newIdentifier = remainder
        }

        return rename(
            node,
            to: newIdentifier,
            message: .removeTestPrefix(oldName: bareName),
            context: context)
    }

    // MARK: - Raw identifier (backtick name with spaces)

    private static func rawIdentifierTransform(
        _ node: FunctionDeclSyntax,
        rawIdent: String,
        context: Context
    ) -> DeclSyntax {
        // A raw identifier gives the test an implicit display name, and Swift Testing rejects a
        // test that carries both an implicit and an explicit one.
        guard !hasDisplayName(node) else { return DeclSyntax(node) }

        let isBackticked = rawIdent.hasPrefix("`") && rawIdent.hasSuffix("`")
        let bareName = isBackticked ? String(rawIdent.dropFirst().dropLast()) : rawIdent

        if isBackticked, bareName.contains(" ") {
            // A name that already carries spaces is a raw identifier phrase. Only a leading
            // `test` word is redundant, and the case of every other word is the author's choice.
            guard let phrase = Self.droppingLeadingTestWord(bareName) else {
                return DeclSyntax(node)
            }
            return rename(
                node,
                to: "`\(phrase)`",
                message: .useRawIdentifier(oldName: bareName, phrase: phrase),
                context: context)
        }

        // A backticked camelCase name carries no separator to split on, and a double underscore
        // marks a name the author spells deliberately. Leave both alone.
        if isBackticked, !bareName.contains("_") || bareName.contains("__") {
            return DeclSyntax(node)
        }

        var words = Self.splitIdentifierWords(bareName)
        if words.first?.lowercased() == "test" { words.removeFirst() }

        let phrase = words.map { $0.lowercased() }.joined(separator: " ")
        // Raw identifiers may not be empty or purely numeric — require at least one letter.
        guard phrase.contains(where: { $0.isLetter }) else { return DeclSyntax(node) }

        guard phrase.contains(" ") else {
            // A single-word phrase needs no backticks. An unbackticked name already has that
            // form, so only a backticked one changes.
            guard isBackticked,
                  phrase.isBareIdentifier,
                  !Self.swiftKeywords.contains(phrase),
                  !context.swiftTestingTestCaseNamesState.allIdentifiers.contains(phrase)
            else { return DeclSyntax(node) }

            return rename(
                node,
                to: phrase,
                message: .useIdentifier(oldName: bareName, newName: phrase),
                context: context)
        }

        let newIdentifier = "`\(phrase)`"
        guard newIdentifier != rawIdent else { return DeclSyntax(node) }

        return rename(
            node,
            to: newIdentifier,
            message: .useRawIdentifier(oldName: bareName, phrase: phrase),
            context: context)
    }

    /// Drops a leading `test` word from a space-separated raw identifier phrase.
    ///
    /// Returns `nil` when the first word is not `test` , or when no word with a letter follows it.
    private static func droppingLeadingTestWord(_ phrase: String) -> String? {
        var words = phrase.split(separator: " ").map(String.init)
        guard words.first?.lowercased() == "test" else { return nil }
        words.removeFirst()

        let remainder = words.joined(separator: " ")
        guard remainder.contains(where: { $0.isLetter }) else { return nil }
        return remainder
    }

    /// Emits `message` and returns `node` with `newIdentifier` as its name.
    private static func rename(
        _ node: FunctionDeclSyntax,
        to newIdentifier: String,
        message: Finding.Message,
        context: Context
    ) -> DeclSyntax {
        Self.diagnose(message, on: node.name, context: context)
        return DeclSyntax(
            node.with(\.name, node.name.with(\.tokenKind, .identifier(newIdentifier))))
    }

    /// Reports whether the `@Test` attribute on `node` names the test explicitly.
    ///
    /// Swift Testing takes the display name from the first unlabeled argument, and only when that
    /// argument is a string literal. `@Test(.tags(.fast))` and `@Test(arguments: [1, 2])` carry no
    /// display name.
    private static func hasDisplayName(_ node: FunctionDeclSyntax) -> Bool {
        guard let attribute = node.attributes.attribute(named: "Test"),
            let arguments = attribute.arguments?.as(LabeledExprListSyntax.self),
            let first = arguments.first,
            first.label == nil else { return false }
        return first.expression.is(StringLiteralExprSyntax.self)
    }

    /// Splits a camelCase / PascalCase identifier into its constituent words, treating underscores
    /// and letter↔digit transitions as boundaries and keeping acronym runs together (`URLSession` →
    /// `["URL", "Session"]`).
    private static func splitIdentifierWords(_ identifier: String) -> [String] {
        let chars = Array(identifier)
        var words: [String] = []
        var current = ""

        for (i, c) in chars.enumerated() {
            if c == "_" {
                if !current.isEmpty {
                    words.append(current)
                    current = ""
                }
                continue
            }
            let prev = i > 0 ? chars[i - 1] : nil
            let next = i + 1 < chars.count ? chars[i + 1] : nil
            let isBoundary: Bool

            if let prev {
                if c.isUppercase, prev.isLowercase || prev.isNumber {
                    isBoundary = true
                } else if c.isUppercase, prev.isUppercase, let next, next.isLowercase {
                    isBoundary = true  // end of an acronym run, e.g. `URLSession`
                } else if c.isNumber, prev.isLetter {
                    isBoundary = true
                } else if c.isLetter, prev.isNumber {
                    isBoundary = true
                } else {
                    isBoundary = false
                }
            } else {
                isBoundary = false
            }
            if isBoundary, !current.isEmpty {
                words.append(current)
                current = ""
            }
            current.append(c)
        }
        if !current.isEmpty { words.append(current) }
        return words
    }
}

fileprivate extension Finding.Message {
    static func removeTestPrefix(oldName: String) -> Finding.Message {
        "remove 'test' prefix from '@Test' function '\(oldName)'"
    }

    static func useRawIdentifier(oldName: String, phrase: String) -> Finding.Message {
        "rename '@Test' function '\(oldName)' to raw identifier '`\(phrase)`'"
    }

    static func useIdentifier(oldName: String, newName: String) -> Finding.Message {
        "rename '@Test' function '\(oldName)' to '\(newName)'"
    }
}

// MARK: - Configuration

package struct SwiftTestingNamesConfiguration: SyntaxRuleValue {
    /// How `@Test` function names should be normalized.
    package enum Style: String, Codable, Sendable {
        /// Strip the redundant `test` prefix, producing a camelCase identifier.
        case standardIdentifier
        /// Convert the camelCase name into a backtick-wrapped raw identifier with spaces.
        case rawIdentifier
    }

    package var rewrite = true
    package var lint: Lint = .warn
    /// The identifier style to normalize `@Test` function names to.
    package var style: Style = .standardIdentifier

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) {
            self.rewrite = rewrite
        }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }
        style = try container.decodeIfPresent(Style.self, forKey: .style) ?? .standardIdentifier
    }
}
