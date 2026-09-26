import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct FlagObserverSkippedInInitTests: RuleTesting {
    private static func message(_ name: String) -> String {
        "this assignment does not run the observer of '\(name)'; assign it in a 'defer' block or a method if the observer must run"
    }

    @Test func selfAssignmentInClassInit() {
        assertLint(
            FlagObserverSkippedInInit.self,
            """
            final class Typesetter {
                var style: LineStyle { didSet { cachedFont = nil } }
                private var cachedFont: Font?
                var cramped = false

                init(style: LineStyle, cramped: Bool) {
                    self.cramped = cramped
                    1️⃣self.style = style
                }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("style"))]
        )
    }

    @Test func bareAssignmentAndWillSetInStruct() {
        assertLint(
            FlagObserverSkippedInInit.self,
            """
            struct Meter {
                var level: Double {
                    willSet { log(newValue) }
                }

                init() {
                    1️⃣level = 0
                }

                init(start: Double) {
                    2️⃣level += start
                }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("level")),
                FindingSpec("2️⃣", message: Self.message("level")),
            ]
        )
    }

    @Test func deferAssignmentCoversTheProperty() {
        assertLint(
            FlagObserverSkippedInInit.self,
            """
            final class Model {
                var name: String { didSet { refresh() } }

                init(name: String) {
                    defer { self.name = name }
                    self.name = ""
                }
            }
            """,
            findings: []
        )
    }

    @Test func setupMethodAssignmentCoversTheProperty() {
        assertLint(
            FlagObserverSkippedInInit.self,
            """
            final class Model {
                var name: String { didSet { refresh() } }

                init(name: String) {
                    self.name = ""
                    self.configure(name)
                }

                private func configure(_ value: String) {
                    name = value
                }
            }
            """,
            findings: []
        )
    }

    @Test func setupMethodForAnotherPropertyDoesNotCover() {
        assertLint(
            FlagObserverSkippedInInit.self,
            """
            final class Model {
                var name: String { didSet { refresh() } }
                var title = ""

                init(name: String) {
                    1️⃣self.name = name
                    configure()
                }

                private func configure() {
                    title = "x"
                }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("name"))]
        )
    }

    @Test func nestedScopesDoNotTrigger() {
        assertLint(
            FlagObserverSkippedInInit.self,
            """
            final class Model {
                var name = "" { didSet { refresh() } }
                var onChange: (() -> Void)?

                init() {
                    onChange = { [unowned self] in self.name = "changed" }
                    func reset() { }
                }
            }
            """,
            findings: []
        )
    }

    @Test func unobservedAndComputedPropertiesDoNotTrigger() {
        assertLint(
            FlagObserverSkippedInInit.self,
            """
            struct Point {
                var x: Double
                var y: Double
                var sum: Double { x + y }
                var label: String {
                    get { "\\(x)" }
                    set { x = Double(newValue) ?? 0 }
                }

                init(x: Double, y: Double) {
                    self.x = x
                    self.y = y
                }
            }
            """,
            findings: []
        )
    }

    @Test func memberOfAnotherValueDoesNotTrigger() {
        assertLint(
            FlagObserverSkippedInInit.self,
            """
            final class Node {
                var value = 0 { didSet { notify() } }
                var child: Node?

                init(child: Node) {
                    child.value = 1
                    self.child = child
                }
            }
            """,
            findings: []
        )
    }

    @Test func staticObservedPropertyDoesNotTrigger() {
        assertLint(
            FlagObserverSkippedInInit.self,
            """
            final class Counter {
                static var total = 0 { didSet { log() } }

                init() {
                    Counter.total = 1
                }
            }
            """,
            findings: []
        )
    }
}
