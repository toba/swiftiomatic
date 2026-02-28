// Vendored from SourceKitten (MIT) — see LICENSES/SourceKitten-MIT.txt

/// Represents the number of bytes in a string.
struct ByteCount: ExpressibleByIntegerLiteral, Hashable, Sendable {
    var value: Int

    init(integerLiteral value: Int) {
        self.value = value
    }

    init(_ value: Int) {
        self.value = value
    }

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
