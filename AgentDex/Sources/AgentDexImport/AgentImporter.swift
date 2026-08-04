import Foundation
import AgentDexCore

/// Scans agent-definition files and log files to build an `agents.json` roster
/// from the agents you actually use — the "logs/indirect" ingest idea from the
/// design doc. Heuristic by nature; it errs toward discovering something you can
/// then hand-tune. All the parsing is pure/testable; only `scan*` touch disk.
public struct AgentImporter {

    public init() {}

    // MARK: - Public result types

    public struct ImportSummary: Equatable, Sendable {
        public var definitionFiles: Int = 0
        public var logFiles: Int = 0
        public var fromDefinitions: Int = 0
        public var fromLogs: Int = 0
        public var total: Int = 0
    }

    public struct ImportResult: Sendable {
        public var profiles: [AgentProfile]
        public var summary: ImportSummary
    }

    /// An in-flight discovery before it becomes an `AgentProfile`.
    struct Discovered {
        var id: String
        var name: String
        var roleText: String
        var fromDefinition: Bool
        var count: Int
        var notes: String?
    }

    // MARK: - Filesystem entry points

    /// Import from a mix of agent-definition directories and log files/dirs.
    /// - agentDirs: directories containing agent definition markdown (e.g. `.claude/agents`).
    /// - logPaths: individual log files or directories to walk for mentions.
    public func scan(agentDirs: [URL], logPaths: [URL], project: String) -> ImportResult {
        var byID: [String: Discovered] = [:]
        var summary = ImportSummary()

        // 1) Agent-definition files → directly authored agents.
        let defFiles = agentDirs.flatMap { files(under: $0, extensions: ["md", "markdown"]) }
        summary.definitionFiles = defFiles.count
        for url in defFiles {
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            if let d = Self.discoveryFromDefinition(text: text, fallbackName: url.deletingPathExtension().lastPathComponent) {
                merge(d, into: &byID)
            }
        }

        // 2) Log files → agents seen/used indirectly.
        let logFiles = logPaths.flatMap { url -> [URL] in
            isDirectory(url) ? files(under: url, extensions: ["log", "txt", "jsonl", "json"]) : [url]
        }
        summary.logFiles = logFiles.count
        for url in logFiles {
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            for (name, count) in Self.detections(inLog: text) {
                merge(Discovered(id: Self.slug(name), name: name, roleText: name,
                                 fromDefinition: false, count: count, notes: "seen in \(url.lastPathComponent)"),
                      into: &byID)
            }
        }

        let profiles = byID.values
            .sorted { $0.id < $1.id }
            .map { Self.makeProfile(from: $0, project: project) }

        summary.fromDefinitions = byID.values.filter { $0.fromDefinition }.count
        summary.fromLogs = byID.values.filter { !$0.fromDefinition }.count
        summary.total = profiles.count
        return ImportResult(profiles: profiles, summary: summary)
    }

    /// Pure variant for tests / previews: build from in-memory content.
    public func build(definitions: [String], logs: [String], project: String) -> ImportResult {
        var byID: [String: Discovered] = [:]
        var summary = ImportSummary(definitionFiles: definitions.count, logFiles: logs.count)
        for (i, text) in definitions.enumerated() {
            if let d = Self.discoveryFromDefinition(text: text, fallbackName: "agent-\(i)") {
                merge(d, into: &byID)
            }
        }
        for text in logs {
            for (name, count) in Self.detections(inLog: text) {
                merge(Discovered(id: Self.slug(name), name: name, roleText: name,
                                 fromDefinition: false, count: count, notes: nil), into: &byID)
            }
        }
        let profiles = byID.values.sorted { $0.id < $1.id }.map { Self.makeProfile(from: $0, project: project) }
        summary.fromDefinitions = byID.values.filter { $0.fromDefinition }.count
        summary.fromLogs = byID.values.filter { !$0.fromDefinition }.count
        summary.total = profiles.count
        return ImportResult(profiles: profiles, summary: summary)
    }

    private func merge(_ d: Discovered, into byID: inout [String: Discovered]) {
        guard !d.id.isEmpty else { return }
        if var existing = byID[d.id] {
            existing.count += d.count
            existing.fromDefinition = existing.fromDefinition || d.fromDefinition
            if existing.roleText.count < d.roleText.count { existing.roleText = d.roleText }
            existing.notes = existing.notes ?? d.notes
            byID[d.id] = existing
        } else {
            byID[d.id] = d
        }
    }

    // MARK: - Pure parsing (unit-tested)

    /// Parse a `.claude/agents/*.md`-style file: YAML frontmatter (name,
    /// description) plus body. Falls back to the filename for the agent name.
    static func discoveryFromDefinition(text: String, fallbackName: String) -> Discovered? {
        let fm = parseFrontmatter(text)
        let name = fm["name"] ?? fallbackName
        let desc = fm["description"] ?? fm["role"] ?? ""
        let role = ([name, desc].joined(separator: " ")).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !slug(name).isEmpty else { return nil }
        return Discovered(id: slug(name), name: name, roleText: role,
                          fromDefinition: true, count: 1,
                          notes: desc.isEmpty ? nil : String(desc.prefix(120)))
    }

