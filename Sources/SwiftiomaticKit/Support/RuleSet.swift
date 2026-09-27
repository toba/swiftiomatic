/// A set of rules, stored as one bit per generated rule index.
///
/// The generator gives each rule a dense index in `ConfigurationRegistry.allRuleTypes` . A test of
/// membership reads one word and does not hash. The words live inline, so a copy does not allocate.
struct RuleSet: Sendable, Equatable {
    /// The bits, 64 rules to a word.
    private var words = ConfigurationRegistry.RuleSetWords(repeating: 0)

    /// An empty set.
    init() {}

    /// Whether the set contains the rule at `index` .
    ///
    /// An index outside the registry is never a member.
    @inline(__always)
    subscript(index: Int) -> Bool {
        get {
            let word = index &>> 6
            guard index >= 0, word < words.count else { return false }
            return words[word] & (1 &<< UInt64(index & 63)) != 0
        }
        set {
            let word = index &>> 6
            guard index >= 0, word < words.count else { return }
            let bit: UInt64 = 1 &<< UInt64(index & 63)
            if newValue { words[word] |= bit } else { words[word] &= ~bit }
        }
    }

    /// Whether the set contains no rule.
    var isEmpty: Bool {
        for word in words.indices where words[word] != 0 { return false }
        return true
    }

    /// Whether the set contains at least one rule of `indices` .
    @inline(__always)
    func containsAny(_ indices: some Sequence<Int>) -> Bool {
        for index in indices where self[index] { return true }
        return false
    }

    /// The indices of the rules in the set, in ascending order.
    var indices: [Int] {
        var result: [Int] = []

        for word in words.indices {
            var bits = words[word]

            while bits != 0 {
                result.append(word &* 64 &+ bits.trailingZeroBitCount)
                bits &= bits &- 1
            }
        }
        return result
    }

    static func == (lhs: RuleSet, rhs: RuleSet) -> Bool {
        for word in lhs.words.indices where lhs.words[word] != rhs.words[word] { return false }
        return true
    }
}
