package import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseExtensionInitToKeepMemberwiseTests: RuleTesting {
    private static let message: String =
        "move this initializer to an extension to keep the synthesized memberwise initializer"

    @Test func guidanceIsConsider() {
        #expect(UseExtensionInitToKeepMemberwise.guidance == .consider)
    }

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

    /// The musup `TrackLyrics` shape: the `guard` picks a path and delegates to `self.init` in
    /// both, so it does not reject the input.
    @Test func guardThatDelegatesIsNotACheck() {
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            public struct TrackLyrics {
              public var status: Status
              public var plainText: String

              public init(status: Status, plainText: String = "") {
                self.status = status
                self.plainText = plainText
              }

              public 1️⃣init(record: Record) {
                guard !record.instrumental else {
                  self.init(status: .instrumental)
                  return
                }
                self.init(status: .found, plainText: record.plainLyrics ?? "")
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func combiningInitInPublicTypeFlagged() {
        // From toba-ui `ViewFrameIntent`. The public initializer can move to an extension and still
        // reach the internal memberwise initializer.
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            public struct ViewFrameIntent: Sendable {
              let width: SizeIntent
              let height: SizeIntent

              public 1️⃣init(
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
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func convertingInitFlagged() {
        // From jig `IssueChildJSON`.
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            public struct CommentJSON: Codable, Sendable {
              public let id: String
              public let body: String
              public let commitSHA: String?

              public 1️⃣init(_ comment: Comment) {
                id = comment.id
                body = comment.body
                commitSHA = comment.sha.isEmpty ? nil : comment.sha
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func parsingInitFlagged() {
        // From jig `SearchQuery`.
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            public struct SearchQuery: Sendable {
              public let groups: [[String]]

              public 1️⃣init(parsing text: String) {
                var groups: [[String]] = []
                for word in text.split(separator: " ") {
                  guard !word.isEmpty else { continue }
                  groups.append([String(word)])
                }
                self.groups = groups
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func delegatingInitsFlagged() {
        // From jig `JigService` and `CitationReview`. The type is public, and one stored property
        // is internal.
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            public struct Service: Sendable {
              public let database: Database
              public let userID: String
              let watch: Watch

              public 1️⃣init(database: Database, user: User) {
                self.init(database: database, actingRecordName: user.recordName)
              }

              2️⃣init(database: Database, actingRecordName: String, watch: Watch = .shared) {
                self.database = database
                userID = actingRecordName
                self.watch = watch
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message),
                FindingSpec("2️⃣", message: Self.message),
            ]
        )
    }

    @Test func derivedPropertyInitFlagged() {
        // From jig `ShellCommandPart` and `KeyedRow`.
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            struct KeyedRow: Identifiable {
              let id: String
              let row: Row
              let showsAvatar: Bool

              1️⃣init(row: Row, showsAvatar: Bool) {
                id = "\\(row.id)#\\(showsAvatar ? 1 : 0)"
                self.row = row
                self.showsAvatar = showsAvatar
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func guardingInitsNotFlagged() {
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            struct Range {
              let low: Int
              let high: Int

              init(ordered pair: (Int, Int)) {
                guard pair.0 <= pair.1 else { fatalError("unordered") }
                low = pair.0
                high = pair.1
              }

              init(bounds: ClosedRange<Int>) {
                assert(!bounds.isEmpty)
                low = bounds.lowerBound
                high = bounds.upperBound
              }

              init(start: Int, end: Int) {
                if start > end { fatalError("unordered") }
                low = start
                high = end
              }
            }
            """,
            findings: []
        )
    }

    @Test func parameterlessInitWithDefaultsNotFlagged() {
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            struct Counter {
              var count = 0

              init() {
                count = 1
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

    @Test func constantAssignmentInitFlagged() {
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            struct EnvProperties {
              var envName: String?
              var ended: Bool
              var numRows: Int
              var alignment: ColumnAlignment?

              1️⃣init(name: String?, alignment: ColumnAlignment? = nil) {
                envName = name
                numRows = 0
                ended = false
                self.alignment = alignment
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func viewWithEnvironmentPropertyNotFlagged() {
        // The attribute arguments set up `dismiss`, so the memberwise initializer is
        // `init(title:)`. An extension cannot redeclare it.
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            struct Header: View {
              let title: String
              @Environment(\\.dismiss) private var dismiss

              init(title: String) {
                self.title = title.uppercased()
              }

              var body: some View { Text(title) }
            }
            """,
            findings: []
        )
    }

    @Test func viewWithPrivateDefaultedStateNotFlagged() {
        // SE-0502 drops `isExpanded` from the memberwise initializer, because it is private and has
        // an initial value. The memberwise initializer is `init(title:)`.
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            struct Header: View {
              let title: String
              @State private var isExpanded = false

              init(title: String) {
                self.title = title.uppercased()
              }

              var body: some View { Text(title) }
            }
            """,
            findings: []
        )
    }

    @Test func optionalLetWithoutValueStaysInMemberwiseLabels() {
        // An optional `let` with no initial value does not start as `nil`. The memberwise
        // initializer takes it, so `init(title:)` differs from the memberwise labels.
        assertLint(
            UseExtensionInitToKeepMemberwise.self,
            """
            struct Header {
              let title: String
              private let subtitle: String?

              1️⃣init(title: String) {
                self.title = title
                subtitle = nil
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }
}
