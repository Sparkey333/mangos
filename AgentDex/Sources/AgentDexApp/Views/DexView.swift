import SwiftUI
import AgentDexCore

/// The Dex: every species generated from your agents, searchable and filterable,
/// with caught/seen status and the full generated identity per entry.
public struct DexView: View {
    @EnvironmentObject var game: GameState

    @State private var searchText: String = ""
    @State private var aspectFilter: Aspect? = nil
    @State private var tierFilter: Tier? = nil
    @State private var statusFilter: StatusFilter = .all
    @State private var sortMode: SortMode = .tier

    public init() {}

    enum StatusFilter: String, CaseIterable {
        case all, caught, seen, unknown
        var label: String { rawValue.capitalized }
    }

    enum SortMode: String, CaseIterable {
        case tier = "Tier ↓"
        case name = "Name A–Z"
        case bst = "BST ↓"
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                header
                searchField
                filterRow
                speciesList
            }
            .navigationTitle("Dex")
        }
    }

    // MARK: - Derived

    private var caughtCount: Int { game.save.caughtCount }
    private var seenCount: Int { game.save.seenCount }
    private var totalCount: Int { game.bestiary.species.count }

    private func status(for s: DaemonSpecies) -> DexStatus { game.save.dex[s.id] ?? .unknown }

    private var filteredSpecies: [DaemonSpecies] {
        var list = game.bestiary.species

        let query = searchText.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(query) ||
                $0.sourceAgentName.localizedCaseInsensitiveContains(query)
            }
        }
        if let aspect = aspectFilter {
            list = list.filter { $0.aspects.contains(aspect) }
        }
        if let tier = tierFilter {
            list = list.filter { $0.tier == tier }
        }
        if statusFilter != .all {
            list = list.filter { sp in
                switch statusFilter {
                case .all:     return true
                case .caught:  return status(for: sp) == .caught
                case .seen:    return status(for: sp) == .seen
                case .unknown: return status(for: sp) == .unknown
                }
            }
        }
        switch sortMode {
        case .tier:
            list.sort { a, b in
                if a.tier != b.tier { return a.tier > b.tier }
                return a.name < b.name
            }
        case .name:
            list.sort { $0.name < $1.name }
        case .bst:
            list.sort { a, b in
                if a.baseStats.total != b.baseStats.total { return a.baseStats.total > b.baseStats.total }
                return a.name < b.name
            }
        }
        return list
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Caught \(caughtCount)").bold()
                Text("· Seen \(seenCount)").foregroundStyle(.secondary)
                Spacer()
                Text("\(caughtCount)/\(totalCount)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            ProgressView(value: Double(caughtCount), total: Double(max(1, totalCount)))
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search name or agent", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }

    // MARK: - Filters

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                aspectMenu
                tierMenu
                statusMenu
                sortMenu
            }
            .padding(.horizontal)
        }
    }

    private var aspectMenu: some View {
        Menu {
            Button("All Aspects") { aspectFilter = nil }
            ForEach(Aspect.allCases, id: \.self) { a in
                Button(a.rawValue.capitalized) { aspectFilter = a }
            }
        } label: {
            menuChip("Aspect", value: aspectFilter.map { $0.rawValue.capitalized })
        }
    }

    private var tierMenu: some View {
        Menu {
            Button("All Tiers") { tierFilter = nil }
            ForEach(Tier.allCases, id: \.self) { t in
                Button(t.rawValue.capitalized) { tierFilter = t }
            }
        } label: {
            menuChip("Tier", value: tierFilter.map { $0.rawValue.capitalized })
        }
    }

    private var statusMenu: some View {
        Menu {
            ForEach(StatusFilter.allCases, id: \.self) { f in
                Button(f.label) { statusFilter = f }
            }
        } label: {
            menuChip("Status", value: statusFilter == .all ? nil : statusFilter.label)
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(SortMode.allCases, id: \.self) { m in
                Button(m.rawValue) { sortMode = m }
            }
        } label: {
            menuChip("Sort", value: sortMode.rawValue)
        }
    }

    private func menuChip(_ title: String, value: String?) -> some View {
        HStack(spacing: 4) {
            Text(value.map { "\(title): \($0)" } ?? title)
            Image(systemName: "chevron.down").font(.caption2)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.thinMaterial, in: Capsule())
    }

    // MARK: - List

    private var speciesList: some View {
        List(filteredSpecies) { sp in
            NavigationLink {
                DaemonDetailView(species: sp, status: status(for: sp))
            } label: {
                row(sp)
            }
        }
        .listStyle(.plain)
    }

    private func row(_ sp: DaemonSpecies) -> some View {
        let st = status(for: sp)
        // Log-only glimpses read cooler/bluer until actually caught.
        let logsGlimpse = sp.origin == .seenInLogs && st != .caught
        return HStack(spacing: 10) {
            DaemonSprite(recipe: sp.sprite, size: 44)
                .colorMultiply(logsGlimpse ? Color(hex: "#9FC5FF") : .white)
                .opacity(st == .unknown ? 0.25 : 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(st == .unknown ? "???" : sp.name).bold()
                HStack(spacing: 4) {
                    chip(sp.tier.rawValue)
                    chip(sp.aspects.map(\.rawValue).joined(separator: "/"))
                }
            }
            Spacer()
            statusBadge(st)
        }
        .padding(.vertical, 2)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.thinMaterial, in: Capsule())
            .foregroundStyle(.secondary)
    }

    @ViewBuilder private func statusBadge(_ st: DexStatus) -> some View {
        switch st {
        case .caught:  Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
        case .seen:    Image(systemName: "eye").foregroundStyle(.yellow)
        case .unknown: Image(systemName: "questionmark.circle").foregroundStyle(.gray)
        }
    }
}

