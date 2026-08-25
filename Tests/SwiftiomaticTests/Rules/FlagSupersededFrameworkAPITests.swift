@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagSupersededFrameworkAPITests: RuleTesting {
  private static let metricManager =
    "'MXMetricManager' is deprecated — use 'MetricManager'"
  private static let metricReports =
    "the 'MX' payload types are deprecated — read 'MetricManager.metricReports' instead"
  private static let backgroundAssets =
    "'NSBundleResourceRequest' is deprecated on OS 27 — stage assets with Background Assets instead"

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
}
