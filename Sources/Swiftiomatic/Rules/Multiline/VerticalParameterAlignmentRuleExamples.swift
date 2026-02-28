enum VerticalParameterAlignmentRuleExamples {
  static let nonTriggeringExamples: [Example] = [
    Example(
      """
      func validateFunction(_ file: SwiftSource, kind: SwiftDeclarationKind,
                            dictionary: SourceKitDictionary) { }
      """,
    ),
    Example(
      """
      func validateFunction(_ file: SwiftSource, kind: SwiftDeclarationKind,
                            dictionary: SourceKitDictionary) -> [RuleViolation]
      """,
    ),
    Example(
      """
      func foo(bar: Int)
      """,
    ),
    Example(
      """
      func foo(bar: Int) -> String
      """,
    ),
    Example(
      """
      func validateFunction(_ file: SwiftSource, kind: SwiftDeclarationKind,
                            dictionary: SourceKitDictionary)
                            -> [RuleViolation]
      """,
    ),
    Example(
      """
      func validateFunction(
         _ file: SwiftSource, kind: SwiftDeclarationKind,
         dictionary: SourceKitDictionary) -> [RuleViolation]
      """,
    ),
    Example(
      """
      func validateFunction(
         _ file: SwiftSource, kind: SwiftDeclarationKind,
         dictionary: SourceKitDictionary
      ) -> [RuleViolation]
      """,
    ),
    Example(
      """
      func regex(_ pattern: String,
                 options: NSRegularExpression.Options = [.anchorsMatchLines,
                                                         .dotMatchesLineSeparators]) -> NSRegularExpression
      """,
    ),
    Example(
      """
      func foo(a: Void,
               b: [String: String] =
               [:]) {
      }
      """,
    ),
    Example(
      """
      func foo(data: (size: CGSize,
                      identifier: String)) {}
      """,
    ),
    Example(
      """
      func foo(data: Data,
               @ViewBuilder content: @escaping (Data.Element.IdentifiedValue) -> Content) {}
      """,
    ),
    Example(
      """
      class A {
          init(bar: Int)
      }
      """,
    ),
    Example(
      """
      class A {
          init(foo: Int,
               bar: String)
      }
      """,
    ),
  ]

  static let triggeringExamples: [Example] = [
    Example(
      """
      func validateFunction(_ file: SwiftSource, kind: SwiftDeclarationKind,
                        ↓dictionary: SourceKitDictionary) { }
      """,
    ),
    Example(
      """
      func validateFunction(_ file: SwiftSource, kind: SwiftDeclarationKind,
                             ↓dictionary: SourceKitDictionary) { }
      """,
    ),
    Example(
      """
      func validateFunction(_ file: SwiftSource,
                        ↓kind: SwiftDeclarationKind,
                        ↓dictionary: SourceKitDictionary) { }
      """,
    ),
    Example(
      """
      func foo(data: Data,
                  ↓@ViewBuilder content: @escaping (Data.Element.IdentifiedValue) -> Content) {}
      """,
    ),
    Example(
      """
      class A {
          init(data: Data,
                      ↓@ViewBuilder content: @escaping (Data.Element.IdentifiedValue) -> Content) {}
      }
      """,
    ),
  ]
}
