struct StaticOperatorConfiguration: RuleConfiguration {
    let id = "static_operator"
    let name = "Static Operator"
    let summary = "Operators should be declared as static functions, not free functions"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
                    Example(
                        """
                        class A: Equatable {
                          static func == (lhs: A, rhs: A) -> Bool {
                            return false
                          }
                        """,
                    ),
                    Example(
                        """
                        class A<T>: Equatable {
                            static func == <T>(lhs: A<T>, rhs: A<T>) -> Bool {
                                return false
                            }
                        """,
                    ),
                    Example(
                        """
                        public extension Array where Element == Rule {
                          static func == (lhs: Array, rhs: Array) -> Bool {
                            if lhs.count != rhs.count { return false }
                            return !zip(lhs, rhs).contains { !$0.0.isEqualTo($0.1) }
                          }
                        }
                        """,
                    ),
                    Example(
                        """
                        private extension Optional where Wrapped: Comparable {
                          static func < (lhs: Optional, rhs: Optional) -> Bool {
                            switch (lhs, rhs) {
                            case let (lhs?, rhs?):
                              return lhs < rhs
                            case (nil, _?):
                              return true
                            default:
                              return false
                            }
                          }
                        }
                        """,
                    ),
                ]
    }
    var triggeringExamples: [Example] {
        [
                    Example(
                        """
                        ↓func == (lhs: A, rhs: A) -> Bool {
                          return false
                        }
                        """,
                    ),
                    Example(
                        """
                        ↓func == <T>(lhs: A<T>, rhs: A<T>) -> Bool {
                          return false
                        }
                        """,
                    ),
                    Example(
                        """
                        ↓func == (lhs: [Rule], rhs: [Rule]) -> Bool {
                          if lhs.count != rhs.count { return false }
                          return !zip(lhs, rhs).contains { !$0.0.isEqualTo($0.1) }
                        }
                        """,
                    ),
                    Example(
                        """
                        private ↓func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
                          switch (lhs, rhs) {
                          case let (lhs?, rhs?):
                            return lhs < rhs
                          case (nil, _?):
                            return true
                          default:
                            return false
                          }
                        }
                        """,
                    ),
                ]
    }
}
