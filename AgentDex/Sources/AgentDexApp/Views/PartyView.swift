import SwiftUI
import AgentDexCore

/// Party management: the six on deck, the box in the back, and a detail sheet
/// per daemon with stats, moves, and the bag.
public struct PartyView: View {
    @EnvironmentObject var game: GameState
    @State private var selection: PartySelection?

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Balance")
                        Spacer()
                        Text("\(game.save.cycles)¢")
                            .bold()
                            .monospacedDigit()
                    }
                }

                Section("Party") {
                    if game.save.party.isEmpty {
                        Text("No daemons yet. The overworld awaits, ominously.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(Array(game.save.party.enumerated()), id: \.element.id) { i, d in
                        Button {
                            selection = PartySelection(id: i)
                        } label: {
                            partyRow(d)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Box") {
                    if game.save.box.isEmpty {
                        Text("Empty. The box dreams of daemons.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(Array(game.save.box.enumerated()), id: \.element.id) { j, d in
                        boxRow(d, index: j)
                    }
                }
            }
            .navigationTitle("Party")
            .sheet(item: $selection) { sel in
                PartyDetailSheet(index: sel.id)
                    .environmentObject(game)
            }
        }
    }

    // MARK: - Rows

    private func partyRow(_ d: Daemon) -> some View {
        HStack(spacing: 12) {
            DaemonSprite(recipe: d.species.sprite, size: 44, anomalous: d.isAnomalous)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(d.species.isAscended ? "\(d.species.name) ✦" : d.species.name)
                        .font(.headline)
                    if d.status != .none {
                        Text(d.status.displayName)
                            .font(.caption2.bold())
                            .foregroundStyle(Color(hex: d.status.colorHex))
                    }
                    Spacer()
                    Text("Lv \(d.level)")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: d.hpFraction)
                    .tint(d.hpFraction > 0.3 ? .green : .red)
                ProgressView(value: Experience.levelProgress(currentXP: d.xp))
                    .tint(.yellow)
                Text(d.species.ability.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }

    private func boxRow(_ d: Daemon, index: Int) -> some View {
        HStack(spacing: 12) {
            DaemonSprite(recipe: d.species.sprite, size: 36, anomalous: d.isAnomalous)
            VStack(alignment: .leading, spacing: 2) {
                Text(d.species.isAscended ? "\(d.species.name) ✦" : d.species.name)
                    .font(.subheadline.bold())
                Text("Lv \(d.level)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Withdraw") {
                game.withdrawFromBox(index)
            }
            .buttonStyle(.bordered)
            .disabled(game.save.party.count >= 6)
        }
    }
}

/// Identifiable wrapper so an Int index can drive `.sheet(item:)`.
private struct PartySelection: Identifiable {
    let id: Int
}

/// Full detail for one party member: big sprite, six stats, moves, actions, bag.
private struct PartyDetailSheet: View {
    @EnvironmentObject var game: GameState
    @Environment(\.dismiss) private var dismiss
    let index: Int

    var body: some View {
        Group {
            if game.save.party.indices.contains(index) {
                detail(game.save.party[index])
            } else {
                // The daemon moved out from under us (boxed, etc.). Bow out.
                VStack(spacing: 12) {
                    Text("This daemon has stepped away.")
                        .foregroundStyle(.secondary)
                    Button("Close") { dismiss() }
                        .buttonStyle(.bordered)
                }
                .padding(40)
            }
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 540)
        #endif
    }

    private func detail(_ d: Daemon) -> some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 8) {
                        DaemonSprite(recipe: d.species.sprite, size: 120,
                                     anomalous: d.isAnomalous, animating: true)
                        Text(d.species.isAscended ? "\(d.species.name) ✦" : d.species.name)
                            .font(.title2.bold())
                        HStack(spacing: 8) {
                            Text("Lv \(d.level)").monospacedDigit()
                            Text("HP \(d.currentHP)/\(d.maxHP)").monospacedDigit()
                            if d.status != .none {
                                Text(d.status.displayName)
                                    .bold()
                                    .foregroundStyle(Color(hex: d.status.colorHex))
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        Text("\(d.species.ability.displayName) — \(d.species.ability.blurb)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section("Stats") {
                    ForEach(Stat.allCases, id: \.self) { s in
                        statRow(s, daemon: d)
                    }
                }

                Section("Moves") {
                    ForEach(d.moves) { m in
                        HStack(spacing: 8) {
                            Text(m.name)
                            Spacer()
                            Text(m.aspect.rawValue.capitalized)
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color(hex: m.aspect.palette.primary).opacity(0.8)))
                                .foregroundStyle(Color.black.opacity(0.8))
                            Text(m.power > 0 ? "\(m.power)" : "—")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }

                Section("Actions") {
                    Button("Set Lead") {
                        game.setLead(index)
                    }
                    .disabled(index == 0)

                    Button("Send to Box") {
                        game.moveToBox(index)
                        dismiss()
                    }
                    .disabled(game.save.party.count <= 1)
                }

                Section("Bag") {
                    let carried = Item.all.filter { game.save.itemCount($0) > 0 }
                    if carried.isEmpty {
                        Text("Nothing in the bag. Vex sends her regards.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(carried) { item in
                        Button {
                            game.useItem(item, onPartyIndex: index)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(item.name) ×\(game.save.itemCount(item))")
                                    .monospacedDigit()
                                Text(item.blurb)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(!canUse(item, on: d))
                    }
                }
            }
            .navigationTitle(d.species.name)
            .toolbar {
                ToolbarItem {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func statRow(_ s: Stat, daemon d: Daemon) -> some View {
        let value = d.stat(s)
        let peak = max(1, Stat.allCases.map { d.stat($0) }.max() ?? 1)
        return HStack(spacing: 8) {
            Text(s.rawValue.uppercased())
                .font(.caption.bold())
                .frame(width: 40, alignment: .leading)
            ProgressView(value: Double(value) / Double(peak))
            Text("\(value)")
                .font(.caption)
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
        }
    }

    /// Mirrors the guards in `GameState.useItem` so buttons dim sensibly.
    private func canUse(_ item: Item, on d: Daemon) -> Bool {
        switch item.effect {
        case .heal, .fullHeal:
            return !d.isFainted && d.currentHP < d.maxHP
        case .revive:
            return d.isFainted
        case .cureStatus:
            return d.status != .none
        case .xpBoost:
            return d.level < Experience.maxLevel
        }
    }
}
