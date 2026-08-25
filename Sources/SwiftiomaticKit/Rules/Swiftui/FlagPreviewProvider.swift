import SwiftSyntax

/// Flag the `PreviewProvider` family, deprecated in the OS 27 SDK.
///
/// The SDK marks `PreviewProvider` , `previewDevice(_:)` , `previewLayout(_:)` ,
/// `previewDisplayName(_:)` and `previewInterfaceOrientation(_:)` as deprecated at 27.0, yet the
/// compiler stays silent about a conformance. Nothing catches these except a lint pass.
///
/// - `PreviewProvider` conformance → the `#Preview` macro
/// - `previewDisplayName(_:)` → the `#Preview("Name")` label
/// - `previewLayout(_:)` → `#Preview(traits: .sizeThatFitsLayout)` or `.fixedLayout(width:height:)`
/// - `previewInterfaceOrientation(_:)` → `#Preview(traits: .landscapeLeft)`
/// - `previewDevice(_:)` → the device picker in Xcode's canvas
///
/// Lint: A `PreviewProvider` conformance or a deprecated preview modifier raises a warning.
final class FlagPreviewProvider: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        flagConformance(node.inheritanceClause)
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        flagConformance(node.inheritanceClause)
        return .visitChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        flagConformance(node.inheritanceClause)
        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            member.base != nil else { return .visitChildren }

        switch member.declName.baseName.text {
            case "previewDisplayName": diagnose(.previewDisplayName, on: member.declName)
            case "previewLayout": diagnose(.previewLayout, on: member.declName)
            case "previewInterfaceOrientation": diagnose(.previewOrientation, on: member.declName)
            case "previewDevice": diagnose(.previewDevice, on: member.declName)
            default: break
        }
        return .visitChildren
    }

    private func flagConformance(_ inheritance: InheritanceClauseSyntax?) {
        guard let inherited = inheritance?.inherited(named: "PreviewProvider") else { return }
        diagnose(.previewProvider, on: inherited)
    }
}

fileprivate extension Finding.Message {
    static let previewProvider: Finding.Message =
        "'PreviewProvider' is deprecated in the 27.0 SDK — use the '#Preview' macro"
    static let previewDisplayName: Finding.Message =
        "'previewDisplayName' is deprecated in the 27.0 SDK — pass the name to '#Preview(\"Name\")'"
    static let previewLayout: Finding.Message =
        "'previewLayout' is deprecated in the 27.0 SDK — use '#Preview(traits: .sizeThatFitsLayout)' or '.fixedLayout(width:height:)'"
    static let previewOrientation: Finding.Message =
        "'previewInterfaceOrientation' is deprecated in the 27.0 SDK — use an orientation trait such as '#Preview(traits: .landscapeLeft)'"
    static let previewDevice: Finding.Message =
        "'previewDevice' is deprecated in the 27.0 SDK — pick the device in Xcode's canvas"
}
