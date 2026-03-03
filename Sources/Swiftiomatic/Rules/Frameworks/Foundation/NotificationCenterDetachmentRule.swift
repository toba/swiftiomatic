import SwiftSyntax

struct NotificationCenterDetachmentRule {
    static let id = "notification_center_detachment"
    static let name = "Notification Center Detachment"
    static let summary = "An object should only remove itself as an observer in `deinit`"
    var options = SeverityOption<Self>(.warning)
}

extension NotificationCenterDetachmentRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}

extension NotificationCenterDetachmentRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.isNotificationCenterDetachmentCall,
                  let arg = node.arguments.first,
                  arg.label == nil,
                  let expr = arg.expression.as(DeclReferenceExprSyntax.self),
                  expr.baseName.tokenKind == .keyword(.self)
            else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }

        override func visit(_: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }
    }
}

extension FunctionCallExprSyntax {
    fileprivate var isNotificationCenterDetachmentCall: Bool {
        guard trailingClosure == nil,
              arguments.count == 1,
              let expr = calledExpression.as(MemberAccessExprSyntax.self),
              expr.declName.baseName.text == "removeObserver",
              let baseExpr = expr.base?.as(MemberAccessExprSyntax.self),
              baseExpr.declName.baseName.text == "default",
              baseExpr.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "NotificationCenter"
        else {
            return false
        }

        return true
    }
}
