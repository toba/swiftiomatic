//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftiomaticKit
import SwiftParser
import SwiftSyntax
import Synchronization

class Frontend: @unchecked Sendable {
  /// Provides formatter configurations for given `.swift` source files, configuration files or configuration strings.
  struct ConfigurationProvider {
    /// Loads formatter configuration files and chaches them in memory.
    private var configurationLoader: ConfigurationLoader = ConfigurationLoader()

    /// The diagnostic engine to which warnings and errors will be emitted.
    private let diagnosticsEngine: DiagnosticsEngine

    /// Creates a new instance with the given options.
    ///
    /// - Parameter diagnosticsEngine: The diagnostic engine to which warnings and errors will be emitted.
    init(diagnosticsEngine: DiagnosticsEngine) {
      self.diagnosticsEngine = diagnosticsEngine
    }

    /// Returns a user-friendly description of a configuration loading error.
    ///
    /// For `DecodingError` values, this includes the coding path so the user can identify
    /// exactly which key is invalid. For other errors, falls back to `localizedDescription`.
    private func descriptionForConfigurationError(_ error: Error) -> String {
      guard let decodingError = error as? DecodingError else {
        return error.localizedDescription
      }
      switch decodingError {
      case .dataCorrupted(let context):
        return descriptionWithCodingPath(context)
      case .typeMismatch(_, let context):
        return descriptionWithCodingPath(context)
      case .keyNotFound(let key, let context):
        let path = (context.codingPath + [key]).map(\.stringValue).joined(separator: ".")
        return "missing key `\(path)`"
      case .valueNotFound(_, let context):
        return descriptionWithCodingPath(context)
      @unknown default:
        return error.localizedDescription
      }
    }

    /// Formats a `DecodingError.Context` with its coding path for diagnostic output.
    private func descriptionWithCodingPath(_ context: DecodingError.Context) -> String {
      if context.codingPath.isEmpty {
        return context.debugDescription
      }
      let path = context.codingPath.map(\.stringValue).joined(separator: ".")
      return "at `\(path)`: \(context.debugDescription)"
    }

    /// Returns the configuration that applies to the given `.swift` source file, when an explicit
    /// configuration path is also perhaps provided.
    ///
    /// This method also checks for unrecognized rules within the configuration.
    ///
    /// - Parameters:
    ///   - pathOrString: A string containing either the path to a configuration file that will be
    ///     loaded, JSON configuration data directly, or `nil` to try to infer it from
    ///     `swiftFileURL`.
    ///   - swiftFileURL: The path to a `.swift` file, which will be used to infer the path to the
    ///     configuration file if `configurationFilePath` is nil.
    ///
    /// - Returns: If successful, the returned configuration is the one loaded from `pathOrString` if
    ///   it was provided, or by searching in paths inferred by `swiftFileURL` if one exists, or the
    ///   default configuration otherwise. If an error occurred when reading the configuration, a
    ///   diagnostic is emitted and `nil` is returned. If neither `pathOrString` nor `swiftFileURL`
    ///   were provided, a default `Configuration()` will be returned.
    mutating func provide(
      forConfigPathOrString pathOrString: String?,
      orForSwiftFileAt swiftFileURL: URL?
    ) -> Configuration? {
      if let pathOrString = pathOrString {
        // Only honor --configuration when it points to an actual file on disk.
        // Xcode passes inline JSON via --configuration which overrides the project
        // config — silently ignore inline JSON so swiftiomatic.json is always used.
        let configurationFileURL = URL(fileURLWithPath: pathOrString)
        if FileManager.default.isReadableFile(atPath: configurationFileURL.path) {
          do {
            let configuration = try configurationLoader.configuration(at: configurationFileURL)
            return configuration
          } catch {
            diagnosticsEngine.emitError(
              "Unable to read configuration: \(descriptionForConfigurationError(error))"
            )
            return nil
          }
        }
        // Inline JSON string — fall through to discover swiftiomatic.json from the file path.
      }

      // If no explicit configuration file path was given but a `.swift` source file path was given,
      // then try to load the configuration by inferring it based on the source file path.
      if let swiftFileURL = swiftFileURL {
        do {
          if let configuration = try configurationLoader.configuration(forPath: swiftFileURL) {
            return configuration
          }
          // Fall through to the default return at the end of the function.
        } catch {
          diagnosticsEngine.emitError(
            "Unable to read configuration for \(swiftFileURL.relativePath): \(descriptionForConfigurationError(error))"
          )
          return nil
        }
      } else {
        // If reading from stdin and no explicit configuration file was given,
        // walk up the file tree from the cwd to find a config.

        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        // Definitely a Swift file. Definitely not a directory. Shhhhhh.
        do {
          if let configuration = try configurationLoader.configuration(forPath: cwd) {
            return configuration
          }
        } catch {
          diagnosticsEngine.emitError(
            "Unable to read configuration for \(cwd.relativePath): \(descriptionForConfigurationError(error))"
          )
          return nil
        }
      }

      // An explicit configuration has not been given, and one cannot be found.
      // Return the default configuration.
      return Configuration()
    }
  }

