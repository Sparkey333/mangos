import WidgetKit
import SwiftUI
import AgentDexCore

/// Home/lock-screen widget (iOS + macOS via WidgetKit). Reads the shared
/// SaveState and shows your active daemon + party/Dex progress — a "Daemon of the
/// Day" style glance. Reuses `SharedStore`, so the widget and app stay in sync.

struct PartyEntry: TimelineEntry {
    let date: Date
    let activeName: String
    let activeLevel: Int
    let recipe: SpriteRecipe?
    let caught: Int
    let total: Int
}

struct PartyProvider: TimelineProvider {
    func placeholder(in context: Context) -> PartyEntry {
        PartyEntry(date: .now, activeName: "Fluxmorph", activeLevel: 5,
                   recipe: nil, caught: 1, total: 7)
    }

    func getSnapshot(in context: Context, completion: @escaping (PartyEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PartyEntry>) -> Void) {
        let entry = makeEntry()
        // Refresh hourly; the app also reloads timelines on capture.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> PartyEntry {
        guard let save = SharedStore.load() else {
            return PartyEntry(date: .now, activeName: "No daemon yet", activeLevel: 0,
                              recipe: nil, caught: 0, total: 0)
        }
        let active = save.activeDaemon
        // Total species count isn't in the save; approximate with dex entries.
        let total = max(save.dex.count, save.caughtCount)
        return PartyEntry(
            date: .now,
            activeName: active?.species.name ?? "Empty party",
            activeLevel: active?.level ?? 0,
            recipe: active?.species.sprite,
            caught: save.caughtCount,
            total: total
        )
    }
}

struct AgentDexWidgetView: View {
    var entry: PartyEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall: small
        default: medium
        }
    }

    private var small: some View {
        VStack(spacing: 6) {
            sprite(size: 48)
            Text(entry.activeName).font(.caption).bold().lineLimit(1)
            Text("Lv \(entry.activeLevel)").font(.caption2).foregroundStyle(.secondary)
            Text("\(entry.caught) bound").font(.caption2)
        }
        .padding()
    }

    private var medium: some View {
        HStack(spacing: 16) {
            sprite(size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text("Active: \(entry.activeName)").font(.headline)
                Text("Level \(entry.activeLevel)").font(.subheadline).foregroundStyle(.secondary)
                Text("Daemons bound: \(entry.caught)").font(.caption)
            }
            Spacer()
        }
        .padding()
    }

    @ViewBuilder private func sprite(size: CGFloat) -> some View {
        if let r = entry.recipe {
            DaemonSprite(recipe: r, size: size)
        } else {
            Image(systemName: "circle.dashed").font(.system(size: size * 0.6))
                .foregroundStyle(.secondary)
        }
    }
}

@main
struct AgentDexWidget: Widget {
    let kind = "AgentDexWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PartyProvider()) { entry in
            AgentDexWidgetView(entry: entry)
        }
        .configurationDisplayName("AgentDex")
        .description("Your active daemon and how many you've bound.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
