// ===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// ===----------------------------------------------------------------------===//

import Foundation
import SwiftSyntax

/// When possible, the synthesized `struct` initializer should be used.
///
/// This means the creation of a (non-public) memberwise initializer with the same structure as the
/// synthesized initializer is forbidden.
///
/// SE-0502 changed which properties the compiler puts in that initializer. A property that is less
/// accessible than the rest *and* carries an initial value is now left out, so it no longer drags
/// the initializer down to its own access level. A hand-written initializer that existed only to
/// work around that is redundant on Swift 6.4.
///
/// Lint: (Non-public) memberwise initializers with the same structure as the synthesized
/// initializer will yield a lint error.
final class UseSynthesizedInit: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        var storedProperties: [VariableDeclSyntax] = []
        var initializers: [InitializerDeclSyntax] = []

        for memberItem in node.memberBlock.members {
            let member = memberItem.decl
            // Collect all stored variables into a list
            if let varDecl = member.as(VariableDeclSyntax.self) {
                guard !varDecl.modifiers.contains(anyOf: [.static]),
                      !varDecl.isComputed,
                      !varDecl.isSetUpByWrapperArguments
                else { continue }
                storedProperties.append(varDecl)
                // Collect any possible redundant initializers into a list
            } else if let initDecl = member.as(InitializerDeclSyntax.self) {
                guard initDecl.optionalMark == nil else { continue }
                guard initDecl.signature.effectSpecifiers?.throwsClause == nil else { continue }
                initializers.append(initDecl)
            }
        }

        let typeLevel = declaredAccessLevel(node.modifiers) ?? .internal
        let levels = storedProperties.map { effectiveAccessLevel(of: $0, typeLevel: typeLevel) }

        // SE-0502: a property below the ceiling that also carries an initial value drops out of the
        // memberwise initializer, so it no longer pulls the initializer down to its own level.
        let ceiling = levels.max() ?? .internal
        let kept = zip(storedProperties, levels).filter { property, level in
            level >= ceiling || !hasInitialValue(property)
        }

        let memberwiseProperties = kept.map(\.0)
        let initLevel = synthesizedInitAccessLevel(ofKept: kept.map(\.1))

        // Collects all of the initializers that could be replaced by the synthesized memberwise
        // initializer(s).
        var extraneousInitializers: [(InitializerDeclSyntax, suggestions: [String])] = []

        for initializer in initializers {
            // Attributes signify intent that isn't automatically synthesized by the compiler.
            guard initializer.attributes.isEmpty,
                  let matches = matchesPropertyList(
                      parameters: initializer.signature.parameterClause.parameters,
                      properties: memberwiseProperties
                  ),
                  matchesAssignmentBody(
                      variables: memberwiseProperties,
                      matches: matches,
                      initBody: initializer.body
                  ),
                  matchesAccessLevel(modifiers: initializer.modifiers, synthesized: initLevel)
            else { continue }

            extraneousInitializers.append((initializer, matches.compactMap(\.suggestion)))
        }

        // The synthesized memberwise initializer(s) are only created when there are no
        // initializers. If there are other initializers that cannot be replaced by a synthesized
        // memberwise initializer, then all of the initializers must remain.
        let initializersCount = node.memberBlock.members.count(where: {
            $0.decl.is(InitializerDeclSyntax.self)
        })

        if extraneousInitializers.count == initializersCount {
            for (initializer, suggestions) in extraneousInitializers {
                diagnose(
                    suggestions.isEmpty
                        ? .removeRedundantInitializer
                        : .declareBuilderProperties(suggestions),
                    on: initializer
                )
            }
        }

        return .visitChildren
    }

    /// Compares the actual access level of an initializer with the access level of a synthesized
    /// memberwise initializer.
    ///
    /// - Parameters:
    ///   - modifiers: The modifier list from the initializer.
    ///   - synthesized: The access level the synthesized initializer would carry.
    /// - Returns: Whether the initializer has the same access level as the synthesized initializer.
    private func matchesAccessLevel(
        modifiers: DeclModifierListSyntax?,
        synthesized: AccessLevel
    ) -> Bool {
        let accessLevel = modifiers?.accessLevelModifier

        switch synthesized {
            case .internal:
                // No explicit access level or internal are equivalent.
                return accessLevel == nil || accessLevel!.name.tokenKind == .keyword(.internal)
            case .fileprivate:
                return accessLevel != nil && accessLevel!.name.tokenKind == .keyword(.fileprivate)
            case .private:
                return accessLevel != nil && accessLevel!.name.tokenKind == .keyword(.private)
        }
    }

    /// Compares initializer parameters to stored properties of the struct.
    ///
    /// - Returns: One match per parameter, in order, or `nil` when the parameters differ from the
    ///   synthesized initializer's.
    private func matchesPropertyList(
        parameters: FunctionParameterListSyntax,
        properties: [VariableDeclSyntax]
    ) -> [ParameterMatch]? {
        guard parameters.count == properties.count else { return nil }

        var matches: [ParameterMatch] = []

        for (idx, parameter) in parameters.enumerated() {
            guard parameter.secondName == nil else { return nil }

            let property = properties[idx]
            let propertyID = property.firstIdentifier
            guard let propertyType = property.firstType,
                  propertyID.identifier.text == parameter.firstName.text
            else { return nil }

            // Ensure that parameters that correspond to properties declared using 'var' have a
            // default argument that is identical to the property's default value. Otherwise, a
            // default argument doesn't match the memberwise initializer.
            let isVarDecl = property.bindingSpecifier.tokenKind == .keyword(.var)

            if isVarDecl, let initializer = property.firstInitializer {
                guard let defaultArg = parameter.defaultValue else { return nil }
                guard initializer.value.description == defaultArg.value.description else {
                    return nil
                }
            } else if parameter.defaultValue != nil { return nil }

            guard let match = parameterMatch(parameter, property: property, type: propertyType)
            else { return nil }
            matches.append(match)
        }
        return matches
    }

    /// Matches one parameter against the stored property it initializes.
    ///
    /// The synthesized initializer marks a closure parameter `@escaping`, so that attribute is
    /// ignored. A result-builder attribute on the parameter matches a builder property in two
    /// shapes. A property of type `T` takes a builder closure `() -> T` and evaluates it during
    /// init. A property of type `() -> T` stores the closure. Each shape keeps its own evaluation
    /// timing.
    private func parameterMatch(
        _ parameter: FunctionParameterSyntax,
        property: VariableDeclSyntax,
        type propertyType: TypeSyntax
    ) -> ParameterMatch? {
        let propertyAttributes = property.attributes.compactMap { $0.as(AttributeSyntax.self) }
        let propertyBuilder = propertyAttributes.first { $0.isResultBuilder }
        let parameterType = parameter.type.withoutEscaping.trimmedDescription

        guard !parameter.attributes.isEmpty else {
            // A builder property's synthesized parameter carries the builder, so a plain
            // parameter differs from it.
            guard propertyBuilder == nil,
                  parameterType == propertyType.trimmedDescription
            else { return nil }
            return .plain
        }

        guard parameter.attributes.count == 1,
              let builder = parameter.attributes.first?.as(AttributeSyntax.self),
              builder.arguments == nil
        else { return nil }
        let builderName = builder.attributeName.trimmedDescription

        // A property already marked with the same builder needs no suggestion. Any other
        // attribute, such as a property wrapper, changes the synthesized parameter.
        let isMarked: Bool
        switch propertyAttributes.count {
            case 0: isMarked = false
            case 1 where propertyBuilder?.attributeName.trimmedDescription == builderName:
                isMarked = true
            default: return nil
        }
        guard propertyAttributes.count == property.attributes.count else { return nil }

        let evaluates: Bool
        if let closure = parameter.type.withoutEscaping.as(FunctionTypeSyntax.self),
           closure.parameters.isEmpty,
           closure.returnClause.type.trimmedDescription == propertyType.trimmedDescription
        {
            evaluates = true
        } else if propertyType.withoutEscaping.is(FunctionTypeSyntax.self),
                  parameterType == propertyType.trimmedDescription
        {
            evaluates = false
        } else {
            return nil
        }

        let suggestion = isMarked
            ? nil
            : "@\(builderName) \(property.bindingSpecifier.text) \(parameter.firstName.text): \(propertyType.trimmedDescription)"
        return .builder(evaluates: evaluates, suggestion: suggestion)
    }

    // Evaluates if all, and only, the stored properties are initialized in the body
    private func matchesAssignmentBody(
        variables: [VariableDeclSyntax],
        matches: [ParameterMatch],
        initBody: CodeBlockSyntax?
    ) -> Bool {
        guard let initBody else { return false }
        guard variables.count == initBody.statements.count else { return false }

        var statements: [String] = []

        for statement in initBody.statements {
            guard let expr = statement.item.as(InfixOperatorExprSyntax.self),
                expr.operator.is(AssignmentExprSyntax.self) else { return false }

            var leftName = ""
            var rightName = ""

            if let memberAccessExpr = expr.leftOperand.as(MemberAccessExprSyntax.self) {
                guard let base = memberAccessExpr.base,
                      base.description.trimmingCharacters(in: .whitespacesAndNewlines) == "self"
                else { return false }

                leftName = memberAccessExpr.declName.baseName.text
            } else {
                return false
            }

            // A builder-evaluating parameter is called once. Every other parameter is assigned
            // as is.
            guard let index = variables.firstIndex(where: {
                $0.firstIdentifier.identifier.text == leftName
            }) else { return false }

            if matches[index].evaluates {
                guard let call = expr.rightOperand.as(FunctionCallExprSyntax.self),
                      call.arguments.isEmpty,
                      call.trailingClosure == nil,
                      call.additionalTrailingClosures.isEmpty,
                      let callee = call.calledExpression.as(DeclReferenceExprSyntax.self)
                else { return false }
                rightName = callee.baseName.text
            } else if let identifierExpr = expr.rightOperand.as(DeclReferenceExprSyntax.self) {
                rightName = identifierExpr.baseName.text
            } else {
                return false
            }

            guard leftName == rightName else { return false }
            statements.append(leftName)
        }

        // Multiset compare: each variable must consume exactly one matching statement, and no
        // statements may be left over. Previously, `firstIndex(of:)` + `remove(at:)` per variable
        // was O(n²) on the statements list.
        var statementCounts: [String: Int] = [:]
        for stmt in statements { statementCounts[stmt, default: 0] += 1 }
        var remaining = statements.count

        for variable in variables {
            let id = variable.firstIdentifier.identifier.text
            guard let count = statementCounts[id], count > 0 else { return false }

            if count == 1 {
                statementCounts.removeValue(forKey: id)
            } else {
                statementCounts[id] = count - 1
            }
            remaining -= 1
        }
        return remaining == 0
    }
}

