import Foundation

/// Which side of the battle an event refers to.
public enum Side: String, Equatable, Sendable { case player, enemy }

/// How a battle ended.
public enum BattleOutcome: Equatable, Sendable {
    case victory        // enemy (or full trainer party) defeated
    case defeat         // player party wiped
    case captured       // wild daemon bound
    case fled           // player ran
}

/// Everything that can happen in a battle, as typed events. Both the overworld
/// choreography and the classic battle screen render the SAME event stream, so
/// the two presentations can never drift apart mechanically.
public enum BattleEvent: Equatable, Sendable {
    case battleStarted(enemyName: String, enemyLevel: Int, isTrainer: Bool, trainerName: String?)
    case daemonSent(side: Side, name: String, level: Int)
    case moveUsed(side: Side, user: String, moveName: String, aspect: Aspect)
    case damage(side: Side, amount: Int, newHP: Int, maxHP: Int, effectiveness: Double, crit: Bool)
    case missed(side: Side, moveName: String)
    case statusApplied(side: Side, status: DaemonStatus)
    case statusCleared(side: Side, status: DaemonStatus)
    case statusTick(side: Side, status: DaemonStatus, damage: Int, newHP: Int)
    case skippedTurn(side: Side, reason: String)
    case selfHit(side: Side, amount: Int, newHP: Int)
    case statChanged(side: Side, key: StageKey, delta: Int, newStage: Int)
    case statChangeFailed(side: Side, key: StageKey)
    case abilityProc(side: Side, ability: Ability, note: String)
    case healed(side: Side, amount: Int, newHP: Int)
    case fainted(side: Side, name: String)
    case xpGained(amount: Int, to: String)
    case leveledUp(name: String, level: Int)
    case learnedMove(name: String, moveName: String)
    case moveNotLearned(name: String, moveName: String)
    case ascended(oldName: String, newName: String)
    case sphereThrown(sphereName: String, shakes: Int, captured: Bool, critical: Bool)
    case itemUsed(itemName: String, target: String)
    case fleeAttempt(success: Bool)
    case payout(amount: Int)
    case battleEnded(outcome: BattleOutcome)
    case message(String)
}

/// What the player can do on their turn.
public enum PlayerAction: Equatable, Sendable {
    case move(Move)
    case switchTo(Int)              // party index
    case useItem(Item)              // applied to the active daemon (or a fainted one for revive)
    case throwSphere(Sphere, quality: Double)
    case flee
}

/// A full battle from start to outcome. Owns working copies of the combatants;
/// GameState writes results back to the save when the battle ends. Everything
/// is driven by an internal seeded RNG, so whole battles are reproducible.
public final class BattleSession {

    public enum Kind {
        case wild(Daemon)
        case trainer(TrainerProfile)
    }

    // MARK: State

    public private(set) var party: [Daemon]
    public private(set) var activeIndex: Int
    public private(set) var enemy: Daemon
    public private(set) var enemyReserve: [Daemon]   // trainer's remaining daemons
    public private(set) var outcome: BattleOutcome?
    public private(set) var capturedDaemon: Daemon?
    public let isTrainerBattle: Bool
    public let trainer: TrainerProfile?

    private var rng: SeededRandom
    private var fleeAttempts = 0
    private let dexCaught: Int
    private let dexTotal: Int

    public var isOver: Bool { outcome != nil }
    public var activeDaemon: Daemon { party[activeIndex] }

    // MARK: Init

