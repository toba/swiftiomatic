@testable package import SwiftiomaticKit

/// Formats `source` through the whole format pipeline and returns the result.
///
/// The call runs every rule that `configuration` enables, then the pretty printer. It discards
/// the findings.
///
/// - Parameters:
///   - source: the source to format
///   - configuration: the configuration the pipeline uses
package func formatWithPipeline(_ source: String, configuration: Configuration) throws -> String {
    let coordinator = RewriteCoordinator(configuration: configuration, findingConsumer: { _ in })
    var output = ""
    try coordinator.format(
        source: source,
        assumingFileURL: nil,
        selection: .infinite,
        to: &output
    )
    return output
}
