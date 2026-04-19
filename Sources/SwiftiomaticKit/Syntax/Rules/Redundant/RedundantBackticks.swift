import SwiftSyntax

/// Remove unnecessary backticks around identifiers.
///
/// Backticks are required when an identifier is a Swift reserved keyword used in a position
/// that expects an identifier. They are redundant when the identifier is:
/// - Not a keyword at all (e.g., `` `myFunc` `` → `myFunc`)
/// - A keyword used after `.` in member access (e.g., `Foo.`default`` → `Foo.default`)
/// - A keyword used as a function argument label (e.g., `func foo(`default`: Int)` → `func foo(default: Int)`)
///
/// Lint: If unnecessary backticks are found, a finding is raised.
///
/// Format: The backticks are removed.
final class RedundantBackticks: RewriteSyntaxRule {
    override class var group: ConfigurationGroup? { .redundancies }

    /// Swift reserved keywords that always require backticks when used as identifiers
    /// (unless in a special context like after `.` or as argument labels).
    private static let swiftKeywords: Set<String> = [
        "as", "associatedtype", "break", "case", "catch", "class", "continue",
        "default", "defer", "deinit", "do", "else", "enum", "extension", "fallthrough",
        "false", "fileprivate", "for", "func", "guard", "if", "import", "in", "init",
        "inout", "internal", "is", "let", "nil", "operator", "precedencegroup", "private",
        "protocol", "public", "repeat", "rethrows", "return", "self", "Self", "static",
        "struct", "subscript", "super", "switch", "throw", "throws", "true", "try",
        "typealias", "var", "where", "while", "await", "consume", "discard",
    ]

    /// Identifiers that need backticks after `.` because they have special meaning.
    private static let specialAfterDot: Set<String> = ["init", "self", "Type"]

    /// Identifiers that need backticks after `::` (module selector).
    private static let specialAfterModuleSelector: Set<String> = ["init", "deinit", "subscript"]

    /// Keywords that need backticks even as argument labels (expression keywords + binding specifiers).
    private static let keywordsRequiringBackticksAsLabels: Set<String> = [
        "let", "var", "true", "false", "nil", "self", "super",
        "Any", "throws", "rethrows", "try", "as", "is", "in",
    ]

    /// Contextual keywords that need backticks in declaration name position
    /// (variable binding, function name, type name) because the parser would
    /// interpret them as declaration introducers.
    private static let contextualKeywordsInDeclPosition: Set<String> = [
        "actor", "macro", "package", "nonisolated",
    ]

    /// Identifiers that should never have backticks removed.
    private static let neverUnescaped: Set<String> = ["_", "$"]

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        guard case .identifier(let text) = token.tokenKind,
            text.hasPrefix("`"), text.hasSuffix("`"), text.count > 2
        else {
            return token
        }

        let bareName = String(text.dropFirst().dropLast())

        // Raw identifiers (contain spaces, non-identifier characters) always need backticks.
        guard isValidBareIdentifier(bareName) else { return token }

        // `_` and `$` always need backticks.
        guard !Self.neverUnescaped.contains(bareName) else { return token }

        guard !backticksRequired(for: bareName, token: token) else { return token }

