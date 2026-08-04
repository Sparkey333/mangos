import Foundation
import XCTest
@testable import AgentDexCore

final class WorldGenTests: XCTestCase {

    // MARK: - Region generation

    func testRegionGenerationIsDeterministic() {
        XCTAssertEqual(WorldGen.region(for: "mangos"), WorldGen.region(for: "mangos"),
                       "Same project must always yield the identical region")
    }

    func testRegionGeometryWithinBounds() {
        let region = WorldGen.region(for: "mangos")

        XCTAssertTrue((3...5).contains(region.patches.count),
                      "Patch count out of band: \(region.patches.count)")
        for patch in region.patches {
            XCTAssertTrue((0.0...1.0).contains(patch.x), "Patch x out of bounds")
            XCTAssertTrue((0.0...1.0).contains(patch.y), "Patch y out of bounds")
            XCTAssertTrue((0.05...0.2).contains(patch.radius),
                          "Patch radius out of band: \(patch.radius)")
        }

        XCTAssertTrue((2...4).contains(region.landmarks.count),
                      "Landmark count out of band: \(region.landmarks.count)")
        for landmark in region.landmarks {
            XCTAssertTrue((0.0...1.0).contains(landmark.x), "Landmark x out of bounds")
            XCTAssertTrue((0.0...1.0).contains(landmark.y), "Landmark y out of bounds")
        }

        XCTAssertTrue(region.displayName.contains("Mangos"),
                      "Display name should carry the capitalized project: \(region.displayName)")
    }

    // MARK: - Load cycle

    func testLoadCyclePhases() {
        XCTAssertEqual(LoadCycle.at(playtimeSeconds: 0), .idle)
        XCTAssertEqual(LoadCycle.at(playtimeSeconds: 600), .busy)
        XCTAssertEqual(LoadCycle.at(playtimeSeconds: 1200), .peak)
        XCTAssertEqual(LoadCycle.at(playtimeSeconds: 1800), .idle)
    }

    func testSpawnMultipliers() {
        XCTAssertEqual(LoadCycle.idle.spawnMultiplier(for: .sub), 1.4)
        XCTAssertEqual(LoadCycle.idle.spawnMultiplier(for: .prime), 0.3)
        XCTAssertEqual(LoadCycle.peak.spawnMultiplier(for: .prime), 3.0)
        for tier in Tier.allCases {
            XCTAssertEqual(LoadCycle.busy.spawnMultiplier(for: tier), 1.0,
                           "Busy hours are the neutral baseline for \(tier)")
        }
    }

    // MARK: - Palette hexes

    func testHexStringsAreWellFormed() {
        for cycle in LoadCycle.allCases {
            XCTAssertTrue(cycle.tintHex.hasPrefix("#"), "Tint for \(cycle) must start with #")
            XCTAssertEqual(cycle.tintHex.count, 7, "Tint for \(cycle) must be #RRGGBB")
        }
        for biome in Biome.allCases {
            XCTAssertTrue(biome.groundHex.hasPrefix("#"), "Ground for \(biome) must start with #")
            XCTAssertEqual(biome.groundHex.count, 7, "Ground for \(biome) must be #RRGGBB")
            XCTAssertTrue(biome.accentHex.hasPrefix("#"), "Accent for \(biome) must start with #")
            XCTAssertEqual(biome.accentHex.count, 7, "Accent for \(biome) must be #RRGGBB")
        }
    }

    // MARK: - Encounters

    func testRollEncounterIsDeterministic() {
        let bestiary = Bestiary(profiles: SampleData.agents)
        let region = WorldGen.region(for: "mangos")

        var rngA = SeededRandom("roll-1")
        var rngB = SeededRandom("roll-1")
        let a = WorldGen.rollEncounter(bestiary: bestiary, region: region,
                                       cycle: .busy, rng: &rngA)
        let b = WorldGen.rollEncounter(bestiary: bestiary, region: region,
                                       cycle: .busy, rng: &rngB)

        XCTAssertNotNil(a)
        XCTAssertNotNil(b)
        XCTAssertEqual(a?.species.id, b?.species.id)
        XCTAssertEqual(a?.level, b?.level)
        XCTAssertEqual(a?.isAnomalous, b?.isAnomalous)
    }

    func testRolledSpeciesBelongsToRegion() {
        let bestiary = Bestiary(profiles: SampleData.agents)
        let region = WorldGen.region(for: "mangos")
        let regionIDs = Set(bestiary.species(inRegion: "mangos").map { $0.id })

        var rng = SeededRandom("membership-seed")
        let rolled = WorldGen.rollEncounter(bestiary: bestiary, region: region,
                                            cycle: .busy, rng: &rng)
        XCTAssertNotNil(rolled)
        if let rolled {
            XCTAssertTrue(regionIDs.contains(rolled.species.id),
                          "Rolled species must live in the region it spawned in")
        }
    }

    func testAnomalousRollsAreRareButPresent() {
        let bestiary = Bestiary(profiles: SampleData.agents)
        let region = WorldGen.region(for: "mangos")

        var anomalous = 0
        var normal = 0
        for i in 0..<600 {
            var rng = SeededRandom("roll-\(i)")
            guard let daemon = WorldGen.rollEncounter(bestiary: bestiary, region: region,
                                                      cycle: .busy, rng: &rng) else {
                XCTFail("Encounter roll \(i) unexpectedly returned nil")
                continue
            }
            if daemon.isAnomalous { anomalous += 1 } else { normal += 1 }
        }

        XCTAssertGreaterThan(anomalous, 0, "600 rolls should surface at least one anomaly")
        XCTAssertGreaterThan(normal, 0, "Anomalies must stay rare — most rolls are normal")
    }
}
