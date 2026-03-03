import SwiftSyntax

struct ControlStatementRule {
    static let id = "control_statement"
    static let name = "Control Statement"
    static let summary =
        "`if`, `for`, `guard`, `switch`, `while`, and `catch` statements shouldn't unnecessarily wrap their conditionals or arguments in parentheses"
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        [
            Example("if condition {}"),
            Example("if (a, b) == (0, 1) {}"),
            Example("if (a || b) && (c || d) {}"),
            Example("if (min...max).contains(value) {}"),
            Example("if renderGif(data) {}"),
            Example("renderGif(data)"),
            Example("guard condition else {}"),
            Example("while condition {}"),
            Example("do {} while condition {}"),
            Example("do { ; } while condition {}"),
            Example("switch foo {}"),
            Example("do {} catch let error as NSError {}"),
            Example("foo().catch(all: true) {}"),
            Example("if max(a, b) < c {}"),
            Example("switch (lhs, rhs) {}"),
            Example("if (f() { g() {} }) {}"),
            Example("if (a + f() {} == 1) {}"),
            Example("if ({ true }()) {}"),
            Example(
                "if ({if i < 1 { true } else { false }}()) {}",
                isExcludedFromDocumentation: true,
            ),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example("↓if (condition) {}"),
            Example("↓if(condition) {}"),
            Example("↓if (condition == endIndex) {}"),
            Example("↓if ((a || b) && (c || d)) {}"),
            Example("↓if ((min...max).contains(value)) {}"),
            Example("↓guard (condition) else {}"),
            Example("↓while (condition) {}"),
            Example("↓while(condition) {}"),
            Example("do { ; } ↓while(condition) {}"),
            Example("do { ; } ↓while (condition) {}"),
            Example("↓switch (foo) {}"),
            Example("do {} ↓catch(let error as NSError) {}"),
            Example("↓if (max(a, b) < c) {}"),
        ]
    }

    static var corrections: [Example: Example] {
        [
            Example("↓if (condition) {}"): Example("if condition {}"),
            Example("↓if(condition) {}"): Example("if condition {}"),
            Example("↓if (condition == endIndex) {}"): Example("if condition == endIndex {}"),
            Example("↓if ((a || b) && (c || d)) {}"): Example("if (a || b) && (c || d) {}"),
            Example("↓if ((min...max).contains(value)) {}"): Example(
                "if (min...max).contains(value) {}",
            ),
            Example("↓guard (condition) else {}"): Example("guard condition else {}"),
            Example("↓while (condition) {}"): Example("while condition {}"),
            Example("↓while(condition) {}"): Example("while condition {}"),
            Example("do {} ↓while (condition) {}"): Example("do {} while condition {}"),
            Example("do {} ↓while(condition) {}"): Example("do {} while condition {}"),
            Example("do { ; } ↓while(condition) {}"): Example("do { ; } while condition {}"),
            Example("do { ; } ↓while (condition) {}"): Example("do { ; } while condition {}"),
            Example("↓switch (foo) {}"): Example("switch foo {}"),
            Example("do {} ↓catch(let error as NSError) {}"): Example(
                "do {} catch let error as NSError {}",
            ),
            Example("↓if (max(a, b) < c) {}"): Example("if max(a, b) < c {}"),
            Example(
                """
                if (a),
                   ( b == 1 ) {}
                """,
            ): Example(
                """
                if a,
                   b == 1 {}
                """,
            ),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension ControlStatementRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }

    func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
        Rewriter(configuration: options, file: file)
    }
}

