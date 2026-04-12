import SwiftiomaticSyntax

struct FunctionBodyLengthRule {
  private static let testConfig = ["warning": 2]
  static let id = "function_body_length"
  static let name = "Function Body Length"
  static let summary = "Function bodies should not span too many lines"
  static var nonTriggeringExamples: [Example] {
    [
      Example("func f() {}", configuration: testConfig),
      Example(
        """
        func f() {
            let x = 0
        }
        """, configuration: testConfig,
      ),
      Example(
        """
        func f() {
            let x = 0
            let y = 1
        }
        """, configuration: testConfig,
      ),
      Example(
        """
        func f() {
            let x = 0
            // comments
            // will
            // be
            // ignored
        }
        """, configuration: testConfig,
      ),
      Example(
        """
            func f() {
                let x = 0
                // empty lines will be ignored


            }
        """, configuration: testConfig,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        ↓func f() {
            let x = 0
            let y = 1
            let z = 2
        }
        """, configuration: testConfig,
      ),
      Example(
        """
        class C {
            ↓deinit {
                let x = 0
                let y = 1
                let z = 2
            }
        }
        """, configuration: testConfig,
      ),
      Example(
        """
        class C {
            ↓init() {
                let x = 0
                let y = 1
                let z = 2
            }
        }
        """, configuration: testConfig,
      ),
      Example(
        """
        class C {
            ↓subscript() -> Int {
                let x = 0
                let y = 1
                return x + y
            }
        }
        """, configuration: testConfig,
      ),
      Example(
        """
        struct S {
            subscript() -> Int {
                ↓get {
                    let x = 0
                    let y = 1
                    return x + y
                }
                ↓set {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                ↓willSet {
                    let x = 0
                    let y = 1
                    let z = 2
                }
            }
        }
        """, configuration: testConfig,
      ),
    ]
  }

  var options = SeverityLevelsConfiguration<Self>(warning: 50, error: 100)
}

extension FunctionBodyLengthRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension FunctionBodyLengthRule {
  fileprivate final class Visitor: BodyLengthVisitor<OptionsType> {
    override func visitPost(_ node: DeinitializerDeclSyntax) {
      if let body = node.body {
        registerViolations(
          leftBrace: body.leftBrace,
          rightBrace: body.rightBrace,
          violationNode: node.deinitKeyword,
          objectName: "Deinitializer",
        )
      }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      if let body = node.body {
        registerViolations(
          leftBrace: body.leftBrace,
          rightBrace: body.rightBrace,
          violationNode: node.funcKeyword,
          objectName: "Function",
        )
      }
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
      if let body = node.body {
        registerViolations(
          leftBrace: body.leftBrace,
          rightBrace: body.rightBrace,
          violationNode: node.initKeyword,
          objectName: "Initializer",
        )
      }
    }

    override func visitPost(_ node: SubscriptDeclSyntax) {
      guard let body = node.accessorBlock else {
        return
      }
      if case .getter = body.accessors {
        registerViolations(
          leftBrace: body.leftBrace,
          rightBrace: body.rightBrace,
          violationNode: node.subscriptKeyword,
          objectName: "Subscript",
        )
      }
      if case .accessors(let accessors) = body.accessors {
        for accessor in accessors {
          guard let body = accessor.body else {
            continue
          }
          registerViolations(
            leftBrace: body.leftBrace,
            rightBrace: body.rightBrace,
            violationNode: accessor.accessorSpecifier,
            objectName: "Accessor",
          )
        }
      }
    }
  }
}
