import Testing

@testable import Swiftiomatic

@Suite struct SinglePropertyPerLineTests {
  @Test func separateLetDeclarations() {
    let input = """
      let a: Int, b: Int
      """
    let output = """
      let a: Int
      let b: Int
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separateVarDeclarations() {
    let input = """
      var x = 10, y = 20
      """
    let output = """
      var x = 10
      var y = 20
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separatePublicVarDeclarations() {
    let input = """
      public var c = 10, d = false, e = \"string\"
      """
    let output = """
      public var c = 10
      public var d = false
      public var e = "string"
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separateObjcVarDeclarations() {
    let input = """
      @objc var f = true, g: Bool
      """
    let output = """
      @objc var f = true
      @objc var g: Bool
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine, exclude: [.propertyTypes])
  }

  @Test func separatePrivateStaticDeclarations() {
    let input = """
      public enum Namespace {
          public static let a = 1, b = 2, c = 3
      }
      """
    let output = """
      public enum Namespace {
          public static let a = 1
          public static let b = 2
          public static let c = 3
      }
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separateDeclarationsWithComplexTypes() {
    let input = """
      let dict: [String: Int], array: [String]
      """
    let output = """
      let dict: [String: Int]
      let array: [String]
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separateDeclarationsWithGenericTypes() {
    let input = """
      var optional: Optional<String>, result: Result<Int, Error>
      """
    let output = """
      var optional: Optional<String>
      var result: Result<Int, Error>
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine, exclude: [.typeSugar])
  }

  @Test func separateDeclarationsWithClosureTypes() {
    let input = """
      let callback: () -> Void, handler: (String) -> Int
      """
    let output = """
      let callback: () -> Void
      let handler: (String) -> Int
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separateDeclarationsWithTupleTypes() {
    let input = """
      let point: (Int, Int), size: (width: Int, height: Int)
      """
    let output = """
      let point: (Int, Int)
      let size: (width: Int, height: Int)
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func preserveIndentation() {
    let input = """
      class Foo {
          let a: Int, b: Int
      }
      """
    let output = """
      class Foo {
          let a: Int
          let b: Int
      }
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func preserveMultipleAttributes() {
    let input = """
      @available(iOS 13.0, *) @objc private var a = 1, b = 2
      """
    let output = """
      @available(iOS 13.0, *) @objc private var a = 1
      @available(iOS 13.0, *) @objc private var b = 2
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func noChangeForSingleProperty() {
    let input = """
      let single: String = \"value\"
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func noChangesForComputedProperties() {
    let input = """
      var computed: Int {
          return value1 + value2
      }
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func ignoreCommasInFunctionCalls() {
    let input = """
      let result = someFunction(param1, param2, param3)
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func ignoreCommasInArrayLiterals() {
    let input = """
      let array = [1, 2, 3, 4, 5]
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func ignoreCommasInDictionaryLiterals() {
    let input = """
      let dict = [\"a\": 1, \"b\": 2, \"c\": 3]
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func ignoreCommasInTuples() {
    let input = """
      let tuple = (1, 2, 3)
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func separatePropertiesWithComplexInitializers() {
    let input = """
      let a = [1, 2, 3], b = (x: 1, y: 2)
      """
    let output = """
      let a = [1, 2, 3]
      let b = (x: 1, y: 2)
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separatePropertiesWithFunctionCallInitializers() {
    let input = """
      let result1 = process(data, options), result2 = transform(input)
      """
    let output = """
      let result1 = process(data, options)
      let result2 = transform(input)
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func insideClassBody() {
    let input = """
      class MyClass {
          let a: Int, b: Int
          private var x = 1, y = 2
      }
      """
    let output = """
      class MyClass {
          let a: Int
          let b: Int
          private var x = 1
          private var y = 2
      }
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func insideStructBody() {
    let input = """
      struct Point {
          let x: Double, y: Double
          var label: String, isVisible: Bool
      }
      """
    let output = """
      struct Point {
          let x: Double
          let y: Double
          var label: String
          var isVisible: Bool
      }
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func insideFunctionBody() {
    let input = """
      func processData() {
          let start = 0, end = 100
          var temp: String, result: Int
      }
      """
    let output = """
      func processData() {
          let start = 0
          let end = 100
          var temp: String
          var result: Int
      }
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func insideClosureBody() {
    let input = """
      let closure = {
          let a = 1, b = 2
          var x: Int, y: Int
      }
      """
    let output = """
      let closure = {
          let a = 1
          let b = 2
          var x: Int
          var y: Int
      }
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func insideInitializer() {
    let input = """
      init() {
          let temp1 = getValue(), temp2 = getOtherValue()
          var config: Config, settings: Settings
      }
      """
    let output = """
      init() {
          let temp1 = getValue()
          let temp2 = getOtherValue()
          var config: Config
          var settings: Settings
      }
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func nestedIndentation() {
    let input = """
      class Outer {
          func method() {
              if condition {
                  let a = 1, b = 2
                  var x: String, y: String
              }
          }
      }
      """
    let output = """
      class Outer {
          func method() {
              if condition {
                  let a = 1
                  let b = 2
                  var x: String
                  var y: String
              }
          }
      }
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separatePropertiesWithArrayTypes() {
    let input = """
      let numbers: [Int], strings: [String], optionals: [Int?]
      """
    let output = """
      let numbers: [Int]
      let strings: [String]
      let optionals: [Int?]
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separatePropertiesWithDictionaryTypes() {
    let input = """
      var userMap: [String: User], settingsMap: [String: Any], counters: [String: Int]
      """
    let output = """
      var userMap: [String: User]
      var settingsMap: [String: Any]
      var counters: [String: Int]
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separatePropertiesWithArrayLiteralValues() {
    let input = """
      let primes = [2, 3, 5, 7], evens = [2, 4, 6, 8], odds = [1, 3, 5, 7]
      """
    let output = """
      let primes = [2, 3, 5, 7]
      let evens = [2, 4, 6, 8]
      let odds = [1, 3, 5, 7]
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separatePropertiesWithDictionaryLiteralValues() {
    let input = """
      let colors = [\"red\": 0xFF0000, \"green\": 0x00FF00], settings = [\"theme\": \"dark\", \"language\": \"en\"]
      """
    let output = """
      let colors = ["red": 0xFF0000, "green": 0x00FF00]
      let settings = ["theme": "dark", "language": "en"]
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separatePropertiesWithMultilineArrayLiterals() {
    let input = """
      let config = [
          "api": "v1",
          "timeout": 30
      ], credentials = ["username": user, "password": pass]
      """
    let output = """
      let config = [
          "api": "v1",
          "timeout": 30
      ]
      let credentials = ["username": user, "password": pass]
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine, exclude: [.trailingCommas])
  }

  @Test func separatePropertiesWithNestedArrayTypes() {
    let input = """
      let matrix: [[Int]], jaggedArray: [[String?]], coordinates: [(Double, Double)]
      """
    let output = """
      let matrix: [[Int]]
      let jaggedArray: [[String?]]
      let coordinates: [(Double, Double)]
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separatePropertiesWithComplexGenericTypes() {
    let input = """
      var publisher: AnyPublisher<String, Error>, subject: PassthroughSubject<Int, Never>
      """
    let output = """
      var publisher: AnyPublisher<String, Error>
      var subject: PassthroughSubject<Int, Never>
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separatePropertiesWithOptionalArrayTypes() {
    let input = """
      let optionalArray: [String]?, arrayOfOptionals: [String?], bothOptional: [String?]?
      """
    let output = """
      let optionalArray: [String]?
      let arrayOfOptionals: [String?]
      let bothOptional: [String?]?
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separatePropertiesWithFunctionTypes() {
    let input = """
      let transformer: (String) -> Int, validator: (String) -> Bool, processor: ([Int]) -> [String]
      """
    let output = """
      let transformer: (String) -> Int
      let validator: (String) -> Bool
      let processor: ([Int]) -> [String]
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separatePropertiesWithEscapingClosureTypes() {
    let input = """
      var onSuccess: (@escaping (Data) -> Void)?, onError: (@escaping (Error) -> Void)?
      """
    let output = """
      var onSuccess: (@escaping (Data) -> Void)?
      var onError: (@escaping (Error) -> Void)?
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separatePropertiesWithSetValues() {
    let input = """
      let vowels: Set = [\"a\", \"e\", \"i\", \"o\", \"u\"], consonants: Set<Character> = [\"b\", \"c\", \"d\"]
      """
    let output = """
      let vowels: Set = ["a", "e", "i", "o", "u"]
      let consonants: Set<Character> = ["b", "c", "d"]
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separatePropertiesWithTupleValues() {
    let input = """
      let point = (x: 10, y: 20), size = (width: 100, height: 200), origin = (0, 0)
      """
    let output = """
      let point = (x: 10, y: 20)
      let size = (width: 100, height: 200)
      let origin = (0, 0)
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separatePropertiesWithObjectInitializers() {
    let input = """
      let url = URL(string: \"https://api.example.com\")!, client = HTTPClient(session: .shared), config = AppConfig.default
      """
    let output = """
      let url = URL(string: "https://api.example.com")!
      let client = HTTPClient(session: .shared)
      let config = AppConfig.default
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine, exclude: [.propertyTypes])
  }

  @Test func separatePropertiesWithChainedMethodCalls() {
    let input = """
      let trimmed = input.trimmingCharacters(in: .whitespaces), uppercased = text.uppercased().replacingOccurrences(of: \" \", with: \"_\")
      """
    let output = """
      let trimmed = input.trimmingCharacters(in: .whitespaces)
      let uppercased = text.uppercased().replacingOccurrences(of: " ", with: "_")
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separatePropertiesWithConditionalValues() {
    let input = """
      let result = condition ? value1 : value2, fallback = optional ?? defaultValue
      """
    let output = """
      let result = condition ? value1 : value2
      let fallback = optional ?? defaultValue
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func separatePropertiesWithTypeInference() {
    let input = """
      let items = [\"apple\", \"banana\", \"cherry\"], counts = [1: \"one\", 2: \"two\"], flags = [true, false, true]
      """
    let output = """
      let items = ["apple", "banana", "cherry"]
      let counts = [1: "one", 2: "two"]
      let flags = [true, false, true]
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func ignoreGuardStatements() {
    let input = """
      guard let foo, foo, bar, let baaz: Baaz else { return }
      """
    let output = """
      guard let foo, foo, bar, let baaz: Baaz else {
          return
      }
      """
    testFormatting(for: input, [output], rules: [.singlePropertyPerLine, .wrapConditionalBodies])
  }

  @Test func ignoreIfStatements() {
    let input = """
      if let animator, animator.state != .inactive {
          animator.stopAnimation(true)
      }
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func sharedTypeAnnotation() {
    let input = """
      let itemPosition, itemSize, viewportSize, minContentOffset, maxContentOffset: CGFloat
      """
    let output = """
      let itemPosition: CGFloat
      let itemSize: CGFloat
      let viewportSize: CGFloat
      let minContentOffset: CGFloat
      let maxContentOffset: CGFloat
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func sharedTypeAnnotationWithModifiers() {
    let input = """
      private let width, height, depth: Double
      """
    let output = """
      private let width: Double
      private let height: Double
      private let depth: Double
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func sharedComplexTypeAnnotation() {
    let input = """
      let first, second, third: [String: Int]
      """
    let output = """
      let first: [String: Int]
      let second: [String: Int]
      let third: [String: Int]
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func mixedDeclarationsWithAndWithoutTypes() {
    let input = """
      let a = 5, b: Int, c = 10
      """
    let output = """
      let a = 5
      let b: Int
      let c = 10
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func guardWithMultipleConditions() {
    let input = """
      guard let user = user,
            user.isActive,
            let token = user.token else {
          return
      }
      """
    let output = """
      guard let user = user,
            user.isActive,
            let token = user.token
      else {
          return
      }
      """
    testFormatting(
      for: input, [output],
      rules: [.singlePropertyPerLine, .elseOnSameLine, .wrapMultilineStatementBraces])
  }

  @Test func ifWithMultipleConditions() {
    let input = """
      if let data = data,
         let result = process(data),
         result.isValid {
          handle(result)
      }
      """
    let output = """
      if let data = data,
         let result = process(data),
         result.isValid
      {
          handle(result)
      }
      """
    testFormatting(
      for: input, [output], rules: [.singlePropertyPerLine, .wrapMultilineStatementBraces])
  }

  @Test func whileWithMultipleConditions() {
    let input = """
      while let item = iterator.next(),
            item.isValid {
          process(item)
      }
      """
    let output = """
      while let item = iterator.next(),
            item.isValid
      {
          process(item)
      }
      """
    testFormatting(
      for: input, [output], rules: [.singlePropertyPerLine, .wrapMultilineStatementBraces])
  }

  @Test func switchCaseWithMultipleBindings() {
    let input = """
      switch value {
      case let (a, b, c):
          return
      }
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func sharedTypeAnnotationDuplication() {
    let input = """
      let itemPosition, itemSize, viewportSize, minContentOffset, maxContentOffset: CGFloat
      """
    let output = """
      let itemPosition: CGFloat
      let itemSize: CGFloat
      let viewportSize: CGFloat
      let minContentOffset: CGFloat
      let maxContentOffset: CGFloat
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func switchCaseWithOptionalBindings() {
    let input = """
      switch value {
      case (let leading?, nil, nil):
          return
      }
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func switchCaseWithMultipleConditions() {
    let input = """
      let fromFrame, toFrame: CGRect
      switch (containerType, destinationContentMode) {
      case (.source, _), (_, .fill):
          break
      }
      """
    let output = """
      let fromFrame: CGRect
      let toFrame: CGRect
      switch (containerType, destinationContentMode) {
      case (.source, _), (_, .fill):
          break
      }
      """
    testFormatting(
      for: input, output, rule: .singlePropertyPerLine,
      exclude: [.sortSwitchCases, .wrapSwitchCases])
  }

  // TODO: Fix tuple parsing - parseExpressionRange doesn't handle tuples correctly
  // @Test func simpleTupleValues() {
  //     let input = "let a = (1, 2), b = (3, 4)"
  //     let output = """
  //     let a = (1, 2)
  //     let b = (3, 4)
  //     """
  //     testFormatting(for: input, output, rule: .singlePropertyPerLine)
  // }

  @Test func basicCommaDetection() {
    // Test if parseExpressionRange is working correctly for simple cases
    let input = """
      let x = 5, y = 10
      """
    let output = """
      let x = 5
      let y = 10
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func simpleSharedType() {
    let input = """
      let a, b: Int
      """
    let output = """
      let a: Int
      let b: Int
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func enumDeclarationWithConformances() {
    let input = """
      enum DiagnosticFailure: Error, CustomStringConvertible { }
      """
    testFormatting(for: input, rule: .singlePropertyPerLine, exclude: [.emptyBraces])
  }

  @Test func ifLetWithTupleDestructuring() {
    let input = """
      if let (cacheKey, cachedHeight) = cachedHeight, cacheKey == newCacheKey {
          return cachedHeight
      }
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func guardCaseWithBinding() {
    let input = """
      guard case .link(let url, _) = tappableContent else {
          return
      }
      """
    testFormatting(for: input, rule: .singlePropertyPerLine, exclude: [.hoistPatternLet])
  }

  @Test func ifLetWithMultipleConditions() {
    let input = """
      if let (cacheKey, cachedHeight) = cachedHeight, cacheKey == newCacheKey {
          return cachedHeight
      }
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func classDeclarationWithMultipleInheritance() {
    let input = """
      public final class PrimaryButton: BaseMarginView, ConstellationView, PrimaryActionLoggable { }
      """
    testFormatting(for: input, rule: .singlePropertyPerLine, exclude: [.emptyBraces])
  }

  @Test func switchCaseWithMultipleLetBindings() {
    let input = """
      switch value {
      case .remote(url: let url, placeholder: let placeholder, aspectRatio: let aspectRatio):
          break
      }
      """
    testFormatting(
      for: input, rule: .singlePropertyPerLine, exclude: [.hoistPatternLet, .wrapSwitchCases])
  }

  @Test func switchCaseWithMixedPatterns() {
    let input = """
      switch content {
      case .link(let title, _, _), .text(let title, _):
          return title
      }
      """
    testFormatting(
      for: input, rule: .singlePropertyPerLine, exclude: [.hoistPatternLet, .wrapSwitchCases])
  }

  @Test func casePatternWithParentheses() {
    let input = """
      switch value {
      case .remote(let url, placeholder):
          break
      }
      """
    testFormatting(for: input, rule: .singlePropertyPerLine, exclude: [.hoistPatternLet])
  }

  @Test func enumWithProtocolConformanceListFollowingProperty() {
    let input = """
      public let foo = "bar"

      enum MyEnum: Error, CustomStringConvertible {
          case foo
          case bar
      }
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func simpleTupleDestructuring() {
    let input = """
      let (foo, bar, baaz) = (1, 2, 3)
      """
    let output = """
      let foo = 1
      let bar = 2
      let baaz = 3
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithVarKeyword() {
    let input = """
      var (x, y, z) = (10, 20, 30)
      """
    let output = """
      var x = 10
      var y = 20
      var z = 30
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithSpaces() {
    let input = """
      let ( a , b , c ) = ( 1 , 2 , 3 )
      """
    let output = """
      let a = 1
      let b = 2
      let c = 3
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithComplexValues() {
    let input = """
      let (name, age, active) = (\"John\", 25, true)
      """
    let output = """
      let name = "John"
      let age = 25
      let active = true
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithModifiers() {
    let input = """
      private let (width, height) = (100.0, 200.0)
      """
    let output = """
      private let width = 100.0
      private let height = 200.0
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithAttributes() {
    let input = """
      @available(iOS 15, *) let (feature1, feature2) = (true, false)
      """
    let output = """
      @available(iOS 15, *) let feature1 = true
      @available(iOS 15, *) let feature2 = false
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithNestedValues() {
    let input = """
      let (array, dict) = ([1, 2, 3], [\"key\": \"value\"])
      """
    let output = """
      let array = [1, 2, 3]
      let dict = ["key": "value"]
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithFunctionCalls() {
    let input = """
      let (min, max) = (calculateMin(), calculateMax())
      """
    let output = """
      let min = calculateMin()
      let max = calculateMax()
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringInsideFunction() {
    let input = """
      func process() {
          let (result, error) = (try? getData(), nil)
      }
      """
    let output = """
      func process() {
          let result = try? getData()
          let error = nil
      }
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func preserveTupleDestructuringWithSingleValue() {
    let input = """
      let (result) = (42)
      """
    testFormatting(for: input, rule: .singlePropertyPerLine, exclude: [.redundantParens])
  }

  @Test func preserveTupleDestructuringWithNonTupleRHS() {
    let input = """
      let (foo, bar, baz) = someFunction()
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func preserveTupleDestructuringWithMethodCall() {
    let input = """
      let (x, y) = point.coordinates()
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func preserveTupleDestructuringWithPropertyAccess2() {
    let input = """
      let (width, height) = view.size
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithIndentation() {
    let input = """
      class Example {
          func test() {
              let (a, b, c) = (1, 2, 3)
          }
      }
      """
    let output = """
      class Example {
          func test() {
              let a = 1
              let b = 2
              let c = 3
          }
      }
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithSwitchTuple() {
    let input = """
      switch value {
      case let (x, y, z):
          break
      }
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithTypeAnnotation() {
    let input = """
      let (a, b): (Int, Bool)
      """
    let output = """
      let a: Int
      let b: Bool
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithTypeAnnotationAndValues() {
    let input = """
      let (c, d): (String, Bool) = ("hello", false)
      """
    let output = """
      let c: String = \"hello\"
      let d: Bool = false
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithComplexTypes() {
    let input = """
      let (items, count): ([String], Int)
      """
    let output = """
      let items: [String]
      let count: Int
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithOptionalTypes() {
    let input = """
      var (name, age): (String?, Int?)
      """
    let output = """
      var name: String?
      var age: Int?
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithModifiersAndTypeAnnotation() {
    let input = """
      private let (width, height): (Double, Double)
      """
    let output = """
      private let width: Double
      private let height: Double
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithAttributesAndTypeAnnotation() {
    let input = """
      @available(iOS 15, *) let (x, y): (CGFloat, CGFloat)
      """
    let output = """
      @available(iOS 15, *) let x: CGFloat
      @available(iOS 15, *) let y: CGFloat
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithFunctionTypes() {
    let input = """
      let (handler, validator): ((String) -> Void, (Int) -> Bool)
      """
    let output = """
      let handler: (String) -> Void
      let validator: (Int) -> Bool
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithNestedTupleTypes() {
    let input = """
      let (point, size): ((Int, Int), (Int, Int))
      """
    let output = """
      let point: (Int, Int)
      let size: (Int, Int)
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func tupleDestructuringWithTypeAnnotationAndPartialValues() {
    let input = """
      let (result, error): (String?, Error?) = (getValue(), nil)
      """
    let output = """
      let result: String? = getValue()
      let error: Error? = nil
      """
    testFormatting(for: input, output, rule: .singlePropertyPerLine)
  }

  @Test func preserveTupleDestructuringWithConditionalExpression() {
    let input = """
      let (foo, bar) =
          if baaz {
              (true, false)
          } else {
              (false, true)
          }
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func preserveTupleDestructuringWithFunctionCall() {
    let input = """
      let (result, _): DecodedResponseWithContextCompletionArgument<Response> = castQueryResponse(from: query)
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func preserveTupleDestructuringWithClosureLiteral() {
    let input = """
      let (_, observers): (Value?, Observers<Value>) = storage.mutate { storage in (nil, storage.observers) }
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func preserveTupleDestructuringWithPropertyAccess() {
    let input = """
      let (width, height) = view.bounds.size
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func preserveTupleDestructuringWithComplexExpression() {
    let input = """
      let (min, max) = array.isEmpty ? (0, 0) : (array.min()!, array.max()!)
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }

  @Test func asyncLetPreserved() {
    let input = """
      async let (one, two) = (performOne(), performTwo())
      let (oneResult, twoResult) = await (one, two)
      """
    testFormatting(for: input, rule: .singlePropertyPerLine)
  }
}
