@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoRepresentableAsDelegateTests: RuleTesting {
    private static func message(_ property: String, _ type: String) -> String {
        "assign 'context.coordinator' to '\(property)', not 'self'. SwiftUI recreates the value of '\(type)' on each update"
    }

    @Test func uiViewRepresentableFlagged() {
        assertLint(
            NoRepresentableAsDelegate.self,
            """
            struct SearchField: UIViewRepresentable {
              func makeUIView(context: Context) -> UISearchBar {
                let bar = UISearchBar()
                1️⃣bar.delegate = self
                return bar
              }
              func updateUIView(_ bar: UISearchBar, context: Context) {}
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("delegate", "SearchField"))]
        )
    }

    @Test func nsViewAndControllerRepresentablesFlagged() {
        assertLint(
            NoRepresentableAsDelegate.self,
            """
            struct WebView: NSViewRepresentable {
              func makeNSView(context: Context) -> WKWebView {
                let view = WKWebView()
                1️⃣view.navigationDelegate = self
                return view
              }
            }

            struct Picker: UIViewControllerRepresentable {
              func makeUIViewController(context: Context) -> PHPickerViewController {
                let picker = PHPickerViewController(configuration: .init())
                2️⃣picker.delegate = self
                return picker
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("navigationDelegate", "WebView")),
                FindingSpec("2️⃣", message: Self.message("delegate", "Picker")),
            ]
        )
    }

    @Test func conformanceInExtensionFlagged() {
        assertLint(
            NoRepresentableAsDelegate.self,
            """
            struct MapPane {
              func makeUIView(context: Context) -> MKMapView {
                let map = MKMapView()
                1️⃣map.delegate = self
                return map
              }
            }

            extension MapPane: UIViewRepresentable {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("delegate", "MapPane"))]
        )
    }

    @Test func coordinatorDelegateNotFlagged() {
        assertLint(
            NoRepresentableAsDelegate.self,
            """
            struct SearchField: UIViewRepresentable {
              func makeCoordinator() -> Coordinator { Coordinator() }

              func makeUIView(context: Context) -> UISearchBar {
                let bar = UISearchBar()
                bar.delegate = context.coordinator
                return bar
              }

              final class Coordinator: NSObject, UISearchBarDelegate {
                func attach(_ bar: UISearchBar) {
                  bar.delegate = self
                }
              }
            }
            """,
            findings: []
        )
    }

    @Test func delegateToSelfOutsideRepresentableNotFlagged() {
        assertLint(
            NoRepresentableAsDelegate.self,
            """
            final class SearchController: UIViewController, UISearchBarDelegate {
              override func viewDidLoad() {
                searchBar.delegate = self
              }
            }

            struct Row: View {
              var body: some View { Text("") }
              func attach(_ bar: UISearchBar) { bar.tag = self.tag }
            }
            """,
            findings: []
        )
    }
}
