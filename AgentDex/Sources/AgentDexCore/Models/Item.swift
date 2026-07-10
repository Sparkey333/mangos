import Foundation

/// Consumable items. Usable from the bag (Hub/Party) and mid-battle.
public struct Item: Codable, Equatable, Hashable, Identifiable, Sendable {
    public enum Effect: Codable, Equatable, Hashable, Sendable {
        case heal(Int)          // restore fixed HP
        case fullHeal           // restore all HP
        case revive             // revive a fainted daemon at half HP
        case cureStatus         // clear any status condition
        case xpBoost(Int)       // grant flat XP
    }

    public var id: String
    public var name: String
    public var blurb: String
    public var effect: Effect
    public var price: Int

    public init(id: String, name: String, blurb: String, effect: Effect, price: Int) {
        self.id = id; self.name = name; self.blurb = blurb
        self.effect = effect; self.price = price
    }

    // MARK: - Catalog

    public static let hotfix = Item(
        id: "hotfix", name: "Hotfix",
        blurb: "Restores 60 HP. Applied in production, naturally.",
        effect: .heal(60), price: 30)

    public static let fullPatch = Item(
        id: "full_patch", name: "Full Patch",
        blurb: "Restores all HP. Release notes sold separately.",
        effect: .fullHeal, price: 120)

    public static let rollback = Item(
        id: "rollback", name: "Rollback",
        blurb: "Revives a crashed daemon at half HP. Works exactly once per purchase, like all rollbacks.",
        effect: .revive, price: 150)

    public static let debugger = Item(
        id: "debugger", name: "Debugger",
        blurb: "Clears any status condition. Mostly by staring at it.",
        effect: .cureStatus, price: 25)

    public static let trainingData = Item(
        id: "training_data", name: "Training Data",
        blurb: "Grants 500 XP. Ethically sourced. Probably.",
        effect: .xpBoost(500), price: 200)

    public static let all: [Item] = [.hotfix, .fullPatch, .rollback, .debugger, .trainingData]

    public static func byID(_ id: String) -> Item? { all.first { $0.id == id } }
}
