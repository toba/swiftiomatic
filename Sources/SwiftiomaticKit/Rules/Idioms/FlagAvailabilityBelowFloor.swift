package import SwiftSyntax

/// Remove an availability check that the deployment floor already satisfies.
///
/// A project with a platform floor of macOS 27 gains nothing from `@available(macOS 14, *)` or from
/// `if #available(macOS 14, *)`. The attribute restricts nothing, and the condition is always true.
/// Both only add noise and an `else` branch that never runs.
///
/// The rule does nothing until a floor is configured. Set one version per platform:
/// `flagAvailabilityBelowFloor.macOS`, `.iOS`, `.tvOS`, `.watchOS` and `.visionOS`. A platform with
/// no floor blocks the finding, so `@available(macOS 13, tvOS 16, *)` stays when only macOS has a
/// floor. `anyAppleOS N` counts as below the floor only when every configured floor is at or above
/// `N`.
///
/// The rule reads only the shorthand form (`@available(macOS 13, *)`) and the form with one
/// `introduced:` label. It ignores `deprecated`, `obsoleted`, `unavailable`, `renamed` and
/// `message` arguments, a Swift version, and an application extension platform.
///
/// Lint: A warning is raised on an `@available` attribute or an `#available` condition whose
/// versions are all at or below the floor, and on an `#unavailable` condition whose versions are
/// all at or below the floor.
///
/// Rewrite: The attribute is removed. A sole `if #available` condition unwraps its body into the
/// enclosing block and drops any `else` branch. A sole `guard #available` statement is removed. One
/// `#available` condition among several is removed from the list. A body that holds a `defer` or a
/// declaration stays, because unwrapping it changes its scope. `#unavailable` is lint only.
final class FlagAvailabilityBelowFloor: StaticFormatRule<AvailabilityFloorConfiguration>,
    @unchecked Sendable
{
    static let rewriteOrder = 626

    override class var group: ConfigurationGroup? { .idioms }

    override class var defaultValue: AvailabilityFloorConfiguration { .init() }

    // MARK: - @available on declarations

    static func transform(
        _ node: FunctionDeclSyntax,
        original _: FunctionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removingAttributes(from: node, context: context)) }

    static func transform(
        _ node: InitializerDeclSyntax,
        original _: InitializerDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removingAttributes(from: node, context: context)) }

    static func transform(
        _ node: DeinitializerDeclSyntax,
        original _: DeinitializerDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removingAttributes(from: node, context: context)) }

    static func transform(
        _ node: SubscriptDeclSyntax,
        original _: SubscriptDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removingAttributes(from: node, context: context)) }

    static func transform(
        _ node: VariableDeclSyntax,
        original _: VariableDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removingAttributes(from: node, context: context)) }

    static func transform(
        _ node: StructDeclSyntax,
        original _: StructDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removingAttributes(from: node, context: context)) }

    static func transform(
        _ node: ClassDeclSyntax,
        original _: ClassDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removingAttributes(from: node, context: context)) }

    static func transform(
        _ node: EnumDeclSyntax,
        original _: EnumDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removingAttributes(from: node, context: context)) }

    static func transform(
        _ node: ActorDeclSyntax,
        original _: ActorDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removingAttributes(from: node, context: context)) }

    static func transform(
        _ node: ProtocolDeclSyntax,
        original _: ProtocolDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removingAttributes(from: node, context: context)) }

    static func transform(
        _ node: ExtensionDeclSyntax,
        original _: ExtensionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removingAttributes(from: node, context: context)) }

    static func transform(
        _ node: TypeAliasDeclSyntax,
        original _: TypeAliasDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removingAttributes(from: node, context: context)) }

    static func transform(
        _ node: EnumCaseDeclSyntax,
        original _: EnumCaseDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removingAttributes(from: node, context: context)) }

    // MARK: - #available among several conditions, and #unavailable

    static func transform(
        _ node: ConditionElementListSyntax,
        original: ConditionElementListSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ConditionElementListSyntax {
        let floors = Floors(context.configuration[Self.self])
        guard !floors.isEmpty else { return node }

        var removable = [Int]()

        for (index, element) in node.enumerated() {
            guard case let .availability(condition) = element.condition,
                  floors.satisfies(condition.availabilityArguments) else { continue }

            if condition.availabilityKeyword.tokenKind == .poundUnavailable {
                Self.diagnose(.alwaysFalse, on: condition.availabilityKeyword, context: context)
            } else {
                removable.append(index)
            }
        }
        guard !removable.isEmpty else { return node }

        // A sole condition of a statement that the block level can remove is reported there.
        if removable.count == node.count, blockLevelHandles(Syntax(original)) { return node }
        // Keep one element so the statement stays valid. The block level or a later pass reports
        // it.
        if removable.count == node.count {
            for index in removable { diagnoseAvailable(node, at: index, context: context) }
            return node
        }

        for index in removable { diagnoseAvailable(node, at: index, context: context) }
        var elements = Array(node)

        for index in removable.reversed() {
            let removed = elements.remove(at: index)

            if index == elements.count, index > 0 {
                // The removed element was last, so the new last element drops its comma.
                var previous = elements[index - 1]
                previous.trailingComma = nil
                previous.trailingTrivia = removed.trailingTrivia
                elements[index - 1] = previous
            } else if index == 0, !elements.isEmpty {
                elements[0].leadingTrivia = removed.leadingTrivia
            }
        }
        return ConditionElementListSyntax(elements)
    }

    // MARK: - Sole #available in an if or guard statement

    static func transform(
        _ node: CodeBlockItemListSyntax,
        original _: CodeBlockItemListSyntax,
        parent _: Syntax?,
        context: Context
    ) -> CodeBlockItemListSyntax {
        let floors = Floors(context.configuration[Self.self])
        guard !floors.isEmpty else { return node }

        var items = [CodeBlockItemSyntax]()
        var pendingTrivia: Trivia?
        var changed = false

        for item in node {
            switch soleAvailability(of: item, floors: floors) {
                case nil:
                    var kept = item
                    if let pendingTrivia { kept.leadingTrivia = pendingTrivia }
                    pendingTrivia = nil
                    items.append(kept)

                case let .guardStatement(condition):
                    Self.diagnose(.alwaysTrue, on: condition.availabilityKeyword, context: context)
                    changed = true
                    pendingTrivia = pendingTrivia ?? item.leadingTrivia

                case let .ifStatement(ifExpr, condition):
                    Self.diagnose(.alwaysTrue, on: condition.availabilityKeyword, context: context)
                    let body = ifExpr.body.statements
                    guard !body.contains(where: changesScope) else {
                        var kept = item
                        if let pendingTrivia { kept.leadingTrivia = pendingTrivia }
                        pendingTrivia = nil
                        items.append(kept)
                        continue
                    }
                    changed = true
                    guard !body.isEmpty else {
                        pendingTrivia = pendingTrivia ?? item.leadingTrivia
                        continue
                    }
                    let unwrapped = dedented(body, from: ifExpr)

                    for (offset, var statement) in unwrapped.enumerated() {
                        if offset == 0 {
                            statement.leadingTrivia = pendingTrivia ?? item.leadingTrivia
                            pendingTrivia = nil
                        }
                        items.append(statement)
                    }
            }
        }
        guard changed else { return node }
        return CodeBlockItemListSyntax(items)
    }

    // MARK: - Attribute removal

    private static func removingAttributes<Decl: DeclSyntaxProtocol & WithAttributesSyntax>(
        from decl: Decl,
        context: Context
    ) -> Decl {
        let floors = Floors(context.configuration[Self.self])
        guard !floors.isEmpty else { return decl }

        let removable = decl.attributes.compactMap { element -> AttributeSyntax? in
            guard case let .attribute(attribute) = element,
                  attribute.attributeName.trimmedDescription == "available",
                  case let .availability(arguments) = attribute.arguments,
                  floors.satisfies(arguments) else { return nil }
            return attribute
        }
        guard !removable.isEmpty else { return decl }

        for attribute in removable {
            Self.diagnose(.removeAttribute, on: attribute, context: context)
        }
        let rewriter = AttributeRemover(
            listID: decl.attributes.id, removing: Set(removable.map(\.id)))
        return rewriter.rewrite(decl).cast(Decl.self)
    }

    // MARK: - Helpers

    private enum SoleAvailability {
        case ifStatement(IfExprSyntax, AvailabilityConditionSyntax)
        case guardStatement(AvailabilityConditionSyntax)
    }

    private static func soleAvailability(
        of item: CodeBlockItemSyntax,
        floors: Floors
    ) -> SoleAvailability? {
        if case let .stmt(statement) = item.item,
           let guardStmt = statement.as(GuardStmtSyntax.self)
        {
            guard let condition = soleAvailableCondition(guardStmt.conditions),
                  floors.satisfies(condition.availabilityArguments) else { return nil }
            return .guardStatement(condition)
        }
        let expression: ExprSyntax? =
            switch item.item {
                case let .expr(expression): expression
                case let .stmt(statement): statement.as(ExpressionStmtSyntax.self)?.expression
                default: nil
            }
        guard let ifExpr = expression?.as(IfExprSyntax.self),
              let condition = soleAvailableCondition(ifExpr.conditions),
              floors.satisfies(condition.availabilityArguments) else { return nil }
        return .ifStatement(ifExpr, condition)
    }

    private static func soleAvailableCondition(
        _ conditions: ConditionElementListSyntax
    ) -> AvailabilityConditionSyntax? {
        guard conditions.count == 1,
              case let .availability(condition) = conditions.first?.condition,
              condition.availabilityKeyword.tokenKind == .poundAvailable else { return nil }
        return condition
    }

    /// Whether the code block level removes the statement that owns `list`.
    private static func blockLevelHandles(_ list: Syntax) -> Bool {
        guard let owner = list.parent else { return false }

        if owner.is(GuardStmtSyntax.self) {
            return owner.parent?.is(CodeBlockItemSyntax.self) ?? false
        }
        guard owner.is(IfExprSyntax.self), let parent = owner.parent else { return false }
        // An `if` statement sits directly in a code block item or in an expression statement.
        if parent.is(CodeBlockItemSyntax.self) { return true }
        return parent.is(ExpressionStmtSyntax.self)
            && (parent.parent?.is(CodeBlockItemSyntax.self) ?? false)
    }

    private static func diagnoseAvailable(
        _ list: ConditionElementListSyntax,
        at index: Int,
        context: Context
    ) {
        let element = list[list.index(list.startIndex, offsetBy: index)]
        guard case let .availability(condition) = element.condition else { return }
        Self.diagnose(.alwaysTrue, on: condition.availabilityKeyword, context: context)
    }

    /// Whether moving `item` out of its block changes the scope of a name or a deferred action.
    private static func changesScope(_ item: CodeBlockItemSyntax) -> Bool {
        switch item.item {
            case .decl: true
            case let .stmt(statement): statement.is(DeferStmtSyntax.self)
            default: false
        }
    }

    /// Moves the body statements one indentation level out, to the level of the `if` statement.
    private static func dedented(
        _ body: CodeBlockItemListSyntax,
        from ifExpr: IfExprSyntax
    ) -> [CodeBlockItemSyntax] {
        let outer = ifExpr.ifKeyword.leadingTrivia.indentation
        let inner = body.first?.leadingTrivia.indentation ?? outer
        let removeCount = max(0, inner.count - outer.count)
        let rewriter = Dedenter(count: removeCount)
        return body.map { rewriter.rewrite($0).cast(CodeBlockItemSyntax.self) }
    }
}

