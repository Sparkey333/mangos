import SwiftUI
import AgentDexCore

/// The Hub tab: the cast up top, the services below. NPC Q&A entries ARE the
/// in-game help system — tutorials, but in character (DESIGN §8).
public struct TownView: View {
    @EnvironmentObject var game: GameState

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Folks") {
                    ForEach(game.npcs) { npc in
                        NavigationLink {
                            NPCDetailView(npc: npc)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(npc.name).bold()
                                Text(npc.role)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Services") {
                    Button {
                        game.healPartyAtHub()
                        Cues.play(.heal)
                    } label: {
                        Label("Clinic — restore party", systemImage: "cross.case")
                    }

                    NavigationLink {
                        ShopView()
                    } label: {
                        Label("Vex's Spheres", systemImage: "circle.circle")
                    }

                    NavigationLink {
                        QuestJournalView()
                    } label: {
                        Label(questJournalLabel, systemImage: "book.closed")
                    }

                    NavigationLink {
                        AchievementsView()
                    } label: {
                        Label("Achievements", systemImage: "trophy")
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .navigationTitle("The Hub")
        }
    }

    private var questJournalLabel: String {
        if let quest = game.currentQuest {
            return "Quest Journal — \(quest.title)\(game.currentQuestReady ? " ✓" : "")"
        }
        return "Quest Journal — ✓ all done"
    }
}

/// One NPC: greeting card, expandable Q&A, and an ambient one-liner.
/// Visiting counts as talking (feeds `talkTo` quest objectives).
public struct NPCDetailView: View {
    @EnvironmentObject var game: GameState
    let npc: NPC

    public init(npc: NPC) {
        self.npc = npc
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(npc.greetingLine(seed: npc.id))
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))

                Text("Ask \(npc.name)…")
                    .font(.headline)
                ForEach(Array(npc.qa.enumerated()), id: \.offset) { _, qa in
                    DisclosureGroup(qa.question) {
                        Text(qa.answer)
                            .font(.callout)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    }
                }

                if let idle = npc.idle.first {
                    Text("“\(idle)”")
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(npc.name)
        .onAppear {
            game.talk(to: npc)
        }
    }
}
