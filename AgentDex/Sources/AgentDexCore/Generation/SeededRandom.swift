import Foundation

/// Stable, process-independent 64-bit hash (FNV-1a). We do NOT use Swift's
/// `Hashable.hashValue` because it is randomized per process, which would break
/// the "same agent → same daemon, forever, on every device" contract.
public func stableHash(_ string: String) -> UInt64 {
    var hash: UInt64 = 0xcbf29ce484222325        // FNV offset basis
    let prime: UInt64 = 0x100000001b3             // FNV prime
    for byte in string.utf8 {
        hash ^= UInt64(byte)
        hash = hash &* prime
    }
    return hash
}

/// A deterministic `RandomNumberGenerator` (SplitMix64). Seeded from a stable
/// hash, it produces the identical stream everywhere — the backbone of
/// reproducible creature generation.
public struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) {
        // Avoid a zero state degenerating; mix the seed once.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    public init(_ string: String) {
        self.init(seed: stableHash(string))
    }

    public mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Uniform integer in `range` (inclusive). Deterministic.
    public mutating func int(in range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(next() % span)
    }

    /// Uniform Double in 0..<1.
    public mutating func unit() -> Double {
        Double(next() >> 11) * (1.0 / 9007199254740992.0)  // 53-bit mantissa
    }

    /// Pick one element deterministically.
    public mutating func pick<T>(_ array: [T]) -> T {
        precondition(!array.isEmpty, "pick from empty array")
        return array[int(in: 0...(array.count - 1))]
    }
}
