import Foundation

struct TypesafeArrayInitRule: Rule {
  static let id = "typesafe_array_init"
  static let name = "Type-safe Array Init"
  static let summary =
    "Prefer using `Array(seq)` over `seq.map { $0 }` to convert a sequence into an Array"
  static let isCorrectable = true
  static let isOptIn = true
  static let requiresSourceKit = true
  static let requiresCompilerArguments = true
  static let requiresFileOnDisk = true
  static var nonTriggeringExamples: [Example] {
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

  static var triggeringExamples: [Example] {
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

  var options = SeverityOption<Self>(.warning)

  private static let parentRule = ArrayInitRule()
  private static let mapTypePatterns = [
    regex(
      """
      \\Q<Self, T where Self : \\E(?:Sequence|Collection)> \
      \\Q(Self) -> ((Self.Element) throws -> T) throws -> [T]\\E
      """,
    ),
    regex(
      """
      \\Q<Self, T, E where Self : \\E(?:Sequence|Collection), \
      \\QE : Error> (Self) -> ((Self.Element) throws(E) -> T) throws(E) -> [T]\\E
      """,
    ),
  ]

  func validate(file: SwiftSource, compilerArguments: [String]) -> [RuleViolation] {
    guard let filePath = file.path else {
      return []
    }
    guard compilerArguments.isNotEmpty else {
      SwiftiomaticError.missingCompilerArguments(path: file.path, ruleID: Self.identifier)
        .print()
      return []
    }
    return Self.parentRule.validate(file: file)
      .filter { violation in
        guard let offset = getOffset(in: file, at: violation.location) else {
          return false
        }
        let cursorInfo = Request.cursorInfoWithoutSymbolGraph(
          file: filePath, offset: offset, arguments: compilerArguments,
        )
        guard let request = try? cursorInfo.sendIfNotDisabled() else {
          return false
        }
        return pointsToSystemMapType(pointee: request)
      }.map { RuleViolation(ruleType: Self.self, location: $0.location) }
  }

  private func pointsToSystemMapType(pointee: [String: SourceKitValue]) -> Bool {
    if pointee["key.is_system"]?.boolValue == true,
      pointee["key.name"]?.stringValue == "map(_:)",
      let typeName = pointee["key.typename"]?.stringValue
    {
      return Self.mapTypePatterns.contains { pattern in
        pattern.hasMatch(in: typeName, range: typeName.fullNSRange)
      }
    }
    return false
  }

  private func getOffset(in file: SwiftSource, at location: Location) -> ByteCount? {
    guard let line = location.line, let offset = location.column else {
      return nil
    }
    return file.stringView.byteOffset(forLine: Int64(line), bytePosition: Int64(offset))
  }
}
