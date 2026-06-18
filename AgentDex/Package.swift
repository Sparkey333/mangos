// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AgentDex",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "AgentDexCore", targets: ["AgentDexCore"])
    ],
    targets: [
        .target(
            name: "AgentDexCore",
            resources: [
                // Example seed data ships with the core so the prototype runs
                // even before you wire up the app bundle.
                .copy("Resources/agents.example.json"),
                .copy("Resources/player.example.json")
            ]
        ),
        .testTarget(
            name: "AgentDexCoreTests",
            dependencies: ["AgentDexCore"]
        )
    ]
)