// MARK: - Detail

public struct DaemonDetailView: View {
    public let species: DaemonSpecies
    public let status: DexStatus

    public init(species: DaemonSpecies, status: DexStatus) {
        self.species = species
        self.status = status
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DaemonSprite(recipe: species.sprite, size: 150, animating: true)

                Text(status == .unknown ? "???" : species.name)
                    .font(.largeTitle).bold()

                Text("from agent “\(species.sourceAgentName)” · \(species.habitat)")
                    .font(.caption).foregroundStyle(.secondary)

                chipsRow

                Text(species.flavor)
                    .font(.callout).italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                abilityCard

                // The mechanical guts stay fogged until you actually bind one.
                VStack(spacing: 16) {
                    statsCard
                    learnsetCard
                    ascensionCard
                }
                .blur(radius: status == .caught ? 0 : 6)
                .overlay(lockedOverlay)

                catchDifficultyRow
            }
            .padding()
        }
        .navigationTitle(status == .unknown ? "???" : species.name)
    }

    // MARK: - Pieces

    private var chipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                tag(species.tier.rawValue.capitalized)
                ForEach(species.aspects, id: \.self) { a in
                    tag(a.rawValue)
                }
                tag(species.origin.rawValue.replacingOccurrences(of: "_", with: " "))
                tag("nature: \(species.nature.rawValue)")
            }
            .padding(.horizontal)
        }
    }

    private var abilityCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(species.ability.displayName).font(.headline)
            Text(species.ability.blurb).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Base Stats").font(.headline)
            ForEach(Stat.allCases, id: \.self) { stat in
                HStack {
                    Text(stat.rawValue.uppercased())
                        .font(.caption)
                        .frame(width: 44, alignment: .leading)
                    ProgressView(value: Double(species.baseStats[stat]), total: 160)
                    Text("\(species.baseStats[stat])")
                        .font(.caption).monospacedDigit()
                        .frame(width: 34, alignment: .trailing)
                }
            }
            Text("BST \(species.baseStats.total)")
                .font(.caption).bold().monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var learnsetCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Learnset").font(.headline)
            ForEach(MovePool.moves(for: species.primaryAspect), id: \.id) { m in
                HStack {
                    Text("Lv \(m.unlockLevel)")
                        .font(.caption.monospaced())
                        .frame(width: 44, alignment: .leading)
                    Text(m.name).font(.caption).bold()
                    Spacer()
                    Text("\(m.aspect.rawValue) · \(m.power > 0 ? "PWR \(m.power)" : m.effect.rawValue)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var ascensionCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Ascension").font(.headline)
            if species.isAscended {
                Text("Ascended form").font(.caption)
            } else if let lvl = species.tier.ascensionLevel {
                Text("Ascends at Lv \(lvl) → \(Ascension.ascend(species).name)").font(.caption)
            } else {
                Text("Does not ascend").font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var catchDifficultyRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "target")
            Text("Catch difficulty: \(catchDifficulty)")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var catchDifficulty: String {
        switch species.catchBaseRate {
        case 150...: return "trivial"
        case 90...:  return "easy"
        case 45...:  return "tricky"
        case 10...:  return "hard"
        default:     return "legendary"
        }
    }

    @ViewBuilder private var lockedOverlay: some View {
        if status != .caught {
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                Text("Bind one to complete this entry.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func tag(_ s: String) -> some View {
        Text(s)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
    }
}
