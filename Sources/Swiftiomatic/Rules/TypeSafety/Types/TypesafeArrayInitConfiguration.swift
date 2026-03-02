struct TypesafeArrayInitConfiguration: RuleConfiguration {
    let id = "typesafe_array_init"
    let name = "Type-safe Array Init"
    let summary = "Prefer using `Array(seq)` over `seq.map { $0 }` to convert a sequence into an Array"
    let isCorrectable = true
    let isOptIn = true
    let requiresSourceKit = true
    let requiresCompilerArguments = true
    let requiresFileOnDisk = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                enum MyError: Error {}
                let myResult: Result<String, MyError> = .success("")
                let result: Result<Any, MyError> = myResult.map { $0 }
                """,
              ),
              Example(
                """
                struct IntArray {
                    let elements = [1, 2, 3]
                    func map<T>(_ transformer: (Int) throws -> T) rethrows -> [T] {
                        try elements.map(transformer)
                    }
                }
                let ints = IntArray()
                let intsCopy = ints.map { $0 }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                func f<Seq: Sequence>(s: Seq) -> [Seq.Element] {
                    s.↓map({ $0 })
                }
                """,
              ),
              Example(
                """
                func f(array: [Int]) -> [Int] {
                    array.↓map { $0 }
                }
                """,
              ),
              Example(
                """
                let myInts = [1, 2, 3].↓map { return $0 }
                """,
              ),
              Example(
                """
                struct Generator: Sequence, IteratorProtocol {
                    func next() -> Int? { nil }
                }
                let array = Generator().↓map { i in i }
                """,
              ),
            ]
    }
}
