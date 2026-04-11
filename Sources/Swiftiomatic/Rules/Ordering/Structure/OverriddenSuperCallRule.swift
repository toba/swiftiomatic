import SwiftSyntax

struct OverriddenSuperCallRule {
  static let id = "overridden_super_call"
  static let name = "Overridden Method Calls Super"
  static let summary = "Some overridden methods should always call super."
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        class VC: UIViewController {
            override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
            }
        }
        """,
      ),
      Example(
        """
        class VC: UIViewController {
            override func viewWillAppear(_ animated: Bool) {
                self.method1()
                super.viewWillAppear(animated)
                self.method2()
            }
        }
        """,
      ),
      Example(
        """
        class VC: UIViewController {
            override func loadView() {
            }
        }
        """,
      ),
      Example(
        """
        class Some {
            func viewWillAppear(_ animated: Bool) {
            }
        }
        """,
      ),
      Example(
        """
        class VC: UIViewController {
            override func viewDidLoad() {
            defer {
                super.viewDidLoad()
                }
            }
        }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        class VC: UIViewController {
            override func viewWillAppear(_ animated: Bool) {↓
                //Not calling to super
                self.method()
            }
        }
        """,
      ),
      Example(
        """
        class VC: UIViewController {
            override func viewWillAppear(_ animated: Bool) {↓
                super.viewWillAppear(animated)
                //Other code
                super.viewWillAppear(animated)
            }
        }
        """,
      ),
      Example(
        """
        class VC: UIViewController {
            override func didReceiveMemoryWarning() {↓
            }
        }
        """,
      ),
    ]
  }

  var options = OverriddenSuperCallOptions()
}

extension OverriddenSuperCallRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension OverriddenSuperCallRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      guard
        let ctx =
          node
          .superCallContext(matchingMethodNames: configuration.resolvedMethodNames)
      else {
        return
      }

      if ctx.callCount == 0 {
        violations.append(
          SyntaxViolation(
            position: ctx.body.leftBrace.endPositionBeforeTrailingTrivia,
            reason: "Method '\(ctx.name)' should call to super function",
          ),
        )
      } else if ctx.callCount > 1 {
        violations.append(
          SyntaxViolation(
            position: ctx.body.leftBrace.endPositionBeforeTrailingTrivia,
            reason: "Method '\(ctx.name)' should call to super only once",
          ),
        )
      }
    }
  }
}