fileprivate extension Finding.Message {
    static let removeRedundantInitializer: Finding.Message =
        "remove this explicit initializer, which is identical to the compiler-synthesized initializer"

    static func declareBuilderProperties(_ declarations: [String]) -> Finding.Message {
        let list = declarations.map { "'\($0)'" }.joined(separator: " and ")
        return "remove this explicit initializer and declare \(list); the synthesized initializer then takes the same builder closure"
    }
}

/// How one initializer parameter maps to the stored property it initializes.
private enum ParameterMatch {
    /// The parameter has the property's type and is assigned as is.
    case plain
    /// The parameter carries a result builder. `evaluates` is true when the initializer calls the
    /// builder closure and false when it stores the closure. `suggestion` is the property
    /// declaration to write when the property lacks the builder.
    case builder(evaluates: Bool, suggestion: String?)

    var evaluates: Bool {
        if case .builder(true, _) = self { true } else { false }
    }

    var suggestion: String? {
        if case let .builder(_, suggestion) = self { suggestion } else { nil }
    }
}

/// Defines the access levels which may be assigned to a synthesized memberwise initializer.
///
/// The order runs from most restricted to least. `internal` is the ceiling, because a synthesized
/// memberwise initializer is never public.
private enum AccessLevel: Int, Comparable {
    case `private`, `fileprivate`, `internal`

