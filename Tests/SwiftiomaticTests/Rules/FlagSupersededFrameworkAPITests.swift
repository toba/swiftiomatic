import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct FlagSupersededFrameworkAPITests: RuleTesting {
    private static let metricManager = "'MXMetricManager' is deprecated — use 'MetricManager'"
    private static let metricReports =
        "the 'MX' payload types are deprecated — read 'MetricManager.metricReports' instead"
    private static let backgroundAssets =
        "'NSBundleResourceRequest' is deprecated on OS 27 — stage assets with Background Assets instead"
    private static let attributedString =
        "store 'AttributedString', not the reference type 'NSAttributedString'"
    private static let attributedStringOwner = "the type that stores the value"
    private static let animatableMacro =
        "replace the hand-written 'animatableData' with the '@Animatable' macro"
    private static let animatableConformance = "the explicit 'Animatable' conformance"

    @Test func sharedManagerReferenceFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            func subscribe() {
              1️⃣MXMetricManager.shared.add(self)
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.metricManager)]
        )
    }

    @Test func subscriberConformanceFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            final class Collector: 1️⃣MXMetricManagerSubscriber {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.metricManager)]
        )
    }

    @Test func payloadParameterFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            func didReceive(_ payloads: [1️⃣MXMetricPayload]) {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.metricReports)]
        )
    }

    @Test func diagnosticPayloadFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            var latest: 1️⃣MXDiagnosticPayload?
            """,
            findings: [FindingSpec("1️⃣", message: Self.metricReports)]
        )
    }

    @Test func bundleResourceRequestFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            func stage() {
              let request = 1️⃣NSBundleResourceRequest(tags: ["level1"])
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.backgroundAssets)]
        )
    }

    @Test func bundleResourceRequestAnnotationFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            var request: 1️⃣NSBundleResourceRequest?
            """,
            findings: [FindingSpec("1️⃣", message: Self.backgroundAssets)]
        )
    }

    @Test func metricManagerNotFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            func subscribe() async {
              for await report in MetricManager.shared.metricReports {
                handle(report)
              }
            }
            """,
            findings: []
        )
    }

    @Test func unrelatedTypeNotFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            var request: URLRequest?
            """,
            findings: []
        )
    }

    // MARK: NSAttributedString storage

    @Test func attributedStringStoredPropertyFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            struct 1️⃣Note {
              var body: 2️⃣NSAttributedString
            }
            """,
            findings: [
                FindingSpec(
                    "2️⃣",
                    message: Self.attributedString,
                    notes: [NoteSpec("1️⃣", message: Self.attributedStringOwner)]
                )
            ]
        )
    }

    @Test func mutableAttributedStringOptionalFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            @Model final class 1️⃣Draft {
              var text: 2️⃣NSMutableAttributedString?
            }
            """,
            findings: [
                FindingSpec(
                    "2️⃣",
                    message: Self.attributedString,
                    notes: [NoteSpec("1️⃣", message: Self.attributedStringOwner)]
                )
            ]
        )
    }

    @Test func attributedStringInitializerParameterFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            struct 1️⃣Note {
              init(body: 2️⃣NSAttributedString) {}
            }
            """,
            findings: [
                FindingSpec(
                    "2️⃣",
                    message: Self.attributedString,
                    notes: [NoteSpec("1️⃣", message: Self.attributedStringOwner)]
                )
            ]
        )
    }

    @Test func attributedStringLocalNotFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            func render() {
              let text: NSAttributedString = make()
              draw(text)
            }
            """,
            findings: []
        )
    }

    @Test func attributedStringComputedPropertyNotFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            struct Note {
              var body: AttributedString
              var legacy: NSAttributedString { NSAttributedString(body) }
            }
            """,
            findings: []
        )
    }

    @Test func swiftAttributedStringNotFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            struct Note {
              var body: AttributedString
            }
            """,
            findings: []
        )
    }

    // MARK: Manual Animatable

    @Test func handWrittenAnimatableDataFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            struct Wave: 1️⃣Animatable {
              var phase: Double
              2️⃣var animatableData: Double {
                get { phase }
                set { phase = newValue }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "2️⃣",
                    message: Self.animatableMacro,
                    notes: [NoteSpec("1️⃣", message: Self.animatableConformance)]
                )
            ]
        )
    }

    @Test func handWrittenAnimatableDataOnShapeExtensionFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            extension Wave: 1️⃣Shape {
              2️⃣var animatableData: AnimatablePair<Double, Double> {
                get { AnimatablePair(phase, amplitude) }
                set { (phase, amplitude) = (newValue.first, newValue.second) }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "2️⃣",
                    message: Self.animatableMacro,
                    notes: [NoteSpec("1️⃣", message: Self.animatableConformance)]
                )
            ]
        )
    }

    @Test func animatableMacroNotFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            @Animatable
            struct Wave: Shape {
              var phase: Double
            }
            """,
            findings: []
        )
    }

    @Test func animatableDataWithoutConformanceNotFlagged() {
        assertLint(
            FlagSupersededFrameworkAPI.self,
            """
            struct Sample {
              var animatableData: Double = 0
            }
            """,
            findings: []
        )
    }
}
