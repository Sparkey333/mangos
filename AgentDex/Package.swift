// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AgentDex",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "AgentDexCore", targets: ["AgentDexCore"]),
        .library(name: "AgentDexImport", targets: ["AgentDexImport"]),
        // A macOS-runnable build of the game via `swift run AgentDexApp`.
        .executable(name: "AgentDexApp", targets: ["AgentDexApp"]),
        // The agent-roster importer CLI: `swift run agentdex-import ...`.
        .executable(name: "agentdex-import", targets: ["agentdex-import"]),
        // The art prompt/generation CLI: `swift run agentdex-artgen ...`.
        .executable(name: "agentdex-artgen", targets: ["agentdex-artgen"])
    ],
    targets: [
        .target(
            name: "AgentDexCore",
            resources: [
                .copy("Resources/agents.example.json"),
                .copy("Resources/player.example.json")
            ]
        ),
        .target(
            name: "AgentDexImport",
            dependencies: ["AgentDexCore"]
        ),
        .executableTarget(
            name: "agentdex-import",
            dependencies: ["AgentDexImport", "AgentDexCore"]
        ),
        .executableTarget(
            name: "agentdex-artgen",
            dependencies: ["AgentDexImport", "AgentDexCore"]
        ),
        // SwiftUI + SpriteKit app. Builds for iOS/macOS (Apple platforms only).
        .executableTarget(
            name: "AgentDexApp",
            dependencies: ["AgentDexCore", "AgentDexImport"]
        ),
        .testTarget(
            name: "AgentDexCoreTests",
            dependencies: ["AgentDexCore"]
        ),
        .testTarget(
            name: "AgentDexImportTests",
            dependencies: ["AgentDexImport", "AgentDexCore"]
        )
    ]
)
