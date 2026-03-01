import SwiftSyntax

struct ProhibitedSuperRule {
  var options = ProhibitedSuperOptions()

  static let description = RuleDescription(
    identifier: "prohibited_super_call",
    name: "Prohibited Calls to Super",
    description: "Some methods should not call super.",
    isOptIn: true,
    nonTriggeringExamples: [
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
        class NSView {
            func updateLayer() {
                self.method1()
            }
        }
        """,
      ),
      Example(
        """
        public class FileProviderExtension: NSFileProviderExtension {
            override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {
                guard let identifier = persistentIdentifierForItem(at: url) else {
                    completionHandler(NSFileProviderError(.noSuchItem))
                    return
                }
            }
        }
        """,
      ),
    ],
    triggeringExamples: [
      Example(
        """
        class VC: UIViewController {
            override func loadView() {↓
                super.loadView()
            }
        }
        """,
      ),
      Example(
        """
        class VC: NSFileProviderExtension {
            override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {↓
                self.method1()
                super.providePlaceholder(at:url, completionHandler: completionHandler)
            }
        }
        """,
      ),
      Example(
        """
        class VC: NSView {
            override func updateLayer() {↓
                self.method1()
                super.updateLayer()
                self.method2()
            }
        }
        """,
      ),
      Example(
        """
        class VC: NSView {
            override func updateLayer() {↓
                defer {
                    super.updateLayer()
                }
            }
        }
        """,
      ),
    ],
  )
}

extension ProhibitedSuperRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ProhibitedSuperRule {}

extension ProhibitedSuperRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      guard let ctx = node.superCallContext(matchingMethodNames: configuration.resolvedMethodNames),
        ctx.callCount > 0
      else {
        return
      }

      violations.append(
        SyntaxViolation(
          position: ctx.body.leftBrace.endPositionBeforeTrailingTrivia,
          reason: "Method '\(ctx.name)' should not call to super function",
        ),
      )
    }
  }
}
