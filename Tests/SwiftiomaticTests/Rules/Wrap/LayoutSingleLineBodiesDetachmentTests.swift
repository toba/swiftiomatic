import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

/// Holds every position read in `LayoutSingleLineBodies` on the parsed tree
///
/// The rewriter hands `transform` a detached copy of the node whenever a child changed. A detached
/// tree starts at offset 0, so a line or a column read off it lands on a different part of the
/// file. Each case collapses an inner literal first, which detaches the outer node, then checks
/// that the outer measurement still reflects the real column.
@Suite
struct SingleLineBodiesDetachmentTests: RuleTesting {
    private func inlineConfig(lineLength: Int) -> Configuration {
        var config = Configuration.forTesting(enabledRule: LayoutSingleLineBodies.key)
        config[LayoutSingleLineBodies.self] = {
            var c = LayoutSingleLineBodiesConfiguration()
            c.mode = .inline
            return c
        }()
        config[LineLength.self] = lineLength
        return config
    }

    @Test func measuresFunctionBracePrefixAfterArrayCollapses() {
        // The array collapses first, so the rewriter hands the function transform a detached node.
        // Measured at its real column the inlined function is 46 wide, which exceeds the limit, so
        // the body stays wrapped. Measured on the detached copy it reads 38 and would collapse.
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                enum T {
                    static func f() -> [Int] {
                        return 1️⃣[
                            1,
                            2
                        ]
                    }
                }
                """,
            expected: """
                enum T {
                    static func f() -> [Int] {
                        return [1, 2]
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place collection literal on same line as declaration")
            ],
            configuration: inlineConfig(lineLength: 40))
    }

    @Test func measuresOuterBracketColumnAfterInnerArrayCollapses() {
        // The inner array collapses first, which detaches the outer array. The outer literal is 30
        // wide at its real column and 11 wide on the detached copy.
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                enum T {
                    static let x = [
                        1️⃣[
                            1,
                            2
                        ],
                        3
                    ]
                }
                """,
            expected: """
                enum T {
                    static let x = [
                        [1, 2],
                        3
                    ]
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place collection literal on same line as declaration")
            ],
            configuration: inlineConfig(lineLength: 20))
    }

    @Test func measuresClosureBraceColumnAfterArrayCollapses() {
        // The array collapses first, which detaches the closure. The inlined closure is 51 wide at
        // its real column and 32 wide on the detached copy.
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                enum T {
                    static let f = { () -> [Int] in
                        return 1️⃣[
                            1,
                            2
                        ]
                    }
                }
                """,
            expected: """
                enum T {
                    static let f = { () -> [Int] in
                        return [1, 2]
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place collection literal on same line as declaration")
            ],
            configuration: inlineConfig(lineLength: 40))
    }
}
