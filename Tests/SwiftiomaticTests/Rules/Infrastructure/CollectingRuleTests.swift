import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct CollectingRuleTests {
  @Test func collectsIntoStorage() async throws {
    struct Spec: MockCollectingRule {
      var options = SeverityConfiguration<Self>(.warning)

      func collectInfo(for _: SwiftSource) -> Int {
        42
      }

      func validate(
        file: SwiftSource,
        collectedInfo: [SwiftSource: Int]
      ) -> [RuleViolation] {
        #expect(collectedInfo[file] == 42)
        return [
          RuleViolation(
            ruleType: Self.self,
            location: Location(file: file, byteOffset: 0),
          )
        ]
      }
    }

    let result = await violations(Example("_ = 0"), config: try #require(Spec.testConfig))
    #expect(!result.isEmpty)
  }

  @Test func collectsAllFiles() async throws {
    struct Spec: MockCollectingRule {
      var options = SeverityConfiguration<Self>(.warning)

      func collectInfo(for file: SwiftSource) -> String {
        file.contents
      }

      func validate(
        file: SwiftSource,
        collectedInfo: [SwiftSource: String]
      ) -> [RuleViolation] {
        let values = collectedInfo.values
        #expect(values.contains("foo"))
        #expect(values.contains("bar"))
        #expect(values.contains("baz"))
        return [
          RuleViolation(
            ruleType: Self.self,
            location: Location(file: file, byteOffset: 0),
          )
        ]
      }
    }

    let inputs = ["foo", "bar", "baz"]
    let allViolations = await inputs.violations(config: try #require(Spec.testConfig))
    #expect(allViolations.count == inputs.count)
  }

  @Test func collectsAnalyzerFiles() async throws {
    struct Spec: MockCollectingRule, AnalyzerRule {
      var options = SeverityConfiguration<Self>(.warning)
      static let isOptIn = true
      static let requiresCompilerArguments = true
      static let requiresFileOnDisk = true

      func collectInfo(for _: SwiftSource, compilerArguments: [String]) -> [String] {
        compilerArguments
      }

      func validate(
        file: SwiftSource, collectedInfo: [SwiftSource: [String]],
        compilerArguments: [String],
      )
        -> [RuleViolation]
      {
        #expect(collectedInfo[file] == compilerArguments)
        return [
          RuleViolation(
            ruleType: Self.self,
            location: Location(file: file, byteOffset: 0),
          )
        ]
      }
    }

    let analyzerResult = await violations(
      Example("_ = 0"),
      config: try #require(Spec.testConfig),
      requiresFileOnDisk: true,
    )
    #expect(!analyzerResult.isEmpty)
  }

  @Test func corrects() async throws {
    struct Spec: MockCollectingRule, CorrectableRule {
      var options = SeverityConfiguration<Self>(.warning)

      func collectInfo(for file: SwiftSource) -> String {
        file.contents
      }

      func validate(
        file: SwiftSource,
        collectedInfo: [SwiftSource: String]
      ) -> [RuleViolation] {
        if collectedInfo[file] == "baz" {
          return [
            RuleViolation(
              ruleType: Self.self,
              location: Location(file: file, byteOffset: 2),
            )
          ]
        }
        return []
      }

      func correct(file: SwiftSource, collectedInfo: [SwiftSource: String]) -> Int {
        collectedInfo[file] == "baz" ? 1 : 0
      }

      func correct(file: SwiftSource) -> Int {
        correct(file: file, collectedInfo: [file: collectInfo(for: file)])
      }
    }

    struct AnalyzerSpec: MockCollectingRule, AnalyzerRule, CorrectableRule {
      var options = SeverityConfiguration<Self>(.warning)
      static let isOptIn = true
      static let requiresCompilerArguments = true
      static let requiresFileOnDisk = true

      func collectInfo(for file: SwiftSource) -> String {
        file.contents
      }

      func validate(
        file: SwiftSource, collectedInfo: [SwiftSource: String],
        compilerArguments _: [String],
      )
        -> [RuleViolation]
      {
        collectedInfo[file] == "baz"
          ? [
            .init(
              ruleType: Spec.self,
              location: Location(file: file, byteOffset: 2),
            )
          ]
          : []
      }

      func correct(
        file: SwiftSource,
        collectedInfo: [SwiftSource: String],
        compilerArguments _: [String],
      ) -> Int {
        collectedInfo[file] == "baz" ? 1 : 0
      }

      func correct(file: SwiftSource) -> Int {
        correct(
          file: file,
          collectedInfo: [file: collectInfo(for: file)],
          compilerArguments: [],
        )
      }
    }

    let inputs = ["foo", "baz"]
    let specCorrections = await inputs.corrections(config: try #require(Spec.testConfig))
    #expect(specCorrections.count == 1)
    let analyzerCorrections = await inputs.corrections(
      config: try #require(AnalyzerSpec.testConfig),
      requiresFileOnDisk: true,
    )
    #expect(analyzerCorrections.count == 1)
  }
}

private protocol MockCollectingRule: CollectingRule {}
extension MockCollectingRule {
  @RuleOptionsDescriptionBuilder
  var configurationDescription: some Documentable { RuleOptionsEntry.noOptions }

  static var id: String { "mock_test_rule_for_swiftlint_tests" }
  static var name: String { "" }
  static var summary: String { "" }

  static var testConfig: Configuration? {
    Configuration(rulesMode: .onlyConfiguration([identifier]), ruleList: RuleList(rules: self))
  }

  init(configuration _: Any) { self.init() }
}