    /// - seed: any stable string; drive it from encounter identity for
    ///   reproducibility, or include entropy for variety.
    public init(kind: Kind, party: [Daemon], seed: String, dexCaught: Int = 0, dexTotal: Int = 0) {
        precondition(!party.isEmpty, "BattleSession requires a party")
        var working = party
        for i in working.indices { working[i].resetBattleState() }
        self.party = working
        self.activeIndex = working.firstIndex { !$0.isFainted } ?? 0
        self.rng = SeededRandom(seed)
        self.dexCaught = dexCaught
        self.dexTotal = dexTotal

        switch kind {
        case .wild(var wild):
            wild.resetBattleState()
            self.enemy = wild
            self.enemyReserve = []
            self.isTrainerBattle = false
            self.trainer = nil
        case .trainer(let profile):
            var enemies = profile.party
            for i in enemies.indices { enemies[i].resetBattleState() }
            self.enemy = enemies.first ?? Daemon(species: party[0].species, level: 5)
            self.enemyReserve = Array(enemies.dropFirst())
            self.isTrainerBattle = true
            self.trainer = profile
        }
    }

    /// The opening events (announce + entry ability procs). Call once.
    public func start() -> [BattleEvent] {
        var events: [BattleEvent] = [
            .battleStarted(enemyName: enemy.species.name, enemyLevel: enemy.level,
                           isTrainer: isTrainerBattle, trainerName: trainer?.name),
            .daemonSent(side: .player, name: activeDaemon.species.name, level: activeDaemon.level)
        ]
        applyEntryAbility(side: .player, events: &events)
        applyEntryAbility(side: .enemy, events: &events)
        return events
    }

    // MARK: - The turn loop

    /// Submit the player's action; resolves the full turn (both sides) and
    /// returns everything that happened, in order.
    public func submit(_ action: PlayerAction) -> [BattleEvent] {
        guard !isOver else { return [] }
        var events: [BattleEvent] = []

        switch action {
        case .flee:
            resolveFlee(&events)
            if isOver { return events }
            enemyTurn(&events)

        case .throwSphere(let sphere, let quality):
            resolveThrow(sphere: sphere, quality: quality, &events)
            if isOver { return events }
            enemyTurn(&events)

        case .useItem(let item):
            resolveItem(item, &events)
            enemyTurn(&events)

        case .switchTo(let index):
            resolveSwitch(to: index, &events)
            enemyTurn(&events)

        case .move(let move):
            let enemyMove = BattleAI.chooseMove(for: enemy, against: activeDaemon, rng: &rng)
            let playerFirst = BattleEngine.playerActsFirst(
                player: activeDaemon, playerMove: move,
                enemy: enemy, enemyMove: enemyMove, rng: &rng)
            if playerFirst {
                playerAct(move, &events)
                if !isOver && !enemy.isFainted { enemyAct(enemyMove, &events) }
            } else {
                enemyAct(enemyMove, &events)
                if !isOver && !activeDaemon.isFainted { playerAct(move, &events) }
            }
        }

        if !isOver { endOfTurn(&events) }
        return events
    }

    // MARK: - Acting

    private func playerAct(_ move: Move, _ events: inout [BattleEvent]) {
        guard canAct(side: .player, &events) else { return }
        executeMove(move, from: .player, &events)
        if enemy.isFainted { handleEnemyFaint(&events) }
    }

    private func enemyAct(_ move: Move, _ events: inout [BattleEvent]) {
        guard canAct(side: .enemy, &events) else { return }
        executeMove(move, from: .enemy, &events)
        if activeDaemon.isFainted { handlePlayerFaint(&events) }
    }

    private func enemyTurn(_ events: inout [BattleEvent]) {
        guard !isOver, !enemy.isFainted else { return }
        let move = BattleAI.chooseMove(for: enemy, against: activeDaemon, rng: &rng)
        enemyAct(move, &events)
    }

