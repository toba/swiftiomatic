import Foundation

/// Structure that represents a string range in bytes.
struct ByteRange: Equatable, Sendable {
    let location: ByteCount
    let length: ByteCount

    var upperBound: ByteCount { location + length }
    var lowerBound: ByteCount { location }

    func contains(_ value: ByteCount) -> Bool {
        location <= value && upperBound > value
    }

    func intersects(_ otherRange: ByteRange) -> Bool {
        contains(otherRange.lowerBound) || contains(otherRange.upperBound - 1)
            || otherRange.contains(lowerBound) || otherRange.contains(upperBound - 1)
    }

    func intersects(_ ranges: [ByteRange]) -> Bool {
        ranges.contains { intersects($0) }
    }

    func union(with otherRange: ByteRange) -> ByteRange {
        let maxUpperBound = max(upperBound, otherRange.upperBound)
        let minLocation = min(location, otherRange.location)
        return ByteRange(location: minLocation, length: maxUpperBound - minLocation)
    }
}
