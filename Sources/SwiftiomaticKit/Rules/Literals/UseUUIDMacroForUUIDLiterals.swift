import Foundation
import SwiftSyntax

/// Replace force-unwrapped `UUID(uuidString:)` initializers with a configured UUID macro.
///
/// A force-unwrapped `UUID(uuidString: "...")!` checks the literal at run time and crashes when the
/// literal is not a valid UUID. A UUID macro such as `#UUID("...")` checks the literal at compile
/// time and removes the force unwrap.
///
/// The rule converts only a plain string literal. It leaves an interpolated string, a
/// concatenation and a variable alone. It adds the configured module import when the file does not
/// import that module yet.
///
/// The rule does nothing until `useUUIDMacroForUUIDLiterals.macroName` is set. Set
/// `useUUIDMacroForUUIDLiterals.moduleName` to add the import.
///
/// Lint: A warning is raised for each `UUID(uuidString: "...")!` that the rule can convert.
///
/// Rewrite: The force-unwrapped initializer is replaced with the configured macro.
final class UseUUIDMacroForUUIDLiterals: StaticFormatRule<UUIDMacroConfiguration>,
    @unchecked Sendable
{
    static let rewriteOrder = 1015

    override class var group: ConfigurationGroup? { .literals }

    override class var defaultValue: UUIDMacroConfiguration {
        var config = UUIDMacroConfiguration()
        config.rewrite = false
        config.lint = .no
        return config
    }

    /// Per-file mutable state held as a typed lazy property on `Context` .
    final class State {
        /// Whether the rule replaced an initializer. This drives the import addition.
        var madeReplacements = false
        /// Whether the file already imports the configured module.
        var hasModuleImport = false
    }

    // MARK: - Pre-scan

    static func willEnter(_ node: SourceFileSyntax, context: Context) {
        let state = context.uuidMacroState
        guard let moduleName = context.configuration[Self.self].moduleName else { return }

        state.hasModuleImport = node.statements.contains { statement in
            statement.item.as(ImportDeclSyntax.self)?.path.first?.name.text == moduleName
        }
    }

    // MARK: - File level: add the import

    static func transform(
        _ node: SourceFileSyntax,
        original _: SourceFileSyntax,
        parent _: Syntax?,
        context: Context
    ) -> SourceFileSyntax {
        let state = context.uuidMacroState
        let config = context.configuration[Self.self]

        guard config.macroName != nil,
              state.madeReplacements,
              !state.hasModuleImport,
              let moduleName = config.moduleName,
              !moduleName.isEmpty else { return node }

        let importDecl = ImportDeclSyntax(
            importKeyword: .keyword(.import, trailingTrivia: .space),
            path: ImportPathComponentListSyntax([
                ImportPathComponentSyntax(name: .identifier(moduleName))
            ]))
        var importItem = CodeBlockItemSyntax(item: .decl(DeclSyntax(importDecl)))
        var statements = Array(node.statements)

        // Insert after the last leading import, or at the top when the file has no import.
        let insertIndex = statements.prefix { $0.item.is(ImportDeclSyntax.self) }.count

        if insertIndex > 0 {
            importItem.leadingTrivia = .newline
        } else if insertIndex < statements.count {
            importItem.leadingTrivia = statements[insertIndex].leadingTrivia
            statements[insertIndex].leadingTrivia = .newlines(2)
        }
        statements.insert(importItem, at: insertIndex)

        var result = node
        result.statements = CodeBlockItemListSyntax(statements)
        return result
    }

    // MARK: - Expression level: replace UUID(uuidString: "...")!

    static func transform(
        _ node: ForceUnwrapExprSyntax,
        original _: ForceUnwrapExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        guard let macroName = context.configuration[Self.self].macroName,
              !macroName.isEmpty,
              let call = node.expression.as(FunctionCallExprSyntax.self),
              call.trailingClosure == nil,
              call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "UUID",
              let argument = call.arguments.first,
              call.arguments.count == 1,
              argument.label?.text == "uuidString",
              let literal = argument.expression.as(StringLiteralExprSyntax.self),
              literal.segments.allSatisfy({ $0.is(StringSegmentSyntax.self) })
        else { return ExprSyntax(node) }

        Self.diagnose(.replaceWithUUIDMacro, on: node, context: context)
        context.uuidMacroState.madeReplacements = true

        let bareName = macroName.hasPrefix("#") ? String(macroName.dropFirst()) : macroName

        let macroExpr = MacroExpansionExprSyntax(
            pound: .poundToken(),
            macroName: .identifier(bareName),
            leftParen: call.leftParen,
            arguments: LabeledExprListSyntax([LabeledExprSyntax(expression: ExprSyntax(literal))]),
            rightParen: call.rightParen)

        var result = ExprSyntax(macroExpr)
        result.leadingTrivia = node.leadingTrivia
        result.trailingTrivia = node.trailingTrivia
        return result
    }
}

fileprivate extension Finding.Message {
    static let replaceWithUUIDMacro: Finding.Message =
        "replace force-unwrapped 'UUID(uuidString:)' with UUID macro"
}

// MARK: - Configuration

package struct UUIDMacroConfiguration: SyntaxRuleValue {
    package var rewrite = true
    package var lint: Lint = .warn
    /// Name of the UUID macro that replaces `UUID(uuidString:)!` , for example `"UUID"` or
    /// `"#UUID"` . When `nil` , the rule is inactive.
    package var macroName: String?
    /// Module that defines `macroName` . The rewrite adds an `import` of it. When `nil` , the rule
    /// adds no import.
    package var moduleName: String?

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) {
            self.rewrite = rewrite
        }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }
        macroName = try container.decodeIfPresent(String.self, forKey: .macroName)
        moduleName = try container.decodeIfPresent(String.self, forKey: .moduleName)
    }
}