    /// Extract simple `key: value` pairs from a leading `---` fenced block.
    static func parseFrontmatter(_ text: String) -> [String: String] {
        let lines = text.components(separatedBy: .newlines)
        guard let first = lines.first?.trimmingCharacters(in: .whitespaces), first == "---" else { return [:] }
        var result: [String: String] = [:]
        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "---" { break }
            guard let colon = trimmed.firstIndex(of: ":") else { continue }
            let key = String(trimmed[..<colon]).trimmingCharacters(in: .whitespaces).lowercased()
            var value = String(trimmed[trimmed.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            value = value.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            if !key.isEmpty { result[key] = value }
        }
        return result
    }

    /// Find agent mentions in log text → name to occurrence count.
    static func detections(inLog text: String) -> [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        let patterns = [
            #"(?:subagent_type|agent_type|agentType|subagent)\"?\s*[:=]\s*\"?([A-Za-z][A-Za-z0-9 _\-]{1,39})"#,
            #"(?:spawn(?:ed|ing)?|launch(?:ed|ing)?|dispatch(?:ed)?)\s+(?:sub-?agent|agent)\s+['\"]?([A-Za-z][A-Za-z0-9 _\-]{1,39})"#,
            #"\bagent\s+['\"]([A-Za-z][A-Za-z0-9 _\-]{1,39})['\"]"#
        ]
        for pattern in patterns {
            guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let ns = text as NSString
            re.enumerateMatches(in: text, range: NSRange(location: 0, length: ns.length)) { match, _, _ in
                guard let match, match.numberOfRanges > 1 else { return }
                let raw = ns.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
                let name = raw.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                guard isPlausibleName(name) else { return }
                counts[name, default: 0] += 1
            }
        }
        return counts.map { ($0.key, $0.value) }.sorted { $0.name < $1.name }
    }

    static func isPlausibleName(_ s: String) -> Bool {
        let bad: Set<String> = ["true", "false", "null", "none", "the", "a", "an", "and", "type", "name"]
        guard s.count >= 2, !bad.contains(s.lowercased()) else { return false }
        return s.first?.isLetter ?? false
    }

    // MARK: - Inference

    static func slug(_ name: String) -> String {
        let lowered = name.lowercased()
        let mapped = lowered.map { ch -> Character in
            (ch.isLetter || ch.isNumber) ? ch : "-"
        }
        let collapsed = String(mapped).split(separator: "-").joined(separator: "-")
        return collapsed
    }

    static func inferTier(name: String, roleText: String, fromDefinition: Bool, count: Int) -> Tier {
        let s = (name + " " + roleText).lowercased()
        func has(_ keys: [String]) -> Bool { keys.contains { s.contains($0) } }
        if has(["prime", "flagship"]) { return .prime }
        if has(["orchestrat", "conductor", "maestro", "coordinat", "lead ", "manager", "supervisor"]) { return .orchestrator }
        if has(["sub-agent", "subagent", "helper", "worker", "util", "scout", "tiny", "micro"]) { return .sub }
        if has(["specialist", "review", "research", "explore", "architect", "planner", "security", "expert", "analyst"]) { return .specialist }
        // Frequently-used, defined agents skew a bit more important.
        if fromDefinition && count >= 20 { return .specialist }
        return .task
    }

    static func makeProfile(from d: Discovered, project: String) -> AgentProfile {
        let tier = inferTier(name: d.name, roleText: d.roleText, fromDefinition: d.fromDefinition, count: d.count)
        let origin: Origin = d.fromDefinition ? .directlyCreated : (d.count >= 3 ? .used : .seenInLogs)
        return AgentProfile(
            id: d.id,
            displayName: prettyName(d.name),
            tier: tier,
            role: d.roleText,
            project: project,
            origin: origin,
            encounters: max(1, d.count),
            notes: d.notes
        )
    }

    static func prettyName(_ raw: String) -> String {
        let parts = raw.split(whereSeparator: { $0 == "-" || $0 == "_" || $0 == " " })
        return parts.map { $0.prefix(1).uppercased() + String($0.dropFirst()) }.joined(separator: " ")
    }

    // MARK: - Filesystem helpers

    private func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }

    private func files(under dir: URL, extensions: [String]) -> [URL] {
        guard isDirectory(dir) else {
            return extensions.contains(dir.pathExtension.lowercased()) ? [dir] : []
        }
        guard let en = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: nil) else { return [] }
        var out: [URL] = []
        for case let u as URL in en where extensions.contains(u.pathExtension.lowercased()) {
            out.append(u)
        }
        return out.sorted { $0.path < $1.path }
    }
}
