import XCTest
@testable import AgentDexCore

final class MetaTests: XCTestCase {

    private func profile(_ id: String, tier: Tier = .task,
                         role: String = "general") -> AgentProfile {
        AgentProfile(id: id, displayName: id, tier: tier, role: role, project: "testbed")
    }

    private func daemon(_ id: String, tier: Tier = .task, role: String = "general",
                        level: Int = 10) -> Daemon {
        Daemon(species: DaemonGenerator.generate(from: profile(id, tier: tier, role: role)),
               level: level)
    }

    // MARK: - Save codec

    func testSaveCodecRoundTrip() throws {
        var save = SaveState.newGame(player: .placeholder)

        let d1 = Daemon(
            species: DaemonGenerator.generate(
                from: profile("scholar", tier: .specialist, role: "researcher")),
            level: 12, currentHP: 5, status: .deprecated
        )
        let ascendedSpecies = Ascension.ascend(
            DaemonGenerator.generate(from: profile("smith", tier: .task, role: "coder"))
        )
        let d2 = Daemon(species: ascendedSpecies, level: 30, isAnomalous: true)

        save.capture(d1)
        save.capture(d2)
        save.earn(1234)
        save.items["hotfix"] = 3
        save.completedQuests = ["q01_hello_world"]
        save.earnedAchievements = ["first_catch"]
        save.rivalStage = 1
        save.starterChosen = true
        var settings = save.settings
        settings.classicBattles = true
        save.settings = settings

        let data = try SaveCodec.encode(save)
        let decoded = SaveCodec.decode(data)
        XCTAssertNotNil(decoded)
        guard let back = decoded else { return }

        XCTAssertEqual(back.party.count, 2)
        XCTAssertEqual(back.party.map { $0.species.id }, save.party.map { $0.species.id })

        // Ascension survives the record → regenerate cycle.
        XCTAssertTrue(back.party[1].species.isAscended)
        XCTAssertEqual(back.party[1].species.name, ascendedSpecies.name)
        XCTAssertTrue(back.party[1].isAnomalous)

        for i in 0..<2 {
            XCTAssertEqual(back.party[i].level, save.party[i].level, "level mismatch at \(i)")
            XCTAssertEqual(back.party[i].xp, save.party[i].xp, "xp mismatch at \(i)")
            XCTAssertEqual(back.party[i].currentHP, save.party[i].currentHP,
                           "currentHP mismatch at \(i)")
            XCTAssertEqual(back.party[i].status, save.party[i].status,
                           "status mismatch at \(i)")
        }

        XCTAssertEqual(back.cycles, save.cycles)
        XCTAssertEqual(back.items, save.items)
        XCTAssertEqual(back.dex, save.dex)
        XCTAssertEqual(back.completedQuests, save.completedQuests)
        XCTAssertEqual(back.earnedAchievements, save.earnedAchievements)
        XCTAssertEqual(back.rivalStage, 1)
        XCTAssertTrue(back.starterChosen)
        XCTAssertTrue(back.settings.classicBattles)
        XCTAssertEqual(back.stats.catches, 2)
    }