    /// Status gates: stalled skips, looped may self-hit, ratelimited may skip.
    private func canAct(side: Side, _ events: inout [BattleEvent]) -> Bool {
        var actor = daemon(on: side)
        defer { setDaemon(actor, on: side) }

        switch actor.status {
        case .stalled:
            if actor.statusTurns > 0 {
                actor.statusTurns -= 1
                events.append(.skippedTurn(side: side, reason: "stalled"))
                if actor.statusTurns == 0 {
                    actor.status = .none
                    events.append(.statusCleared(side: side, status: .stalled))
                }
                return false
            }
            actor.status = .none
            events.append(.statusCleared(side: side, status: .stalled))
            return true

        case .looped:
            if actor.statusTurns > 0 {
                actor.statusTurns -= 1
                if actor.statusTurns == 0 {
                    actor.status = .none
                    events.append(.statusCleared(side: side, status: .looped))
                } else if rng.unit() < 0.33 {
                    // Hits itself in the loop: 40-power typeless self-strike.
                    let dmg = max(1, actor.maxHP / 10)
                    let result = BattleEngine.applyDamage(dmg, to: &actor)
                    events.append(.selfHit(side: side, amount: result.dealt, newHP: actor.currentHP))
                    if result.failsafed {
                        events.append(.abilityProc(side: side, ability: .failsafe, note: "held on at 1 HP"))
                    }
                    if actor.isFainted {
                        events.append(.fainted(side: side, name: actor.species.name))
                        setDaemon(actor, on: side)
                        if side == .enemy { handleEnemyFaint(&events) } else { handlePlayerFaint(&events) }
                    }
                    return false
                }
            }
            return true

        case .ratelimited:
            if rng.unit() < 0.25 {
                events.append(.skippedTurn(side: side, reason: "rate-limited"))
                return false
            }
            return true

        default:
            return true
        }
    }

    private func executeMove(_ move: Move, from side: Side, _ events: inout [BattleEvent]) {
        var attacker = daemon(on: side)
        let defenderSide: Side = side == .player ? .enemy : .player
        var defender = daemon(on: defenderSide)

        events.append(.moveUsed(side: side, user: attacker.species.name,
                                moveName: move.name, aspect: move.aspect))

        guard BattleEngine.rollAccuracy(attacker: attacker, defender: defender, move: move, rng: &rng) else {
            events.append(.missed(side: side, moveName: move.name))
            setDaemon(attacker, on: side)
            return
        }

        // Damage phase.
        if move.category != .status && move.power > 0 {
            let hit = BattleEngine.computeHit(attacker: attacker, defender: defender, move: move, rng: &rng)
            for note in hit.abilityNotes {
                let ability: Ability = note.contains("Hardened") ? .hardened
                    : note.contains("Overclock") ? .overclock : .loadBalancer
                let procSide: Side = (ability == .overclock) ? side : defenderSide
                events.append(.abilityProc(side: procSide, ability: ability, note: note))
            }
            let applied = BattleEngine.applyDamage(hit.amount, to: &defender)
            events.append(.damage(side: defenderSide, amount: applied.dealt,
                                  newHP: defender.currentHP, maxHP: defender.maxHP,
                                  effectiveness: hit.effectiveness, crit: hit.isCrit))
            if applied.failsafed {
                events.append(.abilityProc(side: defenderSide, ability: .failsafe, note: "held on at 1 HP"))
            }

            // Drain / recoil.
            if move.effect == .drain && applied.dealt > 0 {
                let heal = max(1, applied.dealt / 2)
                attacker.currentHP = min(attacker.maxHP, attacker.currentHP + heal)
                events.append(.healed(side: side, amount: heal, newHP: attacker.currentHP))
            }
            if move.effect == .recoil && applied.dealt > 0 {
                let recoil = max(1, applied.dealt / 4)
                let r = BattleEngine.applyDamage(recoil, to: &attacker)
                events.append(.selfHit(side: side, amount: r.dealt, newHP: attacker.currentHP))
            }

            // Firewall: physical contact may overheat the attacker.
            if move.category == .physical && defender.species.ability == .firewall
                && !defender.isFainted && rng.unit() < 0.30 {
                if applyStatus(.overheated, to: &attacker, side: side, &events) {
                    events.append(.abilityProc(side: defenderSide, ability: .firewall, note: "contact burned"))
                }
            }
        }

        // Effect phase (status conditions / stage changes / self-heal).
        let effectHits = move.effectChance == 0 || rng.int(in: 1...100) <= move.effectChance
        if effectHits {
            if let status = move.inflictedStatus, !defender.isFainted {
                _ = applyStatus(status, to: &defender, side: defenderSide, &events)
            }
            if let stage = move.stageEffect {
                if stage.onSelf {
                    applyStageChange(stage.key, stage.delta, to: &attacker, side: side, &events)
                } else if !defender.isFainted {
                    applyStageChange(stage.key, stage.delta, to: &defender, side: defenderSide, &events)
                }
            }
            if move.effect == .healSelf {
                let heal = max(1, attacker.maxHP / 2)
                let before = attacker.currentHP
                attacker.currentHP = min(attacker.maxHP, attacker.currentHP + heal)
                events.append(.healed(side: side, amount: attacker.currentHP - before, newHP: attacker.currentHP))
            }
        }

        setDaemon(attacker, on: side)
        setDaemon(defender, on: defenderSide)

        if attacker.isFainted {
            events.append(.fainted(side: side, name: attacker.species.name))
            if side == .enemy { handleEnemyFaint(&events) } else { handlePlayerFaint(&events) }
        }
        if defender.isFainted && !events.contains(.fainted(side: defenderSide, name: defender.species.name)) {
            events.append(.fainted(side: defenderSide, name: defender.species.name))
        }
    }