// MARK: - Floors

private struct Floors {
    var versions: [String: [Int]] = [:]

    init(_ configuration: AvailabilityFloorConfiguration) {
        let pairs: [(String, String?)] = [
            ("macOS", configuration.macOS), ("iOS", configuration.iOS),
            ("tvOS", configuration.tvOS), ("watchOS", configuration.watchOS),
            ("visionOS", configuration.visionOS),
        ]

        for (platform, text) in pairs {
            guard let text, let version = Floors.parse(text) else { continue }
            versions[platform] = version
        }
    }

    var isEmpty: Bool { versions.isEmpty }

    /// Whether every version in `arguments` is at or below its floor.
    func satisfies(_ arguments: AvailabilityArgumentListSyntax) -> Bool {
        var restrictions = [(platform: String, version: [Int])]()
        var elements = Array(arguments)

        // `macOS, introduced: 12` names one platform and one labeled version.
        if elements.count == 2,
           case let .token(platform) = elements[0].argument,
           case let .availabilityLabeledArgument(labeled) = elements[1].argument
        {
            guard labeled.label.text == "introduced",
                  case let .version(tuple) = labeled.value,
                  let version = Floors.parse(tuple.trimmedDescription) else { return false }
            restrictions.append((platform.text, version))
            elements = []
        }

        for element in elements {
            switch element.argument {
                case let .token(token): guard token.text == "*" else { return false }
                case let .availabilityVersionRestriction(restriction):
                    guard let tuple = restriction.version,
                          let version = Floors.parse(tuple.trimmedDescription) else { return false }
                    restrictions.append((restriction.platform.text, version))
                default: return false
            }
        }
        guard !restrictions.isEmpty else { return false }

        return restrictions.allSatisfy { platform, version in
            if platform == "anyAppleOS" {
                return versions.values.allSatisfy { Floors.compare(version, $0) <= 0 }
            }
            guard let floor = versions[platform] else { return false }
            return Floors.compare(version, floor) <= 0
        }
    }

