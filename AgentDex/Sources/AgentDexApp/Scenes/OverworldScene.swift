import Foundation
import SpriteKit
import AgentDexCore
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// The animated overworld where daemons roam and fights happen IN the world
/// (no screen switch — DESIGN §5.1). Renders the current region's biome,
/// encounter patches and landmarks; the player orb walks around, "presence"
/// orbs wander, and bumping one fires `onEncounter`.
///
/// Battles are choreographed here as SKActions from the SAME `BattleEvent`
/// stream the classic battle screen uses. All the *numbers* come from
/// `AgentDexCore`; this class is presentation only.
public final class OverworldScene: SKScene {

    /// Called when the player bumps a roaming wild daemon.
    public var onEncounter: (() -> Void)?

    // MARK: - World constants

    private let worldWidth: CGFloat = 1500
    private let worldHeight: CGFloat = 1000

    // MARK: - Nodes

    private let terrain = SKNode()
    private let player = SKShapeNode(circleOfRadius: 16)
    private let cameraNode = SKCameraNode()
    private let tintNode = SKSpriteNode(color: SKColor.clear,
                                        size: CGSize(width: 4000, height: 4000))
    private let coordinator = SKNode()
    private var roamers: [SKShapeNode] = []
    private var enemyNode: SKNode?
    private var allyNode: SKNode?
    private var dimNode: SKSpriteNode?

    // MARK: - State

    private var currentProject: String?
    private var patchCenters: [CGPoint] = []
    private var battleActive = false
    private var lastEncounterTime: TimeInterval = 0
    private var didSetUp = false

    // MARK: - Lifecycle

    public override func didMove(to view: SKView) {
        scaleMode = .resizeFill
        setUpIfNeeded()
    }

    private func setUpIfNeeded() {
        guard !didSetUp else { return }
        didSetUp = true

        backgroundColor = SKColor(red: 0.06, green: 0.09, blue: 0.12, alpha: 1)

        terrain.zPosition = 1
        addChild(terrain)

        // Player: white orb with a soft breathing glow ring.
        player.fillColor = SKColor.white
        player.strokeColor = SKColor(white: 1.0, alpha: 0.4)
        player.lineWidth = 2
        player.glowWidth = 3
        player.zPosition = 10
        player.position = CGPoint(x: worldWidth / 2, y: worldHeight / 2)
        let glowRing = SKShapeNode(circleOfRadius: 24)
        glowRing.fillColor = SKColor.clear
        glowRing.strokeColor = SKColor(white: 1.0, alpha: 0.25)
        glowRing.lineWidth = 2
        glowRing.glowWidth = 4
        player.addChild(glowRing)
        glowRing.run(.repeatForever(.sequence([
            .scale(to: 1.15, duration: 0.9),
            .scale(to: 0.9, duration: 0.9)
        ])))
        addChild(player)

        // Camera tracks the player (lerped in update).
        cameraNode.position = player.position
        addChild(cameraNode)
        camera = cameraNode

        // Load-cycle tint rides on the camera so it always covers the view.
        tintNode.alpha = 0.25
        tintNode.zPosition = 50
        tintNode.position = .zero
        cameraNode.addChild(tintNode)

        // Invisible node the battle choreography sequences run on.
        addChild(coordinator)

        spawnRoamers()
    }

    // MARK: - Region / cycle configuration

    /// Idempotent: rebuilds terrain only when the project changes, but always
    /// re-applies the cycle tint.
    public func configure(region: Region, cycle: LoadCycle) {
        setUpIfNeeded()
        applyTint(SpriteNodeFactory.color(hex: cycle.tintHex), animated: false)

        guard region.project != currentProject else { return }
        currentProject = region.project
        rebuildTerrain(for: region)
        resetRoamers()
    }

    /// Animates the ambient tint into the new load cycle's color.
    public func updateCycle(_ cycle: LoadCycle) {
        setUpIfNeeded()
        applyTint(SpriteNodeFactory.color(hex: cycle.tintHex), animated: true)
    }

