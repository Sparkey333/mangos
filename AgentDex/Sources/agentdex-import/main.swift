import Foundation
import AgentDexCore
import AgentDexImport

// agentdex-import — build an agents.json roster from your real agents.
//
// Usage:
//   swift run agentdex-import [--agents DIR]... [--logs PATH]... \
//                             [--project NAME] [-o OUTPUT.json] [--print]
//
// Examples:
//   swift run agentdex-import --agents ~/.claude/agents --logs ~/.claude/projects --project mangos
//   swift run agentdex-import --logs ./session.log -o Config/agents.json

struct Options {
    var agentDirs: [URL] = []
    var logPaths: [URL] = []
    var project = "imported"
    var output: URL? = nil
    var printOnly = false
    var help = false
}

func parseArgs(_ argv: [String]) -> Options {
    var o = Options()
    var i = 0
    func next() -> String? { i += 1; return i < argv.count ? argv[i] : nil }
    while i < argv.count {
        switch argv[i] {
        case "--agents", "-a": if let v = next() { o.agentDirs.append(expand(v)) }
        case "--logs", "-l":   if let v = next() { o.logPaths.append(expand(v)) }
        case "--project", "-p": if let v = next() { o.project = v }
        case "--output", "-o": if let v = next() { o.output = expand(v) }
        case "--print": o.printOnly = true
        case "--help", "-h": o.help = true
        default:
            // Bare paths are treated as logs.
            if !argv[i].hasPrefix("-") { o.logPaths.append(expand(argv[i])) }
        }
        i += 1
    }
    return o
}

func expand(_ path: String) -> URL {
    let expanded = (path as NSString).expandingTildeInPath
    return URL(fileURLWithPath: expanded)
}

let usage = """
agentdex-import — generate an AgentDex roster from your agents.

USAGE:
  agentdex-import [--agents DIR]... [--logs PATH]... [--project NAME] [-o FILE] [--print]

OPTIONS:
  -a, --agents DIR     Directory of agent definition files (e.g. ~/.claude/agents)
  -l, --logs PATH      Log file or directory to scan for agent mentions
  -p, --project NAME   Project/region name to assign (default: "imported")
  -o, --output FILE    Write agents.json here (default: the shared AgentDex config dir)
      --print          Print the JSON to stdout instead of writing
  -h, --help           Show this help

The default output location (read by the app) is:
  \(AgentConfigStore.agentsURL.path)
"""

let opts = parseArgs(Array(CommandLine.arguments.dropFirst()))
if opts.help || (opts.agentDirs.isEmpty && opts.logPaths.isEmpty) {
    print(usage)
    exit(opts.help ? 0 : 1)
}

let importer = AgentImporter()
let result = importer.scan(agentDirs: opts.agentDirs, logPaths: opts.logPaths, project: opts.project)

FileHandle.standardError.write(Data("""
Scanned \(result.summary.definitionFiles) definition file(s), \(result.summary.logFiles) log file(s).
Discovered \(result.summary.total) agent(s): \(result.summary.fromDefinitions) authored, \(result.summary.fromLogs) from logs.

""".utf8))

for p in result.profiles {
    FileHandle.standardError.write(Data("  • \(p.displayName)  [\(p.tier.rawValue)/\(p.origin.rawValue)]  x\(p.encounters)\n".utf8))
}

do {
    if opts.printOnly {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(ConfigLoader.AgentsFile(agents: result.profiles))
        print(String(data: data, encoding: .utf8) ?? "{}")
    } else {
        let dest = opts.output
        try AgentConfigStore.writeAgents(result.profiles, to: dest)
        let path = (dest ?? AgentConfigStore.agentsURL).path
        FileHandle.standardError.write(Data("\nWrote \(result.profiles.count) agents → \(path)\n".utf8))
    }
} catch {
    FileHandle.standardError.write(Data("Error writing output: \(error)\n".utf8))
    exit(2)
}