    static func < (lhs: AccessLevel, rhs: AccessLevel) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// The access level a declaration's own modifiers state, capped at internal, or `nil` when it
/// states none.
///
/// A modifier with a detail, such as `private(set)`, is ignored. That one restricts the setter
/// alone and leaves the memberwise initializer untouched.
private func declaredAccessLevel(_ modifiers: DeclModifierListSyntax) -> AccessLevel? {
    for modifier in modifiers where modifier.detail == nil {
        switch modifier.name.tokenKind {
            case .keyword(.private): return .private
            case .keyword(.fileprivate): return .fileprivate
            case .keyword(.internal), .keyword(.package), .keyword(.public), .keyword(.open):
                return .internal
            default: continue
        }
    }
    return nil
}

/// The access level of a property, falling back to the enclosing type's level when the property
/// states none.
private func effectiveAccessLevel(
    of property: VariableDeclSyntax,
    typeLevel: AccessLevel
) -> AccessLevel { declaredAccessLevel(property.modifiers) ?? typeLevel }

/// Whether the property is initialised at its own declaration.
///
/// SE-0502 drops a less-accessible property from the memberwise initializer only when it has one.
/// An optional with no written value counts, because the compiler initialises it to nil.
private func hasInitialValue(_ property: VariableDeclSyntax) -> Bool {
    if property.firstInitializer != nil { return true }
    guard let type = property.firstType else { return false }
    return type.is(OptionalTypeSyntax.self) || type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self)
        ? true
        : type.as(IdentifierTypeSyntax.self)?.name.text == "Optional"
}

