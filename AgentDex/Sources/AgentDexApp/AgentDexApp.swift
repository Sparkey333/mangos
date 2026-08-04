import SwiftUI
import Combine
import Foundation
import AgentDexCore

/// App entry point. One `GameState` for the whole app; onboarding gates the
/// main tabs; a global toast banner floats over everything.
@main
struct AgentDexApp: App {
    @StateObject private var game = GameState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(game)
        }
    }
}

/// Switches between onboarding and the main tab shell, and hosts global
/// chrome: the toast banner and the 1-second playtime clock that drives
/// load cycles (this world's day/night).
@MainActor
struct RootView: View {
    @EnvironmentObject var game: GameState

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .top) {
            if game.needsOnboarding {
                OnboardingView()
            } else {
                mainTabs
            }

            ToastBanner()
        }
        .onReceive(clock) { _ in
            game.tickPlaytime(1)
        }
        .onAppear {
            AudioBootstrap.install()
            Cues.configure(sound: game.settings.soundOn, haptics: game.settings.hapticsOn)
        }
    }

    private var mainTabs: some View {
        TabView {
            OverworldView()
                .tabItem { Label("World", systemImage: "map") }
            PartyView()
                .tabItem { Label("Party", systemImage: "person.3") }
            DexView()
                .tabItem { Label("Dex", systemImage: "books.vertical") }
            TownView()
                .tabItem { Label("Hub", systemImage: "house") }
        }
    }
}

/// Shows the oldest pending toast in a material capsule pinned to the top.
/// Each toast auto-dismisses after ~2.5s; new toasts play the achievement cue.
@MainActor
private struct ToastBanner: View {
    @EnvironmentObject var game: GameState

    /// Invalidates stale auto-dismiss timers when the queue changes.
    @State private var generation = 0
    /// Last seen queue depth, to detect newly-arrived toasts.
    @State private var seenCount = 0

    var body: some View {
        VStack {
            if let toast = game.toasts.first {
                Text(toast)
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.top, 6)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: game.toasts)
        .onAppear {
            handleQueueChange(game.toasts, cueNewToasts: false)
        }
        .onChange(of: game.toasts) { toasts in
            handleQueueChange(toasts, cueNewToasts: true)
        }
    }

    private func handleQueueChange(_ toasts: [String], cueNewToasts: Bool) {
        if cueNewToasts && toasts.count > seenCount {
            Cues.play(.achievement)
        }
        seenCount = toasts.count

        guard !toasts.isEmpty else { return }
        generation += 1
        let gen = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if gen == generation {
                game.dismissToast()
            }
        }
    }
}
