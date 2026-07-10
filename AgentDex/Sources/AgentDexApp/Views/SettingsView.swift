import SwiftUI
import AgentDexCore

/// Player-facing knobs. Everything routes through `game.settings` /
/// `game.travel(to:)` so persistence and side effects stay in GameState.
public struct SettingsView: View {
    @EnvironmentObject var game: GameState
    @State private var confirmingReset = false

    public init() {}

    public var body: some View {
        Form {
            Section("Battles") {
                Toggle("Classic battle screen", isOn: setting(\.classicBattles))
                Toggle("Show damage numbers", isOn: setting(\.showDamageNumbers))
            }

            Section("Feel") {
                Toggle("Sound", isOn: setting(\.soundOn))
                Toggle("Haptics", isOn: setting(\.hapticsOn))
            }

            Section("World") {
                Picker("Region", selection: regionBinding) {
                    ForEach(game.bestiary.regions, id: \.self) { project in
                        Text(WorldGen.region(for: project).displayName).tag(project)
                    }
                }
                .disabled(game.inBattle)

                infoRow("Load cycle", game.loadCycle.displayName)
                infoRow("Playtime", "\(Int(game.save.playtimeSeconds / 60)) min")
                infoRow("Roster", game.usingImportedRoster
                        ? "Imported roster ✓"
                        : "Sample roster — run agentdex-import to play your own agents")
            }

            Section("Danger") {
                Button("New Game", role: .destructive) {
                    confirmingReset = true
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Start a new game?",
                            isPresented: $confirmingReset,
                            titleVisibility: .visible) {
            Button("Wipe save & restart", role: .destructive) {
                game.resetGame()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your daemons will be released back into the codebase. They'll be fine. You might not be.")
        }
    }

    // MARK: - Bindings

    private func setting(_ keyPath: WritableKeyPath<GameSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { game.settings[keyPath: keyPath] },
            set: { newValue in
                var s = game.settings
                s[keyPath: keyPath] = newValue
                game.settings = s
            }
        )
    }

    private var regionBinding: Binding<String> {
        Binding(
            get: { game.save.currentRegion },
            set: { game.travel(to: $0) }
        )
    }

    // MARK: - Rows

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
            Spacer()
            Text(value)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}
