import Foundation
import SwiftSyntax

/// Collects the rewrite hooks each rule declares, so `RewritePipelineGenerator` can emit the
/// dispatch instead of anyone hand-writing it.
///
/// A rule opts into a node kind by declaring `static func transform(_:original:parent:context:)` ,
/// `static func willEnter(_:context:)` or `static func didExit(_:context:)` for that kind. Adding
/// an overload is therefore the whole registration step.
package final class RewriteHookCollector {
    /// One rule's participation in one node kind.
    package struct Hook {
        package let rule: String
        package let node: String
        /// Whether the rule declares a `transform` for this node, rather than scope hooks alone.
        ///
        /// The declared return type is not recorded, because `RewritePipelineGenerator` picks the
        /// call shape from the node kind.
        package let hasTransform: Bool
        package let hasWillEnter: Bool
        package let hasDidExit: Bool
        /// Sort key within the node kind.
        package let order: Int
    }

    /// Hooks grouped by node kind, each list sorted by `order` .
    package private(set) var hooksByNode: [String: [Hook]] = [:]

    /// Rules that declare a hook but no `rewriteOrder` , which leaves their position undefined.
    ///
    /// A hand-written dispatcher fixes the order for the node kinds it owns, so a rule that hooks
    /// only those kinds is legitimate. `RewriteDispatchAudit` decides which case each one is.
    package private(set) var rulesMissingOrder: Set<String> = []

    /// The hooks those rules declare, sorted by rule then node kind.
    ///
    /// The generated pipeline cannot place them, so they are kept apart from ``hooksByNode`` and
    /// audited instead.
    package private(set) var unorderedHooks: [Hook] = []

    package init() {}

    /// Scans every Swift file under `url` and records the hooks it finds.
    package func collect(from url: URL) async throws {
        try await enumerateSwiftFiles(in: url) { statements in
            // A rule may split its hooks across the class body and one or more extensions in the
            // same file, so gather every member list for the type before reading them.
            var ruleNames: [String] = []
            var membersByRule: [String: [MemberBlockItemListSyntax]] = [:]

            for statement in statements {
                if let classDecl = statement.item.as(ClassDeclSyntax.self),
                    Self.inheritsFormatRule(classDecl)
                {
                    ruleNames.append(classDecl.name.text)
                    membersByRule[classDecl.name.text, default: []]
                        .append(classDecl.memberBlock.members)
                }
                if let extensionDecl = statement.item.as(ExtensionDeclSyntax.self),
                    let name = extensionDecl.extendedType.as(IdentifierTypeSyntax.self)?.name.text {
                    membersByRule[name, default: []].append(extensionDecl.memberBlock.members)
                }
            }

            for name in ruleNames {
                let lists = membersByRule[name] ?? []
                let members = MemberBlockItemListSyntax(lists.flatMap { Array($0) })
                let order = Self.intLiteral(named: "rewriteOrder", in: members)
                let byNode = Self.intDictionary(named: "rewriteOrderByNode", in: members)

                var transforms = Set<String>()
                var willEnter = Set<String>()
                var didExit = Set<String>()

                for member in members {
                    guard let function = member.decl.as(FunctionDeclSyntax.self),
                        function.modifiers.contains(where: { $0.name.text == "static" }),
                        let node = Self.firstParameterType(of: function) else { continue }

                    switch function.name.text {
                        case "transform": transforms.insert(node)
                        case "willEnter": willEnter.insert(node)
                        case "didExit": didExit.insert(node)
                        default: continue
                    }
                }
                let nodes = transforms.union(willEnter).union(didExit)
                if nodes.isEmpty { continue }
                let isOrdered = order != nil || !byNode.isEmpty
                if !isOrdered { self.rulesMissingOrder.insert(name) }

                for node in nodes {
                    let hook = Hook(
                        rule: name,
                        node: node,
                        hasTransform: transforms.contains(node),
                        hasWillEnter: willEnter.contains(node),
                        hasDidExit: didExit.contains(node),
                        order: byNode[node] ?? order ?? 0
                    )

                    if isOrdered {
                        self.hooksByNode[node, default: []].append(hook)
                    } else {
                        self.unorderedHooks.append(hook)
                    }
                }
            }
        }

        for node in hooksByNode.keys {
            // A stable tiebreak keeps the output byte-identical across runs, because the file
            // enumeration order is not guaranteed.
            hooksByNode[node]?.sort { ($0.order, $0.rule) < ($1.order, $1.rule) }
        }
        unorderedHooks.sort { ($0.rule, $0.node) < ($1.rule, $1.node) }
    }

    // MARK: - Declaration lookup

    private static func inheritsFormatRule(_ classDecl: ClassDeclSyntax) -> Bool {
        guard let inheritance = classDecl.inheritanceClause else { return false }

        for inherited in inheritance.inheritedTypes {
            guard let identifier = inherited.type.as(IdentifierTypeSyntax.self) else { continue }
            if identifier.name.text == "StaticFormatRule"
                || identifier.name.text == "StructuralFormatRule" { return true }
        }
        return false
    }

    /// The type of a function's first parameter, which names the node kind the hook serves.
    private static func firstParameterType(of function: FunctionDeclSyntax) -> String? {
        guard let first = function.signature.parameterClause.parameters.first else { return nil }
        return first.type.as(IdentifierTypeSyntax.self)?.name.text
    }

    private static func value(
        named identifier: String,
        in members: MemberBlockItemListSyntax
    ) -> ExprSyntax? {
        for member in members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.firstAndOnly,
                let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                pattern.identifier.text == identifier else { continue }
            return binding.initializer?.value
        }
        return nil
    }

    private static func intLiteral(
        named identifier: String,
        in members: MemberBlockItemListSyntax
    ) -> Int? {
        guard let literal = value(named: identifier, in: members)?
            .as(IntegerLiteralExprSyntax.self)
        else { return nil }
        return Int(literal.literal.text)
    }

    private static func intDictionary(
        named identifier: String,
        in members: MemberBlockItemListSyntax
    ) -> [String: Int] {
        guard let dictionary = value(named: identifier, in: members)?
            .as(DictionaryExprSyntax.self),
              case let .elements(elements) = dictionary.content else { return [:] }

        var result: [String: Int] = [:]

        for element in elements {
            guard let key = element.key.as(StringLiteralExprSyntax.self)?
                .segments.firstAndOnly?.as(StringSegmentSyntax.self)?.content.text,
                  let literal = element.value.as(IntegerLiteralExprSyntax.self),
                  let number = Int(literal.literal.text) else { continue }
            result[key] = number
        }
        return result
    }
}
