import SwiftUI
import AgentDexCore

/// The Dex: every species generated from your agents, with caught/seen status and
/// the generated identity (aspect, tier, stats, flavor).
public struct DexView: View {
    @EnvironmentObject var game: GameState

    public init() {}

    public var body: some View {
        NavigationStack {
            List(game.bestiary.species) { species in
                NavigationLink {
                    DaemonDetailView(species: species, status: status(for: species))
                } label: {
                    row(species)
                }
            }
            .navigationTitle("Dex (\(game.save.caughtCount)/\(game.bestiary.species.count))")
        }
    }

    private func status(for s: DaemonSpecies) -> DexStatus { game.save.dex[s.id] ?? .unknown }

    private func row(_ s: DaemonSpecies) -> some View {
        let st = status(for: s)
        return HStack {
            DaemonSprite(recipe: s.sprite, size: 44)
                .opacity(st == .unknown ? 0.25 : 1)
            VStack(alignment: .leading) {
                Text(st == .unknown ? "???" : s.name).bold()
                Text("\(s.tier.rawValue.capitalized) · \(s.primaryAspect.rawValue)\(s.secondaryAspect.map { "/\($0.rawValue)" } ?? "")")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            statusBadge(st)
        }
    }

    @ViewBuilder private func statusBadge(_ st: DexStatus) -> some View {
        switch st {
        case .caught: Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
        case .seen:   Image(systemName: "eye").foregroundStyle(.yellow)
        case .unknown: Image(systemName: "questionmark.circle").foregroundStyle(.gray)
        }
    }
}

public struct DaemonDetailView: View {
    let species: DaemonSpecies
    let status: DexStatus

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DaemonSprite(recipe: species.sprite, size: 140)
                Text(species.name).font(.largeTitle).bold()
                Text("from agent “\(species.sourceAgentName)” · \(species.habitat)")
                    .font(.caption).foregroundStyle(.secondary)

                HStack {
                    tag(species.tier.rawValue.capitalized)
                    tag(species.primaryAspect.rawValue)
                    if let s = species.secondaryAspect { tag(s.rawValue) }
                    tag(species.origin.rawValue.replacingOccurrences(of: "_", with: " "))
                }

                Text(species.flavor)
                    .font(.callout).italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                statsView
                movesView
            }
            .padding()
        }
        .navigationTitle(status == .unknown ? "???" : species.name)
    }

    private var statsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Base Stats (\(species.baseStats.total))").font(.headline)
            ForEach(Stat.allCases, id: \.self) { stat in
                HStack {
                    Text(stat.rawValue.uppercased()).font(.caption).frame(width: 44, alignment: .leading)
                    ProgressView(value: Double(species.baseStats[stat]), total: 160)
                    Text("\(species.baseStats[stat])").font(.caption).monospacedDigit()
                }
            }
        }
        .padding().background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var movesView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Moves").font(.headline)
            ForEach(species.moves) { m in
                HStack {
                    Text(m.name).bold()
                    Spacer()
                    Text("\(m.aspect.rawValue) · \(m.power > 0 ? "PWR \(m.power)" : m.effect.rawValue)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding().background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func tag(_ s: String) -> some View {
        Text(s).font(.caption2).padding(.horizontal, 8).padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
    }
}
