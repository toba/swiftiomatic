import Foundation
import SwiftSyntax

/// Check for a framework with `#if canImport(...)`, not with `#if os(...)`.
///
/// An `#if os(...)` block that holds only an `import` uses the platform as a stand-in for the
/// framework. `canImport` states the real question. It also keeps working when the framework comes
/// to a new platform, such as UIKit on visionOS or Mac Catalyst.
///
/// The rule fires on a block whose conditions are made only of `os(...)` checks and whose branches
/// hold only `import` declarations. An `#else` or `#elseif` branch marks a platform split, such as
/// AppKit on macOS and UIKit elsewhere. When the file names an `NS` or `UI` type outside any `#if`
/// block, the file depends on a type both frameworks spell, so the split stays and the rule is
/// silent. When every such type sits inside its own `#if` , `#if canImport(UIKit)` with
/// `#elseif canImport(AppKit)` states the need.
///
/// Put the UIKit check first. `canImport(AppKit)` is true on Mac Catalyst, so an AppKit-first split
/// picks AppKit there, but a Catalyst app uses UIKit. To test for AppKit first, write
/// `#if canImport(AppKit) && !targetEnvironment(macCatalyst)` .
///
/// The rule also fires on a block that holds code, when its `os(...)` checks name exactly the
/// platforms that ship a framework the block imports. `#if os(macOS)` around `import AppKit` is one
/// example. The rule stays silent when the check names fewer platforms than the framework ships on,
/// when the block imports no such framework, and when an `#else` or `#elseif` branch imports
/// another platform framework.
///
/// Keep `#if os(...)` when the code depends on the behavior of a platform, not on a framework. An
/// example is a window or file-system behavior that only macOS has. Also keep it when a Mac
/// Catalyst build must skip the code, because `canImport(UIKit)` is true there. The rule cannot see
/// these reasons, so suppress the finding in such a block.
///
/// Lint: An `#if os(...)` block that guards only framework imports raises a warning. An
/// `#if os(...)` block whose platforms match a framework it imports raises a warning.
final class UseCanImportNotOSCheck: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: IfConfigDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let first = node.clauses.first,
              first.condition != nil,
              node.clauses.allSatisfy(isOSImportClause)
        else {
            if let framework = frameworkMatchingPlatforms(node) {
                diagnose(.checkFramework(framework), on: node)
            }
            return .visitChildren
        }

        if node.clauses.count > 1, namesPlatformTypeOutsideConditions(node.root) {
            return .visitChildren
        }
        diagnose(.useCanImport, on: node)
        return .visitChildren
    }

    /// Whether the clause has an `os(...)` -only condition, or none for `#else` , and a body made
    /// only of `import` declarations
    private func isOSImportClause(_ clause: IfConfigClauseSyntax) -> Bool {
        if let condition = clause.condition, !isOSOnly(condition) { return false }
        guard case let .statements(items)? = clause.elements, !items.isEmpty else { return false }
        return items.allSatisfy { $0.item.is(ImportDeclSyntax.self) }
    }

    /// The platforms that ship each platform framework.
    private static let frameworkPlatforms: [String: Set<String>] = [
        "AppKit": ["macOS"],
        "Cocoa": ["macOS"],
        "Quartz": ["macOS"],
        "QuickLook": ["macOS"],
        "UIKit": ["iOS", "tvOS", "visionOS"],
        "WatchKit": ["watchOS"],
    ]

    /// The framework that the first clause imports and whose platforms the first clause's condition
    /// names exactly, or `nil` when there is none.
    ///
    /// Another branch that imports a platform framework marks a platform split, so this returns
    /// `nil` for it.
    private func frameworkMatchingPlatforms(_ node: IfConfigDeclSyntax) -> String? {
        guard let first = node.clauses.first,
              let condition = first.condition,
              let platforms = osNames(condition),
              let framework = importedModules(first).first(where: {
                  Self.frameworkPlatforms[$0] == platforms
              }) else { return nil }

        let splits = node.clauses.dropFirst().lazy.contains { clause in
            importedModules(clause).contains { Self.frameworkPlatforms[$0] != nil }
        }
        return splits ? nil : framework
    }

    /// The modules that the clause imports at its top level.
    private func importedModules(_ clause: IfConfigClauseSyntax) -> [String] {
        guard case let .statements(items)? = clause.elements else { return [] }
        return items.compactMap { $0.item.as(ImportDeclSyntax.self)?.path.first?.name.text }
    }

    /// The platforms that a condition names, when the condition joins only `os(...)` checks with
    /// `||`.
    private func osNames(_ expr: ExprSyntax) -> Set<String>? {
        if let call = expr.as(FunctionCallExprSyntax.self) {
            guard call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "os",
                  let argument = call.arguments.firstAndOnly?.expression
                      .as(DeclReferenceExprSyntax.self) else { return nil }
            return [argument.baseName.text]
        }
        if let tuple = expr.as(TupleExprSyntax.self), let only = tuple.elements.firstAndOnly {
            return osNames(only.expression)
        }

        if let infix = expr.as(InfixOperatorExprSyntax.self) {
            guard isOr(infix.operator),
                  let left = osNames(infix.leftOperand),
                  let right = osNames(infix.rightOperand) else { return nil }
            return left.union(right)
        }
        if let sequence = expr.as(SequenceExprSyntax.self) {
            var names: Set<String> = []

            for (index, element) in sequence.elements.enumerated() {
                if index.isMultiple(of: 2) {
                    guard let found = osNames(element) else { return nil }
                    names.formUnion(found)
                } else if !isOr(element) { return nil }
            }
            return names
        }
        return nil
    }

    private func isOr(_ expr: ExprSyntax) -> Bool {
        expr.as(BinaryOperatorExprSyntax.self)?.operator.text == "||"
    }

    /// Whether the file names an `NS` or `UI` type outside every `#if` block
    private func namesPlatformTypeOutsideConditions(_ root: Syntax) -> Bool {
        root.tokens(viewMode: .sourceAccurate).contains { token in
            guard case .identifier = token.tokenKind, Self.isPlatformTypeName(token.text)
            else { return false }
            return token.ancestorOrSelf(mapping: { $0.as(IfConfigDeclSyntax.self) }) == nil
        }
    }

    private static func isPlatformTypeName(_ name: String) -> Bool {
        guard name.hasPrefix("NS") || name.hasPrefix("UI") else { return false }
        return name.dropFirst(2).first?.isUppercase == true
    }

    /// Reports whether the condition combines only `os(...)` checks with `!`, `&&`, `||` and
    /// parentheses.
    private func isOSOnly(_ expr: ExprSyntax) -> Bool {
        if let call = expr.as(FunctionCallExprSyntax.self) {
            return call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "os"
        }

        if let prefix = expr.as(PrefixOperatorExprSyntax.self) {
            return prefix.operator.text == "!" && isOSOnly(prefix.expression)
        }

        if let tuple = expr.as(TupleExprSyntax.self), let only = tuple.elements.firstAndOnly {
            return isOSOnly(only.expression)
        }

        if let infix = expr.as(InfixOperatorExprSyntax.self) {
            return isLogical(infix.operator) && isOSOnly(infix.leftOperand)
                && isOSOnly(infix.rightOperand)
        }
        if let sequence = expr.as(SequenceExprSyntax.self) {
            return sequence.elements.enumerated().allSatisfy { index, element in
                index.isMultiple(of: 2) ? isOSOnly(element) : isLogical(element)
            }
        }
        return false
    }

    private func isLogical(_ expr: ExprSyntax) -> Bool {
        guard let op = expr.as(BinaryOperatorExprSyntax.self) else { return false }
        return op.operator.text == "&&" || op.operator.text == "||"
    }
}

fileprivate extension Finding.Message {
    static func checkFramework(_ framework: String) -> Finding.Message {
        let suffix = framework == "AppKit" || framework == "Cocoa"
            ? " && !targetEnvironment(macCatalyst)"
            : ""
        return "this '#if os(...)' names exactly the platforms that ship \(framework); check '#if canImport(\(framework))\(suffix)' so the code follows the framework, not the platform list"
    }

    static let useCanImport: Finding.Message =
        "this '#if os(...)' guards only an import; use '#if canImport(...)' to check for the framework, with 'canImport(UIKit)' first or 'canImport(AppKit) && !targetEnvironment(macCatalyst)' so Mac Catalyst picks UIKit"
}
