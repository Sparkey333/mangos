import SwiftUI
import AgentDexCore

/// The main story arc, one row per quest: done, current (highlighted, with live
/// progress), or still classified.
public struct QuestJournalView: View {
    @EnvironmentObject var game: GameState

    public init() {}

    public var body: some View {
        List {
            ForEach(StoryArc.quests) { quest in
                if game.save.completedQuests.contains(quest.id) {
                    completedRow(quest)
                } else if quest.id == game.currentQuest?.id {
                    currentCard(quest)
                } else {
                    lockedRow(quest)
                }
            }
        }
        .navigationTitle("Quest Journal")
    }

    // MARK: - Rows

    private func completedRow(_ quest: Quest) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(quest.title)
                Text(quest.completionLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func currentCard(_ quest: Quest) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "scope")
                    .foregroundStyle(Color.accentColor)
                Text(quest.title)
                    .font(.headline.bold())
                Spacer()
                Text("+\(quest.rewardCycles)¢")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Text(quest.brief)
                .font(.callout)
            Text("Objective: \(quest.objectiveText)")
                .font(.caption.bold())
            Text(QuestEngine.evaluate(quest.objective, save: game.save).progress)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Text("From: \(Scripts.giverName(quest.giverNPC))")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if quest.giverNPC == "rival_rune" {
                Button("Duel Rune") {
                    game.startRivalBattle()
                }
                .buttonStyle(.borderedProminent)
                .disabled(game.inBattle)
                .padding(.top, 4)
            }
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func lockedRow(_ quest: Quest) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundStyle(.secondary)
            Text("Quest \(quest.order): ???")
                .foregroundStyle(.secondary)
        }
    }
}