    @discardableResult
    private func applyStatus(_ status: DaemonStatus, to target: inout Daemon,
                             side: Side, _ events: inout [BattleEvent]) -> Bool {
        guard target.status == .none else { return false }
        // Clean Code immunity.
        if target.species.ability == .cleanCode && (status == .deprecated || status == .overheated) {
            events.append(.abilityProc(side: side, ability: .cleanCode, note: "immune to \(status.displayName)"))
            return false
        }
        target.status = status
        target.statusTurns = status.rollDuration(rng: &rng)
        events.append(.statusApplied(side: side, status: status))
        return true
    }

    private func applyStageChange(_ key: StageKey, _ delta: Int, to target: inout Daemon,
                                  side: Side, _ events: inout [BattleEvent]) {
        if let newStage = target.stages.apply(delta, to: key) {
            events.append(.statChanged(side: side, key: key, delta: delta, newStage: newStage))
        } else {
            events.append(.statChangeFailed(side: side, key: key))
        }
    }

    private func applyEntryAbility(side: Side, events: inout [BattleEvent]) {
        var d = daemon(on: side)
        if d.species.ability == .burstMode {
            if let newStage = d.stages.apply(+1, to: .spe) {
                events.append(.abilityProc(side: side, ability: .burstMode, note: "spun up"))
                events.append(.statChanged(side: side, key: .spe, delta: 1, newStage: newStage))
            }
            setDaemon(d, on: side)
        }
    }

    // MARK: - End of turn

    private func endOfTurn(_ events: inout [BattleEvent]) {
        for side in [Side.player, Side.enemy] {
            guard !isOver else { return }
            var d = daemon(on: side)
            guard !d.isFainted else { continue }

            // Chip damage from status.
            let chip = d.status.chipFraction
            if chip > 0 {
                let dmg = max(1, Int(Double(d.maxHP) * chip))
                let r = BattleEngine.applyDamage(dmg, to: &d)
                events.append(.statusTick(side: side, status: d.status, damage: r.dealt, newHP: d.currentHP))
                if r.failsafed {
                    events.append(.abilityProc(side: side, ability: .failsafe, note: "held on at 1 HP"))
                }
            }

            // Hot Reload regen.
            if d.species.ability == .hotReload && d.currentHP < d.maxHP && !d.isFainted {
                let heal = max(1, d.maxHP / 16)
                d.currentHP = min(d.maxHP, d.currentHP + heal)
                events.append(.abilityProc(side: side, ability: .hotReload, note: "patched itself"))
                events.append(.healed(side: side, amount: heal, newHP: d.currentHP))
            }

            // Garbage Collector: chance to self-cure.
            if d.species.ability == .garbageCollector && d.status != .none && rng.unit() < 0.25 {
                let cured = d.status
                d.status = .none
                d.statusTurns = 0
                events.append(.abilityProc(side: side, ability: .garbageCollector, note: "collected"))
                events.append(.statusCleared(side: side, status: cured))
            }

            setDaemon(d, on: side)

            if d.isFainted {
                events.append(.fainted(side: side, name: d.species.name))
                if side == .enemy { handleEnemyFaint(&events) } else { handlePlayerFaint(&events) }
            }
        }
    }

