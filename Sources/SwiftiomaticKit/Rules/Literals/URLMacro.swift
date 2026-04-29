import SwiftSyntax

/// Replace force-unwrapped `URL(string:)` initializers with a configured URL macro.
///
/// When configured with a macro name like `#URL` and module like `URLFoundation`, this rule
/// converts `URL(string: "https://example.com")!` to `#URL("https://example.com")` and adds
/// the module import if not already present.
///
/// Only simple string literals are converted — string interpolations, concatenations, and
/// non-literal expressions are left alone. The `URL(string:relativeTo:)` and
/// `URL(fileURLWithPath:)` initializers are not affected.
///
/// Requires configuration via `urlMacro.macroName` and `urlMacro.moduleName`.
///
/// Lint: A warning is raised for each `URL(string: "...")!` that can be converted.
///
/// Rewrite: The force-unwrapped URL initializer is replaced with the configured macro.
final class URLMacro: RewriteSyntaxRule<URLMacroConfiguration>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .literals }

    override class var defaultValue: URLMacroConfiguration {
        var config = URLMacroConfiguration()
        config.rewrite = false
        config.lint = .no
        return config
    }

    /// Per-file mutable state held in `Context.ruleState`.
    final class State {
        /// Whether any replacements were made (drives import addition).
        var madeReplacements = false
        /// Whether the configured module is already imported.
        var hasModuleImport = false
    }

    // MARK: - Pre-scan

    static func willEnter(_ node: SourceFileSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        let config = context.configuration[Self.self]
        guard let moduleName = config.moduleName else { return }
        for stmt in node.statements {
            if let importDecl = stmt.item.as(ImportDeclSyntax.self),
                importDecl.path.first?.name.text == moduleName
            {
                state.hasModuleImport = true
                break
            }
        }
    }

    // MARK: - File-level: add import after processing children

    static func transform(
        _ node: SourceFileSyntax,
        parent _: Syntax?,
        context: Context
    ) -> SourceFileSyntax {
        let state = context.ruleState(for: Self.self) { State() }
        let config = context.configuration[Self.self]
        guard config.macroName != nil else { return node }

        guard state.madeReplacements,
            !state.hasModuleImport,
            let moduleName = config.moduleName,
            !moduleName.isEmpty
        else {
            return node
        }

        // Build the import declaration
        let importDecl = ImportDeclSyntax(
            importKeyword: .keyword(.import, trailingTrivia: .space),
            path: ImportPathComponentListSyntax([
                ImportPathComponentSyntax(name: .identifier(moduleName))
            ]))

        // Add it as the first statement with a trailing blank line
        let importItem = CodeBlockItemSyntax(
            leadingTrivia: [],
            item: .decl(DeclSyntax(importDecl)),
            trailingTrivia: [])

        var statements = Array(node.statements)

        // Insert before the first non-import statement, or at the top
        var insertIndex = 0
        for (i, stmt) in statements.enumerated() {
            if stmt.item.is(ImportDeclSyntax.self) {
                insertIndex = i + 1
            } else {
                break
            }
        }

        var importWithTrivia = importItem
        if insertIndex > 0 {
            // Inserting after existing imports: just a newline to continue the import block
            importWithTrivia.leadingTrivia = .newline
        } else if insertIndex < statements.count {
            // Inserting at top (no existing imports): take the first statement's trivia
            importWithTrivia.leadingTrivia = statements[insertIndex].leadingTrivia
            // Add a blank line between the new import and the next statement
            statements[insertIndex].leadingTrivia = .newlines(2)
        }

        statements.insert(importWithTrivia, at: insertIndex)

        var result = node
        result.statements = CodeBlockItemListSyntax(statements)
        return result
    }

    // MARK: - Expression-level: replace URL(string: "...")!

    static func transform(
        _ node: ForceUnwrapExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        let config = context.configuration[Self.self]
        guard let macroName = config.macroName else { return ExprSyntax(node) }

        // The inner expression must be a function call
        guard let call = node.expression.as(FunctionCallExprSyntax.self) else {
            return ExprSyntax(node)
        }

        // Called expression must be `URL`
        guard let declRef = call.calledExpression.as(DeclReferenceExprSyntax.self),
            declRef.baseName.text == "URL"
        else {
            return ExprSyntax(node)
        }

        // Must have exactly one argument labeled `string:`
        let args = Array(call.arguments)
        guard args.count == 1,
            let label = args[0].label,
            label.text == "string"
        else {
            return ExprSyntax(node)
        }

        // The argument value must be a simple string literal (no interpolation)
        guard let stringLiteral = args[0].expression.as(StringLiteralExprSyntax.self),
            isSimpleStringLiteral(stringLiteral)
        else {
            return ExprSyntax(node)
        }

        Self.diagnose(.replaceWithURLMacro, on: node, context: context)

        let state = context.ruleState(for: Self.self) { State() }
        state.madeReplacements = true

        // Strip the `#` prefix from macroName if present for the token
        let bareName = macroName.hasPrefix("#") ? String(macroName.dropFirst()) : macroName

        // Build #URL("...") as a MacroExpansionExprSyntax
        let macroExpr = MacroExpansionExprSyntax(
            pound: .poundToken(),
            macroName: .identifier(bareName),
            leftParen: call.leftParen,
            arguments: LabeledExprListSyntax([
                LabeledExprSyntax(expression: ExprSyntax(stringLiteral))
            ]),
            rightParen: call.rightParen)

        var result = ExprSyntax(macroExpr)
        result.leadingTrivia = node.leadingTrivia
        result.trailingTrivia = node.trailingTrivia
        return result
    }

    // MARK: - Helpers

    /// Returns `true` if the string literal contains only plain text (no interpolation segments).
    private static func isSimpleStringLiteral(_ literal: StringLiteralExprSyntax) -> Bool {
        for segment in literal.segments {
            if !segment.is(StringSegmentSyntax.self) {
                return false
            }
        }
        return true
    }
}

extension Finding.Message {
    fileprivate static let replaceWithURLMacro: Finding.Message =
        "replace force-unwrapped 'URL(string:)' with URL macro"
}

// MARK: - Configuration

package struct URLMacroConfiguration: SyntaxRuleValue {
    package var rewrite = true
    package var lint: Lint = .warn
    /// Name of the URL macro to substitute for `URL(string:)!`, e.g. `"URL"`
    /// or `"#URL"`. When `nil`, the rule is inactive.
    package var macroName: String?
    /// Module that defines `macroName`, used to insert an `import` statement
    /// when applying the rewrite. When `nil`, no import is added.
    package var moduleName: String?

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) {
            self.rewrite = rewrite
        }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }
        self.macroName = try container.decodeIfPresent(String.self, forKey: .macroName)
        self.moduleName = try container.decodeIfPresent(String.self, forKey: .moduleName)
    }
}