    private func applyTint(_ color: SKColor, animated: Bool) {
        tintNode.removeAllActions()
        tintNode.alpha = 0.25
        if animated {
            tintNode.run(.sequence([
                .colorize(with: color, colorBlendFactor: 1.0, duration: 1.0),
                .run { [weak self] in self?.tintNode.color = color }
            ]))
        } else {
            tintNode.color = color
            tintNode.colorBlendFactor = 1.0
        }
    }

    // MARK: - Terrain

    private func rebuildTerrain(for region: Region) {
        terrain.removeAllChildren()
        backgroundColor = SpriteNodeFactory.color(hex: region.biome.groundHex)
        let accent = SpriteNodeFactory.color(hex: region.biome.accentHex)
        var rng = SeededRandom("overworld|\(region.project)")

        // Ambient scatter: faint accent-colored debris across the ground.
        for _ in 0..<40 {
            let alpha = CGFloat(0.05 + 0.07 * rng.unit())
            let shape: SKShapeNode
            if rng.unit() < 0.5 {
                shape = SKShapeNode(circleOfRadius: CGFloat(3 + 9 * rng.unit()))
            } else {
                let w = CGFloat(6 + 14 * rng.unit())
                let h = CGFloat(6 + 14 * rng.unit())
                shape = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 2)
            }
            shape.fillColor = accent.withAlphaComponent(alpha)
            shape.strokeColor = SKColor.clear
            shape.position = CGPoint(x: CGFloat(rng.unit()) * worldWidth,
                                     y: CGFloat(rng.unit()) * worldHeight)
            shape.zPosition = 1
            terrain.addChild(shape)
        }

        // Encounter patches: clusters of swaying "tall code".
        patchCenters = []
        for patch in region.patches {
            let center = CGPoint(x: CGFloat(patch.x) * worldWidth,
                                 y: CGFloat(patch.y) * worldHeight)
            patchCenters.append(center)
            let radius = CGFloat(patch.radius) * worldWidth
            let bladeCount = rng.int(in: 5...8)
            for _ in 0..<bladeCount {
                let angle = CGFloat(rng.unit()) * 2 * .pi
                let dist = CGFloat(rng.unit()) * radius * 0.8
                let blade = SKShapeNode(
                    rectOf: CGSize(width: 14 + CGFloat(10 * rng.unit()),
                                   height: 20 + CGFloat(12 * rng.unit())),
                    cornerRadius: 5)
                blade.fillColor = accent.withAlphaComponent(0.25)
                blade.strokeColor = SKColor.clear
                blade.position = CGPoint(x: center.x + cos(angle) * dist,
                                         y: center.y + sin(angle) * dist)
                blade.zPosition = 2
                terrain.addChild(blade)

                let dur = 1.2 + 1.2 * rng.unit()
                let swayOut = SKAction.group([
                    .scale(to: 1.08, duration: dur),
                    .rotate(toAngle: 0.06, duration: dur)
                ])
                let swayBack = SKAction.group([
                    .scale(to: 0.94, duration: dur),
                    .rotate(toAngle: -0.06, duration: dur)
                ])
                blade.run(.repeatForever(.sequence([swayOut, swayBack])))
            }
        }

