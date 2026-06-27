import Capacitor
import CoreHaptics

// HapticBridgePlugin — exposed to the WebView as window.__hapticBridge.
// The JS HapticEngine posts { type: "haptic", pattern, intensity, sharpness, duration }
// to window.__hapticBridge; this plugin plays it as a real CHHapticPattern.
//
// Capacitor wires this plugin into the WKWebView automatically once registered.

@objc(HapticBridgePlugin)
public class HapticBridgePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier  = "HapticBridgePlugin"
    public let jsName      = "HapticBridge"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "play",   returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "supported", returnType: CAPPluginReturnPromise),
    ]

    private var engine: CHHapticEngine?
    private var engineReady = false

    public override func load() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.playsHapticsOnly = true
            engine?.stoppedHandler = { [weak self] _ in self?.engineReady = false }
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
                self?.engineReady = true
            }
            try engine?.start()
            engineReady = true
        } catch {
            print("[HapticBridge] Engine init failed: \(error)")
        }
    }

    @objc func supported(_ call: CAPPluginCall) {
        call.resolve(["value": CHHapticEngine.capabilitiesForHardware().supportsHaptics])
    }

    // Called by JS HapticEngine.fire() via window.__hapticBridge.play(params)
    @objc func play(_ call: CAPPluginCall) {
        guard engineReady, let engine = engine else {
            call.resolve(); return
        }
        let intensity  = Float(call.getFloat("intensity")  ?? 0.7)
        let sharpness  = Float(call.getFloat("sharpness")  ?? 0.7)
        let duration   = Double(call.getFloat("duration")  ?? 0.02)
        let attack     = Double(call.getFloat("attackTime") ?? 0)
        let release    = Double(call.getFloat("releaseTime") ?? 0)

        do {
            var events: [CHHapticEvent] = []

            // Transient event (the main "click")
            let iParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
            let sParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            let transient = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [iParam, sParam],
                relativeTime: 0
            )
            events.append(transient)

            // Optional continuous tail for edge-slip / shoulder patterns
            if duration > 0.03 {
                let cIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * 0.4)
                let cSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness * 0.3)
                let continuous = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [cIntensity, cSharpness],
                    relativeTime: attack,
                    duration: max(duration - attack - release, 0.01)
                )
                events.append(continuous)
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player  = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            call.resolve()
        } catch {
            call.resolve() // haptic failure is non-fatal
        }
    }
}
