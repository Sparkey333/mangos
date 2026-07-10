import WidgetKit
import SwiftUI
import AgentDexCore

/// Home/lock-screen widget (iOS + macOS via WidgetKit). Reads the shared
/// SaveState and shows your lead daemon, Dex progress, current quest, and a
/// deterministic "Daemon of the Day" drawn from your party + box. Reuses
/// `SharedStore`, so the widget and app stay in sync.
///
/// This file compiles in the WidgetKit extension target alongside
/// SharedStore.swift, Color+Hex.swift, DaemonSprite.swift, and AgentDexCore.

// MARK: - Timeline entry

struct PartyEntry: TimelineEntry {
    let date: Date
    let leadName: String
    let leadLevel: Int
    let leadRecipe: SpriteRecipe?
    let leadAnomalous: Bool
    let hpFraction: Double
    let caught: Int
    let seen: Int
    let cycles: Int
    let questTitle: String?
    let featuredName: String?
    let featuredRecipe: SpriteRecipe?
}

// MARK: - Provider

struct PartyProvider: TimelineProvider {

    func placeholder(in context: Context) -> PartyEntry {
        PartyEntry(
            date: Date(),
            leadName: "Fluxmorph",
            leadLevel: 5,
            leadRecipe: nil,
            leadAnomalous: false,
            hpFraction: 0.8,
            caught: 1,
            seen: 3,
            cycles: 200,
            questTitle: "Hello, World",
            featuredName: nil,
            featuredRecipe: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PartyEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PartyEntry>) -> Void) {
        let entry = makeEntry()
        // Refresh hourly; the app also reloads timelines on capture.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
            ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> PartyEntry {
        guard let save = SharedStore.load() else {
            return PartyEntry(
                date: Date(),
                leadName: "No daemon yet",
                leadLevel: 0,
                leadRecipe: nil,
                leadAnomalous: false,
                hpFraction: 0,
                caught: 0,
                seen: 0,
                cycles: 0,
                questTitle: nil,
                featuredName: nil,
                featuredRecipe: nil
            )
        }

        let lead = save.activeDaemon
        let questTitle = QuestEngine.currentQuest(save: save)?.title

        // Featured "Daemon of the Day": deterministic pick over party + box,
        // keyed by the calendar day so everyone sees the same daemon all day.
        var featured: Daemon?
        let all = save.party + save.box
        if !all.isEmpty {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            let day = formatter.string(from: Date())
            let key = "featured|\(day)"
            let idx = Int(stableHash(key) % UInt64(all.count))
            featured = all[idx]
        }

        let rawFraction = lead?.hpFraction ?? 0
        return PartyEntry(
            date: Date(),
            leadName: lead?.species.name ?? "Empty party",
            leadLevel: lead?.level ?? 0,
            leadRecipe: lead?.species.sprite,
            leadAnomalous: lead?.isAnomalous ?? false,
            hpFraction: min(max(rawFraction, 0), 1),
            caught: save.caughtCount,
            seen: save.seenCount,
            cycles: save.cycles,
            questTitle: questTitle,
            featuredName: featured?.species.name,
            featuredRecipe: featured?.species.sprite
        )
    }
}

// MARK: - Container background shim

extension View {
    /// iOS 17 / macOS 14 require a container background for widgets; earlier
    /// OSes just get padding. Apply to every family's root view.
    @ViewBuilder func widgetBackground() -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            self.containerBackground(.background, for: .widget)
        } else {
            self.padding(8)
        }
    }
}

// MARK: - Views

struct AgentDexWidgetView: View {
    var entry: PartyEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            small.widgetBackground()
#if os(iOS)
        case .accessoryCircular:
            circular.widgetBackground()
#endif
        default:
            medium.widgetBackground()
        }
    }

    // MARK: Small — lead daemon at a glance.

    private var small: some View {
        VStack(spacing: 4) {
            sprite(size: 48, recipe: entry.leadRecipe, anomalous: entry.leadAnomalous)
            Text(entry.leadName)
                .font(.caption).bold()
                .lineLimit(1)
            Text("Lv \(entry.leadLevel)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            ProgressView(value: entry.hpFraction)
                .progressViewStyle(.linear)
                .frame(height: 4)
            Text("\(entry.caught) bound")
                .font(.caption2)
        }
    }

    // MARK: Medium — lead block + progress column.

    private var medium: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                sprite(size: 64, recipe: entry.leadRecipe, anomalous: entry.leadAnomalous)
                Text(entry.leadName)
                    .font(.caption).bold()
                    .lineLimit(1)
                Text("Lv \(entry.leadLevel)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ProgressView(value: entry.hpFraction)
                    .progressViewStyle(.linear)
                    .frame(height: 4)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Dex \(entry.caught)·\(entry.seen) seen")
                    .font(.caption)
                Text("\(entry.cycles)¢")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Text(entry.questTitle ?? "Story complete ✓")
                    .font(.caption)
                    .lineLimit(2)
                if let name = entry.featuredName {
                    HStack(spacing: 4) {
                        if let recipe = entry.featuredRecipe {
                            sprite(size: 24, recipe: recipe, anomalous: false)
                        }
                        Text("Today: \(name)")
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Lock screen (iOS only) — Dex progress gauge.

#if os(iOS)
    private var circular: some View {
        Gauge(value: Double(entry.caught),
              in: 0...Double(max(entry.caught + 1, entry.seen, 1))) {
            Image(systemName: "seal")
        }
        .gaugeStyle(.accessoryCircular)
    }
#endif

    // MARK: Shared sprite helper.

    @ViewBuilder
    private func sprite(size: CGFloat, recipe: SpriteRecipe?, anomalous: Bool) -> some View {
        if let recipe = recipe {
            DaemonSprite(recipe: recipe, size: size, anomalous: anomalous, animating: false)
        } else {
            Image(systemName: "circle.dashed")
                .font(.system(size: size * 0.6))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Widget

@main
struct AgentDexWidget: Widget {
    let kind = "AgentDexWidget"

    private var families: [WidgetFamily] {
        var fams: [WidgetFamily] = [.systemSmall, .systemMedium]
#if os(iOS)
        fams.append(.accessoryCircular)
#endif
        return fams
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PartyProvider()) { entry in
            AgentDexWidgetView(entry: entry)
        }
        .configurationDisplayName("AgentDex")
        .description("Your lead daemon, Dex progress, and the daemon of the day.")
        .supportedFamilies(families)
    }
}
