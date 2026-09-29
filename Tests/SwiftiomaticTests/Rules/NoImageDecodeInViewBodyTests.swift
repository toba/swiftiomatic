import Foundation
import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoImageDecodeInViewBodyTests: RuleTesting {
  private static func message(_ type: String) -> String {
    "'\(type)(data:)' decodes the image on each 'body' evaluation, which is expensive. Decode it once in a model or in '.task'"
  }

  @Test func uiImageInBodyFlagged() {
    assertLint(
      NoImageDecodeInViewBody.self,
      """
      struct Avatar: View {
        let data: Data
        var body: some View {
          if let image = 1️⃣UIImage(data: data) {
            Image(uiImage: image)
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("UIImage"))]
    )
  }

  @Test func nsImageInlineFlagged() {
    assertLint(
      NoImageDecodeInViewBody.self,
      """
      struct Avatar: View {
        let data: Data
        var body: some View {
          Image(nsImage: 1️⃣NSImage(data: data)!)
          Image(nsImage: 2️⃣NSImage.init(data: data)!)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("NSImage")),
        FindingSpec("2️⃣", message: Self.message("NSImage")),
      ]
    )
  }

  @Test func helperReachedFromBodyFlagged() {
    assertLint(
      NoImageDecodeInViewBody.self,
      """
      struct Avatar: View {
        let data: Data
        var body: some View {
          VStack {
            thumbnail
            picture(for: data)
          }
        }
        @ViewBuilder private var thumbnail: some View {
          Image(uiImage: 1️⃣UIImage(data: data) ?? UIImage())
        }
        private func picture(for data: Data) -> some View {
          Image(uiImage: 2️⃣UIImage(data: data, scale: 2)!)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("UIImage")),
        FindingSpec("2️⃣", message: Self.message("UIImage")),
      ]
    )
  }

  @Test func deferredClosuresNotFlagged() {
    assertLint(
      NoImageDecodeInViewBody.self,
      """
      struct Avatar: View {
        let data: Data
        @State private var image: UIImage?
        var body: some View {
          Color.clear
            .task { image = UIImage(data: data) }
            .onChange(of: data) { image = UIImage(data: data) }
          Button("Load") { image = UIImage(data: data) }
        }
      }
      """,
      findings: []
    )
  }

  @Test func uncalledHelperAndNonViewNotFlagged() {
    assertLint(
      NoImageDecodeInViewBody.self,
      """
      struct Avatar: View {
        let data: Data
        var body: some View { Text("") }
        func decode() -> UIImage? { UIImage(data: data) }
      }
      final class Loader {
        var body: UIImage? { UIImage(data: Data()) }
      }
      """,
      findings: []
    )
  }

  @Test func otherInitializersNotFlagged() {
    assertLint(
      NoImageDecodeInViewBody.self,
      """
      struct Avatar: View {
        var body: some View {
          Image(uiImage: UIImage(named: "avatar")!)
          Image(uiImage: UIImage(systemName: "star")!)
        }
      }
      """,
      findings: []
    )
  }
}
