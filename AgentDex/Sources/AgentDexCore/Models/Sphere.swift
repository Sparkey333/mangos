import Foundation

/// The catching "marbles/spheres" you throw. See DESIGN §5.5.
public struct Sphere: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var name: String
    /// Flat multiplier on the base catch rate.
    public var baseMultiplier: Double
    /// If set, grants a large affinity bonus when the target matches this aspect.
    public var affinityAspect: Aspect?
    /// Extra multiplier that scales with how low the target's HP is (Resonant-style).
    public var hpScaling: Double
    /// Allows attempting `prime`-tier daemons at a realistic rate.
    public var canBindPrime: Bool

    public init(id: String, name: String, baseMultiplier: Double,
                affinityAspect: Aspect? = nil, hpScaling: Double = 0,
                canBindPrime: Bool = false) {
        self.id = id; self.name = name; self.baseMultiplier = baseMultiplier
        self.affinityAspect = affinityAspect; self.hpScaling = hpScaling
        self.canBindPrime = canBindPrime
    }

    public static let orb = Sphere(id: "orb", name: "Orb", baseMultiplier: 1.0)
    public static let bindOrb = Sphere(id: "bind_orb", name: "Bind-Orb", baseMultiplier: 1.5)
    public static let resonantOrb = Sphere(id: "resonant_orb", name: "Resonant Orb", baseMultiplier: 1.0, hpScaling: 3.0)
    public static let primeSigil = Sphere(id: "prime_sigil", name: "Prime Sigil", baseMultiplier: 2.0, canBindPrime: true)

    public static func aspectOrb(_ aspect: Aspect) -> Sphere {
        Sphere(id: "\(aspect.rawValue)_orb", name: "\(aspect.rawValue.capitalized) Orb",
               baseMultiplier: 1.2, affinityAspect: aspect)
    }

    /// The default starter loadout.
    public static let starterKit: [Sphere] = [.orb, .orb, .orb, .bindOrb, .resonantOrb]
}
