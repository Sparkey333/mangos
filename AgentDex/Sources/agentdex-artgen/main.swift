import Foundation
import AgentDexCore
import AgentDexImport
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// agentdex-artgen — derive art prompts from your daemon roster and (optionally)
// render them via Higgsfield into a licensed art pack.
//
//   swift run agentdex-artgen [--out DIR] [--project NAME] [--dry-run] [--generate]
//                             [--model NAME] [--count N]
//
// Default is --dry-run: writes prompts.json + a manifest scaffold, NO network,
// NO cost. Add --generate (and export HIGGSFIELD_API_KEY) to actually render.
// Nothing here ships in the app — outputs are committed as static assets.

struct Options {
    var out = URL(fileURLWithPath: "packs/higgsfield")
    var project: String? = nil
    var dryRun = true
    var count = 3
    var model = ProcessInfo.processInfo.environment["HIGGSFIELD_MODEL"] ?? "higgsfield-soul"
    var help = false
}

func parse(_ argv: [String]) -> Options {
    var o = Options(); var i = 0
    func next() -> String? { i += 1; return i < argv.count ? argv[i] : nil }
    while i < argv.count {
        switch argv[i] {
        case "--out", "-o":     if let v = next() { o.out = URL(fileURLWithPath: (v as NSString).expandingTildeInPath) }
        case "--project", "-p": o.project = next()
        case "--dry-run":       o.dryRun = true
        case "--generate":      o.dryRun = false
        case "--model":         if let v = next() { o.model = v }
        case "--count":         if let v = next(), let n = Int(v) { o.count = n }
        case "--help", "-h":    o.help = true
        default: break
        }
        i += 1
    }
    return o
}

let usage = """
agentdex-artgen — art prompts + optional Higgsfield rendering for your roster.

USAGE:
  agentdex-artgen [--out DIR] [--project NAME] [--dry-run|--generate]
                  [--model NAME] [--count N]

  --out DIR       Pack output directory (default: packs/higgsfield)
  --project NAME  Only this project's daemons (default: all)
  --dry-run       Write prompts + manifest scaffold only (default; no cost)
  --generate      Actually call Higgsfield (needs HIGGSFIELD_API_KEY)
  --model NAME    Higgsfield model id (env HIGGSFIELD_MODEL, default higgsfield-soul)
  --count N       Alt versions per base prompt (default 3)

Endpoints (override via env):
  HIGGSFIELD_BASE       default https://platform.higgsfield.ai
  HIGGSFIELD_GEN_PATH   default /v1/generations
  HIGGSFIELD_API_KEY    required for --generate
"""

let opts = parse(Array(CommandLine.arguments.dropFirst()))
if opts.help { print(usage); exit(0) }

// Load the roster the same way the app does.
let (bundledAgents, _) = ConfigLoader.loadBundledExamples()
let roster = (AgentConfigStore.readAgents()?.isEmpty == false ? AgentConfigStore.readAgents()! : bundledAgents)
    .filter { opts.project == nil || $0.project == opts.project }
guard !roster.isEmpty else {
    FileHandle.standardError.write(Data("No agents in roster.\n".utf8)); exit(1)
}

let species = roster.map(DaemonGenerator.generate)
var prompts: [ArtPrompt] = []
for s in species {
    // Base gets `count` alts; ascended/anomalous get a single render each.
    prompts.append(ArtDirector.prompt(for: s, variant: .base, count: opts.count))
    if s.tier.ascensionLevel != nil {
        prompts.append(ArtDirector.prompt(for: s, variant: .ascended, count: 1))
    }
    prompts.append(ArtDirector.prompt(for: s, variant: .anomalous, count: 1))
}

try? FileManager.default.createDirectory(at: opts.out, withIntermediateDirectories: true)

// Always write the reproducible prompt list.
let promptsURL = opts.out.appendingPathComponent("prompts.json")
if let data = try? ArtManifest.encoder.encode(prompts) {
    try? data.write(to: promptsURL, options: .atomic)
    FileHandle.standardError.write(Data("Wrote \(prompts.count) prompts → \(promptsURL.path)\n".utf8))
}

// Manifest scaffold (entries filled as renders land).
var manifest = ArtManifest(packID: "higgsfield", title: "AgentDex — Higgsfield Pack",
                           defaultLicense: "LicenseRef-AgentDex-Generated")

