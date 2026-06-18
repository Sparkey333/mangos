import Foundation

/// The protagonist — seeded from you. Colors the intro and NPC dialogue, and
/// picks your starting affinity (which biases your first daemon / starter Sphere).
public struct PlayerProfile: Codable, Equatable, Sendable {
    public var handle: String
    public var bio: String
    /// Your leaning — biases starter selection and some dialogue.
    public var startingAspect: Aspect
    /// A few traits used to flavor dialogue (kept freeform on purpose).
    public var traits: [String]

    public init(handle: String, bio: String, startingAspect: Aspect, traits: [String] = []) {
        self.handle = handle; self.bio = bio
        self.startingAspect = startingAspect; self.traits = traits
    }

    public static let placeholder = PlayerProfile(
        handle: "Conductor",
        bio: "Runs a lot of agents. Sleeps occasionally.",
        startingAspect: .flux,
        traits: ["dry humor", "ships fast"]
    )
}
