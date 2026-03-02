// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swiftiomatic",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "SwiftiomaticLib", targets: ["Swiftiomatic"]),
        .executable(name: "swiftiomatic", targets: ["SwiftiomaticCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-format.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.0.2"),
    ],
    targets: [
        .target(
            name: "Swiftiomatic",
            dependencies: [
                "SourceKitC",
                .product(name: "SwiftIDEUtils", package: "swift-syntax"),
                .product(name: "SwiftLexicalLookup", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftFormat", package: "swift-format"),
                .product(name: "Yams", package: "Yams"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("ApproachableConcurrency"),
                .enableUpcomingFeature("InternalImportsByDefault"),
                .enableUpcomingFeature("MemberImportVisibility"),
                .enableUpcomingFeature("DisableOutwardActorIsolation"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            ],
        ),
        .executableTarget(
            name: "SwiftiomaticCLI",
            dependencies: [
                "Swiftiomatic",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("ApproachableConcurrency"),
                .enableUpcomingFeature("InternalImportsByDefault"),
                .enableUpcomingFeature("MemberImportVisibility"),
                .enableUpcomingFeature("DisableOutwardActorIsolation"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            ],
        ),
        .executableTarget(
            name: "GeneratePipeline",
            dependencies: [
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("ApproachableConcurrency"),
            ],
        ),
        .target(
            name: "SourceKitC",
        ),
        .testTarget(
            name: "SwiftiomaticTests",
            dependencies: [
                "Swiftiomatic",
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            resources: [
                .copy("Suggest/SuggestFixtures"),
                .copy("Configuration/ConfigFixtures"),
                .copy("Format/BadConfig"),
                .copy("Rules/Resources"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("ApproachableConcurrency"),
            ],
        ),
    ],
)
