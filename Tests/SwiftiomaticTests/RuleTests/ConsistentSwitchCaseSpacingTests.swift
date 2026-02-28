import Testing
@testable import Swiftiomatic

@Suite struct ConsistentSwitchCaseSpacingTests {
    @Test func insertsBlankLinesToMakeSwitchStatementSpacingConsistent1() {
        let input = """
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
        """

        let output = """
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
        """
        testFormatting(for: input, output, rule: .consistentSwitchCaseSpacing)
    }

    @Test func insertsBlankLinesToMakeSwitchStatementSpacingConsistent2() {
        let input = """
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
        """

        let output = """
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
        """
        testFormatting(for: input, output, rule: .consistentSwitchCaseSpacing)
    }

    @Test func insertsBlankLinesToMakeSwitchStatementSpacingConsistent3() {
        let input = """
        var name: PlanetType {
            switch self {
            // The planet closest to the sun
            case .mercury:
                "Mercury"
            // Similar to Earth but way more deadly
            case .venus:
                "Venus"

            // The best planet, where everything cool happens
            case .earth:
                "Earth"

            // This planet is entirely inhabited by robots.
            // There are cool landers, rovers, and even a helicopter.
            case .mars:
                "Mars"

            // The biggest planet with the most moons
            case .jupiter:
                "Jupiter"

            // Other planets have rings, but satun's are the best.
            case .saturn:
                "Saturn"
            case .uranus:
                "Uranus"
            case .neptune:
                "Neptune"
            }
        }
        """

        let output = """
        var name: PlanetType {
            switch self {
            // The planet closest to the sun
            case .mercury:
                "Mercury"

            // Similar to Earth but way more deadly
            case .venus:
                "Venus"

            // The best planet, where everything cool happens
            case .earth:
                "Earth"

            // This planet is entirely inhabited by robots.
            // There are cool landers, rovers, and even a helicopter.
            case .mars:
                "Mars"

            // The biggest planet with the most moons
            case .jupiter:
                "Jupiter"

            // Other planets have rings, but satun's are the best.
            case .saturn:
                "Saturn"

            case .uranus:
                "Uranus"

            case .neptune:
                "Neptune"
            }
        }
        """
        testFormatting(for: input, output, rule: .consistentSwitchCaseSpacing)
    }

    @Test func removesBlankLinesToMakeSwitchStatementConsistent() {
        let input = """
        var name: PlanetType {
            switch self {
            // The planet closest to the sun
            case .mercury:
                "Mercury"

            case .venus:
                "Venus"
            // The best planet, where everything cool happens
            case .earth:
                "Earth"
            // This planet is entirely inhabited by robots.
            // There are cool landers, rovers, and even a helicopter.
            case .mars:
                "Mars"
            case .jupiter:
                "Jupiter"
            // Other planets have rings, but satun's are the best.
            case .saturn:
                "Saturn"
            case .uranus:
                "Uranus"
            case .neptune:
                "Neptune"
            }
        }
        """

        let output = """
        var name: PlanetType {
            switch self {
            // The planet closest to the sun
            case .mercury:
                "Mercury"
            case .venus:
                "Venus"
            // The best planet, where everything cool happens
            case .earth:
                "Earth"
            // This planet is entirely inhabited by robots.
            // There are cool landers, rovers, and even a helicopter.
            case .mars:
                "Mars"
            case .jupiter:
                "Jupiter"
            // Other planets have rings, but satun's are the best.
            case .saturn:
                "Saturn"
            case .uranus:
                "Uranus"
            case .neptune:
                "Neptune"
            }
        }
        """

        testFormatting(for: input, output, rule: .consistentSwitchCaseSpacing)
    }

    @Test func singleLineAndMultiLineSwitchCase1() {
        let input = """
        switch planetType {
        case .terrestrial:
            if options.treatPlutoAsPlanet {
                [.mercury, .venus, .earth, .mars, .pluto]
            } else {
                [.mercury, .venus, .earth, .mars]
            }
        case .gasGiant:
            [.jupiter, .saturn, .uranus, .neptune]
        }
        """

        let output = """
        switch planetType {
        case .terrestrial:
            if options.treatPlutoAsPlanet {
                [.mercury, .venus, .earth, .mars, .pluto]
            } else {
                [.mercury, .venus, .earth, .mars]
            }

        case .gasGiant:
            [.jupiter, .saturn, .uranus, .neptune]
        }
        """

        testFormatting(
            for: input, [output], rules: [.blankLineAfterSwitchCase, .consistentSwitchCaseSpacing],
        )
    }

    @Test func singleLineAndMultiLineSwitchCase2() {
        let input = """
        switch planetType {
        case .gasGiant:
            [.jupiter, .saturn, .uranus, .neptune]
        case .terrestrial:
            if options.treatPlutoAsPlanet {
                [.mercury, .venus, .earth, .mars, .pluto]
            } else {
                [.mercury, .venus, .earth, .mars]
            }
        }
        """

        testFormatting(for: input, rule: .consistentSwitchCaseSpacing)
    }

    @Test func switchStatementWithSingleMultilineCase_blankLineAfterSwitchCaseEnabled() {
        let input = """
        switch action {
        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)
        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()
        case let .scanPlanet(planet):
            scanner.scan(planet)
        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """

        let output = """
        switch action {
        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)

        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()

        case let .scanPlanet(planet):
            scanner.scan(planet)

        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """

        testFormatting(
            for: input, [output], rules: [.consistentSwitchCaseSpacing, .blankLineAfterSwitchCase],
        )
    }

    @Test func switchStatementWithSingleMultilineCase_blankLineAfterSwitchCaseDisabled() {
        let input = """
        switch action {
        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)
        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()
        case let .scanPlanet(planet):
            scanner.scan(planet)
        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """

        testFormatting(
            for: input, rule: .consistentSwitchCaseSpacing, exclude: [.blankLineAfterSwitchCase],
        )
    }
}