  /// Represents a file to be processed by the frontend and any file-specific options associated
  /// with it.
  final class FileToProcess: Sendable {
    /// A file URL representing the path to the source file being processed.
    ///
    /// It is the responsibility of the specific frontend to make guarantees about the validity of
    /// this path. For example, the formatting frontend ensures that it is a path to an existing
    /// file only when doing in-place formatting (so that the file can be replaced). In other
    /// situations, it may correspond to a different file than the underlying file handle (if
    /// standard input is used with the `--assume-filename` flag), or it may not be a valid path at
    /// all (the string `"<stdin>"`).
    let url: URL

    /// The configuration that should applied for this file.
    let configuration: Configuration

    /// the selected ranges to process
    let selection: Selection

    /// The string contents of the file, read eagerly during initialization.
    ///
    /// The contents of the file are assumed to be UTF-8 encoded. If there is an error decoding the
    /// contents, this will be `nil`.
    let sourceText: String?

    init(
      fileHandle: FileHandle,
      url: URL,
      configuration: Configuration,
      selection: Selection = .infinite
    ) {
      self.url = url
      self.configuration = configuration
      self.selection = selection
      let sourceData = fileHandle.readDataToEndOfFile()
      fileHandle.closeFile()
      self.sourceText = String(data: sourceData, encoding: .utf8)
    }
  }

  /// Prints diagnostics to standard error, optionally with color.
  final let diagnosticPrinter: StderrDiagnosticPrinter

  /// The diagnostic engine to which warnings and errors will be emitted.
  final let diagnosticsEngine: DiagnosticsEngine

  /// Options that control the tool's configuration.
  final let configurationOptions: ConfigurationOptions

  /// Options that apply during formatting or linting.
  final let lintFormatOptions: LintFormatOptions

  /// The provider for formatter configurations.
  private final let configurationProvider: Mutex<ConfigurationProvider>

  /// Advanced options that are useful for developing/debugging but otherwise not meant for general
  /// use.
  final var debugOptions: DebugOptions {
    [
      lintFormatOptions.debugDisablePrettyPrint ? .disablePrettyPrint : [],
      lintFormatOptions.debugDumpTokenStream ? .dumpTokenStream : [],
    ]
  }

  /// Creates a new frontend with the given options.
  ///
  /// - Parameter lintFormatOptions: Options that apply during formatting or linting.
  init(
    configurationOptions: ConfigurationOptions,
    lintFormatOptions: LintFormatOptions,
    treatWarningsAsErrors: Bool = false
  ) {
    self.configurationOptions = configurationOptions
    self.lintFormatOptions = lintFormatOptions

    self.diagnosticPrinter = StderrDiagnosticPrinter(
      colorMode: lintFormatOptions.colorDiagnostics.map { $0 ? .on : .off } ?? .auto
    )
    self.diagnosticsEngine = DiagnosticsEngine(
      diagnosticsHandlers: [diagnosticPrinter.printDiagnostic],
      treatWarningsAsErrors: treatWarningsAsErrors
    )
    self.configurationProvider = Mutex(ConfigurationProvider(diagnosticsEngine: self.diagnosticsEngine))
  }

