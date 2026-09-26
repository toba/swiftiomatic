import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseExtensionInitToKeepMemberwiseTests: RuleTesting {
    private static let message: String =
        "move this initializer to an extension to keep the synthesized memberwise initializer"

    @Test func relabeledInitFlagged() {
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            struct Point {
              let x: Double
              let y: Double

              1️⃣init(horizontal: Double, vertical: Double) {
                self.x = horizontal
                self.y = vertical
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func reorderedInitFlagged() {
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            struct Point {
              let x: Double
              let y: Double

              1️⃣init(y: Double, x: Double) {
                self.x = x
                self.y = y
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func matchingLabelsNotFlagged() {
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            struct Point {
              let x: Double
              let y: Double

              init(x: Double, y: Double = 0) {
                self.x = x
                self.y = y
              }
            }
            """,
            findings: []
        )
    }

    @Test func validatingInitNotFlagged() {
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            struct Range {
              let low: Int
              let high: Int

              init(from low: Int, to high: Int) {
                precondition(low <= high)
                self.low = low
                self.high = high
              }
            }
            """,
            findings: []
        )
    }

    @Test func normalizingInitNotFlagged() {
        // From toba-ui `ViewFrameIntent`.
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            public struct ViewFrameIntent: Sendable {
              let width: SizeIntent
              let height: SizeIntent

              public init(
                minWidth: CGFloat? = nil,
                idealWidth: CGFloat? = nil,
                maxWidth: CGFloat? = nil,
                minHeight: CGFloat? = nil,
                idealHeight: CGFloat? = nil,
                maxHeight: CGFloat? = nil,
              ) {
                width = SizeIntent(minimum: minWidth, ideal: idealWidth, maximum: maxWidth)
                height = SizeIntent(minimum: minHeight, ideal: idealHeight, maximum: maxHeight)
              }
            }
            """,
            findings: []
        )
    }

    @Test func publicTypeWithInternalPropertiesNotFlagged() {
        // From toba-ui `FlowLayout`.
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            public struct FlowLayout: Layout {
              let spacing: CGFloat?
              let limitHeight: CGFloat?
              let alignment: HorizontalAlignment

              public init(
                spacing: CGFloat? = nil,
                alignment: HorizontalAlignment = .leading,
                limitHeight: CGFloat? = nil,
              ) {
                self.spacing = spacing
                self.alignment = alignment
                self.limitHeight = limitHeight
              }
            }
            """,
            findings: []
        )
    }

    @Test func initInExtensionNotFlagged() {
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            struct Point {
              let x: Double
              let y: Double
            }

            extension Point {
              init(horizontal: Double, vertical: Double) {
                self.x = horizontal
                self.y = vertical
              }
            }
            """,
            findings: []
        )
    }

    @Test func classInitNotFlagged() {
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            final class Point {
              let x: Double
              let y: Double

              init(horizontal: Double, vertical: Double) {
                self.x = horizontal
                self.y = vertical
              }
            }
            """,
            findings: []
        )
    }

    @Test func failableAndThrowingInitsNotFlagged() {
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            struct Point {
              let x: Double
              let y: Double

              init?(horizontal: Double, vertical: Double) {
                self.x = horizontal
                self.y = vertical
              }

              init(h: Double, v: Double) throws {
                self.x = h
                self.y = v
              }
            }
            """,
            findings: []
        )
    }
}