        diagnose(.removeRedundantBackticks(name: bareName), on: token)
        return token.with(\.tokenKind, .identifier(bareName))
    }

    // MARK: - Context analysis

    /// Determines if backticks are required for the given bare name at the given token position.
    private func backticksRequired(for bareName: String, token: TokenSyntax) -> Bool {
        // After `.` (member access): most keywords become identifiers.
        if isAfterDot(token) {
            return Self.specialAfterDot.contains(bareName)
        }

        // After `::` (module selector): most keywords become identifiers.
        if isAfterModuleSelector(token) {
            return Self.specialAfterModuleSelector.contains(bareName)
        }

        // In function/init/subscript argument label position: most keywords can be used
        // without backticks, but expression keywords and binding specifiers still need them.
        if isArgumentLabel(token) {
            return Self.keywordsRequiringBackticksAsLabels.contains(bareName)
        }

        // Accessor keywords in accessor contexts need backticks regardless of keyword status.
        if isAccessorKeyword(bareName) && isInAccessorContext(token) {
            return true
        }

        // Not a reserved keyword — check contextual keyword cases.
        if !Self.swiftKeywords.contains(bareName) {
            // `Any` in enum case declarations needs backticks.
            if bareName == "Any" && isInEnumCaseDecl(token) {
                return true
            }

            // `Type` inside a type declaration needs backticks (metatype conflict).
            if bareName == "Type" && isInsideTypeDeclaration(token) {
                return true
            }

            // Contextual keywords like `actor` need backticks in declaration name position
            // (variable binding, function name) where the parser would see them as keywords.
            if Self.contextualKeywordsInDeclPosition.contains(bareName)
                && isDeclarationName(token)
            {
                return true
            }

            return false
        }

        // From here: bareName is a reserved keyword in a non-special position.

        // `self` in variable binding position (e.g., `let `self`: URL`): needs backticks.
        if bareName == "self" && isPropertyOrVariableBinding(token) {
            return true
        }

        // `Self` and `Any` in type annotation position don't need backticks.
        if bareName == "Self" || bareName == "Any",
            isInTypeAnnotationOrReturnPosition(token)
        {
            return false
        }

        // All other reserved keywords need backticks.
        return true
    }

    // MARK: - Position checks

    /// Token is after a `.` in member access (expression or type).
    private func isAfterDot(_ token: TokenSyntax) -> Bool {
        // Expression member access: Foo.bar
        if let declRef = token.parent?.as(DeclReferenceExprSyntax.self),
            declRef.baseName.id == token.id
        {
            let grandparent = declRef.parent
            if grandparent?.is(MemberAccessExprSyntax.self) == true
                || grandparent?.is(KeyPathPropertyComponentSyntax.self) == true
            {
                return true
            }
        }
        // Type member access: Foo.Type, Foo.Protocol
        if let memberType = token.parent?.as(MemberTypeSyntax.self),
            memberType.name.id == token.id
        {
            return true
        }
        return false
    }

    /// Token is after a `::` module selector operator.
    private func isAfterModuleSelector(_ token: TokenSyntax) -> Bool {
        guard let prevToken = token.previousToken(viewMode: .sourceAccurate) else {
            return false
        }
        return prevToken.tokenKind == .colonColon
            || prevToken.text == "::"
    }

    /// Token is a function/init/subscript parameter label (firstName or secondName with a following `:`).
    private func isArgumentLabel(_ token: TokenSyntax) -> Bool {
        if let param = token.parent?.as(FunctionParameterSyntax.self) {
            return param.firstName.id == token.id || param.secondName?.id == token.id
        }
        if let param = token.parent?.as(EnumCaseParameterSyntax.self) {
            return param.firstName?.id == token.id || param.secondName?.id == token.id
        }
        return false
    }

    /// Token is `Self` or `Any` in a type annotation (after `:` or `->`) position.
    private func isInTypeAnnotationOrReturnPosition(_ token: TokenSyntax) -> Bool {
        // Check if this identifier is used as a type name.
        // The token would be inside an IdentifierTypeSyntax that's a child of
        // TypeAnnotationSyntax or ReturnClauseSyntax.
        guard let identType = token.parent?.as(IdentifierTypeSyntax.self) else {
            return false
        }
        let context = identType.parent
        return context?.is(TypeAnnotationSyntax.self) == true
            || context?.is(ReturnClauseSyntax.self) == true
            || context?.is(FunctionParameterSyntax.self) == true
    }

    /// Token is in a property or variable binding pattern (e.g., `let `self`: URL`).
    private func isPropertyOrVariableBinding(_ token: TokenSyntax) -> Bool {
        return token.parent?.is(IdentifierPatternSyntax.self) == true
    }

    /// Token is a declaration name (variable binding, function name, type name, enum case).
    private func isDeclarationName(_ token: TokenSyntax) -> Bool {
        if token.parent?.is(IdentifierPatternSyntax.self) == true { return true }
        if let funcDecl = token.parent?.as(FunctionDeclSyntax.self),
            funcDecl.name.id == token.id
        {
            return true
        }
        if let classDecl = token.parent?.as(ClassDeclSyntax.self),
            classDecl.name.id == token.id
        {
            return true
        }
        if let structDecl = token.parent?.as(StructDeclSyntax.self),
            structDecl.name.id == token.id
        {
            return true
        }
        if let enumDecl = token.parent?.as(EnumDeclSyntax.self),
            enumDecl.name.id == token.id
        {
            return true
        }
        if let actorDecl = token.parent?.as(ActorDeclSyntax.self),
            actorDecl.name.id == token.id
        {
            return true
        }
        return false
    }

    /// Token is inside a type's member block (not the type's own name).
    private func isInsideTypeDeclaration(_ token: TokenSyntax) -> Bool {
        var current: Syntax? = Syntax(token)
        while let parent = current?.parent {
            // A MemberBlockSyntax means we're inside a type body.
            if parent.is(MemberBlockSyntax.self) {
                return true
            }
            // Stop at source file level.
            if parent.is(SourceFileSyntax.self) {
                return false
            }
            current = parent
        }
        return false
    }

    /// Token is the name in an enum case declaration.
    private func isInEnumCaseDecl(_ token: TokenSyntax) -> Bool {
        return token.parent?.is(EnumCaseElementSyntax.self) == true
    }

    /// Whether the name is an accessor keyword that becomes reserved in accessor contexts.
    private func isAccessorKeyword(_ name: String) -> Bool {
        switch name {
        case "get", "set", "willSet", "didSet", "_modify": return true
        default: return false
        }
    }

    /// Token is inside an accessor block (computed property, subscript).
    private func isInAccessorContext(_ token: TokenSyntax) -> Bool {
        var current: Syntax? = Syntax(token)
        while let parent = current?.parent {
            if parent.is(AccessorBlockSyntax.self) {
                return true
            }
            if parent.is(FunctionDeclSyntax.self) || parent.is(ClosureExprSyntax.self) {
                return false
            }
            current = parent
        }
        return false
    }

    /// Checks if a bare name is a valid Swift identifier (no spaces, starts with
    /// letter/underscore, etc).
    private func isValidBareIdentifier(_ name: String) -> Bool {
        guard let first = name.unicodeScalars.first else { return false }
        guard first == "_" || first.properties.isXIDStart else { return false }
        return name.unicodeScalars.dropFirst().allSatisfy {
            $0 == "_" || $0.properties.isXIDContinue
        }
    }
}

extension Finding.Message {
    fileprivate static func removeRedundantBackticks(name: String) -> Finding.Message {
        "remove unnecessary backticks around '\(name)'"
    }
}
