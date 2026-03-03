import SwiftSyntax

struct BlankLinesBetweenImportsRule {
    static let id = "blank_lines_between_imports"
    static let name = "Blank Lines Between Imports"
    static let summary = "There should be no blank lines between import statements"
    static let scope: Scope = .format
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        [
            Example(
                """
                import A
                import B
                import C
                """,
            ),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example(
                """
                import A

                ↓import B
                """,
            ),
        ]
    }

    static var corrections: [Example: Example] {
        [
            Example("import A\n\n↓import B"): Example("import A\nimport B"),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension BlankLinesBetweenImportsRule: SwiftSyntaxCorrectableRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }

    func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
        Rewriter(configuration: options, file: file)
    }
}

extension BlankLinesBetweenImportsRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: SourceFileSyntax) {
            var prevWasImport = false
            for item in node.statements {
                let isImport = item.item.is(ImportDeclSyntax.self)
                if isImport, prevWasImport {
                    // Check if there are blank lines between this and previous import
                    if item.leadingTrivia.newlineCount > 1 {
                        violations.append(item.positionAfterSkippingLeadingTrivia)
                    }
                }
                prevWasImport = isImport
            }
        }
    }

    fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
        override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
            var newStatements = [CodeBlockItemSyntax]()
            var prevWasImport = false
            var changed = false

            for item in node.statements {
                let isImport = item.item.is(ImportDeclSyntax.self)
                if isImport, prevWasImport {
                    if item.leadingTrivia.newlineCount > 1 {
                        numberOfCorrections += 1
                        // Replace blank lines with a single newline, preserving non-newline trivia
                        var newPieces = [TriviaPiece]()
                        var addedNewline = false
                        for piece in item.leadingTrivia {
                            switch piece {
                                case .newlines, .carriageReturns, .carriageReturnLineFeeds:
                                    if !addedNewline {
                                        newPieces.append(.newlines(1))
                                        addedNewline = true
                                    }
                                default:
                                    newPieces.append(piece)
                            }
                        }
                        let newItem = item.with(\.leadingTrivia, Trivia(pieces: newPieces))
                        newStatements.append(newItem)
                        changed = true
                        prevWasImport = isImport
                        continue
                    }
                }
                newStatements.append(item)
                prevWasImport = isImport
            }

            if changed {
                return super.visit(node.with(\.statements, CodeBlockItemListSyntax(newStatements)))
            }
            return super.visit(node)
        }
    }
}
