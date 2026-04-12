import SwiftiomaticSyntax

struct RedundantMainActorViewRule {
  static let id = "redundant_main_actor_view"
  static let name = "Redundant @MainActor on View"
  static let summary =
    "SwiftUI View, App, Scene, and ViewModifier types are implicitly @MainActor"
  static let isCorrectable = true

  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        struct ContentView: View {
          var body: some View { Text("Hello") }
        }
        """
      ),
      Example(
        """
        @MainActor
        class ViewModel {
          var name = ""
        }
        """
      ),
      Example(
        """
        @MainActor
        struct Service {
          func run() {}
        }
        """
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        ↓@MainActor
        struct ContentView: View {
          var body: some View { Text("Hello") }
        }
        """
      ),
      Example(
        """
        ↓@MainActor struct SettingsView: View {
          var body: some View { EmptyView() }
        }
        """
      ),
      Example(
        """
        ↓@MainActor
        struct MyApp: App {
          var body: some Scene { WindowGroup { Text("") } }
        }
        """
      ),
      Example(
        """
        ↓@MainActor
        struct MyModifier: ViewModifier {
          func body(content: Content) -> some View { content }
        }
        """
      ),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example(
        """
        ↓@MainActor
        struct ContentView: View {
          var body: some View { Text("Hello") }
        }
        """
      ): Example(
        """
        struct ContentView: View {
          var body: some View { Text("Hello") }
        }
        """
      ),
      Example(
        """
        ↓@MainActor struct SettingsView: View {
          var body: some View { EmptyView() }
        }
        """
      ): Example(
        """
        struct SettingsView: View {
          var body: some View { EmptyView() }
        }
        """
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension RedundantMainActorViewRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RedundantMainActorViewRule {
  private static let swiftUIProtocols: Set<String> = [
    "View", "ViewModifier", "App", "Scene",
  ]

  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: StructDeclSyntax) {
      checkMainActor(attributes: node.attributes, inheritance: node.inheritanceClause)
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      checkMainActor(attributes: node.attributes, inheritance: node.inheritanceClause)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
      checkMainActor(attributes: node.attributes, inheritance: node.inheritanceClause)
    }

    private func checkMainActor(
      attributes: AttributeListSyntax,
      inheritance: InheritanceClauseSyntax?
    ) {
      guard let inheritance,
        inheritance.inheritedTypes.contains(where: { inherited in
          guard let name = inherited.type.as(IdentifierTypeSyntax.self)?.name.text else {
            return false
          }
          return swiftUIProtocols.contains(name)
        }),
        let mainActorAttr = attributes.first(where: {
          $0.as(AttributeSyntax.self)?.attributeNameText == "MainActor"
        })?.as(AttributeSyntax.self)
      else {
        return
      }

      let start = mainActorAttr.positionAfterSkippingLeadingTrivia
      let end: AbsolutePosition
      if let nextToken = mainActorAttr.lastToken(viewMode: .sourceAccurate)?
        .nextToken(viewMode: .sourceAccurate)
      {
        end = nextToken.positionAfterSkippingLeadingTrivia
      } else {
        end = mainActorAttr.endPosition
      }

      violations.append(
        SyntaxViolation(
          position: start,
          severity: configuration.severity,
          correction: SyntaxViolation.Correction(
            start: start,
            end: end,
            replacement: "",
          ),
        ),
      )
    }
  }
}
