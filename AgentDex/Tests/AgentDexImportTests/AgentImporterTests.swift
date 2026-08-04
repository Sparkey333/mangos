import XCTest
@testable import AgentDexImport
import AgentDexCore

final class AgentImporterTests: XCTestCase {

    func testParseFrontmatter() {
        let text = """
        ---
        name: Explore
        description: Read-only search agent for broad fan-out research
        ---
        Body text here.
        """
        let fm = AgentImporter.parseFrontmatter(text)
        XCTAssertEqual(fm["name"], "Explore")
        XCTAssertTrue(fm["description"]?.contains("fan-out") ?? false)
    }

    func testSlug() {
        XCTAssertEqual(AgentImporter.slug("Code Reviewer"), "code-reviewer")
        XCTAssertEqual(AgentImporter.slug("log_scout"), "log-scout")
        XCTAssertEqual(AgentImporter.slug("Explore!!"), "explore")
    }

    func testTierInference() {
        XCTAssertEqual(AgentImporter.inferTier(name: "Maestro Orchestrator", roleText: "coordinates agents", fromDefinition: true, count: 5), .orchestrator)
        XCTAssertEqual(AgentImporter.inferTier(name: "Log Scout", roleText: "log helper", fromDefinition: false, count: 1), .sub)
        XCTAssertEqual(AgentImporter.inferTier(name: "Security Reviewer", roleText: "reviews code", fromDefinition: true, count: 1), .specialist)
        XCTAssertEqual(AgentImporter.inferTier(name: "Runner", roleText: "does a thing", fromDefinition: false, count: 1), .task)
    }

    func testDetectionsInLog() {
        let log = """
        [info] subagent_type: "Explore" started
        launched agent 'Builder' to implement feature
        {"agentType":"code-reviewer"}
        subagent_type: "Explore" again
        nothing to see: true
        """
        let hits = Dictionary(uniqueKeysWithValues: AgentImporter.detections(inLog: log).map { ($0.name, $0.count) })
        XCTAssertEqual(hits["Explore"], 2)
        XCTAssertNotNil(hits["Builder"])
        XCTAssertNotNil(hits["code-reviewer"])
        XCTAssertNil(hits["true"]) // filtered
    }

    func testBuildEndToEnd() {
        let definitions = [
            """
            ---
            name: Explore
            description: research and search across the codebase
            ---
            """,
            """
            ---
            name: Maestro
            description: orchestrator that coordinates other agents
            ---
            """
        ]
        let logs = [
            "subagent_type: \"Explore\"\nsubagent_type: \"Explore\"\nlaunched agent 'Builder'"
        ]
        let result = AgentImporter().build(definitions: definitions, logs: logs, project: "mangos")

        let ids = Set(result.profiles.map { $0.id })
        XCTAssertTrue(ids.contains("explore"))
        XCTAssertTrue(ids.contains("maestro"))
        XCTAssertTrue(ids.contains("builder"))

        // Explore appears in a definition AND logs → authored origin, encounters combined.
        let explore = result.profiles.first { $0.id == "explore" }!
        XCTAssertEqual(explore.origin, .directlyCreated)
        XCTAssertGreaterThanOrEqual(explore.encounters, 2)

        // Maestro is an orchestrator by inference.
        XCTAssertEqual(result.profiles.first { $0.id == "maestro" }?.tier, .orchestrator)

        // Builder only from logs → not authored.
        XCTAssertNotEqual(result.profiles.first { $0.id == "builder" }?.origin, .directlyCreated)

        XCTAssertEqual(result.summary.total, result.profiles.count)
    }

    func testImportedProfilesGenerateDaemons() {
        // The whole point: imported profiles must feed the core generator cleanly.
        let result = AgentImporter().build(
            definitions: ["---\nname: Explore\ndescription: research\n---"],
            logs: [], project: "mangos"
        )
        let bestiary = Bestiary(profiles: result.profiles)
        XCTAssertEqual(bestiary.species.count, result.profiles.count)
        XCTAssertFalse(bestiary.species.isEmpty)
    }
}
