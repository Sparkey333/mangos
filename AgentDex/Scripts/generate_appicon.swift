// generate_appicon.swift — procedurally render the AgentDex app icon.
//
// Runs as a plain script on a Mac (no Xcode project, no SPM target):
//
//   swift Scripts/generate_appicon.swift [outdir]     # default outdir: build/icon-gen
//
// Outputs:
//   <outdir>/AppIcon.appiconset/   — icon-1024.png + Contents.json (Xcode asset catalog)
//   <outdir>/AgentDex.iconset/     — the 10 PNG sizes `iconutil -c icns` expects
//
// The icon: a glowing 12-point mandala (the "prime sigil" from DESIGN.md §3.4)
// on a deep navy → indigo gradient, ringed by six Aspect-colored orbiting dots.
// Everything is drawn in code so no binary assets live in the repo.

import Foundation

#if canImport(AppKit)
import AppKit

// MARK: - Helpers

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("error: \(message)\n").utf8))
    exit(1)
}

/// Parse "#RRGGBB" (leading '#' optional) into an NSColor.
func color(hex: String, alpha: CGFloat = 1.0) -> NSColor {
    var s = hex
    if s.hasPrefix("#") { s.removeFirst() }
    guard s.count == 6, let value = UInt32(s, radix: 16) else {
        fail("bad hex color: \(hex)")
    }
    let r = CGFloat((value >> 16) & 0xFF) / 255.0
    let g = CGFloat((value >> 8) & 0xFF) / 255.0
    let b = CGFloat(value & 0xFF) / 255.0
    return NSColor(calibratedRed: r, green: g, blue: b, alpha: alpha)
}

/// Regular polygon path centered on `center`.
func polygonPath(center: CGPoint, radius: CGFloat, sides: Int, rotationDegrees: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    let offset = rotationDegrees * .pi / 180
    for i in 0..<sides {
        let angle = (CGFloat(i) / CGFloat(sides)) * 2 * .pi + offset + .pi / 2
        let point = CGPoint(x: center.x + radius * cos(angle),
                            y: center.y + radius * sin(angle))
        if i == 0 { path.move(to: point) } else { path.line(to: point) }
    }
    path.close()
    return path
}

func makeBitmapRep(size: Int) -> NSBitmapImageRep {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { fail("could not create \(size)x\(size) bitmap") }
    rep.size = NSSize(width: size, height: size)
    return rep
}

// MARK: - Master render (1024x1024)

