import SwiftSyntax

struct UnavailableFunctionRule {
    static let id = "unavailable_function"
    static let name = "Unavailable Function"
    static let summary = "Unimplemented functions should be marked as unavailable"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
            Example(
                """
                class ViewController: UIViewController {
                  @available(*, unavailable)
                  public required init?(coder aDecoder: NSCoder) {
                    preconditionFailure("init(coder:) has not been implemented")
                  }
                }
                """,
            ),
            Example(
                """
                func jsonValue(_ jsonString: String) -> NSObject {
                   let data = jsonString.data(using: .utf8)!
                   let result = try! JSONSerialization.jsonObject(with: data, options: [])
                   if let dict = (result as? [String: Any])?.bridge() {
                    return dict
                   } else if let array = (result as? [Any])?.bridge() {
                    return array
                   }
                   fatalError()
                }
                """,
            ),
            Example(
                """
                func resetOnboardingStateAndCrash() -> Never {
                    resetUserDefaults()
                    // Crash the app to re-start the onboarding flow.
                    fatalError("Onboarding re-start crash.")
                }
                """,
            ),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example(
                """
                class ViewController: UIViewController {
                  public required ↓init?(coder aDecoder: NSCoder) {
                    fatalError("init(coder:) has not been implemented")
                  }
                }
                """,
            ),
            Example(
                """
                class ViewController: UIViewController {
                  public required ↓init?(coder aDecoder: NSCoder) {
                    let reason = "init(coder:) has not been implemented"
                    fatalError(reason)
                  }
                }
                """,
            ),
            Example(
                """
                class ViewController: UIViewController {
                  public required ↓init?(coder aDecoder: NSCoder) {
                    preconditionFailure("init(coder:) has not been implemented")
                  }
                }
                """,
            ),
            Example(
                """
                ↓func resetOnboardingStateAndCrash() {
                    resetUserDefaults()
                    // Crash the app to re-start the onboarding flow.
                    fatalError("Onboarding re-start crash.")
                }
                """,
            ),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension UnavailableFunctionRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}

extension UnavailableFunctionRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            guard !node.returnsNever,
                  !node.attributes.hasUnavailableAttribute,
                  node.body.containsTerminatingCall,
                  !node.body.containsReturn
            else {
                return
            }

            violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            guard !node.attributes.hasUnavailableAttribute,
                  node.body.containsTerminatingCall,
                  !node.body.containsReturn
            else {
                return
            }

            violations.append(node.initKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

extension FunctionDeclSyntax {
    fileprivate var returnsNever: Bool {
        if let expr = signature.returnClause?.type.as(IdentifierTypeSyntax.self) {
            return expr.name.text == "Never"
        }
        return false
    }
}

extension AttributeListSyntax {
    fileprivate var hasUnavailableAttribute: Bool {
        contains { elem in
            guard let attr = elem.as(AttributeSyntax.self),
                  let arguments = attr.arguments?.as(AvailabilityArgumentListSyntax.self)
            else {
                return false
            }

            let attributeName = attr.attributeNameText
            return attributeName == "available"
                && arguments.contains { arg in
                    arg.argument.as(TokenSyntax.self)?.tokenKind.isUnavailableKeyword == true
                }
        }
    }
}

extension CodeBlockSyntax? {
    fileprivate var containsTerminatingCall: Bool {
        guard let statements = self?.statements else {
            return false
        }

        let terminatingFunctions: Set = [
            "abort",
            "fatalError",
            "preconditionFailure",
        ]

        return statements.contains { item in
            guard let function = item.item.as(FunctionCallExprSyntax.self),
                  let identifierExpr = function.calledExpression.as(DeclReferenceExprSyntax.self)
            else {
                return false
            }

            return terminatingFunctions.contains(identifierExpr.baseName.text)
        }
    }

    fileprivate var containsReturn: Bool {
        guard let statements = self?.statements else {
            return false
        }

        return ReturnFinderVisitor(viewMode: .sourceAccurate)
            .walk(tree: statements, handler: \.containsReturn)
    }
}

private final class ReturnFinderVisitor: SyntaxVisitor {
    private(set) var containsReturn = false

    override func visitPost(_: ReturnStmtSyntax) {
        containsReturn = true
    }

    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }
}
