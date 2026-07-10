import SwiftUI
import AgentDexCore

/// The Archivist's dopamine tokens, in a two-column grid. Secret ones stay
/// redacted until earned.
public struct AchievementsView: View {
    @EnvironmentObject var game: GameState

    public init() {}

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private var earnedCount: Int {
        AchievementEngine.all.filter { game.save.earnedAchievements.contains($0.id) }.count
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("\(earnedCount) / \(AchievementEngine.all.count) earned")
                    .font(.headline)
                    .monospacedDigit()
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(AchievementEngine.all) { achievement in
                        cell(achievement)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Achievements")
    }

    private func cell(_ achievement: Achievement) -> some View {
        let earned = game.save.earnedAchievements.contains(achievement.id)
        let redacted = achievement.secret && !earned
        return VStack(spacing: 6) {
            Image(systemName: earned ? "trophy.fill" : (redacted ? "questionmark.circle" : "trophy"))
                .font(.title2)
                .foregroundStyle(earned ? Color.yellow : Color.secondary)
            Text(redacted ? "???" : achievement.title)
                .font(.subheadline.bold())
                .multilineTextAlignment(.center)
            Text(redacted ? "???" : achievement.blurb)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .top)
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .opacity(earned ? 1.0 : 0.55)
    }
}
