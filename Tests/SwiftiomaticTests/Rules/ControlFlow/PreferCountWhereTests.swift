import Foundation
import Testing

@testable import Swiftiomatic

@Suite struct PreferCountWhereTests {
  @Test func convertFilterToCountWhere() {
    let input = """
      planets.filter({ !$0.moons.isEmpty }).count
      """

    let output = """
      planets.count(where: { !$0.moons.isEmpty })
      """

    let options = FormatOptions(swiftVersion: "6.0")
    testFormatting(for: input, output, rule: .preferCountWhere, options: options)
  }

  @Test func convertFilterTrailingClosureToCountWhere() {
    let input = """
      planets.filter { !$0.moons.isEmpty }.count
      """

    let output = """
      planets.count(where: { !$0.moons.isEmpty })
      """

    let options = FormatOptions(swiftVersion: "6.0")
    testFormatting(for: input, output, rule: .preferCountWhere, options: options)
  }

  @Test func convertNestedFilter() {
    let input = """
      planets.filter { planet in
          planet.moons.filter { moon in
              moon.hasAtmosphere
          }.count > 1
      }.count
      """

    let output = """
      planets.count(where: { planet in
          planet.moons.count(where: { moon in
              moon.hasAtmosphere
          }) > 1
      })
      """

    let options = FormatOptions(swiftVersion: "6.0")
    testFormatting(for: input, output, rule: .preferCountWhere, options: options)
  }

  @Test func preservesFilterBeforeSwift6() {
    let input = """
      planets.filter { !$0.moons.isEmpty }.count
      """

    let options = FormatOptions(swiftVersion: "5.10")
    testFormatting(for: input, rule: .preferCountWhere, options: options)
  }

  @Test func preservesCountMethod() {
    let input = """
      planets.filter { !$0.moons.isEmpty }.count(of: earth)
      """

    let options = FormatOptions(swiftVersion: "6.0")
    testFormatting(for: input, rule: .preferCountWhere, options: options)
  }
}