    static func parse(_ text: String) -> [Int]? {
        let trimmed = text.filter { !$0.isWhitespace }
        guard !trimmed.isEmpty else { return nil }
        var parts = [Int]()

        for piece in trimmed.split(separator: ".") {
            guard let number = Int(piece) else { return nil }
            parts.append(number)
        }
        return parts
    }

    static func compare(_ lhs: [Int], _ rhs: [Int]) -> Int {
        for index in 0..<max(lhs.count, rhs.count) {
            let left = index < lhs.count ? lhs[index] : 0
            let right = index < rhs.count ? rhs[index] : 0
            if left != right { return left < right ? -1 : 1 }
        }
        return 0
    }
}

// MARK: - Rewriters

/// Removes chosen attributes from one attribute list and gives the leading trivia of a removed
/// attribute to the token that follows it.
private final class AttributeRemover: SyntaxRewriter {
    let listID: SyntaxIdentifier
    let removing: Set<SyntaxIdentifier>
    private var pendingTrivia: Trivia?

    init(listID: SyntaxIdentifier, removing: Set<SyntaxIdentifier>) {
        self.listID = listID
        self.removing = removing
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: AttributeListSyntax) -> AttributeListSyntax {
        guard node.id == listID else { return super.visit(node) }
        var kept = [AttributeListSyntax.Element]()

        for element in node {
            if removing.contains(element.id) {
                pendingTrivia = pendingTrivia ?? element.leadingTrivia
                continue
            }
            var element = element

            if let pendingTrivia {
                element.leadingTrivia = pendingTrivia
                self.pendingTrivia = nil
            }
            kept.append(element)
        }
        return AttributeListSyntax(kept)
    }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        guard let pendingTrivia else { return token }
        self.pendingTrivia = nil
        return token.with(\.leadingTrivia, pendingTrivia)
    }
}

