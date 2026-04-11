import Foundation

/// A half-open byte range within a source string
///
/// Combines a ``ByteCount`` location and length to describe a contiguous span
/// of UTF-8 bytes, analogous to `NSRange` but in byte units.
struct ByteRange: Equatable, Sendable {
  /// The starting byte offset
  let location: ByteCount

  /// The number of bytes in this range
  let length: ByteCount

  /// The exclusive upper bound (`location + length`)
  var upperBound: ByteCount { location + length }

  /// The inclusive lower bound (same as ``location``)
  var lowerBound: ByteCount { location }

  /// Whether this range contains the given byte offset
  ///
  /// - Parameters:
  ///   - value: The byte offset to test.
  func contains(_ value: ByteCount) -> Bool {
    location <= value && upperBound > value
  }

  /// Whether this range overlaps another byte range
  ///
  /// - Parameters:
  ///   - otherRange: The range to test for intersection.
  func intersects(_ otherRange: ByteRange) -> Bool {
    contains(otherRange.lowerBound) || contains(otherRange.upperBound - 1)
      || otherRange.contains(lowerBound) || otherRange.contains(upperBound - 1)
  }

  /// Whether this range overlaps any range in the given array
  ///
  /// - Parameters:
  ///   - ranges: The array of ranges to test.
  func intersects(_ ranges: [ByteRange]) -> Bool {
    ranges.contains { intersects($0) }
  }

  /// The smallest range that covers both this range and the other
  ///
  /// - Parameters:
  ///   - otherRange: The range to merge with.
  func union(with otherRange: ByteRange) -> ByteRange {
    let maxUpperBound = max(upperBound, otherRange.upperBound)
    let minLocation = min(location, otherRange.location)
    return ByteRange(location: minLocation, length: maxUpperBound - minLocation)
  }
}
