import Foundation
import SwiftParser
import SwiftSyntax

/// Require `.strictMemorySafety()` in the Swift settings of each target of a package manifest.
///
/// Strict memory safety makes the compiler report each use of an unsafe construct that has no
/// `unsafe` marker. A target without the setting accepts unsafe code with no warning. The policy
/// applies to every target, with or without unsafe code today, so that new unsafe code gets the
/// warning.
///
/// The rule reads only a file named `Package.swift` . It checks each `.target` , `.executableTarget`
/// , `.testTarget` and `.macro` call. The `swiftSettings:` argument passes when it holds
/// `.strictMemorySafety()` , or names a top-level variable of the manifest whose value holds it,
/// directly or through another such variable. A `for` loop over `package.targets` that sets
/// `.strictMemorySafety()` passes every target.
///
/// Lint: A target in `Package.swift` has no `.strictMemorySafety()` in its `swiftSettings` .
final class RequireStrictMemorySafetySetting: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    /// The target factory methods whose targets compile Swift code.
    private static let swiftTargetKinds: Set<String> = [
        "target", "executableTarget", "testTarget", "macro",
    ]

    private static let settingName = "strictMemorySafety"

    /// The top-level variables whose values hold the setting, or `nil` when every target passes.
    private var safeNames: Set<String>?

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        guard context.fileURL.lastPathComponent == "Package.swift" else { return .skipChildren }
        safeNames = Self.safeSettingNames(in: node)
        return safeNames == nil ? .skipChildren : .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let safeNames,
              let member = node.calledExpression.as(MemberAccessExprSyntax.self),
              member.base == nil,
              Self.swiftTargetKinds.contains(member.declName.baseName.text),
              !Self.isDependency(node) else {
            return .visitChildren
        }
        let settings = node.arguments.first { $0.label?.text == "swiftSettings" }
        if let settings, Self.holdsSetting(settings.expression, safeNames: safeNames) {
            return .visitChildren
        }
        diagnose(.addSetting(Self.targetName(of: node)), on: member.declName)
        return .visitChildren
    }

    /// The names of the top-level variables whose values hold the setting, or `nil` when a loop
    /// over `package.targets` applies it to every target
    private static func safeSettingNames(in file: SourceFileSyntax) -> Set<String>? {
        var initializers: [String: ExprSyntax] = [:]

        for item in file.statements {
            if let loop = item.item.as(ForStmtSyntax.self),
               loop.sequence.trimmedDescription.hasSuffix(".targets"),
               mentionsSetting(loop.body)
            {
                return nil
            }
            guard let variable = item.item.as(VariableDeclSyntax.self) else { continue }

            for binding in variable.bindings {
                guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                      let value = binding.initializer?.value else { continue }
                initializers[name] = value
            }
        }

        // A variable can hold the setting through another variable, so repeat to a fixed point
        var safe: Set<String> = []
        var changed = true

        while changed {
            changed = false
            for (name, value) in initializers where !safe.contains(name) {
                if holdsSetting(value, safeNames: safe) {
                    safe.insert(name)
                    changed = true
                }
            }
        }
        return safe
    }

    /// Whether `expr` spells the setting or reads a variable in `safeNames`
    private static func holdsSetting(_ expr: ExprSyntax, safeNames: Set<String>) -> Bool {
        expr.tokens(viewMode: .sourceAccurate).contains { token in
            guard case let .identifier(text) = token.tokenKind else { return false }
            return text == settingName || safeNames.contains(text)
        }
    }

    private static func mentionsSetting(_ syntax: some SyntaxProtocol) -> Bool {
        syntax.tokens(viewMode: .sourceAccurate).contains {
            $0.tokenKind == .identifier(settingName)
        }
    }

    /// Whether `call` is a `Target.Dependency` such as `.target(name:)` in a `dependencies:` list
    private static func isDependency(_ call: FunctionCallExprSyntax) -> Bool {
        var current = call.parent

        while let ancestor = current {
            if let argument = ancestor.as(LabeledExprSyntax.self) {
                return argument.label?.text == "dependencies"
            }
            current = ancestor.parent
        }
        return false
    }

    /// The literal `name:` argument of a target call, or the method name when there is none
    private static func targetName(of call: FunctionCallExprSyntax) -> String {
        guard let name = call.arguments.first(where: { $0.label?.text == "name" }),
              let literal = name.expression.as(StringLiteralExprSyntax.self),
              let text = literal.representedLiteralValue else {
            return call.calledExpression.trimmedDescription
        }
        return text
    }
}

fileprivate extension Finding.Message {
    static func addSetting(_ target: String) -> Finding.Message {
        "add '.strictMemorySafety()' to the 'swiftSettings' of '\(target)'. Every target must opt in to strict memory safety"
    }
}
