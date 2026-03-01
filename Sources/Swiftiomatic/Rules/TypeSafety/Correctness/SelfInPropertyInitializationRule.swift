import SwiftSyntax

struct SelfInPropertyInitializationRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "self_in_property_initialization",
    name: "Self in Property Initialization",
    description:
      "`self` refers to the unapplied `NSObject.self()` method, which is likely not expected; "
      + "make the variable `lazy` to be able to refer to the current instance or use `ClassName.self`",
    nonTriggeringExamples: [
      Example(
        """
        class View: UIView {
            let button: UIButton = {
                return UIButton()
            }()
        }
        """,
      ),
      Example(
        """
        class View: UIView {
            lazy var button: UIButton = {
                let button = UIButton()
                button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
                return button
            }()
        }
        """,
      ),
      Example(
        """
        class View: UIView {
            var button: UIButton = {
                let button = UIButton()
                button.addTarget(otherObject, action: #selector(didTapButton), for: .touchUpInside)
                return button
            }()
        }
        """,
      ),
      Example(
        """
        class View: UIView {
            private let collectionView: UICollectionView = {
                let layout = UICollectionViewFlowLayout()
                let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
                collectionView.registerReusable(Cell.self)

                return collectionView
            }()
        }
        """,
      ),
      Example(
        """
        class Foo {
            var bar: Bool = false {
                didSet {
                    value = {
                        if bar {
                            return self.calculateA()
                        } else {
                            return self.calculateB()
                        }
                    }()
                    print(value)
                }
            }

            var value: String?

            func calculateA() -> String { "A" }
            func calculateB() -> String { "B" }
        }
        """, isExcludedFromDocumentation: true,
      ),
      Example(
        """
        final class NotActuallyReferencingSelf {
            let keyPath: Any = \\String.self
            let someType: Any = String.self
        }
        """, isExcludedFromDocumentation: true,
      ),
    ],
    triggeringExamples: [
      Example(
        """
        class View: UIView {
            ↓var button: UIButton = {
                let button = UIButton()
                button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
                return button
            }()
        }
        """,
      ),
      Example(
        """
        class View: UIView {
            ↓let button: UIButton = {
                let button = UIButton()
                button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
                return button
            }()
        }
        """,
      ),
    ],
  )
}

extension SelfInPropertyInitializationRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension SelfInPropertyInitializationRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: VariableDeclSyntax) {
      guard !node.modifiers.contains(keyword: .lazy),
        !node.modifiers.containsStaticOrClass,
        let closestDecl = node.closestDecl(),
        closestDecl.is(ClassDeclSyntax.self)
      else {
        return
      }

      let visitor = IdentifierUsageVisitor(viewMode: .sourceAccurate)
      for binding in node.bindings {
        guard let initializer = binding.initializer,
          visitor.walk(tree: initializer.value, handler: \.isTokenUsed)
        else {
          continue
        }

        violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

private final class IdentifierUsageVisitor: SyntaxVisitor {
  private(set) var isTokenUsed = false

  override func visitPost(_ node: DeclReferenceExprSyntax) {
    if node.baseName.tokenKind == .keyword(.self),
      node.keyPathInParent != \MemberAccessExprSyntax.declName,
      node.keyPathInParent != \KeyPathPropertyComponentSyntax.declName
    {
      isTokenUsed = true
    }
  }
}

extension SyntaxProtocol {
  fileprivate func closestDecl() -> DeclSyntax? {
    if let decl = parent?.as(DeclSyntax.self) {
      return decl
    }

    return parent?.closestDecl()
  }
}