  /// Runs the linter or formatter over the inputs.
  final func run() {
    if lintFormatOptions.paths == ["-"] {
      processStandardInput()
    } else if lintFormatOptions.paths.isEmpty {
      diagnosticsEngine.emitWarning(
        """
        Running sm without input paths is deprecated and will be removed in the future.

        Please update your invocation to do either of the following:

        - Pass `-` to read from stdin (e.g., `cat MyFile.swift | sm -`).
        - Pass one or more paths to Swift source files or directories containing
          Swift source files. When passing directories, make sure to include the
          `--recursive` flag.

        For more information, use the `--help` option.
        """
      )
      processStandardInput()
    } else {
      processURLs(
        lintFormatOptions.paths.map(URL.init(fileURLWithPath:)),
        parallel: lintFormatOptions.parallel
      )
    }
  }

  /// Called by the frontend to process a single file.
  ///
  /// Subclasses must override this method to provide the actual linting or formatting logic.
  ///
  /// - Parameter fileToProcess: A `FileToProcess` that contains information about the file to be
  ///   processed.
  func processFile(_ fileToProcess: FileToProcess) {
    fatalError("Must be overridden by subclasses.")
  }

  /// Processes source content from standard input.
  private func processStandardInput() {
    let assumedUrl = lintFormatOptions.assumeFilename.map(URL.init(fileURLWithPath:))

    guard
      let configuration = configurationProvider.withLock({
        $0.provide(
          forConfigPathOrString: configurationOptions.configuration,
          orForSwiftFileAt: assumedUrl
        )
      })
    else {
      // Already diagnosed in the called method.
      return
    }

    let selection: Selection
    if !lintFormatOptions.lines.isEmpty {
      selection = Selection(lineRanges: lintFormatOptions.lines)
    } else {
      selection = Selection(offsetRanges: lintFormatOptions.offsets)
    }

    let fileToProcess = FileToProcess(
      fileHandle: FileHandle.standardInput,
      url: assumedUrl ?? URL(fileURLWithPath: "<stdin>"),
      configuration: configuration,
      selection: selection
    )
    processFile(fileToProcess)
  }

  /// Processes source content from a list of files and/or directories provided as file URLs.
  private func processURLs(_ urls: [URL], parallel: Bool) {
    precondition(
      !urls.isEmpty,
      "processURLs(_:) should only be called when 'urls' is non-empty."
    )

    if parallel {
      let filesToProcess =
        FileIterator(urls: urls, followSymlinks: lintFormatOptions.followSymlinks)
        .compactMap(openAndPrepareFile)
      DispatchQueue.concurrentPerform(iterations: filesToProcess.count) { index in
        processFile(filesToProcess[index])
      }
    } else {
      FileIterator(urls: urls, followSymlinks: lintFormatOptions.followSymlinks)
        .lazy
        .compactMap(openAndPrepareFile)
        .forEach(processFile)
    }
  }

  /// Read and prepare the file at the given path for processing, optionally synchronizing
  /// diagnostic output.
  private func openAndPrepareFile(at url: URL) -> FileToProcess? {
    guard let sourceFile = try? FileHandle(forReadingFrom: url) else {
      diagnosticsEngine.emitError(
        "Unable to open \(url.relativePath): file is not readable or does not exist"
      )
      return nil
    }

    guard
      let configuration = configurationProvider.withLock({
        $0.provide(
          forConfigPathOrString: configurationOptions.configuration,
          orForSwiftFileAt: url
        )
      })
    else {
      // Already diagnosed in the called method.
      return nil
    }

    let selection: Selection
    if !lintFormatOptions.lines.isEmpty {
      selection = Selection(lineRanges: lintFormatOptions.lines)
    } else {
      selection = Selection(offsetRanges: lintFormatOptions.offsets)
    }

    return FileToProcess(
      fileHandle: sourceFile,
      url: url,
      configuration: configuration,
      selection: selection
    )
  }

}
