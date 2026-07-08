import SwiftUI
import AgentDexCore

/// The Town tab: talk to NPCs. The Q&A entries ARE the in-game help system —
/// tutorialized in character (DESIGN §8). Also exposes Heal + restock for testing.
public struct TownView: View {
    @EnvironmentObject var game: GameState

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(game.npcs) { npc in
                        NavigationLink {
                            NPCDetailView(npc: npc)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(npc.name).bold()
                                Text(npc.role).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Conductor's Bench") {
                    Button("Restore party") { game.healParty() }
                    Text("Spheres: " + sphereSummary())
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("The Hub")
        }
    }

    private func sphereSummary() -> String {
        let items = game.save.inventory.filter { $0.value > 0 }
            .map { "\($0.key) x\($0.value)" }.sorted()
        return items.isEmpty ? "none" : items.joined(separator: ", ")
    }
}

public struct NPCDetailView: View {
    let npc: NPC

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(npc.greetingLine(seed: npc.id))
                    .font(.title3)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                Text("Ask \(npc.name)...").font(.headline)
                ForEach(Array(npc.qa.enumerated()), id: \.offset) { _, qa in
                    DisclosureGroup(qa.question) {
                        Text(qa.answer).font(.callout).padding(.vertical, 4)
                    }
                }

                if !npc.idle.isEmpty {
                    Text("- \(npc.idle.first ?? "")")
                        .font(.caption).italic().foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(npc.name)
    }
}
