import SwiftSyntax
import ConfigurationKit

/// A block should hold a statement or a comment
///
/// An empty block does nothing, and it does not say whether that is deliberate. A reader cannot
/// tell an intentional no-op from unfinished work. A comment inside the braces settles the
/// question, so a block holding only a comment passes.
///
/// Four kinds of block are checked, and each has its own switch: function bodies, initializer and
/// deinitializer bodies, statement blocks ( `if` , `for` , `while` , `repeat` , `do` , `catch` ,
/// `defer` , `guard` ) and closures. Accessor bodies such as `willSet` and type bodies such as
/// `enum E {}` are never checked.
///
/// Set `allowCompactEmptyBlocks` to skip a block whose braces sit together with nothing between
/// them, such as `func f() {}` . A spaced form like `{ }` and a multi-line form still raise a
/// finding.
///
/// Lint: An empty block of an enabled kind raises a warning.
final class NoEmptyBlock: LintSyntaxRule<NoEmptyBlockConfiguration>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
        guard let kind = Self.blockKind(of: node), isEnabled(kind), node.statements.isEmpty
        else { return .visitChildren }
        check(
            after: node.leftBrace.trailingTrivia,
            before: node.rightBrace.leadingTrivia,
            anchor: node.leftBrace,
            kind: kind
        )
        return .visitChildren
    }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        guard ruleConfig.checkClosureBlocks, node.statements.isEmpty else { return .visitChildren }
        // a capture list or a parameter list pushes the opening trivia past the `in` keyword
        check(
            after: node.signature?.trailingTrivia ?? node.leftBrace.trailingTrivia,
            before: node.rightBrace.leadingTrivia,
            anchor: node.leftBrace,
            kind: .closure
        )
        return .visitChildren
    }

    private func check(after: Trivia, before: Trivia, anchor: TokenSyntax, kind: BlockKind) {
        guard !after.hasAnyComments, !before.hasAnyComments else { return }
        guard !(after.isEmpty && before.isEmpty && ruleConfig.allowCompactEmptyBlocks) else {
            return
        }
        diagnose(.emptyBlock(kind), on: anchor)
    }

    private func isEnabled(_ kind: BlockKind) -> Bool {
        switch kind {
            case .function: ruleConfig.checkFunctionBodies
            case .initializer: ruleConfig.checkInitializerBodies
            case .statement: ruleConfig.checkStatementBlocks
            case .closure: ruleConfig.checkClosureBlocks
        }
    }

    private static func blockKind(of node: CodeBlockSyntax) -> BlockKind? {
        switch node.parent?.kind {
            case .functionDecl: .function
            case .initializerDecl, .deinitializerDecl: .initializer
            case .ifExpr,
                 .guardStmt,
                 .forStmt,
                 .whileStmt,
                 .repeatStmt,
                 .doStmt,
                 .deferStmt,
                 .catchClause: .statement
            default: nil
        }
    }

    fileprivate enum BlockKind {
        case function, initializer, statement, closure

        var noun: String {
            switch self {
                case .function: "function body"
                case .initializer: "initializer body"
                case .statement: "statement block"
                case .closure: "closure"
            }
        }
    }
}

fileprivate extension Finding.Message {
    static func emptyBlock(_ kind: NoEmptyBlock.BlockKind) -> Finding.Message {
        "empty \(kind.noun); add a statement or a comment that explains the no-op"
    }
}

// MARK: - Configuration

package struct NoEmptyBlockConfiguration: SyntaxRuleValue {
    package var lint: Lint = .warn
    /// Whether an empty `func` body raises a finding.
    package var checkFunctionBodies = true
    /// Whether an empty `init` or `deinit` body raises a finding.
    package var checkInitializerBodies = true
    /// Whether an empty control-flow block raises a finding, covering `if` , `for` , `while` ,
    /// `repeat` , `do` , `catch` , `defer` and `guard` .
    package var checkStatementBlocks = true
    /// Whether an empty closure raises a finding.
    package var checkClosureBlocks = true
    /// Whether to skip a block whose braces hold nothing at all, such as `func f() {}` . A spaced
    /// or multi-line empty block still raises a finding.
    package var allowCompactEmptyBlocks = false

    package var rewrite = false

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try c.decodeIfPresent(Lint.self, forKey: .lint) { lint = v }
        if let v = try c.decodeIfPresent(Bool.self, forKey: .checkFunctionBodies) {
            checkFunctionBodies = v
        }
        if let v = try c.decodeIfPresent(Bool.self, forKey: .checkInitializerBodies) {
            checkInitializerBodies = v
        }
        if let v = try c.decodeIfPresent(Bool.self, forKey: .checkStatementBlocks) {
            checkStatementBlocks = v
        }
        if let v = try c.decodeIfPresent(Bool.self, forKey: .checkClosureBlocks) {
            checkClosureBlocks = v
        }
        if let v = try c.decodeIfPresent(Bool.self, forKey: .allowCompactEmptyBlocks) {
            allowCompactEmptyBlocks = v
        }
    }

    private enum CodingKeys: String, CodingKey {
        case lint
        case checkFunctionBodies, checkInitializerBodies, checkStatementBlocks, checkClosureBlocks
        case allowCompactEmptyBlocks
    }
}
