@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct BlankLineAfterSwitchCaseTests: RuleTesting {

  @Test func multilineCasesGetBlankLine() {
    assertFormatting(
      BlankLinesAfterSwitchCase.self,
      input: """
        func handle(_ action: Action) {
            switch action {
            1️⃣case .engageWarpDrive:
                navigationComputer.destination = targetedDestination
                await warpDrive.spinUp()
                warpDrive.activate()
            case .handleIncomingEnergyBlast:
                await energyShields.prepare()
                energyShields.engage()
            }
        }
        """,
      expected: """
        func handle(_ action: Action) {
            switch action {
            case .engageWarpDrive:
                navigationComputer.destination = targetedDestination
                await warpDrive.spinUp()
                warpDrive.activate()

            case .handleIncomingEnergyBlast:
                await energyShields.prepare()
                energyShields.engage()
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line after multiline switch case"),
      ]
    )
  }

  @Test func singleLineCasesUnchanged() {
    assertFormatting(
      BlankLinesAfterSwitchCase.self,
      input: """
        var planetType: PlanetType {
            switch self {
            case .mercury, .venus, .earth, .mars:
                .terrestrial
            case .jupiter, .saturn, .uranus, .neptune:
                .gasGiant
            }
        }
        """,
      expected: """
        var planetType: PlanetType {
            switch self {
            case .mercury, .venus, .earth, .mars:
                .terrestrial
            case .jupiter, .saturn, .uranus, .neptune:
                .gasGiant
            }
        }
        """,
      findings: []
    )
  }

  @Test func removesBlankLineAfterLastCase() {
    assertFormatting(
      BlankLinesAfterSwitchCase.self,
      input: """
        func handle(_ action: Action) {
            switch action {
            case .engageWarpDrive:
                warpDrive.spinUp()
                warpDrive.activate()

            case .handleIncomingEnergyBlast:
                energyShields.prepare()
                energyShields.engage()

            1️⃣}
        }
        """,
      expected: """
        func handle(_ action: Action) {
            switch action {
            case .engageWarpDrive:
                warpDrive.spinUp()
                warpDrive.activate()

            case .handleIncomingEnergyBlast:
                energyShields.prepare()
                energyShields.engage()
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove blank line before closing brace"),
      ]
    )
  }

  @Test func mixedSingleAndMultiLineCases() {
    assertFormatting(
      BlankLinesAfterSwitchCase.self,
      input: """
        switch action {
        1️⃣case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()
        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)
        2️⃣case let .scanPlanet(planet):
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
        FindingSpec("1️⃣", message: "insert blank line after multiline switch case"),
        FindingSpec("2️⃣", message: "insert blank line after multiline switch case"),
      ]
    )
  }

  @Test func alreadyHasBlankLines() {
    assertFormatting(
      BlankLinesAfterSwitchCase.self,
      input: """
        switch action {
        case .engageWarpDrive:
            warpDrive.engage()

        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)

        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """,
      expected: """
        switch action {
        case .engageWarpDrive:
            warpDrive.engage()

        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)

        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """,
      findings: []
    )
  }

  @Test func singleLineCasesWithCommentsUnchanged() {
    assertFormatting(
      BlankLinesAfterSwitchCase.self,
      input: """
        var name: String {
            switch self {
            // The planet closest to the sun
            case .mercury:
                "Mercury"
            case .venus:
                "Venus"
            // The best planet
            case .earth:
                "Earth"
            case .mars:
                "Mars"
            }
        }
        """,
      expected: """
        var name: String {
            switch self {
            // The planet closest to the sun
            case .mercury:
                "Mercury"
            case .venus:
                "Venus"
            // The best planet
            case .earth:
                "Earth"
            case .mars:
                "Mars"
            }
        }
        """,
      findings: []
    )
  }

  @Test func defaultCaseHandled() {
    assertFormatting(
      BlankLinesAfterSwitchCase.self,
      input: """
        switch value {
        1️⃣case .a:
            doSomething()
            doSomethingElse()
        default:
            break
        }
        """,
      expected: """
        switch value {
        case .a:
            doSomething()
            doSomethingElse()

        default:
            break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line after multiline switch case"),
      ]
    )
  }
}
