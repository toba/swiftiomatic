import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoHelperMethodInViewTests: RuleTesting {
    private static func message(_ name: String) -> String {
        "'body' runs '\(name)' on each evaluation; move the work into a model or a child view that SwiftUI can compare"
    }

    @Test func methodPassedAsFunctionValue() {
        assertLint(
            NoHelperMethodInView.self,
            """
            struct MathView: View {
                let latex: String
                @State private var cache = RenderCache()

                var body: some View {
                    switch cache.result(for: latex, build: render) {
                        case let .success(info): Canvas { _, _ in }
                        case .failure: Text("error")
                    }
                }

                private 1️⃣func render() -> Result<RenderInfo, any Error> {
                    .success(RenderInfo())
                }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("render"))]
        )
    }

    @Test func methodCalledInBodyAndInExtension() {
        assertLint(
            NoHelperMethodInView.self,
            """
            struct Badge: View {
                let count: Int

                var body: some View {
                    Text(self.label(for: count)).foregroundStyle(tint())
                }
            }

            extension Badge {
                1️⃣func label(for count: Int) -> String { "\\(count)" }
                2️⃣func tint() -> Color { count > 9 ? .red : .blue }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("label")),
                FindingSpec("2️⃣", message: Self.message("tint")),
            ]
        )
    }

    @Test func methodNotReferencedFromBodyIsIgnored() {
        assertLint(
            NoHelperMethodInView.self,
            """
            struct MathView: View {
                var fontSize: CGFloat = 20

                var body: some View { Text("x") }

                func fontSize(_ size: CGFloat) -> MathView {
                    var copy = self
                    copy.fontSize = size
                    return copy
                }

                func reset() {}
            }
            """,
            findings: []
        )
    }

    @Test func viewFactoryAndStaticMembersAreIgnored() {
        assertLint(
            NoHelperMethodInView.self,
            """
            struct List: View {
                var body: some View { row(); header; Self.format(1); other.render() }

                func row() -> some View { Text("r") }
                static func format(_ value: Int) -> String { "" }
                func render() -> Int { 0 }
            }
            """,
            findings: []
        )
    }

    @Test func nonViewTypeIsIgnored() {
        assertLint(
            NoHelperMethodInView.self,
            """
            struct Model {
                var body: String { render() }
                func render() -> String { "" }
            }
            """,
            findings: []
        )
    }
}