    // MARK: - Faints, XP, level-ups, ascension

    private func handleEnemyFaint(_ events: inout [BattleEvent]) {
        guard !isOver else { return }
        awardXP(&events)

        if isTrainerBattle && !enemyReserve.isEmpty {
            enemy = enemyReserve.removeFirst()
            var e = enemy
            e.resetBattleState()
            enemy = e
            events.append(.daemonSent(side: .enemy, name: enemy.species.name, level: enemy.level))
            applyEntryAbility(side: .enemy, events: &events)
            return
        }

        // Battle won.
        let amount: Int
        if let trainer {
            amount = trainer.payout
            events.append(.message(trainer.defeatLine))
        } else {
            amount = enemy.level * enemy.species.tier.payoutMultiplier
        }
        events.append(.payout(amount: amount))
        outcome = .victory
        events.append(.battleEnded(outcome: .victory))
    }

    private func handlePlayerFaint(_ events: inout [BattleEvent]) {
        guard !isOver else { return }
        if let next = party.firstIndex(where: { !$0.isFainted }) {
            activeIndex = next
            events.append(.daemonSent(side: .player, name: activeDaemon.species.name, level: activeDaemon.level))
            applyEntryAbility(side: .player, events: &events)
        } else {
            if let trainer { events.append(.message(trainer.victoryLine)) }
            outcome = .defeat
            events.append(.battleEnded(outcome: .defeat))
        }
    }

    private func awardXP(_ events: inout [BattleEvent]) {
        var winner = party[activeIndex]
        guard !winner.isFainted else { return }
        let gain = Experience.gain(defeating: enemy, winnerLevel: winner.level, isTrainer: isTrainerBattle)
        let oldLevel = winner.level
        winner.xp += gain
        events.append(.xpGained(amount: gain, to: winner.species.name))

        let newLevel = Experience.level(forXP: winner.xp)
        if newLevel > oldLevel {
            let hpBefore = winner.maxHP
            winner.level = newLevel
            // Leveling up grows max HP; keep the same missing-HP amount.
            let hpGain = winner.maxHP - hpBefore
            winner.currentHP = min(winner.maxHP, winner.currentHP + max(0, hpGain))
            events.append(.leveledUp(name: winner.species.name, level: newLevel))

            // Learn newly-unlocked moves (auto-learn when there's room).
            for move in MovePool.newlyUnlocked(for: winner.species.primaryAspect,
                                               from: oldLevel, to: newLevel) {
                if winner.moves.count < 4 {
                    winner.moves.append(move)
                    events.append(.learnedMove(name: winner.species.name, moveName: move.name))
                } else {
                    events.append(.moveNotLearned(name: winner.species.name, moveName: move.name))
                }
            }

            // Ascension.
            if Ascension.canAscend(winner.species, at: newLevel) {
                let oldName = winner.species.name
                winner.species = Ascension.ascend(winner.species)
                winner.currentHP = min(winner.maxHP, winner.currentHP)
                events.append(.ascended(oldName: oldName, newName: winner.species.name))
            }
        }
        party[activeIndex] = winner
    }

