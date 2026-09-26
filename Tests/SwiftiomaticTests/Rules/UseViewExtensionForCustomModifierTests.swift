@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseViewExtensionForCustomModifierTests: RuleTesting {
  private static func message(_ type: String) -> String {
    "'.modifier(\(type)(...))' exposes the modifier type at the call site. Add a 'View' extension method that applies it, and call that method"
  }

  @Test func guidanceIsShould() {
    #expect(UseViewExtensionForCustomModifier.guidance == .should)
  }

  /// The Thesis `OutlineList` and `ProjectNodeRow` shape.
  @Test func customModifierAtCallSiteFlagged() {
    assertLint(
      UseViewExtensionForCustomModifier.self,
      """
      private struct OutlineRowLabel: View {
        var body: some View {
          content(element, isHovered)
            .onHover { isHovered = $0 }
            .1️⃣modifier(DraggableRow(element: element, drag: drag, height: $height) {
              content(element, false)
            })
            .2️⃣modifier(CloudSharingSheet<Project>(isPresented: $sharing))
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("DraggableRow")),
        FindingSpec("2️⃣", message: Self.message("CloudSharingSheet")),
      ]
    )
  }

  @Test func explicitInitializerFlagged() {
    assertLint(
      UseViewExtensionForCustomModifier.self,
      """
      struct Row: View {
        var body: some View {
          Text("x")
            .1️⃣modifier(DraggableRow.init(height: 4))
            .2️⃣modifier(CloudSharingSheet<Project>.init(isPresented: $sharing))
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("DraggableRow")),
        FindingSpec("2️⃣", message: Self.message("CloudSharingSheet")),
      ]
    )
  }

  @Test func viewExtensionWrapperNotFlagged() {
    assertLint(
      UseViewExtensionForCustomModifier.self,
      """
      extension View {
        func draggableRow(element: Element) -> some View {
          modifier(DraggableRow(element: element))
        }
        func cloudSharing(isPresented: Binding<Bool>) -> some View {
          self.modifier(CloudSharingSheet(isPresented: isPresented))
        }
      }
      extension SwiftUI.View {
        var styled: some View { self.modifier(Styled()) }
      }
      """,
      findings: []
    )
  }

  @Test func otherShapesNotFlagged() {
    assertLint(
      UseViewExtensionForCustomModifier.self,
      """
      Text("x")
        .modifier(style)
        .modifier(isOn ? AnyModifier() : AnyModifier())
        .padding()
      """,
      findings: []
    )
  }
}
