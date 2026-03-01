/// A UTF-8 byte count used for SourceKit offset and length calculations
///
/// Wraps a plain `Int` so that byte-based arithmetic cannot be accidentally
/// mixed with character-based or UTF-16 indices.
struct ByteCount: ExpressibleByIntegerLiteral, Hashable, Sendable {
    /// The raw byte count
    var value: Int

    /// Creates a byte count from an integer literal
    ///
    /// - Parameters:
    ///   - value: The integer literal value.
    init(integerLiteral value: Int) {
        self.value = value
    }

    /// Creates a byte count from an `Int`
    ///
    /// - Parameters:
    ///   - value: The number of bytes.
    init(_ value: Int) {
        self.value = value
    }

    /// Creates a byte count from an `Int64`
    ///
    /// - Parameters:
    ///   - value: The number of bytes as a 64-bit integer.
    init(_ value: Int64) {
        self.value = Int(value)
    }
}

extension ByteCount: CustomStringConvertible {
    var description: String { value.description }
}

extension ByteCount: Comparable {
    static func < (lhs: ByteCount, rhs: ByteCount) -> Bool {
        lhs.value < rhs.value
    }
}

extension ByteCount: AdditiveArithmetic {
    static func - (lhs: ByteCount, rhs: ByteCount) -> ByteCount {
        ByteCount(lhs.value - rhs.value)
    }

    static func -= (lhs: inout ByteCount, rhs: ByteCount) {
        lhs.value -= rhs.value
    }

    static func + (lhs: ByteCount, rhs: ByteCount) -> ByteCount {
        ByteCount(lhs.value + rhs.value)
    }

    static func += (lhs: inout ByteCount, rhs: ByteCount) {
        lhs.value += rhs.value
    }
}
