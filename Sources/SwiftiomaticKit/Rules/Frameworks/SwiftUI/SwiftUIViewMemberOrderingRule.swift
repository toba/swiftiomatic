import SwiftiomaticSyntax
import SwiftSyntax

struct SwiftUIViewMemberOrderingRule {
  static let id = "swiftui_view_member_ordering"
  static let name = "SwiftUI View Member Ordering"
  static let summary =
    "SwiftUI View members should follow: @Environment/@FocusState → let → @State → computed var → init → body → view builders → helpers"
  static let scope: Scope = .suggest

  static var nonTriggeringExamples: [Example] {
    [
      // Correct order
      Example(
        """
        struct MyView: View {
            @Environment(\\.dismiss) private var dismiss
            @FocusState private var isFocused: Bool
            let title: String
            @State private var count = 0
            var body: some View { Text(title) }
        }
        """
      ),
      // Minimal view — just body
      Example(
        """
        struct MyView: View {
            var body: some View { Text("Hello") }
        }
        """
      ),
      // init before body is correct
      Example(
        """
        struct MyView: View {
            let title: String
            @State private var count = 0
            init(title: String) { self.title = title }
            var body: some View { Text(title) }
        }
        """
      ),
      // Helper func after body is correct
      Example(
        """
        struct MyView: View {
            @State private var count = 0
            var body: some View { Text("\\(count)") }
            private func increment() { count += 1 }
        }
        """
      ),
      // Non-View struct is ignored
      Example(
        """
        struct NotAView {
            func helper() {}
            let name: String
        }
        """
      ),
      // @ViewBuilder computed property after body is correct (view builder)
      Example(
        """
        struct MyView: View {
            var body: some View { header }
            @ViewBuilder var header: some View { Text("Header") }
        }
        """
      ),
      // @Binding is in the let group (non-state stored property)
      Example(
        """
        struct MyView: View {
            @Binding var isPresented: Bool
            @State private var count = 0
            var body: some View { Text("\\(count)") }
        }
        """
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      // @State before @Environment
      Example(
        """
        struct MyView: View {
            @State private var count = 0
            ↓@Environment(\\.dismiss) private var dismiss
            var body: some View { Text("\\(count)") }
        }
        """
      ),
      // let before @Environment
      Example(
        """
        struct MyView: View {
            let title: String
            ↓@Environment(\\.dismiss) private var dismiss
            var body: some View { Text(title) }
        }
        """
      ),
      // body before @State
      Example(
        """
        struct MyView: View {
            var body: some View { Text("\\(count)") }
            ↓@State private var count = 0
        }
        """
      ),
      // Helper func before body
      Example(
        """
        struct MyView: View {
            @State private var count = 0
            ↓private func increment() { count += 1 }
            var body: some View { Text("\\(count)") }
        }
        """
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension SwiftUIViewMemberOrderingRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

/// Member category in the expected SwiftUI View ordering.
/// Raw values define sort order — lower values should appear first.
private enum ViewMemberCategory: Int, Comparable, CustomStringConvertible {
  case environment = 0   // @Environment, @FocusState
  case letProperty = 1   // let, @Binding
  case stateProperty = 2 // @State, @AppStorage, @SceneStorage, @Query
  case computedVar = 3   // computed var (non-body, non-@ViewBuilder)
  case initializer = 4   // init
  case body = 5          // var body
  case viewBuilder = 6   // @ViewBuilder computed var returning some View
  case helper = 7        // functions, subscripts

  static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

  var description: String {
    switch self {
    case .environment: "@Environment/@FocusState"
    case .letProperty: "let"
    case .stateProperty: "@State"
    case .computedVar: "computed var"
    case .initializer: "init"
    case .body: "body"
    case .viewBuilder: "@ViewBuilder"
    case .helper: "helper func"
    }
  }
}

/// Attributes that place a property in the environment group.
private let environmentAttributes: Set<String> = [
  "Environment", "FocusState",
]

/// Attributes that place a property in the state group.
private let stateAttributes: Set<String> = [
  "State", "AppStorage", "SceneStorage", "Query",
]

/// SwiftUI View protocols to check inheritance against.
private let viewProtocols: Set<String> = ["View"]

extension ViolationMessage {
  fileprivate static func viewMemberOutOfOrder(
    _ found: ViewMemberCategory, after expected: ViewMemberCategory
  ) -> Self {
    "\(found) should appear before \(expected) in a SwiftUI View"
  }
}

extension SwiftUIViewMemberOrderingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skipsNestedScopes: Bool { true }

    override func visitPost(_ node: StructDeclSyntax) {
      checkMemberOrder(node)
    }

    private func checkMemberOrder(_ node: StructDeclSyntax) {
      // Only check types conforming to View
      guard let inheritanceClause = node.inheritanceClause,
        inheritanceClause.inheritedTypes.contains(where: { inherited in
          guard let simpleType = inherited.type.as(IdentifierTypeSyntax.self) else {
            return false
          }
          return viewProtocols.contains(simpleType.name.text)
        })
      else { return }

      let categorized = node.memberBlock.members.compactMap { member -> (
        position: AbsolutePosition, category: ViewMemberCategory
      )? in
        categorize(member: member)
      }

      guard categorized.count >= 2 else { return }

      // Track the highest category seen so far
      var highWaterMark = categorized[0].category
      for i in 1..<categorized.count {
        let current = categorized[i]
        if current.category < highWaterMark {
          violations.append(
            SyntaxViolation(
              position: current.position,
              message: .viewMemberOutOfOrder(current.category, after: highWaterMark),
              confidence: .medium,
              suggestion:
                "Move \(current.category) members before \(highWaterMark) members",
            )
          )
        } else {
          highWaterMark = current.category
        }
      }
    }

    private func categorize(member: MemberBlockItemSyntax) -> (
      position: AbsolutePosition, category: ViewMemberCategory
    )? {
      let decl = member.decl

      // Initializer
      if let initDecl = decl.as(InitializerDeclSyntax.self) {
        return (initDecl.initKeyword.positionAfterSkippingLeadingTrivia, .initializer)
      }

      // Function → helper
      if let funcDecl = decl.as(FunctionDeclSyntax.self) {
        return (
          funcDecl.attributes.first?.positionAfterSkippingLeadingTrivia
            ?? funcDecl.funcKeyword.positionAfterSkippingLeadingTrivia,
          .helper
        )
      }

      // Subscript → helper
      if let subDecl = decl.as(SubscriptDeclSyntax.self) {
        return (subDecl.subscriptKeyword.positionAfterSkippingLeadingTrivia, .helper)
      }

      // Variable declaration
      if let varDecl = decl.as(VariableDeclSyntax.self) {
        let position =
          varDecl.attributes.first?.positionAfterSkippingLeadingTrivia
          ?? varDecl.bindingSpecifier.positionAfterSkippingLeadingTrivia
        return (position, categorizeVariable(varDecl))
      }

      // Skip nested types, #if blocks, etc.
      return nil
    }

    private func categorizeVariable(_ decl: VariableDeclSyntax) -> ViewMemberCategory {
      // Check attributes first
      for attribute in decl.attributes {
        guard let attr = attribute.as(AttributeSyntax.self) else { continue }
        let name = attr.attributeNameText

        if environmentAttributes.contains(name) {
          return .environment
        }
        if stateAttributes.contains(name) {
          return .stateProperty
        }
        if name == "ViewBuilder" {
          return .viewBuilder
        }
      }

      // Check if it's the body property
      if let firstBinding = decl.bindings.first,
        firstBinding.pattern.trimmedDescription == "body",
        firstBinding.accessorBlock != nil
      {
        return .body
      }

      // let properties (including @Binding which has no accessor block)
      if decl.bindingSpecifier.tokenKind == .keyword(.let) {
        return .letProperty
      }

      // @Binding is a var but acts as a passed-in property — treat as let group
      if decl.attributes.contains(where: {
        $0.as(AttributeSyntax.self)?.attributeNameText == "Binding"
      }) {
        return .letProperty
      }

      // Computed var (has accessor block but is not body)
      if let firstBinding = decl.bindings.first, firstBinding.accessorBlock != nil {
        // Check if return type is `some View` — treat as view builder
        if let typeAnnotation = firstBinding.typeAnnotation,
          typeAnnotation.type.trimmedDescription.hasSuffix("View")
        {
          return .viewBuilder
        }
        return .computedVar
      }

      // Stored var without special attributes — state-like
      return .stateProperty
    }
  }
}
