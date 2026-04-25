import SwiftSyntax

/// Some `override`d methods on Apple frameworks rely on the parent class
/// running its own implementation. Forgetting to call `super` is a common
/// source of subtle bugs (memory warnings ignored, view lifecycle skipped,
/// test setup not run).
///
/// The rule is opt-in. Configure the list of method names via
/// `requireSuperCall.methodNames`. Defaults cover common UIKit/AppKit/XCTest
/// methods. Names use SwiftLint's resolved-name format: `viewDidLoad()`,
/// `viewWillAppear(_:)`, `setEditing(_:animated:)`.
///
/// Lint: When an `override` of a configured method either omits the
/// `super.<name>(...)` call or calls it more than once, a warning is raised.
final class RequireSuperCall: LintSyntaxRule<RequireSuperCallConfiguration>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }
    override class var defaultValue: RequireSuperCallConfiguration {
        var config = RequireSuperCallConfiguration()
        config.lint = .no
        return config
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let body = node.body else { return .visitChildren }
        guard node.modifiers.contains(.override) else {
            return .visitChildren
        }
        if node.modifiers.contains(anyOf: [.static, .class]) {
            return .visitChildren
        }

        let resolved = resolvedName(of: node)
        let methods = ruleConfig.methodNames
        guard methods.contains(resolved) else { return .visitChildren }

        let count = countSuperCalls(named: node.name.text, in: body)
        if count == 0 {
            diagnose(.missingSuperCall(resolved), on: node.name)
        } else if count > 1 {
            diagnose(.multipleSuperCalls(resolved), on: node.name)
        }

        return .visitChildren
    }

    private func resolvedName(of node: FunctionDeclSyntax) -> String {
        var labels: [String] = []
        for parameter in node.signature.parameterClause.parameters {
            labels.append(parameter.firstName.text)
        }
        if labels.isEmpty {
            return "\(node.name.text)()"
        }
        return "\(node.name.text)(\(labels.map { "\($0):" }.joined()))"
    }

    private func countSuperCalls(named name: String, in body: CodeBlockSyntax) -> Int {
        let visitor = SuperCallCounter(targetName: name, viewMode: .sourceAccurate)
        visitor.walk(body)
        return visitor.count
    }
}

private final class SuperCallCounter: SyntaxVisitor {
    let targetName: String
    var count = 0

    init(targetName: String, viewMode: SyntaxTreeViewMode) {
        self.targetName = targetName
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
            let base = memberAccess.base?.as(SuperExprSyntax.self),
            base.superKeyword.tokenKind == .keyword(.super),
            memberAccess.declName.baseName.text == targetName
        {
            count += 1
        }
        return .visitChildren
    }
}

extension Finding.Message {
    fileprivate static func missingSuperCall(_ name: String) -> Finding.Message {
        "override of '\(name)' should call super"
    }

    fileprivate static func multipleSuperCalls(_ name: String) -> Finding.Message {
        "override of '\(name)' should call super exactly once, not multiple times"
    }
}

// MARK: - Configuration

package struct RequireSuperCallConfiguration: SyntaxRuleValue {
    package var rewrite = false
    package var lint: Lint = .warn
    /// Methods whose overrides must call `super`. Entries are full Swift
    /// selectors, e.g. `"viewDidLoad()"` or `"setEditing(_:animated:)"`.
    /// Replacing this list overrides the built-in UIKit/AppKit/XCTest defaults.
    package var methodNames: [String] = Self.defaultMethodNames

    private static let defaultMethodNames: [String] = [
        // NSObject
        "awakeFromNib()",
        "prepareForInterfaceBuilder()",
        // UICollectionViewLayout
        "invalidateLayout()",
        "invalidateLayout(with:)",
        // UIView
        "prepareForReuse()",
        "updateConstraints()",
        // UIViewController
        "didReceiveMemoryWarning()",
        "encodeRestorableState(with:)",
        "decodeRestorableState(with:)",
        "setEditing(_:animated:)",
        "viewDidAppear(_:)",
        "viewDidDisappear(_:)",
        "viewDidLoad()",
        "viewWillAppear(_:)",
        "viewWillDisappear(_:)",
        // XCTestCase
        "setUp()",
        "setUpWithError()",
        "tearDown()",
        "tearDownWithError()",
        "invokeTest()",
    ]

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) {
            self.rewrite = rewrite
        }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) {
            self.lint = lint
        }
        self.methodNames =
            try container.decodeIfPresent([String].self, forKey: .methodNames)
            ?? Self.defaultMethodNames
    }
}
