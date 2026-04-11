import Foundation
import SwiftSyntax

/// The placement of a segment of Swift in a collection of source files.
struct Location: CustomStringConvertible, Comparable, Codable, Sendable {
  /// The file path on disk for this location.
  let file: String?
  /// The line offset in the file for this location. 1-indexed.
  let line: Int?
  /// The column offset in the file for this location. 1-indexed.
  let column: Int?

  /// A lossless printable description of this location.
  var description: String {
    // Xcode likes warnings and errors in the following format:
    // {full_path_to_file}{:line}{:character}: {error,warning}: {content}
    let fileString = file ?? "<nopath>"
    let lineString = ":\(line ?? 1)"
    let charString = ":\(column ?? 1)"
    return [fileString, lineString, charString].joined()
  }

  /// The file path for this location relative to the current working directory.
  var relativeFile: String? {
    file?.replacingOccurrences(of: FileManager.default.currentDirectoryPath + "/", with: "")
  }

  /// Creates a `Location` by specifying its properties directly.
  ///
  /// - Parameters:
  ///   - file: The file path on disk for this location.
  ///   - line: The line offset in the file for this location. 1-indexed.
  ///   - column: The column offset in the file for this location. 1-indexed.
  init(file: String?, line: Int? = nil, column: Int? = nil) {
    self.file = file
    self.line = line
    self.column = column
  }

  /// Creates a `Location` based on a `SwiftSource` and a byte-offset into the file.
  /// Fails if the specified offset was not a valid location in the file.
  ///
  /// - Parameters:
  ///   - file: The file for this location.
  ///   - offset: The offset in bytes into the file for this location.
  init(file: SwiftSource, byteOffset offset: ByteCount) {
    self.file = file.path
    if let lineAndCharacter = file.stringView.lineAndCharacter(forByteOffset: offset) {
      line = lineAndCharacter.line
      column = lineAndCharacter.character
    } else {
      line = nil
      column = nil
    }
  }

  /// Creates a `Location` based on a `SwiftSource` and a SwiftSyntax `AbsolutePosition` into the file.
  /// Fails if the specified offset was not a valid location in the file.
  ///
  /// - Parameters:
  ///   - file: The file for this location.
  ///   - position: The absolute position returned from SwiftSyntax.
  init(file: SwiftSource, position: AbsolutePosition) {
    self.init(file: file, byteOffset: ByteCount(position.utf8Offset))
  }

  /// Creates a `Location` based on a `SwiftSource` and a UTF8 character-offset into the file.
  /// Fails if the specified offset was not a valid location in the file.
  ///
  /// - Parameters:
  ///   - file: The file for this location.
  ///   - offset: The offset in UTF8 fragments into the file for this location.
  init(file: SwiftSource, characterOffset offset: Int) {
    self.file = file.path
    if let lineAndCharacter = file.stringView.lineAndCharacter(forCharacterOffset: offset) {
      line = lineAndCharacter.line
      column = lineAndCharacter.character
    } else {
      line = nil
      column = nil
    }
  }

  /// Creates a `Location` based on a `SwiftSource` and a `String.Index` into the file contents.
  ///
  /// - Parameters:
  ///   - file: The file for this location.
  ///   - index: An index into the file's contents string.
  init(file: SwiftSource, stringIndex index: String.Index) {
    let offset = file.contents.utf16.distance(
      from: file.contents.utf16.startIndex, to: index,
    )
    self.init(file: file, characterOffset: offset)
  }

  // MARK: Comparable

  static func < (lhs: Self, rhs: Self) -> Bool {
    if lhs.file != rhs.file {
      return lhs.file < rhs.file
    }
    if lhs.line != rhs.line {
      return lhs.line < rhs.line
    }
    return lhs.column < rhs.column
  }
}

extension Optional where Wrapped: Comparable {
  fileprivate static func < (lhs: Optional, rhs: Optional) -> Bool {
    switch (lhs, rhs) {
    case (let lhs?, let rhs?):
      return lhs < rhs
    case (nil, _?):
      return true
    default:
      return false
    }
  }
}
