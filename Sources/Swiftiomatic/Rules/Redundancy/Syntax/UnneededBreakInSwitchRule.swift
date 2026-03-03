import SwiftSyntax
import SwiftBasicFormat

struct UnneededBreakInSwitchRule {
    static let id = "unneeded_break_in_switch"
    static let name = "Unneeded Break in Switch"
    static let summary = "Avoid using unneeded break statements"
    static let isCorrectable = true

    private static func embedInSwitch(
        _ text: String,
        case: String = "case .bar",
        file: StaticString = #filePath,
        line: UInt = #line,
    ) -> Example {
        Example(
            """
            switch foo {
            \(`case`):
                \(text)
            }
            """, file: file, line: line,
        )
    }

    static var nonTriggeringExamples: [Example] {
        [
            embedInSwitch("break"),
            embedInSwitch("break", case: "default"),
            embedInSwitch("for i in [0, 1, 2] { break }"),
            embedInSwitch("if true { break }"),
            embedInSwitch("something()"),
            Example(
                """
                let items = [Int]()
                for item in items {
                    if bar() {
                        do {
                            try foo()
                        } catch {
                            bar()
                            break
                        }
                    }
                }
                """,
            ),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            embedInSwitch("something()\n    ↓break"),
            embedInSwitch("something()\n    ↓break // comment"),
            embedInSwitch("something()\n    ↓break", case: "default"),
            embedInSwitch("something()\n    ↓break", case: "case .foo, .foo2 where condition"),
        ]
    }

    static var corrections: [Example: Example] {
        [
            embedInSwitch("something()\n    ↓break"): embedInSwitch("something()"),
            embedInSwitch("something()\n    ↓break // line comment"): embedInSwitch(
                "something()\n     // line comment",
            ),
            embedInSwitch(
                """
                something()
                ↓break
                /*
                block comment
                */
                """,
            ): embedInSwitch(
                """
                something()
                /*
                block comment
                */
                """,
            ),
            embedInSwitch("something()\n    ↓break /// doc line comment"): embedInSwitch(
                "something()\n     /// doc line comment",
            ),
            embedInSwitch(
                """
                something()
                ↓break
                ///
                /// doc block comment
                ///
                """,
            ): embedInSwitch(
                """
                something()
                ///
                /// doc block comment
                ///
                """,
            ),
            embedInSwitch("something()\n    ↓break", case: "default"): embedInSwitch(
                "something()", case: "default",
            ),
            embedInSwitch("something()\n    ↓break", case: "case .foo, .foo2 where condition"):
                embedInSwitch("something()", case: "case .foo, .foo2 where condition"),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension UnneededBreakInSwitchRule: SwiftSyntaxCorrectableRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }

    func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
        Rewriter(configuration: options, file: file)
    }
}

extension UnneededBreakInSwitchRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: SwitchCaseSyntax) {
            guard let statement = node.unneededBreak else {
                return
            }
            violations.append(statement.item.positionAfterSkippingLeadingTrivia)
        }
    }

    fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
        override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
            let stmts = CodeBlockItemListSyntax(node.statements.dropLast())
            guard let breakStatement = node.unneededBreak, let secondLast = stmts.last else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            let trivia = breakStatement.item.leadingTrivia + breakStatement.item.trailingTrivia
            let newNode =
                node
                    .with(\.statements, stmts)
                    .with(\.statements.trailingTrivia, secondLast.item.trailingTrivia + trivia)
                    .trimmed { !$0.isComment }
                    .formatted()
                    .as(SwitchCaseSyntax.self)!
            return super.visit(newNode)
        }
    }
}

extension SwitchCaseSyntax {
    fileprivate var unneededBreak: CodeBlockItemSyntax? {
        guard statements.count > 1,
              let breakStatement = statements.last?.item.as(BreakStmtSyntax.self),
              breakStatement.label == nil
        else {
            return nil
        }
        return statements.last
    }
}

extension TriviaPiece {
    fileprivate var isComment: Bool {
        switch self {
            case .lineComment, .blockComment, .docLineComment, .docBlockComment:
                return true
            default:
                return false
        }
    }
}
