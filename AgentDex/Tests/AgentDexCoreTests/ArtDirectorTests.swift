import XCTest
@testable import AgentDexCore

final class ArtDirectorTests: XCTestCase {

    private func species(_ id: String, tier: Tier = .specialist, role: String = "researcher") -> DaemonSpecies {
        DaemonGenerator.generate(from: AgentProfile(id: id, displayName: id, tier: tier,
                                                    role: role, project: "t"))
    }

    func testKeyIsStableAndVariantTagged() {
        XCTAssertEqual(ArtDirector.key(for: "explore", variant: .base), "explore__base")
        XCTAssertEqual(ArtDirector.key(for: "explore", variant: .ascended), "explore__ascended")
        XCTAssertEqual(ArtDirector.key(for: "explore", variant: .alt(2)), "explore__alt2")
    }

    func testPromptIsDeterministic() {
        let s = species("explore")
        let a = ArtDirector.prompt(for: s, variant: .base)
        let b = ArtDirector.prompt(for: s, variant: .base)
        XCTAssertEqual(a, b, "Same species+variant must yield the identical prompt/seed")
        XCTAssertFalse(a.positive.isEmpty)
        XCTAssertTrue(a.positive.contains(s.name))
        XCTAssertFalse(a.positive.contains("\n"))
    }

    func testVariantsDiffer() {
        let s = species("explore")
        let base = ArtDirector.prompt(for: s, variant: .base)
        let anom = ArtDirector.prompt(for: s, variant: .anomalous)
        XCTAssertNotEqual(base.key, anom.key)
        XCTAssertNotEqual(base.seed, anom.seed)
        XCTAssertTrue(anom.positive.contains("anomalous"))
    }

    func testCountClamped() {
        let s = species("explore")
        XCTAssertEqual(ArtDirector.prompt(for: s, variant: .base, count: 99).count, 8)
        XCTAssertEqual(ArtDirector.prompt(for: s, variant: .base, count: 0).count, 1)
    }

    func testPromptsIncludeAscendedForAscendableTier() {
        // Specialist tier ascends → base + ascended + anomalous.
        let variants = Set(ArtDirector.prompts(for: species("explore")).map { $0.variant })
        XCTAssertTrue(variants.contains("base"))
        XCTAssertTrue(variants.contains("ascended"))
        XCTAssertTrue(variants.contains("anomalous"))
    }

    func testManifestCreditLinesOnlyForAttributedNonCC0() {
        var m = ArtManifest(packID: "p", title: "P", defaultLicense: "CC0-1.0")
        m.entries = [
            ArtEntry(key: "a__base", speciesID: "a", variant: "base", file: "a.png",
                     license: "CC0-1.0", source: "x", attribution: "Someone"),
            ArtEntry(key: "b__base", speciesID: "b", variant: "base", file: "b.png",
                     license: "CC-BY-4.0", source: "y", attribution: "Artist Q")
        ]
        XCTAssertEqual(m.creditLines, ["Artist Q — CC-BY-4.0"])
    }
}
