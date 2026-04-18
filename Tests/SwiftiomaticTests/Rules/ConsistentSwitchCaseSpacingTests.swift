@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct ConsistentSwitchCaseSpacingTests: RuleTesting {

  @Test func insertsBlankLinesToMatchMajority() {
    assertFormatting(
      ConsistentSwitchCaseSpacing.self,
      input: """
        switch action {
        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()

        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)
        1️⃣case let .scanPlanet(planet):
            scanner.target = planet
            scanner.scanAtmosphere()
            scanner.scanBiosphere()
            scanner.scanForArtificialLife()

        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """,
      expected: """
        switch action {
        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()

        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)

        case let .scanPlanet(planet):
            scanner.target = planet
            scanner.scanAtmosphere()
            scanner.scanBiosphere()
            scanner.scanForArtificialLife()

        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "add blank line between switch cases for consistency"),
      ]
    )
  }

  @Test func insertsBlankLineOnTie() {
    assertFormatting(
      ConsistentSwitchCaseSpacing.self,
      input: """
        switch action {
        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()

        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)
        1️⃣case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """,
      expected: """
        switch action {
        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()

        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)

        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "add blank line between switch cases for consistency"),
      ]
    )
  }

  @Test func removesBlankLinesToMatchMajority() {
    assertFormatting(
      ConsistentSwitchCaseSpacing.self,
      input: """
        var name: String {
            switch self {
            case .mercury:
                "Mercury"

            1️⃣case .venus:
                "Venus"
            case .earth:
                "Earth"
            case .mars:
                "Mars"
            case .jupiter:
                "Jupiter"
            case .saturn:
                "Saturn"
            case .uranus:
                "Uranus"
            case .neptune:
                "Neptune"
            }
        }
        """,
      expected: """
        var name: String {
            switch self {
            case .mercury:
                "Mercury"
            case .venus:
                "Venus"
            case .earth:
                "Earth"
            case .mars:
                "Mars"
            case .jupiter:
                "Jupiter"
            case .saturn:
                "Saturn"
            case .uranus:
                "Uranus"
            case .neptune:
                "Neptune"
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove blank line between switch cases for consistency"),
      ]
    )
  }

  @Test func alreadyConsistentNoChange() {
    assertFormatting(
      ConsistentSwitchCaseSpacing.self,
      input: """
        switch action {
        case .a:
            doA()
        case .b:
            doB()
        case .c:
            doC()
        }
        """,
      expected: """
        switch action {
        case .a:
            doA()
        case .b:
            doB()
        case .c:
            doC()
        }
        """,
      findings: []
    )
  }

  @Test func alreadyConsistentWithBlankLines() {
    assertFormatting(
      ConsistentSwitchCaseSpacing.self,
      input: """
        switch action {
        case .a:
            doA()

        case .b:
            doB()

        case .c:
            doC()
        }
        """,
      expected: """
        switch action {
        case .a:
            doA()

        case .b:
            doB()

        case .c:
            doC()
        }
        """,
      findings: []
    )
  }

  @Test func singleCaseNoChange() {
    assertFormatting(
      ConsistentSwitchCaseSpacing.self,
      input: """
        switch action {
        case .a:
            doA()
        }
        """,
      expected: """
        switch action {
        case .a:
            doA()
        }
        """,
      findings: []
    )
  }
}