func writeManifest() {
    let url = opts.out.appendingPathComponent("manifest.json")
    if let data = try? ArtManifest.encoder.encode(manifest) { try? data.write(to: url, options: .atomic) }
}

// ---- Higgsfield HTTP (best-effort; only with --generate) --------------------

let env = ProcessInfo.processInfo.environment
let base = env["HIGGSFIELD_BASE"] ?? "https://platform.higgsfield.ai"
let genPath = env["HIGGSFIELD_GEN_PATH"] ?? "/v1/generations"

/// POST a generation and return any image URLs the response exposes. This is a
/// deliberately tolerant adapter — Higgsfield's exact schema evolves, so it
/// scans the JSON for image-like URLs rather than assuming one shape.
func higgsfieldRender(_ prompt: ArtPrompt, key: String) -> [URL] {
    guard let url = URL(string: base + genPath) else { return [] }
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body: [String: Any] = [
        "model": opts.model,
        "task": "text-to-image",
        "prompt": prompt.positive,
        "negative_prompt": prompt.negative,
        "seed": prompt.seed,
        "width": prompt.width,
        "height": prompt.height,
        "num_images": prompt.count
    ]
    req.httpBody = try? JSONSerialization.data(withJSONObject: body)

    var found: [URL] = []
    let sem = DispatchSemaphore(value: 0)
    URLSession.shared.dataTask(with: req) { data, _, err in
        defer { sem.signal() }
        guard let data, err == nil else { return }
        found = extractImageURLs(fromJSON: data)
    }.resume()
    _ = sem.wait(timeout: .now() + 120)
    return found
}

func extractImageURLs(fromJSON data: Data) -> [URL] {
    guard let obj = try? JSONSerialization.jsonObject(with: data) else { return [] }
    var urls: [URL] = []
    func walk(_ any: Any) {
        if let s = any as? String, s.hasPrefix("http"),
           [".png", ".jpg", ".jpeg", ".webp"].contains(where: { s.lowercased().contains($0) }),
           let u = URL(string: s) { urls.append(u) }
        else if let arr = any as? [Any] { arr.forEach(walk) }
        else if let dict = any as? [String: Any] { dict.values.forEach(walk) }
    }
    walk(obj)
    return urls
}

func download(_ url: URL, to dest: URL) -> Bool {
    var ok = false
    let sem = DispatchSemaphore(value: 0)
    URLSession.shared.dataTask(with: url) { data, _, _ in
        if let data { try? data.write(to: dest, options: .atomic); ok = true }
        sem.signal()
    }.resume()
    _ = sem.wait(timeout: .now() + 120)
    return ok
}

if opts.dryRun {
    FileHandle.standardError.write(Data("""
    Dry run — no images generated. Review \(promptsURL.lastPathComponent), then:
      export HIGGSFIELD_API_KEY=…   &&   swift run agentdex-artgen --generate
    """.utf8))
    writeManifest()
    exit(0)
}

guard let key = env["HIGGSFIELD_API_KEY"], !key.isEmpty else {
    FileHandle.standardError.write(Data("--generate requires HIGGSFIELD_API_KEY.\n".utf8)); exit(2)
}

FileHandle.standardError.write(Data("Rendering \(prompts.count) prompts via \(opts.model)…\n".utf8))
for p in prompts {
    let urls = higgsfieldRender(p, key: key)
    for (i, u) in urls.enumerated() {
        let file = urls.count > 1 ? "\(p.key)_\(i).png" : "\(p.key).png"
        if download(u, to: opts.out.appendingPathComponent(file)) {
            manifest.entries.append(ArtEntry(
                key: p.key, speciesID: p.speciesID, variant: p.variant, file: file,
                license: "LicenseRef-AgentDex-Generated", source: "higgsfield:\(opts.model)"))
            FileHandle.standardError.write(Data("  ✓ \(file)\n".utf8))
        }
    }
    writeManifest()
    if urls.isEmpty {
        FileHandle.standardError.write(Data("  · no image for \(p.key) (check schema/model)\n".utf8))
    }
}
FileHandle.standardError.write(Data("Done. Pack at \(opts.out.path)\n".utf8))