        for landmark in region.landmarks {
            addLandmark(landmark, accent: accent, rng: &rng)
        }
    }

    private func addLandmark(_ landmark: Landmark, accent: SKColor, rng: inout SeededRandom) {
        let pos = CGPoint(x: CGFloat(landmark.x) * worldWidth,
                          y: CGFloat(landmark.y) * worldHeight)
        switch landmark.kind {
        case .serverPillar:
            let pillar = SKShapeNode(rectOf: CGSize(width: 24, height: 90), cornerRadius: 6)
            pillar.fillColor = SKColor(white: 0.22, alpha: 1)
            pillar.strokeColor = accent.withAlphaComponent(0.7)
            pillar.lineWidth = 1.5
            pillar.position = pos
            pillar.zPosition = 3
            terrain.addChild(pillar)
            let glow = SKShapeNode(circleOfRadius: 8)
            glow.fillColor = accent.withAlphaComponent(0.8)
            glow.strokeColor = SKColor.clear
            glow.glowWidth = 6
            glow.position = CGPoint(x: pos.x, y: pos.y + 28)
            glow.zPosition = 4
            terrain.addChild(glow)
            glow.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.35, duration: 0.9),
                .fadeAlpha(to: 1.0, duration: 0.9)
            ])))

        case .dataSpring:
            let pool = SKShapeNode(circleOfRadius: 22)
            pool.fillColor = accent.withAlphaComponent(0.5)
            pool.strokeColor = accent
            pool.lineWidth = 1.5
            pool.glowWidth = 5
            pool.position = pos
            pool.zPosition = 3
            terrain.addChild(pool)
            let ring = SKShapeNode(circleOfRadius: 22)
            ring.fillColor = SKColor.clear
            ring.strokeColor = accent.withAlphaComponent(0.8)
            ring.lineWidth = 2
            ring.position = pos
            ring.zPosition = 3
            terrain.addChild(ring)
            let expand = SKAction.group([
                .scale(to: 2.4, duration: 1.8),
                .fadeAlpha(to: 0, duration: 1.8)
            ])
            let reset = SKAction.group([
                .scale(to: 1.0, duration: 0),
                .fadeAlpha(to: 0.8, duration: 0)
            ])
            ring.run(.repeatForever(.sequence([expand, reset, .wait(forDuration: 0.4)])))

        case .brokenBuild:
            let slabCount = rng.int(in: 2...3)
            for i in 0..<slabCount {
                let slab = SKShapeNode(rectOf: CGSize(width: 34 - CGFloat(i) * 6, height: 16),
                                       cornerRadius: 3)
                slab.fillColor = SKColor(white: 0.35, alpha: 1)
                slab.strokeColor = SKColor(white: 0.5, alpha: 1)
                slab.position = CGPoint(x: pos.x + CGFloat(i * 8) - 8,
                                        y: pos.y + CGFloat(i * 14))
                slab.zRotation = CGFloat(0.5 * rng.unit() - 0.25)
                slab.zPosition = 3
                terrain.addChild(slab)
            }
            let label = SKLabelNode(text: "404")
            label.fontName = "Helvetica-Bold"
            label.fontSize = 11
            label.fontColor = SKColor(white: 0.75, alpha: 1)
            label.position = CGPoint(x: pos.x, y: pos.y + CGFloat(slabCount * 14) + 8)
            label.zPosition = 4
            terrain.addChild(label)

        case .antenna:
            let mast = SKShapeNode(rectOf: CGSize(width: 4, height: 70))
            mast.fillColor = SKColor(white: 0.55, alpha: 1)
            mast.strokeColor = SKColor.clear
            mast.position = pos
            mast.zPosition = 3
            terrain.addChild(mast)
            let beacon = SKShapeNode(circleOfRadius: 4)
            beacon.fillColor = accent
            beacon.strokeColor = SKColor.clear
            beacon.glowWidth = 4
            beacon.position = CGPoint(x: pos.x, y: pos.y + 38)
            beacon.zPosition = 4
            terrain.addChild(beacon)
            beacon.run(.repeatForever(.sequence([
                .fadeOut(withDuration: 0.12),
                .wait(forDuration: 0.5),
                .fadeIn(withDuration: 0.12),
                .wait(forDuration: 0.5)
            ])))
        }
    }

    // MARK: - Roamers ("presences")

    private func spawnRoamers() {
        for _ in 0..<4 {
            let orb = SKShapeNode(circleOfRadius: 13)
            orb.fillColor = SKColor(white: 1.0, alpha: 0.35)
            orb.strokeColor = SKColor.clear
            orb.zPosition = 5
            let core = SKShapeNode(circleOfRadius: 4)
            core.fillColor = SKColor(white: 1.0, alpha: 0.8)
            core.strokeColor = SKColor.clear
            orb.addChild(core)
            orb.position = randomRoamPoint()
            addChild(orb)
            roamers.append(orb)
            startRoaming(orb)
        }
    }

    private func startRoaming(_ orb: SKShapeNode) {
        orb.removeAllActions()
        orb.run(.repeatForever(.sequence([
            .scale(to: 1.12, duration: 0.8),
            .scale(to: 0.92, duration: 0.8)
        ])), withKey: "pulse")
        wander(orb)
    }

    private func wander(_ orb: SKShapeNode) {
        let move = SKAction.move(to: randomRoamPoint(), duration: Double.random(in: 2...4))
        move.timingMode = .easeInEaseOut
        orb.run(.sequence([
            move,
            .wait(forDuration: Double.random(in: 0.2...0.8)),
            .run { [weak self, weak orb] in
                guard let self, let orb, !self.battleActive else { return }
                self.wander(orb)
            }
        ]), withKey: "wander")
    }

    private func randomRoamPoint() -> CGPoint {
        if let center = patchCenters.randomElement() {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 0...120)
            return clampToWorld(CGPoint(x: center.x + cos(angle) * dist,
                                        y: center.y + sin(angle) * dist))
        }
        return CGPoint(x: CGFloat.random(in: 60...(worldWidth - 60)),
                       y: CGFloat.random(in: 60...(worldHeight - 60)))
    }

    private func resetRoamers() {
        for orb in roamers {
            orb.position = randomRoamPoint()
            if !battleActive { startRoaming(orb) }
        }
    }

    // MARK: - Input (touch on iOS; mouse on macOS)

    #if os(iOS)
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        movePlayer(to: touch.location(in: self))
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        movePlayer(to: touch.location(in: self))
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
        let move = SKAction.move(to: clampToWorld(point), duration: 0.15)
        move.timingMode = .easeOut
        player.run(move, withKey: "move")
    }

    private func clampToWorld(_ point: CGPoint) -> CGPoint {
        CGPoint(x: min(max(16, point.x), worldWidth - 16),
                y: min(max(16, point.y), worldHeight - 16))
    }

    // MARK: - Frame update

    public override func update(_ currentTime: TimeInterval) {
        // Camera trails the player with a soft lerp.
        let lerp: CGFloat = 0.12
        cameraNode.position = CGPoint(
            x: cameraNode.position.x + (player.position.x - cameraNode.position.x) * lerp,
            y: cameraNode.position.y + (player.position.y - cameraNode.position.y) * lerp
        )

        // Bump detection → encounter, throttled, suppressed during battle.
        guard !battleActive, currentTime - lastEncounterTime > 1.5 else { return }
        for orb in roamers where !orb.isHidden {
            let distance = hypot(orb.position.x - player.position.x,
                                 orb.position.y - player.position.y)
            if distance < 30 {
                lastEncounterTime = currentTime
                orb.run(.sequence([.scale(to: 1.4, duration: 0.1),
                                   .scale(to: 1.0, duration: 0.1)]))
                onEncounter?()
                break
            }
        }
    }

    // MARK: - Battle presentation

    public func battleBegan(enemyRecipe: SpriteRecipe, enemyAnomalous: Bool, playerRecipe: SpriteRecipe?) {
        setUpIfNeeded()
        battleActive = true

        // Defensive: clear any leftovers from a previous battle.
        enemyNode?.removeFromParent()
        allyNode?.removeFromParent()
        dimNode?.removeFromParent()

        for orb in roamers {
            orb.removeAllActions()
            orb.isHidden = true
        }

        let dim = SKSpriteNode(color: SKColor.black,
                               size: CGSize(width: worldWidth, height: worldHeight))
        dim.alpha = 0
        dim.position = CGPoint(x: worldWidth / 2, y: worldHeight / 2)
        dim.zPosition = 40
        addChild(dim)
        dim.run(.fadeAlpha(to: 0.35, duration: 0.25))
        dimNode = dim

        let enemy = SpriteNodeFactory.daemonNode(recipe: enemyRecipe,
                                                 anomalous: enemyAnomalous,
                                                 size: 90)
        enemy.position = clampToWorld(CGPoint(x: player.position.x + 120,
                                              y: player.position.y + 10))
        enemy.zPosition = 45
        enemy.setScale(0)
        addChild(enemy)
        enemy.run(spawnPop())
        spawnFlash(at: enemy.position)
        enemyNode = enemy

        if let playerRecipe {
            let ally = SpriteNodeFactory.daemonNode(recipe: playerRecipe,
                                                    anomalous: false,
                                                    size: 70)
            ally.position = clampToWorld(CGPoint(x: player.position.x - 60,
                                                 y: player.position.y))
            ally.zPosition = 45
            ally.setScale(0)
            addChild(ally)
            ally.run(spawnPop())
            spawnFlash(at: ally.position)
            allyNode = ally
        } else {
            allyNode = nil
        }
    }

    /// Plays the event stream as a serial choreography, then calls `completion`
    /// (on the main thread — SpriteKit runs actions there).
    public func choreograph(_ events: [BattleEvent], completion: @escaping () -> Void) {
        setUpIfNeeded()
        var actions: [SKAction] = []
        for event in events {
            actions.append(.run { [weak self] in self?.render(event) })
            actions.append(.wait(forDuration: delay(after: event)))
        }
        actions.append(.run { completion() })
        coordinator.run(.sequence(actions))
    }

    public func battleEnded() {
        battleActive = false

        let leaving: [SKNode?] = [enemyNode, allyNode, dimNode]
        for node in leaving {
            node?.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))
        }
        enemyNode = nil
        allyNode = nil
        dimNode = nil

        for orb in roamers {
            orb.isHidden = false
            orb.alpha = 1
            orb.setScale(1)
            startRoaming(orb)
        }
    }

    // MARK: - Event rendering

    /// How long the choreography lingers on each event.
    private func delay(after event: BattleEvent) -> TimeInterval {
        switch event {
        case .moveUsed: return 0.5
        case .damage: return 0.8
        case .missed: return 0.5
        case .statusApplied: return 0.6
        case .statusTick: return 0.5
        case .healed: return 0.6
        case .fainted: return 0.7
        case .sphereThrown(_, let shakes, _, _):
            return 0.75 + Double(max(0, shakes)) * 0.4 + 0.9
        case .leveledUp, .ascended: return 0.7
        case .daemonSent(let side, _, _): return side == .player ? 0.5 : 0.3
        case .battleEnded: return 0.3
        default: return 0.05
        }
    }

    private func render(_ event: BattleEvent) {
        switch event {
        case .moveUsed(let side, _, _, let aspect):
            renderMove(from: side, aspect: aspect)

        case .damage(let side, let amount, _, _, let effectiveness, let crit):
            renderDamage(on: side, amount: amount, effectiveness: effectiveness, crit: crit)

        case .missed(let side, _):
            let target = battleNode(for: side == .player ? .enemy : .player)
            floatLabel("miss", color: SKColor.gray, at: target?.position ?? player.position)
            Cues.play(.miss)

        case .statusApplied(let side, let status):
            if let node = battleNode(for: side) {
                pulseRing(color: SpriteNodeFactory.color(hex: status.colorHex),
                          at: node.position, radius: 22, scale: 2.0)
            }
            Cues.play(.statusApply)

        case .statusTick(let side, let status, _, _):
            if let node = battleNode(for: side) {
                pulseRing(color: SpriteNodeFactory.color(hex: status.colorHex),
                          at: node.position, radius: 14, scale: 1.6)
            }

        case .healed(let side, let amount, _):
            if let node = battleNode(for: side) {
                floatLabel("+\(amount)", color: SKColor.green, at: node.position)
            }

        case .fainted(let side, _):
            renderFaint(on: side)

        case .sphereThrown(_, let shakes, let captured, let critical):
            renderSphereThrow(shakes: shakes, captured: captured, critical: critical)

        case .leveledUp:
            goldenRing(at: (allyNode ?? player).position)
            Cues.play(.levelUp)

        case .ascended:
            goldenRing(at: (allyNode ?? player).position)
            Cues.play(.ascend)

        case .daemonSent(let side, _, _):
            if side == .player, let ally = allyNode {
                ally.removeAllActions()
                ally.alpha = 1
                ally.setScale(0)
                ally.run(spawnPop())
                spawnFlash(at: ally.position)
            }

        default:
            break
        }
    }

    private func renderMove(from side: Side, aspect: Aspect) {
        guard let attacker = battleNode(for: side),
              let defender = battleNode(for: side == .player ? .enemy : .player) else { return }

        // Lunge toward the defender and back.
        let dx = defender.position.x - attacker.position.x
        let dy = defender.position.y - attacker.position.y
        let length = max(1, hypot(dx, dy))
        let out = SKAction.move(by: CGVector(dx: dx / length * 24, dy: dy / length * 24),
                                duration: 0.18)
        out.timingMode = .easeIn
        let back = out.reversed()
        back.timingMode = .easeOut
        attacker.run(.sequence([out, back]), withKey: "lunge")

        // Aspect-colored impact flash at the defender.
        let flash = SKShapeNode(circleOfRadius: 24)
        flash.fillColor = SpriteNodeFactory.color(hex: aspect.palette.primary)
            .withAlphaComponent(0.55)
        flash.strokeColor = SKColor.clear
        flash.position = defender.position
        flash.zPosition = 46
        addChild(flash)
        flash.run(.sequence([
            .wait(forDuration: 0.15),
            .group([.scale(to: 1.5, duration: 0.25), .fadeOut(withDuration: 0.25)]),
            .removeFromParent()
        ]))
    }

    private func renderDamage(on side: Side, amount: Int, effectiveness: Double, crit: Bool) {
        let node = battleNode(for: side)
        let position = node?.position ?? player.position

        var text = "-\(amount)"
        var color = SKColor.white
        if crit {
            text += "!"
            color = SKColor.red
        }
        if effectiveness > 1.0 {
            text += "!"
            if !crit { color = SKColor.orange }
        } else if effectiveness < 1.0 {
            text += "…"
            if !crit { color = SKColor.gray }
        }
        floatLabel(text, color: color, at: position)

        if let node {
            hitFlash(on: node)
            node.run(.sequence([
                .moveBy(x: 6, y: 0, duration: 0.04),
                .moveBy(x: -12, y: 0, duration: 0.05),
                .moveBy(x: 12, y: 0, duration: 0.05),
                .moveBy(x: -12, y: 0, duration: 0.05),
                .moveBy(x: 6, y: 0, duration: 0.04)
            ]), withKey: "shake")
        }

        Cues.play(effectiveness > 1.0 ? .superHit : (effectiveness < 1.0 ? .weakHit : .hit))
    }

    private func renderFaint(on side: Side) {
        Cues.play(.faint)
        let node: SKNode? = side == .enemy ? enemyNode : allyNode
        node?.run(.group([
            .fadeOut(withDuration: 0.5),
            .scaleY(to: 0.1, duration: 0.5)
        ]), withKey: "faint")
    }

    private func renderSphereThrow(shakes: Int, captured: Bool, critical: Bool) {
        guard let enemy = enemyNode else { return }
        // Note: the throw-start cue is played by the HUD when the player
        // commits the throw, so the scene doesn't repeat it here.

        let start = (allyNode ?? player).position
        let target = enemy.position
        let dx = target.x - start.x
        let dy = target.y - start.y

        let orb = SKShapeNode(circleOfRadius: 8)
        orb.fillColor = SKColor.white
        orb.strokeColor = SKColor.clear
        orb.glowWidth = 2
        orb.position = start
        orb.zPosition = 46
        addChild(orb)

        var sequence: [SKAction] = []

        // Two-segment arc: up-and-over, then down onto the enemy.
        sequence.append(.move(by: CGVector(dx: dx * 0.5, dy: dy * 0.5 + 60), duration: 0.25))
        sequence.append(.move(by: CGVector(dx: dx * 0.5, dy: dy * 0.5 - 60), duration: 0.25))

        // The enemy is pulled inside.
        sequence.append(.run { [weak self] in
            self?.enemyNode?.run(.group([
                .scale(to: 0.05, duration: 0.15),
                .fadeOut(withDuration: 0.15)
            ]))
        })
        sequence.append(.wait(forDuration: 0.2))

        for _ in 0..<max(0, shakes) {
            sequence.append(.run { Cues.play(.shake) })
            sequence.append(.rotate(toAngle: 0.25, duration: 0.12))
            sequence.append(.rotate(toAngle: -0.25, duration: 0.12))
            sequence.append(.rotate(toAngle: 0, duration: 0.11))
            sequence.append(.wait(forDuration: 0.05))
        }

        if captured {
            sequence.append(.run { [weak self, weak orb] in
                Cues.play(.catchSuccess)
                if let orb { self?.sparkleBurst(at: orb.position, count: critical ? 12 : 8) }
            })
            sequence.append(.wait(forDuration: 0.6))
            sequence.append(.fadeOut(withDuration: 0.4))
            sequence.append(.removeFromParent())
        } else {
            sequence.append(.run { [weak self] in
                Cues.play(.catchFail)
                self?.enemyNode?.run(.group([
                    .scale(to: 1.0, duration: 0.2),
                    .fadeIn(withDuration: 0.2)
                ]))
            })
            sequence.append(.group([
                .scale(to: 2.0, duration: 0.2),
                .fadeOut(withDuration: 0.2)
            ]))
            sequence.append(.removeFromParent())
        }

        orb.run(.sequence(sequence))
    }

    // MARK: - Effect helpers

    private func battleNode(for side: Side) -> SKNode? {
        switch side {
        case .enemy: return enemyNode
        case .player: return allyNode ?? player
        }
    }

    private func spawnPop() -> SKAction {
        .sequence([
            .scale(to: 1.15, duration: 0.18),
            .scale(to: 1.0, duration: 0.1)
        ])
    }

    private func spawnFlash(at position: CGPoint) {
        let flash = SKShapeNode(circleOfRadius: 30)
        flash.fillColor = SKColor(white: 1.0, alpha: 0.7)
        flash.strokeColor = SKColor.clear
        flash.position = position
        flash.zPosition = 46
        addChild(flash)
        flash.run(.sequence([
            .group([.scale(to: 1.6, duration: 0.25), .fadeOut(withDuration: 0.25)]),
            .removeFromParent()
        ]))
    }

    private func hitFlash(on node: SKNode) {
        let flash = SKShapeNode(circleOfRadius: 26)
        flash.fillColor = SKColor(white: 1.0, alpha: 0.8)
        flash.strokeColor = SKColor.clear
        flash.zPosition = 5
        node.addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()]))
    }

    private func floatLabel(_ text: String, color: SKColor, at position: CGPoint) {
        let label = SKLabelNode(text: text)
        label.fontName = "Helvetica-Bold"
        label.fontSize = 20
        label.fontColor = color
        label.position = CGPoint(x: position.x, y: position.y + 24)
        label.zPosition = 48
        addChild(label)
        label.run(.sequence([
            .group([.moveBy(x: 0, y: 40, duration: 0.7), .fadeOut(withDuration: 0.7)]),
            .removeFromParent()
        ]))
    }

    private func pulseRing(color: SKColor, at position: CGPoint, radius: CGFloat, scale: CGFloat) {
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.fillColor = SKColor.clear
        ring.strokeColor = color
        ring.lineWidth = 3
        ring.position = position
        ring.zPosition = 47
        addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: scale, duration: 0.5), .fadeOut(withDuration: 0.5)]),
            .removeFromParent()
        ]))
    }

    private func goldenRing(at position: CGPoint) {
        let ring = SKShapeNode(circleOfRadius: 18)
        ring.fillColor = SKColor.clear
        ring.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.3, alpha: 1.0)
        ring.lineWidth = 3
        ring.glowWidth = 4
        ring.position = position
        ring.zPosition = 47
        addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 2.6, duration: 0.6), .fadeOut(withDuration: 0.6)]),
            .removeFromParent()
        ]))
    }

    private func sparkleBurst(at position: CGPoint, count: Int) {
        for i in 0..<count {
            let sparkle = SKShapeNode(circleOfRadius: 3)
            sparkle.fillColor = SKColor.white
            sparkle.strokeColor = SKColor.clear
            sparkle.position = position
            sparkle.zPosition = 47
            addChild(sparkle)
            let angle = CGFloat(i) / CGFloat(max(1, count)) * 2 * .pi
            sparkle.run(.sequence([
                .group([
                    .move(by: CGVector(dx: cos(angle) * 40, dy: sin(angle) * 40), duration: 0.5),
                    .fadeOut(withDuration: 0.5)
                ]),
                .removeFromParent()
            ]))
        }
    }
}
