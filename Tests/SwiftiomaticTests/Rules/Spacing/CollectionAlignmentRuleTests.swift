import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct CollectionAlignmentRuleTests {

  // MARK: - Align Left (default)

  @Test func alignLeftNoViolationForAlignedArray() async {
    await assertNoViolation(
      CollectionAlignmentRule.self,
      """
      let coordinates = [
          CLLocationCoordinate2D(latitude: 0, longitude: 33),
          CLLocationCoordinate2D(latitude: 0, longitude: 66),
          CLLocationCoordinate2D(latitude: 0, longitude: 99)
      ]
      """)
  }

  @Test func alignLeftNoViolationForAlignedSet() async {
    await assertNoViolation(
      CollectionAlignmentRule.self,
      """
      var evenNumbers: Set<Int> = [
          2,
          4,
          6
      ]
      """)
  }

  @Test func alignLeftNoViolationForSingleLineArray() async {
    await assertNoViolation(
      CollectionAlignmentRule.self,
      """
      let abc = [1, 2, 3, 4]
      """)
  }

  @Test func alignLeftNoViolationForSingleLineMultilineArray() async {
    await assertNoViolation(
      CollectionAlignmentRule.self,
      """
      let abc = [
          1, 2, 3, 4
      ]
      """)
  }

  @Test func alignLeftNoViolationForSingleLineDictionary() async {
    await assertNoViolation(
      CollectionAlignmentRule.self,
      """
      let abc = [
          "foo": "bar", "fizz": "buzz"
      ]
      """)
  }

  @Test func alignLeftNoViolationForAlignedDictionary() async {
    await assertNoViolation(
      CollectionAlignmentRule.self,
      """
      doThings(arg: [
          "foo": 1,
          "bar": 2,
          "fizz": 2,
          "buzz": 2
      ])
      """)
  }

  @Test func alignLeftNoViolationForAttributeString() async {
    await assertNoViolation(
      CollectionAlignmentRule.self,
      """
      NSAttributedString(string: "...", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .regular),
                                                     .foregroundColor: UIColor(white: 0, alpha: 0.2)])
      """)
  }

  @Test func alignLeftDetectsMisalignedDictionaryKeys() async {
    await assertLint(
      CollectionAlignmentRule.self,
      """
      doThings(arg: [
          "foo": 1,
          "bar": 2,
         1️⃣"fizz": 2,
         2️⃣"buzz": 2
      ])
      """,
      findings: [
        FindingSpec(
          "1️⃣", message: "All elements in a collection literal should be vertically aligned"),
        FindingSpec(
          "2️⃣", message: "All elements in a collection literal should be vertically aligned"),
      ])
  }

  @Test func alignLeftDetectsMisalignedDictionaryValues() async {
    await assertLint(
      CollectionAlignmentRule.self,
      """
      let abc = [
          "alpha": "a",
           1️⃣"beta": "b",
          "gamma": "g",
          "delta": "d",
        2️⃣"epsilon": "e"
      ]
      """,
      findings: [
        FindingSpec(
          "1️⃣", message: "All elements in a collection literal should be vertically aligned"),
        FindingSpec(
          "2️⃣", message: "All elements in a collection literal should be vertically aligned"),
      ])
  }

  @Test func alignLeftDetectsMisalignedMeals() async {
    await assertLint(
      CollectionAlignmentRule.self,
      """
      let meals = [
                      "breakfast": "oatmeal",
                      "lunch": "sandwich",
          1️⃣"dinner": "burger"
      ]
      """,
      findings: [
        FindingSpec(
          "1️⃣", message: "All elements in a collection literal should be vertically aligned")
      ])
  }

  @Test func alignLeftDetectsMisalignedArrayElement() async {
    await assertLint(
      CollectionAlignmentRule.self,
      """
      let coordinates = [
          CLLocationCoordinate2D(latitude: 0, longitude: 33),
              1️⃣CLLocationCoordinate2D(latitude: 0, longitude: 66),
          CLLocationCoordinate2D(latitude: 0, longitude: 99)
      ]
      """,
      findings: [
        FindingSpec(
          "1️⃣", message: "All elements in a collection literal should be vertically aligned")
      ])
  }

  @Test func alignLeftDetectsMisalignedSetElement() async {
    await assertLint(
      CollectionAlignmentRule.self,
      """
      var evenNumbers: Set<Int> = [
          2,
        1️⃣4,
          6
      ]
      """,
      findings: [
        FindingSpec(
          "1️⃣", message: "All elements in a collection literal should be vertically aligned")
      ])
  }

  // MARK: - Align Colons

  @Test func alignColonsNoViolationForAlignedColons() async {
    await assertNoViolation(
      CollectionAlignmentRule.self,
      """
      doThings(arg: [
          "foo": 1,
          "bar": 2,
         "fizz": 2,
         "buzz": 2
      ])
      """,
      configuration: ["align_colons": true])
  }

  @Test func alignColonsNoViolationForAlignedAlpha() async {
    await assertNoViolation(
      CollectionAlignmentRule.self,
      """
      let abc = [
          "alpha": "a",
           "beta": "b",
          "gamma": "g",
          "delta": "d",
        "epsilon": "e"
      ]
      """,
      configuration: ["align_colons": true])
  }

  @Test func alignColonsNoViolationForWeirdColons() async {
    await assertNoViolation(
      CollectionAlignmentRule.self,
      """
      var weirdColons = [
          "a"    :  1,
            "b"  :2,
             "c" :      3
      ]
      """,
      configuration: ["align_colons": true])
  }

  @Test func alignColonsNoViolationForMultilineDict() async {
    await assertNoViolation(
      CollectionAlignmentRule.self,
      """
      let d = [    "short": 1,
                "veryLong": 2]
      """,
      configuration: ["align_colons": true])
  }

  @Test func alignColonsDetectsMisalignedColons() async {
    await assertLint(
      CollectionAlignmentRule.self,
      """
      doThings(arg: [
          "foo": 1,
          "bar": 2,
          "fizz"1️⃣: 2,
          "buzz"2️⃣: 2
      ])
      """,
      findings: [
        FindingSpec(
          "1️⃣", message: "All elements in a collection literal should be vertically aligned"),
        FindingSpec(
          "2️⃣", message: "All elements in a collection literal should be vertically aligned"),
      ],
      configuration: ["align_colons": true])
  }

  @Test func alignColonsDetectsMisalignedAlphaColons() async {
    await assertLint(
      CollectionAlignmentRule.self,
      """
      let abc = [
          "alpha": "a",
          "beta"1️⃣: "b",
          "gamma": "c",
          "delta": "d",
          "epsilon"2️⃣: "e"
      ]
      """,
      findings: [
        FindingSpec(
          "1️⃣", message: "All elements in a collection literal should be vertically aligned"),
        FindingSpec(
          "2️⃣", message: "All elements in a collection literal should be vertically aligned"),
      ],
      configuration: ["align_colons": true])
  }

  @Test func alignColonsDetectsWeirdColonsMisalignment() async {
    await assertLint(
      CollectionAlignmentRule.self,
      """
      var weirdColons = [
          "a"    :  1,
          "b"  1️⃣:2,
          "c"    :      3
      ]
      """,
      findings: [
        FindingSpec(
          "1️⃣", message: "All elements in a collection literal should be vertically aligned")
      ],
      configuration: ["align_colons": true])
  }

  // MARK: - Shared violations (fire in both modes)

  @Test func alignColonsDetectsMisalignedArrayElement() async {
    await assertLint(
      CollectionAlignmentRule.self,
      """
      let coordinates = [
          CLLocationCoordinate2D(latitude: 0, longitude: 33),
              1️⃣CLLocationCoordinate2D(latitude: 0, longitude: 66),
          CLLocationCoordinate2D(latitude: 0, longitude: 99)
      ]
      """,
      findings: [
        FindingSpec(
          "1️⃣", message: "All elements in a collection literal should be vertically aligned")
      ],
      configuration: ["align_colons": true])
  }

  @Test func alignColonsDetectsMisalignedSetElement() async {
    await assertLint(
      CollectionAlignmentRule.self,
      """
      var evenNumbers: Set<Int> = [
          2,
        1️⃣4,
          6
      ]
      """,
      findings: [
        FindingSpec(
          "1️⃣", message: "All elements in a collection literal should be vertically aligned")
      ],
      configuration: ["align_colons": true])
  }
}
