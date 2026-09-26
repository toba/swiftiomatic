import Testing
import Foundation
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct FlagInMemoryModelStoreTests: RuleTesting {
    private static func message(_ label: String = "isStoredInMemoryOnly") -> String {
        "'\(label): true' outside a test or preview discards every saved model when the app quits"
    }

    @Test func appContainerFlagged() {
        assertLint(
            FlagInMemoryModelStore.self,
            """
            @main struct TripsApp: App {
              let container: ModelContainer = {
                let config = ModelConfiguration(1️⃣isStoredInMemoryOnly: true)
                return try! ModelContainer(for: Trip.self, configurations: config)
              }()
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message())]
        )
    }

    @Test func modelContainerModifierFlagged() {
        assertLint(
            FlagInMemoryModelStore.self,
            """
            struct Root: View {
              var body: some View {
                Content().modelContainer(for: Trip.self, 1️⃣inMemory: true)
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("inMemory"))]
        )
    }

    @Test func falseValueNotFlagged() {
        assertLint(
            FlagInMemoryModelStore.self,
            """
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            let other = ModelConfiguration(isStoredInMemoryOnly: flag)
            """,
            findings: []
        )
    }

    @Test func previewMacroNotFlagged() {
        assertLint(
            FlagInMemoryModelStore.self,
            """
            #Preview {
              TripList()
                .modelContainer(for: Trip.self, inMemory: true)
            }
            """,
            findings: []
        )
    }

    @Test func previewProviderNotFlagged() {
        assertLint(
            FlagInMemoryModelStore.self,
            """
            struct TripList_Previews: PreviewProvider {
              static var previews: some View {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                return TripList()
              }
            }
            """,
            findings: []
        )
    }

    @Test func fileNotFlagged() {
        assertLint(
            FlagInMemoryModelStore.self,
            """
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            """,
            findings: [],
            assumingFileURL: URL(fileURLWithPath: "/tmp/Tests/TripTests.swift")
        )
    }
}