extension ControlStatementRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            [ProtocolDeclSyntax.self]
        }

        override func visitPost(_ node: CatchClauseSyntax) {
            if node.catchItems.containSuperfluousParens == true {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: GuardStmtSyntax) {
            if node.conditions.containSuperfluousParens {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: IfExprSyntax) {
            if node.conditions.containSuperfluousParens {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: SwitchExprSyntax) {
            if node.subject.unwrapped != nil {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: WhileStmtSyntax) {
            if node.conditions.containSuperfluousParens {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
        override func visit(_ node: CatchClauseSyntax) -> CatchClauseSyntax {
            guard case let items = node.catchItems, items.containSuperfluousParens == true else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            let node =
                node
                    .with(\.catchKeyword, node.catchKeyword.with(\.trailingTrivia, .space))
                    .with(\.catchItems, items.withoutParens)
            return super.visit(node)
        }

        override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
            guard node.conditions.containSuperfluousParens else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            let node =
                node
                    .with(\.guardKeyword, node.guardKeyword.with(\.trailingTrivia, .space))
                    .with(\.conditions, node.conditions.withoutParens)
            return super.visit(node)
        }

        override func visit(_ node: IfExprSyntax) -> ExprSyntax {
            guard node.conditions.containSuperfluousParens else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            let node =
                node
                    .with(\.ifKeyword, node.ifKeyword.with(\.trailingTrivia, .space))
                    .with(\.conditions, node.conditions.withoutParens)
            return super.visit(node)
        }

        override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
            guard let tupleElement = node.subject.unwrapped else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            let node =
                node
                    .with(\.switchKeyword, node.switchKeyword.with(\.trailingTrivia, .space))
                    .with(\.subject, tupleElement.with(\.trailingTrivia, .space))
            return super.visit(node)
        }

        override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
            guard node.conditions.containSuperfluousParens else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            let node =
                node
                    .with(\.whileKeyword, node.whileKeyword.with(\.trailingTrivia, .space))
                    .with(\.conditions, node.conditions.withoutParens)
            return super.visit(node)
        }
    }
}

extension ExprSyntax {
    fileprivate var unwrapped: ExprSyntax? {
        if let expr = `as`(TupleExprSyntax.self)?.elements.onlyElement?.expression {
            return containsTrailingClosure(Syntax(expr)) ? nil : expr
        }
        return nil
    }

    private func containsTrailingClosure(_ node: Syntax) -> Bool {
        switch node.as(SyntaxEnum.self) {
            case let .functionCallExpr(node):
                node.trailingClosure != nil || node.calledExpression.is(ClosureExprSyntax.self)
            case let .sequenceExpr(node):
                node.elements.contains { containsTrailingClosure(Syntax($0)) }
            default: false
        }
    }
}

extension ConditionElementListSyntax {
    fileprivate var containSuperfluousParens: Bool {
        contains {
            if case let .expression(wrapped) = $0.condition {
                return wrapped.unwrapped != nil
            }
            return false
        }
    }

    fileprivate var withoutParens: Self {
        let conditions = map { (element: ConditionElementSyntax) -> ConditionElementSyntax in
            if let expression = element.condition.as(ExprSyntax.self)?.unwrapped {
                return
                    element
                        .with(\.condition, .expression(expression))
                        .with(\.leadingTrivia, element.leadingTrivia)
                        .with(\.trailingTrivia, element.trailingTrivia)
            }
            return element
        }
        return Self(conditions)
            .with(\.leadingTrivia, leadingTrivia)
            .with(\.trailingTrivia, trailingTrivia)
    }
}

extension CatchItemListSyntax {
    fileprivate var containSuperfluousParens: Bool {
        contains { $0.unwrapped != nil }
    }

    fileprivate var withoutParens: Self {
        let items = map { (item: CatchItemSyntax) -> CatchItemSyntax in
            if let expression = item.unwrapped {
                return
                    item
                        .with(
                            \.pattern,
                            PatternSyntax(ExpressionPatternSyntax(expression: expression)),
                        )
                        .with(\.leadingTrivia, item.leadingTrivia)
                        .with(\.trailingTrivia, item.trailingTrivia)
            }
            return item
        }
        return Self(items)
            .with(\.leadingTrivia, leadingTrivia)
            .with(\.trailingTrivia, trailingTrivia)
    }
}

extension CatchItemSyntax {
    fileprivate var unwrapped: ExprSyntax? {
        pattern?.as(ExpressionPatternSyntax.self)?.expression.unwrapped
    }
}