    // MARK: - Non-move actions

    private func resolveThrow(sphere: Sphere, quality: Double, _ events: inout [BattleEvent]) {
        guard !isTrainerBattle else {
            events.append(.message("You can't throw a Sphere at another Conductor's daemon. There are norms."))
            return
        }
        let attempt = CatchCalculator.attempt(
            target: enemy, sphere: sphere, throwQuality: quality,
            dexCaught: dexCaught, dexTotal: dexTotal, rng: &rng)
        events.append(.sphereThrown(sphereName: sphere.name, shakes: attempt.shakes,
                                    captured: attempt.captured, critical: attempt.critical))
        if attempt.captured {
            capturedDaemon = enemy
            outcome = .captured
            events.append(.battleEnded(outcome: .captured))
        }
    }

    private func resolveItem(_ item: Item, _ events: inout [BattleEvent]) {
        var target = party[activeIndex]
        switch item.effect {
        case .heal(let amount):
            let before = target.currentHP
            target.currentHP = min(target.maxHP, target.currentHP + amount)
            events.append(.itemUsed(itemName: item.name, target: target.species.name))
            events.append(.healed(side: .player, amount: target.currentHP - before, newHP: target.currentHP))
        case .fullHeal:
            target.currentHP = target.maxHP
            events.append(.itemUsed(itemName: item.name, target: target.species.name))
            events.append(.healed(side: .player, amount: target.maxHP, newHP: target.currentHP))
        case .cureStatus:
            let old = target.status
            target.status = .none
            target.statusTurns = 0
            events.append(.itemUsed(itemName: item.name, target: target.species.name))
            if old != .none { events.append(.statusCleared(side: .player, status: old)) }
        case .revive:
            if let idx = party.firstIndex(where: { $0.isFainted }) {
                party[idx].currentHP = max(1, party[idx].maxHP / 2)
                party[idx].status = .none
                events.append(.itemUsed(itemName: item.name, target: party[idx].species.name))
            } else {
                events.append(.message("No one needs reviving. Aggressively healthy party."))
            }
            return
        case .xpBoost(let amount):
            target.xp += amount
            events.append(.itemUsed(itemName: item.name, target: target.species.name))
            let newLevel = Experience.level(forXP: target.xp)
            if newLevel > target.level {
                target.level = newLevel
                events.append(.leveledUp(name: target.species.name, level: newLevel))
            }
        }
        party[activeIndex] = target
    }

    private func resolveSwitch(to index: Int, _ events: inout [BattleEvent]) {
        guard party.indices.contains(index), index != activeIndex, !party[index].isFainted else {
            events.append(.message("Can't switch to that daemon."))
            return
        }
        activeIndex = index
        var d = party[index]
        d.resetBattleState()
        party[index] = d
        events.append(.daemonSent(side: .player, name: d.species.name, level: d.level))
        applyEntryAbility(side: .player, events: &events)
    }

    private func resolveFlee(_ events: inout [BattleEvent]) {
        guard !isTrainerBattle else {
            events.append(.message("You can't flee a Conductor duel. It's in the EULA."))
            return
        }
        fleeAttempts += 1
        let ps = Double(activeDaemon.battleStat(.spe))
        let es = Double(max(1, enemy.battleStat(.spe)))
        let chance = min(0.95, 0.35 + 0.2 * (ps / es) + 0.1 * Double(fleeAttempts))
        let success = rng.unit() < chance
        events.append(.fleeAttempt(success: success))
        if success {
            outcome = .fled
            events.append(.battleEnded(outcome: .fled))
        }
    }

    // MARK: - Helpers

    private func daemon(on side: Side) -> Daemon {
        side == .player ? party[activeIndex] : enemy
    }

    private func setDaemon(_ d: Daemon, on side: Side) {
        if side == .player { party[activeIndex] = d } else { enemy = d }
    }
}
