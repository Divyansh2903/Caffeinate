// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Caffeinate",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Caffeinate",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ],
            path: "Sources/Caffeinate"
        ),
        .testTarget(
            name: "CaffeinateTests",
            dependencies: ["Caffeinate"],
            path: "Tests/CaffeinateTests"
        ),
    ]
)
