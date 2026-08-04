import Foundation

/// An NPC and its lines. Dialogue is data (not code) so tone is tunable without
/// recompiling and can be localized/expanded later. See DESIGN §8.
public struct NPC: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var role: String              // "Professor", "Shopkeep", etc.
    public var greeting: [String]        // shown on first talk (random pick)
    /// In-character answers to common player questions (the in-game help system).
    public var qa: [QA]
    public var idle: [String]            // ambient one-liners

    public struct QA: Codable, Equatable, Sendable {
        public var question: String      // player-facing prompt
        public var answer: String
        public init(question: String, answer: String) {
            self.question = question; self.answer = answer
        }
    }

    public init(id: String, name: String, role: String, greeting: [String],
                qa: [QA], idle: [String]) {
        self.id = id; self.name = name; self.role = role
        self.greeting = greeting; self.qa = qa; self.idle = idle
    }

    /// Deterministic line pick so the same encounter reads consistently.
    public func greetingLine(seed: String) -> String {
        guard !greeting.isEmpty else { return "…" }
        var rng = SeededRandom(seed)
        return rng.pick(greeting)
    }
}