func renderMasterIcon(size: Int) -> NSImage {
    let rep = makeBitmapRep(size: size)
    guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
        fail("could not create graphics context")
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext

    let s = CGFloat(size)
    let center = CGPoint(x: s / 2, y: s / 2)

    // 1) Background: vertical gradient, deep navy (top) → indigo (bottom).
    let gradientColors: CFArray = [color(hex: "#0A0F1E").cgColor,
                                   color(hex: "#1B1040").cgColor] as CFArray
    let locations: [CGFloat] = [0.0, 1.0]
    if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: gradientColors,
                                 locations: locations) {
        cg.drawLinearGradient(gradient,
                              start: CGPoint(x: center.x, y: s),
                              end: CGPoint(x: center.x, y: 0),
                              options: [])
    } else {
        color(hex: "#0A0F1E").setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: s, height: s)).fill()
    }

    // 2) Central mandala: two 12-gon outlines, white with a soft glow.
    NSGraphicsContext.saveGraphicsState()
    let glow = NSShadow()
    glow.shadowColor = NSColor.white.withAlphaComponent(0.9)
    glow.shadowBlurRadius = 30
    glow.shadowOffset = .zero
    glow.set()

    NSColor.white.withAlphaComponent(0.95).setStroke()
    let outerGon = polygonPath(center: center, radius: 340, sides: 12, rotationDegrees: 0)
    outerGon.lineWidth = 10
    outerGon.stroke()

    let innerGon = polygonPath(center: center, radius: 260, sides: 12, rotationDegrees: 15)
    innerGon.lineWidth = 6
    innerGon.stroke()
    NSGraphicsContext.restoreGraphicsState()

    // 3) Glowing core circle.
    NSGraphicsContext.saveGraphicsState()
    let coreGlow = NSShadow()
    coreGlow.shadowColor = color(hex: "#7FD7FF", alpha: 0.9)
    coreGlow.shadowBlurRadius = 30
    coreGlow.shadowOffset = .zero
    coreGlow.set()
    color(hex: "#7FD7FF", alpha: 0.9).setFill()
    NSBezierPath(ovalIn: NSRect(x: center.x - 70, y: center.y - 70,
                                width: 140, height: 140)).fill()
    NSGraphicsContext.restoreGraphicsState()

    // 4) Six orbiting Aspect dots at 60° steps.
    let dotHexes = ["#7FD7FF", "#FF6A3D", "#9B8CFF", "#8B9DA3", "#C9A0FF", "#43FF8E"]
    let orbit: CGFloat = 430
    let dotRadius: CGFloat = 26
    for (i, hexString) in dotHexes.enumerated() {
        let angle = CGFloat(i) * 60 * .pi / 180 + .pi / 2
        let dc = CGPoint(x: center.x + orbit * cos(angle),
                         y: center.y + orbit * sin(angle))
        NSGraphicsContext.saveGraphicsState()
        let dotGlow = NSShadow()
        dotGlow.shadowColor = color(hex: hexString, alpha: 0.8)
        dotGlow.shadowBlurRadius = 18
        dotGlow.shadowOffset = .zero
        dotGlow.set()
        color(hex: hexString).setFill()
        NSBezierPath(ovalIn: NSRect(x: dc.x - dotRadius, y: dc.y - dotRadius,
                                    width: dotRadius * 2, height: dotRadius * 2)).fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    // 5) Vignette: a very thick, translucent black circle whose stroke band
    //    covers the outer edge of the canvas, darkening corners/edges subtly.
    NSColor.black.withAlphaComponent(0.25).setStroke()
    let vignette = NSBezierPath(ovalIn: NSRect(x: -s * 0.25, y: -s * 0.25,
                                               width: s * 1.5, height: s * 1.5))
    vignette.lineWidth = s * 0.5
    vignette.stroke()

    ctx.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    let image = NSImage(size: NSSize(width: s, height: s))
    image.addRepresentation(rep)
    return image
}

// MARK: - PNG writer (redraws the master at an exact pixel size)

func write(_ image: NSImage, size: Int, to url: URL) {
    let rep = makeBitmapRep(size: size)
    guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
        fail("could not create graphics context for \(size)px")
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    ctx.imageInterpolation = .high
    image.draw(in: NSRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size)),
               from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
               operation: .copy,
               fraction: 1.0)
    ctx.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fail("PNG encoding failed for \(url.lastPathComponent)")
    }
    do {
        try data.write(to: url)
    } catch {
        fail("could not write \(url.path): \(error.localizedDescription)")
    }
    print("    + \(url.lastPathComponent) (\(size)x\(size))")
}

// MARK: - Main

let outdir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/icon-gen"
let outURL = URL(fileURLWithPath: outdir, isDirectory: true)
let appiconsetURL = outURL.appendingPathComponent("AppIcon.appiconset", isDirectory: true)
let iconsetURL = outURL.appendingPathComponent("AgentDex.iconset", isDirectory: true)

do {
    try FileManager.default.createDirectory(at: appiconsetURL, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
} catch {
    fail("could not create output directories under \(outURL.path): \(error.localizedDescription)")
}

print("==> rendering master icon (1024x1024)…")
let master = renderMasterIcon(size: 1024)

print("==> writing \(appiconsetURL.path)…")
write(master, size: 1024, to: appiconsetURL.appendingPathComponent("icon-1024.png"))
let contentsJSON = """
{
  "images" : [
    {
      "filename" : "icon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""
do {
    try contentsJSON.write(to: appiconsetURL.appendingPathComponent("Contents.json"),
                           atomically: true, encoding: .utf8)
    print("    + Contents.json")
} catch {
    fail("could not write Contents.json: \(error.localizedDescription)")
}

print("==> writing \(iconsetURL.path)…")
let iconsetSizes: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]
for entry in iconsetSizes {
    write(master, size: entry.pixels, to: iconsetURL.appendingPathComponent(entry.name))
}

print("done. icon assets in \(outURL.path)")

#else
print("generate_appicon.swift requires macOS (AppKit not available).")
exit(1)
#endif
