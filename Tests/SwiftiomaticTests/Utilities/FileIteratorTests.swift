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

@_spi(Internal) @_spi(Testing) import Swiftiomatic
import XCTest

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

final class FileIteratorTests: XCTestCase {
  private var tmpdir: URL!

  override func setUpWithError() throws {
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

  override func tearDownWithError() throws {
    try FileManager.default.removeItem(at: tmpdir)
  }

  func testNoFollowSymlinks() throws {
    let seen = allFilesSeen(iteratingOver: [tmpdir], followSymlinks: false)
    XCTAssertEqual(seen.count, 2)
    XCTAssertTrue(seen.contains { $0.path.hasSuffix("project/real1.swift") })
    XCTAssertTrue(seen.contains { $0.path.hasSuffix("project/real2.swift") })
  }

  func testFollowSymlinks() throws {
    let seen = allFilesSeen(iteratingOver: [tmpdir], followSymlinks: true)
    XCTAssertEqual(seen.count, 3)
    XCTAssertTrue(seen.contains { $0.path.hasSuffix("project/real1.swift") })
    XCTAssertTrue(seen.contains { $0.path.hasSuffix("project/real2.swift") })
    // Hidden but found through the visible symlink project/link.swift
    XCTAssertTrue(seen.contains { $0.path.hasSuffix("project/.hidden.swift") })
  }

  func testFollowSymlinksToSymlinks() throws {
    let seen = allFilesSeen(
      iteratingOver: [tmpURL("project/linktolink.swift")],
      followSymlinks: true
    )
    // Hidden but found through the visible symlink chain.
    XCTAssertTrue(seen.contains { $0.path.hasSuffix("project/.hidden.swift") })
  }

  func testSymlinkCyclesAreIgnored() throws {
    let seen = allFilesSeen(
      iteratingOver: [
        tmpURL("project/cycliclink.swift"),
        tmpURL("project/2stepcyclebegin.swift"),
        tmpURL("project/link.swift"),
      ],
      followSymlinks: true
    )
    // Hidden but found through the visible symlink chain.
    XCTAssertTrue(seen.contains { $0.path.hasSuffix("project/.hidden.swift") })
    // And the cycles were ignored.
    XCTAssertEqual(seen.count, 1)
  }

  func testTraversesHiddenFilesIfExplicitlySpecified() throws {
    let seen = allFilesSeen(
      iteratingOver: [tmpURL("project/.build"), tmpURL("project/.hidden.swift")],
      followSymlinks: false
    )
    XCTAssertEqual(seen.count, 2)
    XCTAssertTrue(seen.contains { $0.path.hasSuffix("project/.build/generated.swift") })
    XCTAssertTrue(seen.contains { $0.path.hasSuffix("project/.hidden.swift") })
  }

  func testDoesNotFollowSymlinksIfFollowSymlinksIsFalseEvenIfExplicitlySpecified() {
    let seen = allFilesSeen(
      iteratingOver: [tmpURL("project/link.swift"), tmpURL("project/rellink.swift")],
      followSymlinks: false
    )
    XCTAssertTrue(seen.isEmpty)
  }

  func testDoesNotTrimFirstCharacterOfPathIfRunningInRoot() throws {
    var root = tmpdir!
    while !root.isRoot {
      root.deleteLastPathComponent()
    }
    let rootPath = root.path
    let seen = allFilesSeen(iteratingOver: [tmpdir], followSymlinks: false, workingDirectory: root).map(\.relativePath)
    XCTAssertTrue(seen.allSatisfy { $0.hasPrefix(rootPath) }, "\(seen) does not contain root directory '\(rootPath)'")
  }

  func testShowsRelativePaths() throws {
    let seen = allFilesSeen(iteratingOver: [tmpdir], followSymlinks: false, workingDirectory: tmpdir)
    XCTAssertEqual(Set(seen.map(\.relativePath)), ["project/real1.swift", "project/real2.swift"])
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
    workingDirectory: URL = URL(fileURLWithPath: ".")
  ) -> [URL] {
    let iterator = FileIterator(urls: urls, followSymlinks: followSymlinks, workingDirectory: workingDirectory)
    var seen: [URL] = []
    for next in iterator {
      seen.append(next)
    }
    return seen
  }
}
