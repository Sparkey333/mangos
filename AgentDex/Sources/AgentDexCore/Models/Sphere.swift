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
    /// Shop price in Cycles.
    public var price: Int

    public init(id: String, name: String, baseMultiplier: Double,
                affinityAspect: Aspect? = nil, hpScaling: Double = 0,
                canBindPrime: Bool = false, price: Int = 20) {
        self.id = id; self.name = name; self.baseMultiplier = baseMultiplier
        self.affinityAspect = affinityAspect; self.hpScaling = hpScaling
        self.canBindPrime = canBindPrime; self.price = price
    }

    // Backwards-compatible decoding: older data lacks `price`.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        baseMultiplier = try c.decode(Double.self, forKey: .baseMultiplier)
        affinityAspect = try c.decodeIfPresent(Aspect.self, forKey: .affinityAspect)
        hpScaling = try c.decodeIfPresent(Double.self, forKey: .hpScaling) ?? 0
        canBindPrime = try c.decodeIfPresent(Bool.self, forKey: .canBindPrime) ?? false
        price = try c.decodeIfPresent(Int.self, forKey: .price) ?? 20
    }

    public static let orb = Sphere(id: "orb", name: "Orb", baseMultiplier: 1.0, price: 20)
    public static let bindOrb = Sphere(id: "bind_orb", name: "Bind-Orb", baseMultiplier: 1.5, price: 60)
    public static let resonantOrb = Sphere(id: "resonant_orb", name: "Resonant Orb", baseMultiplier: 1.0, hpScaling: 3.0, price: 100)
    public static let primeSigil = Sphere(id: "prime_sigil", name: "Prime Sigil", baseMultiplier: 2.0, canBindPrime: true, price: 2000)

    public static func aspectOrb(_ aspect: Aspect) -> Sphere {
        Sphere(id: "\(aspect.rawValue)_orb", name: "\(aspect.rawValue.capitalized) Orb",
               baseMultiplier: 1.2, affinityAspect: aspect, price: 80)
    }

    /// Everything purchasable, in shop display order.
    public static var shopCatalog: [Sphere] {
        [.orb, .bindOrb, .resonantOrb]
            + Aspect.allCases.map { aspectOrb($0) }
            + [.primeSigil]
    }

    public static func byID(_ id: String) -> Sphere? {
        shopCatalog.first { $0.id == id }
    }

    /// The default starter loadout.
    public static let starterKit: [Sphere] = [.orb, .orb, .orb, .orb, .orb, .bindOrb, .resonantOrb]
}