    func testLegacySaveRescue() {
        let json = #"""
        {"player":{"handle":"Conductor","bio":"b","startingAspect":"flux","traits":[]},"party":[{"species":{"id":"explore","tier":"specialist","origin":"used","sourceAgentName":"Explore","habitat":"mangos","primaryAspect":"aether"},"level":9,"currentHP":30,"status":"none","instanceID":"00000000-0000-0000-0000-000000000000"}],"box":[],"inventory":{"orb":3},"dex":{"explore":"caught"},"currentRegion":"Hub"}
        """#
        let rescued = SaveCodec.decode(Data(json.utf8))
        XCTAssertNotNil(rescued)
        guard let save = rescued else { return }

        XCTAssertEqual(save.player.handle, "Conductor")
        XCTAssertEqual(save.party.count, 1)
        XCTAssertEqual(save.party[0].species.id, "explore")
        XCTAssertEqual(save.party[0].level, 9)
        XCTAssertEqual(save.dex["explore"], .caught)
    }

    // MARK: - Quests

    func testQuestChainAdvances() {
        var save = SaveState.newGame(player: .placeholder)
        XCTAssertEqual(QuestEngine.currentQuest(save: save)?.id, "q01_hello_world")

        XCTAssertFalse(QuestEngine.evaluate(.talkTo(npcID: "prof_quill"), save: save).done)
        save.talkedTo.insert("prof_quill")
        XCTAssertTrue(QuestEngine.evaluate(.talkTo(npcID: "prof_quill"), save: save).done)

        save.completedQuests.insert("q01_hello_world")
        XCTAssertEqual(QuestEngine.currentQuest(save: save)?.id, "q02_first_contact")
    }

    func testQuestObjectiveCoverage() {
        var save = SaveState.newGame(player: .placeholder)
        func done(_ objective: Quest.Objective) -> Bool {
            QuestEngine.evaluate(objective, save: save).done
        }

        // catchCount tracks stats.catches.
        XCTAssertFalse(done(.catchCount(1)))
        let forgeDaemon = daemon("welder", tier: .task, role: "coder")
        XCTAssertEqual(forgeDaemon.species.primaryAspect, .forge)
        save.capture(forgeDaemon)
        XCTAssertTrue(done(.catchCount(1)))

        // catchDistinct tracks distinct caught species in the dex.
        XCTAssertFalse(done(.catchDistinct(2)))
        let specialistDaemon = daemon("scribe", tier: .specialist, role: "researcher")
        save.capture(specialistDaemon)
        XCTAssertTrue(done(.catchDistinct(2)))

        // seeDistinct counts anything not unknown (caught counts as seen).
        XCTAssertFalse(done(.seeDistinct(3)))
        save.markSeen("glimpsed-only")
        XCTAssertTrue(done(.seeDistinct(3)))

        // catchAspect: the coder daemon is forge-aspected.
        XCTAssertTrue(done(.catchAspect(.forge)))

        // catchTierAtLeast: the researcher is specialist tier.
        XCTAssertTrue(done(.catchTierAtLeast(.specialist)))

        // defeatRival keys off rivalStage.
        XCTAssertFalse(done(.defeatRival(stage: 1)))
        save.rivalStage = 1
        XCTAssertTrue(done(.defeatRival(stage: 1)))

        // winBattles keys off stats.battlesWon.
        XCTAssertFalse(done(.winBattles(3)))
        save.stats.battlesWon = 3
        XCTAssertTrue(done(.winBattles(3)))

        // earnCycles keys off lifetime stats.cyclesEarned.
        XCTAssertFalse(done(.earnCycles(500)))
        save.earn(500)
        XCTAssertTrue(done(.earnCycles(500)))
    }

    // MARK: - Achievements

    func testAchievementsEarnOnceAndRich() {
        var save = SaveState.newGame(player: .placeholder)
        save.stats.catches = 1

        var earned = AchievementEngine.newlyEarned(save: save, dexTotal: 100)
        XCTAssertTrue(earned.contains { $0.id == "first_catch" })

        save.earnedAchievements.insert("first_catch")
        earned = AchievementEngine.newlyEarned(save: save, dexTotal: 100)
        XCTAssertFalse(earned.contains { $0.id == "first_catch" },
                       "already-earned achievements must not re-fire")

        save.cycles = 5000
        earned = AchievementEngine.newlyEarned(save: save, dexTotal: 100)
        XCTAssertTrue(earned.contains { $0.id == "rich" })
    }

    func testDexCompletenessAchievementsAgainstTinyBestiary() {
        var save = SaveState.newGame(player: .placeholder)
        save.capture(daemon("tiny-a", role: "coder", level: 5))
        save.capture(daemon("tiny-b", role: "researcher", level: 5))

        let earned = AchievementEngine.newlyEarned(save: save, dexTotal: 2)
        XCTAssertTrue(earned.contains { $0.id == "dex_half" })
        XCTAssertTrue(earned.contains { $0.id == "dex_full" })
    }

    // MARK: - Save mutations

    func testCaptureOverflowsToBoxWhenPartyFull() {
        var save = SaveState.newGame(player: .placeholder)
        for i in 0..<7 {
            save.capture(daemon("mon-\(i)", level: 5))
        }
        XCTAssertEqual(save.party.count, 6)
        XCTAssertEqual(save.box.count, 1)
        XCTAssertEqual(save.stats.catches, 7)
    }

    func testEconomySpendAndEarn() {
        var save = SaveState(player: .placeholder)
        XCTAssertEqual(save.cycles, 0)
        XCTAssertFalse(save.spend(50), "spending with an empty wallet must fail")
        save.earn(100)
        XCTAssertTrue(save.spend(50))
        XCTAssertEqual(save.cycles, 50)
    }
}
