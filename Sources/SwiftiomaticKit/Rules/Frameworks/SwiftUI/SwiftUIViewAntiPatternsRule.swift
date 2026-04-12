import SwiftiomaticSyntax

struct SwiftUIViewAntiPatternsRule {
  static let id = "swiftui_view_anti_patterns"
  static let name = "SwiftUI View Anti-Patterns"
  static let summary =
    "Detect common SwiftUI performance and correctness anti-patterns in view code"
  static let scope: Scope = .suggest

  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        struct MyView: View {
          var body: some View {
            Text("Hello").visualEffect { content, proxy in
              content.offset(x: proxy.size.width)
            }
          }
        }
        """
      ),
      Example(
        """
        struct MyView: View {
          private static let formatter: DateFormatter = {
            let f = DateFormatter()
            f.dateStyle = .short
            return f
          }()
          var body: some View { Text(Self.formatter.string(from: Date())) }
        }
        """
      ),
      Example(
        """
        struct MyView: View {
          let sortedItems: [Item]
          var body: some View {
            ForEach(sortedItems) { item in Text(item.name) }
          }
        }
        """
      ),
      Example(
        """
        struct MyView: View {
          var body: some View {
            Text("Hello")
              .fileImporter(isPresented: $show, allowedContentTypes: [.text]) { _ in }
          }
        }
        """
      ),
      // Stable ForEach identity — uses Identifiable conformance
      Example(
        """
        struct MyView: View {
          let items: [Item]
          var body: some View {
            ForEach(items) { item in Text(item.name) }
          }
        }
        """
      ),
      // Stable root with conditional content inside
      Example(
        """
        struct MyView: View {
          @State var isLoaded = false
          var body: some View {
            VStack {
              if isLoaded { Text("Done") } else { ProgressView() }
            }
          }
        }
        """
      ),
      // withAnimation outside onChange is fine
      Example(
        """
        struct MyView: View {
          var body: some View {
            Button("Tap") { withAnimation { toggle() } }
              .onChange(of: value) { _, new in update(new) }
          }
        }
        """
      ),
      // .animation(_:value:) inside onChange is the recommended pattern
      Example(
        """
        struct MyView: View {
          var body: some View {
            Text("Hello")
              .animation(.default, value: offset)
              .onChange(of: value) { _, new in offset = new }
          }
        }
        """
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        struct MyView: View {
          var body: some View {
            ↓GeometryReader { proxy in
              Text("Width: \\(proxy.size.width)")
            }
          }
        }
        """
      ),
      Example(
        """
        struct MyView: View {
          func showPicker() {
            let panel = ↓NSOpenPanel()
            panel.runModal()
          }
        }
        """
      ),
      Example(
        """
        struct MyView: View {
          func savePicker() {
            let panel = ↓NSSavePanel()
            panel.runModal()
          }
        }
        """
      ),
      Example(
        """
        struct MyView: View {
          var body: some View {
            Text(↓DateFormatter().string(from: Date()))
          }
        }
        """
      ),
      Example(
        """
        struct MyView: View {
          @State var items: [Item]
          var body: some View {
            ↓ForEach(items.sorted(by: { $0.name < $1.name })) { item in
              Text(item.name)
            }
          }
        }
        """,
        isExcludedFromDocumentation: true,
      ),
      // Unstable ForEach identity: id: \.self
      Example(
        """
        struct MyView: View {
          let names: [String]
          var body: some View {
            ForEach(names, ↓id: \\.self) { name in Text(name) }
          }
        }
        """
      ),
      // Top-level if/else in body swaps root identity
      Example(
        """
        struct MyView: View {
          @State var isLoaded = false
          var body: some View {
            ↓if isLoaded {
              ContentView()
            } else {
              LoadingView()
            }
          }
        }
        """
      ),
      // withAnimation inside onChange — last transaction wins
      Example(
        """
        struct MyView: View {
          @State var offset: CGFloat = 0
          var body: some View {
            Text("Hello")
              .onChange(of: value) { _, new in
                ↓withAnimation { offset = new }
              }
          }
        }
        """
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension SwiftUIViewAntiPatternsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ViolationMessage {
  fileprivate static let geometryReader: Self =
    "GeometryReader is often replaceable with Layout protocol or .visualEffect modifier"

  fileprivate static func panelAPI(_ name: String) -> Self {
    "\(name) should be replaced with .fileImporter/.fileExporter in SwiftUI"
  }

  fileprivate static func formatterInBody(_ name: String) -> Self {
    "\(name) allocated in view body — cache as static property or @State"
  }

  fileprivate static let sortFilterInForEach: Self =
    "Sorting/filtering inside ForEach runs every body evaluation — precompute the collection"

  fileprivate static let unstableForEachIdentity: Self =
    "ForEach with 'id: \\.self' uses unstable identity — prefer Identifiable conformance"

  fileprivate static let topLevelConditionalBody: Self =
    "Top-level if/else in View body swaps root identity — wrap in a stable container"

  fileprivate static let withAnimationInOnChange: Self =
    "withAnimation inside onChange can be overridden by non-animated updates — use .animation(_:value:) modifier instead"
}

private let panelTypes: Set<String> = ["NSOpenPanel", "NSSavePanel"]

private let formatterTypes: Set<String> = [
  "DateFormatter", "NumberFormatter", "MeasurementFormatter",
]

extension SwiftUIViewAntiPatternsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private var bodyDepth = 0
    private var onChangeDepth = 0

    // MARK: - Track `body` computed property scope

    override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
      if node.pattern.trimmedDescription == "body",
        node.accessorBlock != nil
      {
        bodyDepth += 1
        checkTopLevelConditional(in: node)
      }
      return .visitChildren
    }

    override func visitPost(_ node: PatternBindingSyntax) {
      if node.pattern.trimmedDescription == "body",
        node.accessorBlock != nil
      {
        bodyDepth -= 1
      }
    }

    // MARK: - GeometryReader and panel APIs

    override func visitPost(_ node: DeclReferenceExprSyntax) {
      let name = node.baseName.text

      if name == "GeometryReader" {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            message: .geometryReader,
            confidence: .medium,
            suggestion: "Consider using the Layout protocol or .visualEffect modifier",
          )
        )
        return
      }

      if panelTypes.contains(name) {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            message: .panelAPI(name),
            confidence: .high,
            suggestion: "Use .fileImporter or .fileExporter modifier instead",
          )
        )
        return
      }
    }

    // MARK: - Formatter allocation in body & ForEach patterns

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
      // Track .onChange modifier depth for withAnimation detection
      if let member = node.calledExpression.as(MemberAccessExprSyntax.self),
        member.declName.baseName.text == "onChange"
      {
        onChangeDepth += 1
      }
      return .visitChildren
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
      // Untrack onChange depth
      if let member = node.calledExpression.as(MemberAccessExprSyntax.self),
        member.declName.baseName.text == "onChange"
      {
        onChangeDepth -= 1
      }

      guard bodyDepth > 0 else { return }

      let callee = node.calledExpression.trimmedDescription
      if formatterTypes.contains(callee) {
        violations.append(
          SyntaxViolation(
            position: node.calledExpression.positionAfterSkippingLeadingTrivia,
            message: .formatterInBody(callee),
            confidence: .high,
            suggestion: "Cache as a static property or @State",
          )
        )
      }

      // MARK: - Sorting/filtering inside ForEach

      if callee == "ForEach",
        let firstArg = node.arguments.first
      {
        let argText = firstArg.expression.trimmedDescription
        if argText.contains(".sorted(") || argText.contains(".sorted {")
          || argText.contains(".filter(") || argText.contains(".filter {")
        {
          violations.append(
            SyntaxViolation(
              position: node.positionAfterSkippingLeadingTrivia,
              message: .sortFilterInForEach,
              confidence: .high,
              suggestion: "Precompute the sorted/filtered collection before ForEach",
            )
          )
        }

        // MARK: - Unstable ForEach identity (id: \.self)

        for arg in node.arguments where arg.label?.text == "id" {
          if arg.expression.trimmedDescription == "\\.self" {
            violations.append(
              SyntaxViolation(
                position: arg.positionAfterSkippingLeadingTrivia,
                message: .unstableForEachIdentity,
                confidence: .medium,
                suggestion: "Conform elements to Identifiable or use a stable key path",
              )
            )
          }
        }
      }

      // MARK: - withAnimation inside onChange

      if callee == "withAnimation", onChangeDepth > 0 {
        violations.append(
          SyntaxViolation(
            position: node.calledExpression.positionAfterSkippingLeadingTrivia,
            message: .withAnimationInOnChange,
            confidence: .medium,
            suggestion: "Use .animation(_:value:) modifier scoped to the animating view",
          )
        )
      }
    }

    // MARK: - Top-level if/else in body

    private func checkTopLevelConditional(in node: PatternBindingSyntax) {
      guard let accessorBlock = node.accessorBlock,
        case let .getter(items) = accessorBlock.accessors
      else { return }

      // Only flag when the if/else is the sole root expression
      guard items.count == 1,
        let ifExpr = items.first?.item.as(IfExprSyntax.self),
        ifExpr.elseBody != nil
      else { return }

      violations.append(
        SyntaxViolation(
          position: ifExpr.positionAfterSkippingLeadingTrivia,
          message: .topLevelConditionalBody,
          confidence: .medium,
          suggestion: "Wrap in a stable container like VStack, Group, or ZStack",
        )
      )
    }
  }
}
