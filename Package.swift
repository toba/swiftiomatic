// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "swiftiomatic",
    platforms: [.macOS(.v26)],
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
        // Accept any 603.x patch or minor release. swift-syntax bumps the major
        // version for each Swift release, so 604 and later can break the API.
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "603.0.0"..<"604.0.0"),
        // Self-hosted lint via prebuilt binary from a previous release. Breaks
        // the cycle that prevents a target from depending on a plugin in the
        // same package as the executable the plugin invokes.
        .package(url: "https://github.com/toba/swiftiomatic-plugins", from: "3.0.0"),
        // `AnyCodingKey` lets `Configuration` decode and encode a key it does not
        // name in an enum. The type sat in `ConfigurationKit` as a copy of this
        // one. The three `Platform/*.swift` files import AppKit on macOS, but
        // each holds one `typealias` and exports no symbol, so a link never
        // pulls them.
        //
        // 1.12.0 is the floor because it is the first release that ships the
        // library dynamic under the name TobaCoreLibrary. A static product is
        // absorbed into every image that links it, so two images in one process
        // hold two type descriptors for each TobaCore type, and a conformance
        // lookup that compares them returns a null metadata the Swift runtime
        // dies on. The floor was 1.0.0, which already declares every conformance
        // `Configuration` relies on.
        .package(url: "https://github.com/toba/toba-core", from: "1.12.0"),
        // `Mutex+support` turns `withLock { $0.append(x) }` into `append(x)` and
        // `withLock { $0 }` into `withValue`. The package declares no dependency
        // of its own and imports no UI framework, so it adds nothing to the `sm`
        // link.
        //
        // 1.1.0 is the floor because it is the first release that ships the
        // library dynamic under the name TobaConcurrencyLibrary. A static
        // product is absorbed into every image that links it, and two type
        // descriptors for one type make a conformance lookup return a null
        // metadata the Swift runtime dies on. The floor was 1.0.0, which already
        // declares every helper this package calls.
        .package(url: "https://github.com/toba/toba-concurrency", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "ConfigurationKit",
            exclude: ["README.md"]
        ),
        .target(
            name: "SwiftiomaticKit",
            dependencies: [
                "ConfigurationKit",
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "TobaConcurrencyLibrary", package: "toba-concurrency"),
                .product(name: "TobaCoreLibrary", package: "toba-core"),
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
            capability: .command(
                intent: .custom(
                    verb: "lint-source-code",
                    description: "Lint source code for a specified target."
                )
            ),
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
            name: "Generator",
            dependencies: ["GeneratorKit"],
            exclude: ["README.md"]
        ),
        .executableTarget(
            name: "Swiftiomatic",
            dependencies: [
                "SwiftiomaticKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "TobaConcurrencyLibrary", package: "toba-concurrency"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            exclude: ["README.md"],
            plugins: [
                .plugin(name: "SwiftiomaticBuildToolPlugin", package: "swiftiomatic-plugins"),
            ]
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