/// Removes up to `count` spaces or tabs of indentation after each newline in leading trivia.
private final class Dedenter: SyntaxRewriter {
    let count: Int

    init(count: Int) {
        self.count = count
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        guard count > 0 else { return token }
        var pieces = [TriviaPiece]()
        var afterNewline = false

        for piece in token.leadingTrivia {
            switch piece {
                case .newlines, .carriageReturns, .carriageReturnLineFeeds:
                    afterNewline = true
                    pieces.append(piece)
                case let .spaces(n) where afterNewline:
                    afterNewline = false
                    if n > count { pieces.append(.spaces(n - count)) }
                case let .tabs(n) where afterNewline:
                    afterNewline = false
                    if n > count { pieces.append(.tabs(n - count)) }
                default:
                    afterNewline = false
                    pieces.append(piece)
            }
        }
        return token.with(\.leadingTrivia, Trivia(pieces: pieces))
    }
}

fileprivate extension Finding.Message {
    static let removeAttribute: Finding.Message =
        "remove '@available'; every version it names is at or below the deployment floor"
    static let alwaysTrue: Finding.Message =
        "remove '#available'; every version it names is at or below the deployment floor, so the check is always true"
    static let alwaysFalse: Finding.Message =
        "'#unavailable' names only versions at or below the deployment floor, so the check is always false"
}

// MARK: - Configuration

package struct AvailabilityFloorConfiguration: SyntaxRuleValue {
    package var rewrite = true
    package var lint: Lint = .warn
    /// The lowest macOS version the project supports, such as `"27"` . When `nil` , macOS has no
    /// floor and blocks every finding that names it.
    package var macOS: String?
    /// The lowest iOS version the project supports.
    package var iOS: String?
    /// The lowest tvOS version the project supports.
    package var tvOS: String?
    /// The lowest watchOS version the project supports.
    package var watchOS: String?
    /// The lowest visionOS version the project supports.
    package var visionOS: String?

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) {
            self.rewrite = rewrite
        }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }
        macOS = try container.decodeIfPresent(String.self, forKey: .macOS)
        iOS = try container.decodeIfPresent(String.self, forKey: .iOS)
        tvOS = try container.decodeIfPresent(String.self, forKey: .tvOS)
        watchOS = try container.decodeIfPresent(String.self, forKey: .watchOS)
        visionOS = try container.decodeIfPresent(String.self, forKey: .visionOS)
    }
}
