import SpriteKit
import AgentDexCore
#if os(macOS)
import AppKit
#endif

/// The animated overworld where daemons roam and fights happen IN the world
/// (no screen switch — DESIGN §5.1). This prototype scene renders a player node
/// and a couple of wandering wild daemons; walking into one fires `onEncounter`.
///
/// The visual fight (move telegraphs, hop-attacks, the thrown sphere arc) is
/// driven here via SKActions, while all the *numbers* come from `GameState` /
/// `AgentDexCore`. Keep presentation here; keep rules in core.
public final class OverworldScene: SKScene {

    /// Called when the player bumps a roaming wild daemon.
    public var onEncounter: (() -> Void)?

    private let player = SKShapeNode(circleOfRadius: 16)
    private var wanderers: [SKShapeNode] = []
    private var lastEncounter: TimeInterval = 0

    public override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.06, green: 0.09, blue: 0.12, alpha: 1)
        scaleMode = .resizeFill
        setupPlayer()
        spawnWanderers(count: 3)
    }

    private func setupPlayer() {
        player.fillColor = .white
        player.strokeColor = .cyan
        player.lineWidth = 2
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        player.zPosition = 10
        addChild(player)
    }

    private func spawnWanderers(count: Int) {
        for _ in 0..<count {
            let node = SKShapeNode(rectOf: CGSize(width: 26, height: 26), cornerRadius: 6)
            node.fillColor = SKColor(red: .random(in: 0.3...0.9),
                                     green: .random(in: 0.3...0.9),
                                     blue: .random(in: 0.5...1.0), alpha: 1)
            node.strokeColor = .white
            node.position = CGPoint(x: .random(in: 40...max(60, size.width - 40)),
                                    y: .random(in: 40...max(60, size.height - 40)))
            node.zPosition = 5
            addChild(node)
            wanderers.append(node)
            wander(node)
        }
    }

    private func wander(_ node: SKShapeNode) {
        let dest = CGPoint(x: .random(in: 40...max(60, size.width - 40)),
                           y: .random(in: 40...max(60, size.height - 40)))
        let move = SKAction.move(to: dest, duration: .random(in: 1.5...3.5))
        move.timingMode = .easeInEaseOut
        node.run(.sequence([move, .run { [weak self, weak node] in
            guard let self, let node else { return }
            self.wander(node)
        }]))
    }

    // MARK: - Input (touch on iOS; mouse on macOS)

    #if os(iOS)
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        movePlayer(to: t.location(in: self))
    }
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        movePlayer(to: t.location(in: self))
    }
    #endif

    #if os(macOS)
    public override func mouseDown(with event: NSEvent) {
        movePlayer(to: event.location(in: self))
    }
    public override func mouseDragged(with event: NSEvent) {
        movePlayer(to: event.location(in: self))
    }
    #endif

    private func movePlayer(to point: CGPoint) {
        let clamped = CGPoint(x: min(max(16, point.x), size.width - 16),
                              y: min(max(16, point.y), size.height - 16))
        player.run(.move(to: clamped, duration: 0.15))
    }

    public override func update(_ currentTime: TimeInterval) {
        // Bump detection → encounter, throttled so you don't spam battles.
        guard currentTime - lastEncounter > 1.0 else { return }
        for node in wanderers {
            if hypot(node.position.x - player.position.x,
                     node.position.y - player.position.y) < 30 {
                lastEncounter = currentTime
                pulse(node)
                onEncounter?()
                break
            }
        }
    }

    private func pulse(_ node: SKShapeNode) {
        node.run(.sequence([.scale(to: 1.4, duration: 0.1), .scale(to: 1.0, duration: 0.1)]))
    }
}
