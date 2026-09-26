@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseKeyPathTests: RuleTesting {
  @Test func mapWithTrailingClosure() {
    assertFormatting(
      UseKeyPath.self,
      input: """
        let names = items.map 1️⃣{ $0.name }
        """,
      expected: """
        let names = items.map(\\.name)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use keyPath expression instead of closure in 'map'"),
      ]
    )
  }

  @Test func compactMapWithTrailingClosure() {
    assertFormatting(
      UseKeyPath.self,
      input: """
        let names = items.compactMap 1️⃣{ $0.optionalName }
        """,
      expected: """
        let names = items.compactMap(\\.optionalName)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use keyPath expression instead of closure in 'compactMap'"),
      ]
    )
  }

  @Test func filterWithTrailingClosure() {
    assertFormatting(
      UseKeyPath.self,
      input: """
        let active = items.filter 1️⃣{ $0.isActive }
        """,
      expected: """
        let active = items.filter(\\.isActive)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use keyPath expression instead of closure in 'filter'"),
      ]
    )
  }

  @Test func mapWithParenthesizedClosure() {
    assertFormatting(
      UseKeyPath.self,
      input: """
        let names = items.map(1️⃣{ $0.name })
        """,
      expected: """
        let names = items.map(\\.name)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use keyPath expression instead of closure in 'map'"),
      ]
    )
  }

  @Test func chainedPropertyAccess() {
    assertFormatting(
      UseKeyPath.self,
      input: """
        let names = items.map 1️⃣{ $0.foo.bar }
        """,
      expected: """
        let names = items.map(\\.foo.bar)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use keyPath expression instead of closure in 'map'"),
      ]
    )
  }

  @Test func containsWhereWithClosure() {
    assertFormatting(
      UseKeyPath.self,
      input: """
        let has = items.contains(where: 1️⃣{ $0.isValid })
        """,
      expected: """
        let has = items.contains(where: \\.isValid)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use keyPath expression instead of closure in 'contains(where:)'"),
      ]
    )
  }

  @Test func mapWithComplexClosure() {
    assertFormatting(
      UseKeyPath.self,
      input: """
        let names = items.map { $0.name.uppercased() }
        """,
      expected: """
        let names = items.map { $0.name.uppercased() }
        """,
      findings: []
    )
  }

  @Test func mapWithNamedParameter() {
    assertFormatting(
      UseKeyPath.self,
      input: """
        let names = items.map { item in item.name }
        """,
      expected: """
        let names = items.map { item in item.name }
        """,
      findings: []
    )
  }

  @Test func mapWithMultipleStatements() {
    assertFormatting(
      UseKeyPath.self,
      input: """
        let names = items.map {
          let x = $0.name
          return x
        }
        """,
      expected: """
        let names = items.map {
          let x = $0.name
          return x
        }
        """,
      findings: []
    )
  }

  @Test func keyPathAlreadyUsed() {
    assertFormatting(
      UseKeyPath.self,
      input: """
        let names = items.map(\\.name)
        """,
      expected: """
        let names = items.map(\\.name)
        """,
      findings: []
    )
  }

  @Test func containsWithoutWhere() {
    assertFormatting(
      UseKeyPath.self,
      input: """
        let has = items.contains { $0.isValid }
        """,
      expected: """
        let has = items.contains { $0.isValid }
        """,
      findings: []
    )
  }

  @Test func unrelatedMethod() {
    assertFormatting(
      UseKeyPath.self,
      input: """
        let x = items.forEach { $0.doSomething }
        """,
      expected: """
        let x = items.forEach { $0.doSomething }
        """,
      findings: []
    )
  }

  // MARK: - Adapted from SwiftFormat

  @Test func bareDollarZeroNotConverted() {
    // `{ $0 }` is not a property access — don't convert
    assertFormatting(
      UseKeyPath.self,
      input: """
        let foo = bar.map { $0 }
        """,
      expected: """
        let foo = bar.map { $0 }
        """,
      findings: []
    )
  }

  @Test func methodCallNotConverted() {
    // `$0.foo()` is a method call, not a property access
    assertFormatting(
      UseKeyPath.self,
      input: """
        let foo = bar.map { $0.foo() }
        """,
      expected: """
        let foo = bar.map { $0.foo() }
        """,
      findings: []
    )
  }

  @Test func optionalChainingNotConverted() {
    // `$0?.foo` uses optional chaining — don't convert
    assertFormatting(
      UseKeyPath.self,
      input: """
        let foo = bar.map { $0?.foo }
        """,
      expected: """
        let foo = bar.map { $0?.foo }
        """,
      findings: []
    )
  }

  @Test func compoundExpressionNotConverted() {
    assertFormatting(
      UseKeyPath.self,
      input: """
        let foo = bar.map { $0.foo || baz }
        """,
      expected: """
        let foo = bar.map { $0.foo || baz }
        """,
      findings: []
    )
  }

  @Test func multipleTrailingClosuresNotConverted() {
    assertFormatting(
      UseKeyPath.self,
      input: """
        foo.map { $0.bar } reverse: { $0.bar }
        """,
      expected: """
        foo.map { $0.bar } reverse: { $0.bar }
        """,
      findings: []
    )
  }

  @Test func multilineClosureConverted() {
    assertFormatting(
      UseKeyPath.self,
      input: """
        let foo = bar.map 1️⃣{
            $0.foo
        }
        """,
      expected: """
        let foo = bar.map(\\.foo)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use keyPath expression instead of closure in 'map'"),
      ]
    )
  }

  // MARK: - Any (Root) -> Value closure argument

  @Test func forEachContentClosureConverted() {
    // From Thesis `ErrorAlert.swift`
    assertFormatting(
      UseKeyPath.self,
      input: """
        var actions: some View { ForEach(responses) 1️⃣{ $0.button } }
        """,
      expected: """
        var actions: some View { ForEach(responses, content: \\.button) }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use keyPath expression instead of closure in 'ForEach'"),
      ]
    )
  }

  @Test func onGeometryChangeTransformConverted() {
    // From Thesis `OutlineList.swift`
    assertFormatting(
      UseKeyPath.self,
      input: """
        let decorated = content
          .onGeometryChange(for: CGFloat.self) 1️⃣{
            $0.size.height
          } action: {
            height = $0
          }
        """,
      expected: """
        let decorated = content
          .onGeometryChange(for: CGFloat.self, of: \\.size.height) {
            height = $0
          }
        """,
      findings: [
        FindingSpec(
          "1️⃣", message: "use keyPath expression instead of closure in 'onGeometryChange'"),
      ]
    )
  }

  @Test func labeledClosureArgumentConverted() {
    // From Thesis `ExportView.swift`
    assertFormatting(
      UseKeyPath.self,
      input: """
        PreviewWindow(
          selections: LocalFile.Exportable.allCases,
          displayName: 1️⃣{ $0.name },
          render: { format in renderPlaceholder(for: format) },
        )
        """,
      expected: """
        PreviewWindow(
          selections: LocalFile.Exportable.allCases,
          displayName: \\.name,
          render: { format in renderPlaceholder(for: format) },
        )
        """,
      findings: [
        FindingSpec(
          "1️⃣", message: "use keyPath expression instead of closure in 'PreviewWindow(displayName:)'"),
      ]
    )
  }

  @Test func actionLabelsAndUnknownTrailingClosuresNotConverted() {
    // A `Void` result cannot take a key path, and an unknown call hides the trailing closure's label
    assertFormatting(
      UseKeyPath.self,
      input: """
        Toggle(isOn: binding, action: { $0.toggle })
        Sheet(onDismiss: { $0.close }, perform: { $0.run })
        Custom(items) { $0.name }
        ForEach(items) { $0.name } footer: { Text("x") }
        ForEach(items) {
          let x = $0.name
          x
        }
        """,
      expected: """
        Toggle(isOn: binding, action: { $0.toggle })
        Sheet(onDismiss: { $0.close }, perform: { $0.run })
        Custom(items) { $0.name }
        ForEach(items) { $0.name } footer: { Text("x") }
        ForEach(items) {
          let x = $0.name
          x
        }
        """,
      findings: []
    )
  }
  @Test func findingInRewrittenCallSitsOnOriginalClosure() {
    // The inner conversion detaches the outer call, so the outer finding must use the original.
    assertFormatting(
      UseKeyPath.self,
      input: """
        struct Rows: View {
          var body: some View {
            ForEach(items.filter(1️⃣{ $0.isOn })) 2️⃣{ $0.row }
          }
        }
        """,
      expected: """
        struct Rows: View {
          var body: some View {
            ForEach(items.filter(\\.isOn), content: \\.row)
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use keyPath expression instead of closure in 'filter'"),
        FindingSpec("2️⃣", message: "use keyPath expression instead of closure in 'ForEach'"),
      ]
    )
  }
}
