import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoUnusedPrivateMemberTests: RuleTesting {
    private static func message(_ name: String) -> String {
        "nothing in the file references private '\(name)'. Remove it"
    }

    @Test func guidanceIsShould() { #expect(NoUnusedPrivateMember.guidance == .should) }

    @Test func unusedMembersFlagged() {
        assertLint(
            NoUnusedPrivateMember.self,
            """
            struct Parser {
              private let 1️⃣cache = [String: Int]()
              private var 2️⃣total: Int { 0 }
              private static let 3️⃣shared = 1
              private func 4️⃣helper() {}
              fileprivate func 5️⃣other() {}

              func run() {}
            }

            private func 6️⃣freeHelper() {}
            private let 7️⃣globalValue = 1
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("cache")),
                FindingSpec("2️⃣", message: Self.message("total")),
                FindingSpec("3️⃣", message: Self.message("shared")),
                FindingSpec("4️⃣", message: Self.message("helper")),
                FindingSpec("5️⃣", message: Self.message("other")),
                FindingSpec("6️⃣", message: Self.message("freeHelper")),
                FindingSpec("7️⃣", message: Self.message("globalValue")),
            ]
        )
    }

    @Test func referencedMembersNotFlagged() {
        assertLint(
            NoUnusedPrivateMember.self,
            """
            final class Controller {
              private var count = 0
              private var name = ""
              private static let limit = 3
              @State private var isOn = false
              @Published private var value = 0
              private func tap() {}
              private func other(_ x: Int) {}
              private func third() {}

              func run() {
                count += 1
                print(self.name, Controller.limit, $isOn, _value)
                let action = #selector(tap)
                let f = other(_:)
                [1].forEach(Self.third)
              }
            }

            private func helper() {}
            func main() { helper() }
            """,
            findings: []
        )
    }

    @Test func referenceFromExtensionCounts() {
        assertLint(
            NoUnusedPrivateMember.self,
            """
            struct Row {
              fileprivate var title = ""
            }

            extension Row {
              var upper: String { title.uppercased() }
            }
            """,
            findings: []
        )
    }

    @Test func exemptMembersNotFlagged() {
        assertLint(
            NoUnusedPrivateMember.self,
            """
            final class ViewController: NSViewController {
              @IBOutlet private var label: NSTextField!
              @IBAction private func tapped(_ sender: Any) {}
              @objc private func handle() {}
              override private func viewDidLoad() {}
              dynamic private func swap() {}
              @_dynamicReplacement(for: foo) private func replacement() {}
              private init(x: Int) {}
              private subscript(i: Int) -> Int { i }
              private func callAsFunction() {}
              private static func == (lhs: ViewController, rhs: ViewController) -> Bool { true }
            }

            @objcMembers final class Bridge: NSObject {
              private func exposed() {}
            }

            @Suite struct Tests {
              @Test private func works() {}
            }
            """,
            findings: []
        )
    }

    @Test func fileprivateMemberOfConformingTypeNotFlagged() {
        assertLint(
            NoUnusedPrivateMember.self,
            """
            private protocol Named { var name: String { get } }

            private struct User: Named {
              fileprivate var name: String { "" }
              private func 1️⃣unused() {}
            }

            private struct Other {
              fileprivate func describe() -> String { "" }
            }

            extension Other: CustomStringConvertible {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("unused"))]
        )
    }

    @Test func storedPropertyOfSynthesizingTypeNotFlagged() {
        assertLint(
            NoUnusedPrivateMember.self,
            """
            struct Payload: Codable {
              private let id: Int
            }

            struct Key: Hashable {
              private var raw: String
            }

            struct Row: View {
              @State private var 1️⃣unusedState = 0
              private var 2️⃣unusedComputed: Int { 0 }
              var body: some View { EmptyView() }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("unusedState")),
                FindingSpec("2️⃣", message: Self.message("unusedComputed")),
            ]
        )
    }

    @Test func privateSetterIsNotPrivateMember() {
        assertLint(
            NoUnusedPrivateMember.self,
            """
            struct Counter {
              private(set) var count = 0
            }
            """,
            findings: []
        )
    }
}
