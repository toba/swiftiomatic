import SwiftSyntax

struct PrivateActionRule {
    static let id = "private_action"
    static let name = "Private Actions"
    static let summary = "IBActions should be private"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
            Example(
                "class Foo {\n\t@IBAction private func barButtonTapped(_ sender: UIButton) {}\n}",
            ),
            Example(
                "struct Foo {\n\t@IBAction private func barButtonTapped(_ sender: UIButton) {}\n}",
            ),
            Example(
                "class Foo {\n\t@IBAction fileprivate func barButtonTapped(_ sender: UIButton) {}\n}",
            ),
            Example(
                "struct Foo {\n\t@IBAction fileprivate func barButtonTapped(_ sender: UIButton) {}\n}",
            ),
            Example(
                "private extension Foo {\n\t@IBAction func barButtonTapped(_ sender: UIButton) {}\n}",
            ),
            Example(
                "fileprivate extension Foo {\n\t@IBAction func barButtonTapped(_ sender: UIButton) {}\n}",
            ),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example("class Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example("struct Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example(
                "class Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}",
            ),
            Example(
                "struct Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}",
            ),
            Example(
                "class Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}",
            ),
            Example(
                "struct Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}",
            ),
            Example("extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example(
                "extension Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}",
            ),
            Example(
                "extension Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}",
            ),
            Example(
                "public extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}",
            ),
            Example(
                "internal extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}",
            ),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension PrivateActionRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}

extension PrivateActionRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            node.modifiers.containsPrivateOrFileprivate() ? .skipChildren : .visitChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard node.isIBAction, !node.modifiers.containsPrivateOrFileprivate() else {
                return
            }

            violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}