/// Computes the access level which would be applied to the synthesized memberwise initializer of a
/// struct, given the levels of the properties the initializer still takes.
///
/// The initializer can be no more accessible than its least accessible parameter, so this is the
/// minimum. SE-0502 changes the input to this function, not the function itself: a less accessible
/// property that carries an initial value never reaches here, so it no longer pulls the result
/// down. A less accessible property with no initial value still does.
///
/// The rules for default memberwise initializer access levels are defined in The Swift Programming
/// Language: https://docs.swift.org/swift-book/LanguageGuide/AccessControl.html#ID21
///
/// - Parameter levels: The access levels of the properties the initializer takes.
/// - Returns: The synthesized memberwise initializer's access level.
private func synthesizedInitAccessLevel(ofKept levels: [AccessLevel]) -> AccessLevel {
    levels.min() ?? .internal
}

// FIXME: Stop using these extensions; they make assumptions about the structure of stored
// properties and may miss some valid cases, like tuple patterns.
fileprivate extension VariableDeclSyntax {
    /// Returns array of all identifiers listed in the declaration.
    var identifiers: [IdentifierPatternSyntax] {
        var ids: [IdentifierPatternSyntax] = []
        for binding in bindings {
            guard let id = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
            ids.append(id)
        }
        return ids
    }

    /// Returns the first identifier.
    var firstIdentifier: IdentifierPatternSyntax { identifiers[0] }

    /// Returns the first type explicitly stated in the declaration, if present.
    var firstType: TypeSyntax? { bindings.first?.typeAnnotation?.type }

    /// Returns the first initializer clause, if present.
    var firstInitializer: InitializerClauseSyntax? { bindings.first?.initializer }

    /// Whether the property is computed. A property with only `willSet` or `didSet` observers
    /// stays stored.
    var isComputed: Bool {
        bindings.contains { binding in
            switch binding.accessorBlock?.accessors {
                case .getter: true
                case let .accessors(list):
                    list.contains {
                        ![.keyword(.willSet), .keyword(.didSet)].contains($0.accessorSpecifier.tokenKind)
                    }
                case nil: false
            }
        }
    }

    /// Whether a property wrapper's attribute arguments set the property up, as in
    /// `@Environment(\.dismiss) var dismiss`. The memberwise initializer takes no parameter for it.
    var isSetUpByWrapperArguments: Bool {
        firstInitializer == nil
            && attributes.contains { $0.as(AttributeSyntax.self)?.arguments != nil }
    }
}

fileprivate extension AttributeSyntax {
    /// Whether the attribute names a result builder, judged by the `Builder` suffix convention.
    var isResultBuilder: Bool {
        arguments == nil && attributeName.trimmedDescription.hasSuffix("Builder")
    }
}

fileprivate extension TypeSyntax {
    /// The type without an `@escaping` attribute.
    var withoutEscaping: TypeSyntax {
        guard let attributed = self.as(AttributedTypeSyntax.self) else { return self }
        let kept = attributed.attributes.filter {
            $0.as(AttributeSyntax.self)?.attributeName.trimmedDescription != "escaping"
        }
        guard kept.isEmpty, attributed.specifiers.isEmpty else {
            return TypeSyntax(attributed.with(\.attributes, kept))
        }
        return attributed.baseType
    }
}
