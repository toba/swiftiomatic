import SwiftSyntax

struct WeakDelegateRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = WeakDelegateConfiguration()

  static let description = RuleDescription(
    identifier: "weak_delegate",
    name: "Weak Delegate",
    description: "Delegates should be weak to avoid reference cycles",
    isOptIn: true,
    nonTriggeringExamples: [
      Example("class Foo {\n  weak var delegate: SomeProtocol?\n}"),
      Example("class Foo {\n  weak var someDelegate: SomeDelegateProtocol?\n}"),
      Example("class Foo {\n  weak var delegateScroll: ScrollDelegate?\n}"),
      // We only consider properties to be a delegate if it has "delegate" in its name
      Example("class Foo {\n  var scrollHandler: ScrollDelegate?\n}"),
      // Only trigger on instance variables, not local variables
      Example("func foo() {\n  var delegate: SomeDelegate\n}"),
      // Only trigger when variable has the suffix "-delegate" to avoid false positives
      Example("class Foo {\n  var delegateNotified: Bool?\n}"),
      // There's no way to declare a property weak in a protocol
      Example("protocol P {\n var delegate: AnyObject? { get set }\n}"),
      Example("class Foo {\n protocol P {\n var delegate: AnyObject? { get set }\n}\n}"),
      Example(
        "class Foo {\n var computedDelegate: ComputedDelegate {\n return bar() \n} \n}",
      ),
      Example(
        """
        class Foo {
            var computedDelegate: ComputedDelegate {
                get {
                    return bar()
                }
           }
        """,
      ),
      Example(
        "struct Foo {\n @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate \n}",
      ),
      Example(
        "struct Foo {\n @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate \n}",
      ),
      Example(
        "struct Foo {\n @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var extensionDelegate \n}",
      ),
      Example(
        """
        class Foo {
            func makeDelegate() -> SomeDelegate {
                let delegate = SomeDelegate()
                return delegate
            }
        }
        """,
      ),
      Example(
        """
        class Foo {
            var bar: Bool {
                let appDelegate = AppDelegate.bar
                return appDelegate.bar
            }
        }
        """, isExcludedFromDocumentation: true,
      ),
      Example("private var appDelegate: String?", isExcludedFromDocumentation: true),
    ],
    triggeringExamples: [
      Example("class Foo {\n  ↓var delegate: SomeProtocol?\n}"),
      Example("class Foo {\n  ↓var scrollDelegate: ScrollDelegate?\n}"),
      Example(
        """
        class Foo {
            ↓var delegate: SomeProtocol? {
                didSet {
                    print("Updated delegate")
                }
           }
        """,
      ),
    ],
  )
}

extension WeakDelegateRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension WeakDelegateRule {}

extension WeakDelegateRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      guard node.hasDelegateSuffix,
        node.weakOrUnownedModifier == nil,
        !node.hasComputedBody,
        !node.containsIgnoredAttribute,
        let parent = node.parent,
        Syntax(parent).enclosingClass() != nil
      else {
        return
      }

      violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension Syntax {
  fileprivate func enclosingClass() -> ClassDeclSyntax? {
    if let classExpr = `as`(ClassDeclSyntax.self) {
      return classExpr
    }
    if `as`(DeclSyntax.self) != nil {
      return nil
    }

    return parent?.enclosingClass()
  }
}

extension VariableDeclSyntax {
  fileprivate var hasDelegateSuffix: Bool {
    bindings.allSatisfy { binding in
      guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
        return false
      }

      return pattern.identifier.text.lowercased().hasSuffix("delegate")
    }
  }

  fileprivate var hasComputedBody: Bool {
    bindings.allSatisfy { binding in
      if case .getter = binding.accessorBlock?.accessors {
        return true
      }
      return binding.accessorBlock?.specifiesGetAccessor == true
    }
  }

  fileprivate var containsIgnoredAttribute: Bool {
    let ignoredAttributes: Set = [
      "UIApplicationDelegateAdaptor",
      "NSApplicationDelegateAdaptor",
      "WKExtensionDelegateAdaptor",
    ]

    return attributes.contains { attr in
      guard case .attribute(let customAttr) = attr,
        let typeIdentifier = customAttr.attributeName.as(IdentifierTypeSyntax.self)
      else {
        return false
      }

      return ignoredAttributes.contains(typeIdentifier.name.text)
    }
  }
}
