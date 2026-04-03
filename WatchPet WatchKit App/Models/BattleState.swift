import Foundation

// MARK: - BattleParticipant
struct BattleParticipant {
    let name: String
    var hp: Int
    let maxHP: Int
    let moves: [Move]
    let attributes: Attributes
    var isPlayer: Bool
}

// MARK: - BattleLogEntry
struct BattleLogEntry: Identifiable {
    let id = UUID()
    let text: String
}

// MARK: - BattleTurn
enum BattleTurn {
    case player, opponent
}

// MARK: - BattleResult
enum BattleResult {
    case playerWon, opponentWon
}

// MARK: - BattleState
// Pure value type — no side effects. The ViewModel drives it and applies outcomes.
struct BattleState {
    var player:   BattleParticipant
    var opponent: BattleParticipant
    var turn:     BattleTurn = .player
    var log:      [BattleLogEntry] = []
    var result:   BattleResult?

    var isOver: Bool { result != nil }

    // MARK: Player move
    mutating func executePlayerMove(_ move: Move) {
        guard turn == .player, !isOver else { return }
        let dmg = calculateDamage(move: move, attacker: player, defender: opponent)
        opponent.hp = max(0, opponent.hp - dmg)
        appendLog("\(player.name) used \(move.name)! \(dmg) dmg.")
        if opponent.hp == 0 {
            appendLog("\(player.name) wins!")
            result = .playerWon
            return
        }
        turn = .opponent
    }

    // MARK: AI move — returns updated state (caller must trigger this after player)
    mutating func executeAIMove() {
        guard turn == .opponent, !isOver else { return }
        let move = bestAIMove()
        let dmg  = calculateDamage(move: move, attacker: opponent, defender: player)
        player.hp = max(0, player.hp - dmg)
        appendLog("\(opponent.name) used \(move.name)! \(dmg) dmg.")
        if player.hp == 0 {
            appendLog("\(opponent.name) wins!")
            result = .opponentWon
            return
        }
        turn = .player
    }

    // MARK: Damage formula
    private func calculateDamage(move: Move, attacker: BattleParticipant, defender: BattleParticipant) -> Int {
        // Hit check
        guard Int.random(in: 1...100) <= move.accuracy else {
            return 0
        }

        var dmg = Double(move.basePower)

        // Attacker's relevant attribute boosts damage
        let attackStat: Int
        switch move.attributeBoost {
        case "athleticism": attackStat = attacker.attributes.athleticism
        case "combat":      attackStat = attacker.attributes.combat
        case "cuteness":    attackStat = attacker.attributes.cuteness
        case "wisdom":      attackStat = attacker.attributes.wisdom
        default:            attackStat = attacker.attributes.combat
        }
        dmg *= (1.0 + Double(attackStat) / 100.0)

        // Defender's athleticism provides a small damage reduction
        let defMult = 1.0 - Double(defender.attributes.athleticism) / 200.0
        dmg *= defMult

        // 10% crit chance
        if Double.random(in: 0..<1) < 0.10 {
            dmg *= 1.5
            appendLog("Critical hit!")
        }

        return max(1, Int(dmg))
    }

    private mutating func appendLog(_ text: String) {
        log.append(BattleLogEntry(text: text))
    }

    private func bestAIMove() -> Move {
        opponent.moves.max {
            calculateDamage(move: $0, attacker: opponent, defender: player) <
            calculateDamage(move: $1, attacker: opponent, defender: player)
        } ?? opponent.moves[0]
    }
}

// MARK: - Factory
extension BattleState {
    static func make(pet: VirtualPet, petSpecies: Species, opponentSpecies: Species) -> BattleState {
        let petHP      = 50 + pet.attributes.combat / 2
        let opponentHP = 50 + Int.random(in: 10...30)

        let player = BattleParticipant(
            name:       petSpecies.name,
            hp:         petHP,
            maxHP:      petHP,
            moves:      petSpecies.moves,
            attributes: pet.attributes,
            isPlayer:   true
        )
        let ai = BattleParticipant(
            name:       opponentSpecies.name,
            hp:         opponentHP,
            maxHP:      opponentHP,
            moves:      opponentSpecies.moves,
            attributes: Attributes(
                athleticism: Int.random(in: 10...40),
                combat:      Int.random(in: 10...40),
                cleanliness: 0,
                cuteness:    0,
                wisdom:      Int.random(in: 0...20)
            ),
            isPlayer: false
        )
        return BattleState(player: player, opponent: ai)
    }
}
