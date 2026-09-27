import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseGuardForMainPathTests: RuleTesting {
    private static let message =
        "the main path sits inside this trailing 'if'; use 'guard ... else { return }' and unindent the body"

    @Test func trailingIfInVoidFunction() {
        assertLint(
            UseGuardForMainPath.self,
            """
            class Display {
                func draw(_ context: CGContext) {
                    1️⃣if localBackgroundColor != nil {
                        context.saveGState()
                        context.setFillColor(localBackgroundColor!.cgColor)
                        context.fill(displayBounds())
                        context.restoreGState()
                    }
                }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func trailingIfAfterOtherStatementsInInit() {
        assertLint(
            UseGuardForMainPath.self,
            """
            struct Cache {
                init(values: [Int]?) {
                    self.count = 0
                    1️⃣if let values {
                        count = values.count
                        storage = values
                        sorted = values.sorted()
                    }
                }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func shortTrailingIfIsIgnored() {
        assertLint(
            UseGuardForMainPath.self,
            """
            func update() {
                if isDirty {
                    redraw()
                    isDirty = false
                }
            }
            """,
            findings: []
        )
    }

    @Test func ifWithElseIsIgnored() {
        assertLint(
            UseGuardForMainPath.self,
            """
            func update() {
                if isDirty {
                    a()
                    b()
                    c()
                } else {
                    d()
                }
            }
            """,
            findings: []
        )
    }

    @Test func ifFollowedByStatementsIsIgnored() {
        assertLint(
            UseGuardForMainPath.self,
            """
            func update() {
                if isDirty {
                    a()
                    b()
                    c()
                }
                finish()
            }
            """,
            findings: []
        )
    }

    @Test func trailingIfInLoopOrClosureIsIgnored() {
        assertLint(
            UseGuardForMainPath.self,
            """
            func update() {
                items.forEach { item in
                    if item.isDirty {
                        a()
                        b()
                        c()
                    }
                }
                for item in items {
                    if item.isDirty {
                        a()
                        b()
                        c()
                    }
                }
            }
            """,
            findings: []
        )
    }
}
