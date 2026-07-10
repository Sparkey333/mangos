import SwiftUI
import AgentDexCore

/// Vex's shop: spheres up front, items in the back, commentary throughout.
/// Pushed from the Hub, so it uses the surrounding NavigationStack.
public struct ShopView: View {
    @EnvironmentObject var game: GameState

    public init() {}

    public var body: some View {
        List {
            Section {
                Text(vexLine)
                    .font(.callout)
                    .italic()
                HStack {
                    Text("Balance")
                    Spacer()
                    Text("\(game.save.cycles)¢")
                        .bold()
                        .monospacedDigit()
                }
            }

            Section("Spheres") {
                ForEach(Sphere.shopCatalog) { sphere in
                    sphereRow(sphere)
                }
            }

            Section("Items") {
                ForEach(Item.all) { item in
                    itemRow(item)
                }
            }
        }
        .navigationTitle("Vex's Spheres")
    }

    private var vexLine: String {
        game.npcs.first { $0.id == "shop_vex" }?.greeting.first
            ?? "Spheres! Get your Spheres!"
    }

    // MARK: - Rows

    private func sphereRow(_ sphere: Sphere) -> some View {
        let owned = game.save.sphereCount(sphere)
        return HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(sphere.name).font(.headline)
                    if owned > 0 {
                        Text("×\(owned)")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                Text(blurb(for: sphere))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(sphere.price)¢")
                    .font(.subheadline)
                    .monospacedDigit()
                Button("Buy") {
                    if game.buySphere(sphere) {
                        Cues.play(.buy)
                    } else {
                        Cues.play(.deny)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(game.save.cycles < sphere.price)
            }
        }
    }

    private func itemRow(_ item: Item) -> some View {
        let owned = game.save.itemCount(item)
        return HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.name).font(.headline)
                    if owned > 0 {
                        Text("×\(owned)")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                Text(item.blurb)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.price)¢")
                    .font(.subheadline)
                    .monospacedDigit()
                Button("Buy") {
                    if game.buyItem(item) {
                        Cues.play(.buy)
                    } else {
                        Cues.play(.deny)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(game.save.cycles < item.price)
            }
        }
    }

    // MARK: - Copy

    private func blurb(for sphere: Sphere) -> String {
        switch sphere.id {
        case "orb":
            return "The base model. No features, no excuses, occasionally works."
        case "bind_orb":
            return "An Orb that went to a seminar. Tries 50% harder, costs 200% more."
        case "resonant_orb":
            return "Rewards violence-first diplomacy — the lower their HP, the harder it grips."
        case "prime_sigil":
            return "Legendary-rated. The only Sphere that won't bounce off a prime and invoice you for the insult."
        case "aether_orb":
            return "Whispers citations at Aether daemons until they climb in to correct one."
        case "forge_orb":
            return "Forge daemons respect it. It has clearly been through production."
        case "order_orb":
            return "Order daemons enter voluntarily. It's properly labeled."
        case "warden_orb":
            return "Passed the Warden security review. The only Sphere that ever has."
        case "flux_orb":
            return "Flux daemons cannot resist a container marked 'miscellaneous'."
        case "cipher_orb":
            return "Cipher daemons mistake it for an unread log file. Snap. Done."
        default:
            return "A sphere of unclear provenance. Throw it and find out."
        }
    }
}
