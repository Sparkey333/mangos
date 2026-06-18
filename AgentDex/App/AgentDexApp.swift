import SwiftUI

/// App entry point. iOS-first; the same code targets macOS once you add a Mac
/// destination (the simulation in AgentDexCore is platform-agnostic).
@main
struct AgentDexApp: App {
    @StateObject private var game = GameState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        TabView {
            OverworldView()
                .tabItem { Label("World", systemImage: "map") }
            DexView()
                .tabItem { Label("Dex", systemImage: "books.vertical") }
            TownView()
                .tabItem { Label("Hub", systemImage: "house") }
        }
    }
}
