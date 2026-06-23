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
@testable import SwiftiomaticKit
import Testing

extension URL {
  fileprivate var realpath: URL {
    return self.path.withCString { path in
      guard let realpath = Darwin.realpath(path, nil) else {
        return self
      }
      let result = URL(fileURLWithPath: String(cString: realpath))
      free(realpath)
      return result
    }
  }
}

@Suite
final class FileIteratorTests {
  private let tmpdir: URL

  init() throws {
    tmpdir = try FileManager.default.url(
      for: .itemReplacementDirectory,
      in: .userDomainMask,
      appropriateFor: FileManager.default.temporaryDirectory,
      create: true
    ).realpath

    // Create a simple file tree used by the tests below.
    try touch("project/real1.swift")
    try touch("project/real2.swift")
    try touch("project/.hidden.swift")
    try touch("project/.build/generated.swift")
    try symlink("project/link.swift", to: "project/.hidden.swift")
    try symlink("project/rellink.swift", relativeTo: ".hidden.swift")

    // Test both a self-cycle and a cycle between multiple symlinks.
    try symlink("project/cycliclink.swift", relativeTo: "cycliclink.swift")
    try symlink("project/linktolink.swift", relativeTo: "link.swift")

    // Test symlinks that use nonstandardized paths.
    try symlink("project/2stepcyclebegin.swift", relativeTo: "../project/2stepcycleend.swift")
    try symlink("project/2stepcycleend.swift", relativeTo: "./2stepcyclebegin.swift")
  }

  deinit {
    try? FileManager.default.removeItem(at: tmpdir)
  }

  @Test func noFollowSymlinks() {
    let seen = allFilesSeen(iteratingOver: [tmpdir], followSymlinks: false)
    #expect(seen.count == 2)
    #expect(seen.contains { $0.path.hasSuffix("project/real1.swift") })
    #expect(seen.contains { $0.path.hasSuffix("project/real2.swift") })
  }

  @Test func followSymlinks() {
    let seen = allFilesSeen(iteratingOver: [tmpdir], followSymlinks: true)
    #expect(seen.count == 3)
    #expect(seen.contains { $0.path.hasSuffix("project/real1.swift") })
    #expect(seen.contains { $0.path.hasSuffix("project/real2.swift") })
    // Hidden but found through the visible symlink project/link.swift
    #expect(seen.contains { $0.path.hasSuffix("project/.hidden.swift") })
  }

  @Test func followSymlinksToSymlinks() {
    let seen = allFilesSeen(
      iteratingOver: [tmpURL("project/linktolink.swift")],
      followSymlinks: true
    )
    // Hidden but found through the visible symlink chain.
    #expect(seen.contains { $0.path.hasSuffix("project/.hidden.swift") })
  }

  @Test func symlinkCyclesAreIgnored() {
    let seen = allFilesSeen(
      iteratingOver: [
        tmpURL("project/cycliclink.swift"),
        tmpURL("project/2stepcyclebegin.swift"),
        tmpURL("project/link.swift"),
      ],
      followSymlinks: true
    )
    // Hidden but found through the visible symlink chain.
    #expect(seen.contains { $0.path.hasSuffix("project/.hidden.swift") })
    // And the cycles were ignored.
    #expect(seen.count == 1)
  }

  @Test func traversesHiddenFilesIfExplicitlySpecified() {
    let seen = allFilesSeen(
      iteratingOver: [tmpURL("project/.build"), tmpURL("project/.hidden.swift")],
      followSymlinks: false
    )
    #expect(seen.count == 2)
    #expect(seen.contains { $0.path.hasSuffix("project/.build/generated.swift") })
    #expect(seen.contains { $0.path.hasSuffix("project/.hidden.swift") })
  }

  @Test func doesNotFollowSymlinksIfFollowSymlinksIsFalseEvenIfExplicitlySpecified() {
    let seen = allFilesSeen(
      iteratingOver: [tmpURL("project/link.swift"), tmpURL("project/rellink.swift")],
      followSymlinks: false
    )
    #expect(seen.isEmpty)
  }

  @Test func doesNotTrimFirstCharacterOfPathIfRunningInRoot() {
    var root = tmpdir
    while !root.isRoot {
      root.deleteLastPathComponent()
    }
    let rootPath = root.path
    let seen = allFilesSeen(iteratingOver: [tmpdir], followSymlinks: false, workingDirectory: root)
      .map(\.relativePath)
    #expect(seen.allSatisfy { $0.hasPrefix(rootPath) })
  }

