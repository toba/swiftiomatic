import ArgumentParser
import Foundation
import SwiftiomaticKit

extension SwiftiomaticCommand {
  struct Doctor: ParsableCommand {
    nonisolated(unsafe) static var configuration = CommandConfiguration(
      abstract: "Validate the configuration file",
      discussion: """
        Validates swiftiomatic.json in two stages: first against the JSON Schema \
        (catching unknown keys, wrong types, and invalid values), then through full \
        configuration parsing (catching semantic issues like unsupported versions). \
        If schema validation fails, parsing is skipped.
        """
    )

    @OptionGroup()
    var configurationOptions: ConfigurationOptions

    func run() throws {
      let diagnosticPrinter = StderrDiagnosticPrinter(colorMode: .auto)
      let diagnosticsEngine = DiagnosticsEngine(
        diagnosticsHandlers: [diagnosticPrinter.printDiagnostic]
      )

      // Locate the configuration file.
      let (configURL, data) = try findConfiguration(diagnosticsEngine: diagnosticsEngine)

      // Stage 1: JSON Schema validation.
      let instance: JSONValue
      do {
        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true
        instance = try decoder.decode(JSONValue.self, from: data)
      } catch {
        diagnosticsEngine.emitError(
          "\(configURL.lastPathComponent): invalid JSON: \(error.localizedDescription)"
        )
        throw ExitCode.failure
      }

      let schemaErrors = validateSchema(instance: instance, schema: ConfigurationSchema.schema)
      if !schemaErrors.isEmpty {
        for error in schemaErrors {
          diagnosticsEngine.emitError(
            "\(configURL.lastPathComponent) \(error.instanceLocation): \(error.message)"
          )
        }
        throw ExitCode.failure
      }

      // Stage 2: Full configuration parsing.
      do {
        _ = try Configuration(data: data)
      } catch {
        let detail: String
        if let decodingError = error as? DecodingError {
          detail = "\(decodingError)"
        } else {
          detail = "\(error)"
        }
        diagnosticsEngine.emitError(
          "\(configURL.lastPathComponent): \(detail)"
        )
        throw ExitCode.failure
      }

      print("Configuration is valid: \(configURL.path)")
    }

    private func findConfiguration(
      diagnosticsEngine: DiagnosticsEngine
    ) throws -> (URL, Data) {
      let configURL: URL

      if let explicit = configurationOptions.configuration {
        let url = URL(fileURLWithPath: explicit)
        if FileManager.default.isReadableFile(atPath: url.path) {
          configURL = url
        } else {
          diagnosticsEngine.emitError("Configuration file not found: \(explicit)")
          throw ExitCode.failure
        }
      } else {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        guard let found = Configuration.url(forConfigurationFileApplyingTo: cwd) else {
          diagnosticsEngine.emitError(
            "No swiftiomatic.json found in current directory or parents"
          )
          throw ExitCode.failure
        }
        configURL = found
      }

      do {
        let data = try Data(contentsOf: configURL)
        return (configURL, data)
      } catch {
        diagnosticsEngine.emitError(
          "Could not read \(configURL.path): \(error.localizedDescription)"
        )
        throw ExitCode.failure
      }
    }
  }
}
