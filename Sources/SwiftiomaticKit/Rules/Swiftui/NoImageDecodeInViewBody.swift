import SwiftSyntax

/// Flag `UIImage(data:)` and `NSImage(data:)` calls that run during `body` evaluation.
///
/// SwiftUI evaluates `body` again whenever a dependency of the view changes. An image decode there
/// runs again on each evaluation, on the main actor. Decoding is expensive, so the view can drop
/// frames. Decode the image once in a model, or in `.task` , and store the result.
///
/// The rule checks `body` , and the same-file computed properties and called methods that `body`
/// reaches. Closures that run later, such as a `Button` action or a `.task` body, do not count.
///
/// Lint: A call `UIImage(data:)` or `NSImage(data:)` runs during `body` evaluation of a `View` .
final class NoImageDecodeInViewBody: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    private static let imageTypes: Set<String> = ["UIImage", "NSImage"]

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        report(in: node)
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        report(in: node)
        return .visitChildren
    }

    private func report(in node: some DeclSyntaxProtocol) {
        for call in context.callsDuringViewBody(of: node) {
            guard let type = call.constructedTypeName, Self.imageTypes.contains(type),
                  call.arguments.first?.label?.text == "data" else { continue }
            diagnose(.imageDecode(type), on: call)
        }
    }
}

fileprivate extension Finding.Message {
    static func imageDecode(_ type: String) -> Finding.Message {
        "'\(type)(data:)' decodes the image on each 'body' evaluation, which is expensive. Decode it once in a model or in '.task'"
    }
}
