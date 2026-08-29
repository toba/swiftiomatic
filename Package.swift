// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swiftiomatic",
    platforms: [.macOS(.v27)],
    products: [
        .executable(name: "sm", targets: ["Swiftiomatic"]),
        .library(name: "SwiftiomaticKit", targets: ["SwiftiomaticKit"]),
        .plugin(name: "FormatPlugin", targets: ["Format Source Code"]),
        .plugin(name: "LintPlugin", targets: ["Lint Source Code"]),
        .plugin(name: "LintBuildPlugin", targets: ["Lint on Build"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.7.0"),
        // 604 is the line that Swift 6.4 ships. It carries no stable tag yet, so the lower bound
        // names a prerelease to bring the 604 line into range.
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            "604.0.0-prerelease-2026-06-05"..<"605.0.0"
        ),
        // Self-hosted lint via prebuilt binary from a previous release. Breaks the cycle that
        // prevents a target from depending on a plugin in the same package as the executable the
        // plugin invokes.
        .package(url: "https://github.com/toba/swiftiomatic-plugins", from: "3.0.0"),
        // `AnyCodingKey` lets `Configuration` decode and encode a key it does not name in an enum.
        // The type sat in `ConfigurationKit` as a copy of this one. The three `Platform/*.swift`
        // files import AppKit on macOS, but each holds one `typealias` and exports no symbol, so a
        // link never pulls them. 1.11.3 is the floor because it reads TOBA_STATIC_LINK.
        .package(url: "https://github.com/toba/toba-core", from: "1.11.3"),
        // `Mutex+support` turns `withLock { $0.append(x) }` into `append(x)` and
        // `withLock { $0 }` into `withValue`. The package declares no dependency
        // of its own and imports no UI framework, so it adds nothing to the `sm`
        // link.
        // 1.1.1 is the floor because it reads TOBA_STATIC_LINK.
        .package(url: "https://github.com/toba/toba-concurrency", from: "1.1.1"),
        // Benchmarks only. No `sm` target depends on it, so it never links.
        .package(url: "https://github.com/ordo-one/benchmark", from: "1.36.2"),
        // Benchmarks only. Vends the run length and the threshold bands every suite shares.
        .package(url: "https://github.com/toba/toba-benchmark", from: "1.0.0"),
    ],
    targets: [
        .target(name: "ConfigurationKit", exclude: ["README.md"]),
        .target(
            name: "SwiftiomaticKit",
            dependencies: [
                "ConfigurationKit",
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "TobaConcurrency", package: "toba-concurrency"),
                .product(name: "TobaCore", package: "toba-core"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftWarningControl", package: "swift-syntax"),
            ],
            exclude: ["README.md", "Generated"],
            plugins: [
                "GenerateCode",
                .plugin(name: "SwiftiomaticBuildToolPlugin", package: "swiftiomatic-plugins"),
            ]
        ),
        .target(
            name: "SwiftiomaticTestSupport",
            dependencies: [
                "SwiftiomaticKit",
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ],
            path: "Tests/SwiftiomaticTestSupport",
            exclude: ["README.md"]
        ),
        .target(
            name: "GeneratorKit",
            dependencies: [
                "ConfigurationKit",
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            path: "Sources/GeneratorKit",
            exclude: ["README.md"]
        ),
        .plugin(
            name: "Format Source Code",
            capability: .command(
                intent: .sourceCodeFormatting(),
                permissions: [
                    .writeToPackageDirectory(reason: "This command formats the Swift source files")
                ]
            ),
            dependencies: [.target(name: "Swiftiomatic")],
            path: "Plugins/FormatPlugin"
        ),
        .plugin(
            name: "Lint Source Code",
            capability: .command(intent: .custom(
                verb: "lint-source-code", description: "Lint source code for a specified target.")),
            dependencies: [.target(name: "Swiftiomatic")],
            path: "Plugins/LintPlugin"
        ),
        .plugin(
            name: "Lint on Build",
            capability: .buildTool(),
            dependencies: [.target(name: "Swiftiomatic")],
            path: "Plugins/LintBuildPlugin"
        ),
        .plugin(
            name: "GenerateCode",
            capability: .buildTool(),
            dependencies: [.target(name: "Generator")],
            path: "Plugins/GeneratePlugin"
        ),
        .executableTarget(
            name: "Generator", dependencies: ["GeneratorKit"], exclude: ["README.md"]),
        .executableTarget(
            name: "Swiftiomatic",
            dependencies: [
                "SwiftiomaticKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "TobaConcurrency", package: "toba-concurrency"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            exclude: ["README.md"],
            plugins: [.plugin(name: "SwiftiomaticBuildToolPlugin", package: "swiftiomatic-plugins")]
        ),
        // Needs `-Xswiftc -enable-testing` because it uses `@testable`.
        .executableTarget(
            name: "SwiftiomaticBenchmarks",
            dependencies: [
                "SwiftiomaticKit",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "TobaBenchmark", package: "toba-benchmark"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            path: "Benchmarks/SwiftiomaticBenchmarks",
            exclude: ["README.md"],
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .testTarget(
            name: "SwiftiomaticPerformanceTests",
            dependencies: [
                "SwiftiomaticKit",
                "SwiftiomaticTestSupport",
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            exclude: ["README.md"]
        ),
        .testTarget(
            name: "SwiftiomaticTests",
            dependencies: [
                "SwiftiomaticKit",
                "SwiftiomaticTestSupport",
                "GeneratorKit",
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ],
            exclude: ["README.md"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
