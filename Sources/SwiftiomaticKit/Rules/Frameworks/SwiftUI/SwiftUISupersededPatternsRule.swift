import SwiftiomaticSyntax

struct SwiftUISupersededPatternsRule {
  static let id = "swiftui_superseded_patterns"
  static let name = "SwiftUI Superseded Patterns"
  static let summary =
    "Detect SwiftUI patterns superseded by modern alternatives (@Observable, NavigationStack, etc.)"
  static let scope: Scope = .suggest

  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        @Observable
        class ViewModel {
          var name = ""
        }
        """
      ),
      Example(
        """
        struct ContentView: View {
          @State var model = ViewModel()
          var body: some View { Text(model.name) }
        }
        """
      ),
      Example(
        """
        NavigationStack {
          List { Text("Item") }
        }
        """
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        ↓class ViewModel: ObservableObject {
          @Published var name = ""
        }
        """
      ),
      Example(
        """
        struct ContentView: View {
          ↓@StateObject var model = ViewModel()
          var body: some View { Text("") }
        }
        """
      ),
      Example(
        """
        struct ContentView: View {
          ↓@ObservedObject var model: ViewModel
          var body: some View { Text("") }
        }
        """
      ),
      Example(
        """
        struct ContentView: View {
          ↓@EnvironmentObject var settings: Settings
          var body: some View { Text("") }
        }
        """
      ),
      Example(
        """
        struct ContentView: View {
          var body: some View {
            ↓NavigationView {
              Text("Hello")
            }
          }
        }
        """,
        isExcludedFromDocumentation: true,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension SwiftUISupersededPatternsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ViolationMessage {
  fileprivate static func observableObject(_ name: String) -> Self {
    "Class '\(name)' conforms to ObservableObject; use @Observable instead"
  }

  fileprivate static func supersededWrapper(_ wrapper: String, replacement: String) -> Self {
    "@\(wrapper) is superseded by \(replacement)"
  }

  fileprivate static let navigationView: Self =
    "NavigationView is deprecated; use NavigationStack or NavigationSplitView"
}

extension SwiftUISupersededPatternsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    // MARK: - ObservableObject conformance

    override func visitPost(_ node: ClassDeclSyntax) {
      guard let inheritanceClause = node.inheritanceClause,
        inheritanceClause.inheritedTypes.contains(where: {
          $0.type.as(IdentifierTypeSyntax.self)?.name.text == "ObservableObject"
        })
      else { return }

      violations.append(
        SyntaxViolation(
          position: node.classKeyword.positionAfterSkippingLeadingTrivia,
          message: .observableObject(node.name.text),
        )
      )
    }

    // MARK: - Superseded property wrappers

    private static let supersededWrappers: [String: String] = [
      "StateObject": "@State",
      "ObservedObject": "@State or @Bindable",
      "EnvironmentObject": "@Environment",
    ]

    override func visitPost(_ node: AttributeSyntax) {
      let name = node.attributeNameText
      if let replacement = Self.supersededWrappers[name] {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            message: .supersededWrapper(name, replacement: replacement),
          )
        )
      }
    }

    // MARK: - NavigationView

    override func visitPost(_ node: DeclReferenceExprSyntax) {
      if node.baseName.text == "NavigationView" {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            message: .navigationView,
          )
        )
      }
    }
  }
}