  @Test func showsRelativePaths() {
    let seen = allFilesSeen(iteratingOver: [tmpdir], followSymlinks: false, workingDirectory: tmpdir)
    #expect(Set(seen.map(\.relativePath)) == ["project/real1.swift", "project/real2.swift"])
  }

  @Test func excludesPruneDirectoryDescendants() throws {
    try touch("project/Generated/gen1.swift")
    try touch("project/Generated/sub/gen2.swift")
    let seen = allFilesSeen(
      iteratingOver: [tmpdir],
      followSymlinks: false,
      excludes: ["**/Generated/**"],
      workingDirectory: tmpdir
    )
    let names = Set(seen.map(\.relativePath))
    #expect(names == ["project/real1.swift", "project/real2.swift"])
  }

  @Test func excludesSkipsMatchingFiles() throws {
    try touch("project/Foo.generated.swift")
    let seen = allFilesSeen(
      iteratingOver: [tmpdir],
      followSymlinks: false,
      excludes: ["**/*.generated.swift"],
      workingDirectory: tmpdir
    )
    #expect(!seen.contains { $0.relativePath.hasSuffix("Foo.generated.swift") })
    #expect(seen.contains { $0.relativePath.hasSuffix("project/real1.swift") })
  }

  /// Regression coverage for the SwiftLint `/private`-firmlink exclusion bug (realm/SwiftLint
  /// #6783). On macOS, `standardizedFileURL` strips a leading `/private` from firmlinked paths
  /// (`/var`, `/tmp`), so an exclude *candidate* is normalized to the `/var` form. A user's
  /// absolute exclude pattern (or `realpath`-resolved input path) frequently keeps the `/private`
  /// form, so the two never matched and excluded files were processed anyway. `excludeCandidates`
  /// now offers both the `/private`-stripped and `/private`-prefixed absolute forms, so an absolute
  /// pattern matches regardless of which form it is written in.
  @Test func excludesMatchAbsolutePatternAcrossPrivateFirmlink() throws {
    try touch("project/Generated/gen.swift")

    // `tmpdir` is the real path (typically `/private/var/...`); the firmlink form drops `/private`.
    let privateForm = tmpdir.path
    let firmlinkForm: String = {
      guard privateForm.hasPrefix("/private/") else { return privateForm }
      return String(privateForm.dropFirst("/private".count))
    }()

    for base in Set([privateForm, firmlinkForm]) {
      let seen = allFilesSeen(
        iteratingOver: [tmpdir],
        followSymlinks: false,
        excludes: ["\(base)/project/Generated/**"],
        workingDirectory: tmpdir
      )
      #expect(
        !seen.contains { $0.path.hasSuffix("gen.swift") },
        "absolute exclude written as \(base)/... failed to exclude gen.swift"
      )
      #expect(seen.contains { $0.path.hasSuffix("project/real1.swift") })
    }
  }
}

extension FileIteratorTests {
  private func tmpURL(_ path: String) -> URL {
    return tmpdir.appendingPathComponent(path, isDirectory: false)
  }

  private func touch(_ path: String) throws {
    let fileURL = tmpURL(path)
    try FileManager.default.createDirectory(
      at: fileURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    struct FailedToCreateFileError: Error {
      let url: URL
    }
    if !FileManager.default.createFile(atPath: fileURL.path, contents: Data()) {
      throw FailedToCreateFileError(url: fileURL)
    }
  }

  private func symlink(_ source: String, to target: String) throws {
    try FileManager.default.createSymbolicLink(
      at: tmpURL(source),
      withDestinationURL: tmpURL(target)
    )
  }

  private func symlink(_ source: String, relativeTo target: String) throws {
    try FileManager.default.createSymbolicLink(
      atPath: tmpURL(source).path,
      withDestinationPath: target
    )
  }

  private func allFilesSeen(
    iteratingOver urls: [URL],
    followSymlinks: Bool,
    excludes: [String] = [],
    workingDirectory: URL = URL(fileURLWithPath: ".")
  ) -> [URL] {
    let iterator = FileIterator(urls: urls, followSymlinks: followSymlinks, excludes: excludes, workingDirectory: workingDirectory)
    var seen: [URL] = []
    for next in iterator {
      seen.append(next)
    }
    return seen
  }
}
