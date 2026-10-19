import SwiftUI

// MARK: - BattleView
struct BattleView: View {

    @ObservedObject var battleVM: BattleViewModel
    @EnvironmentObject var petVM: PetViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var bgPulse = false

    var body: some View {
        ZStack {
            // Battle background — dark crimson atmosphere
            battleBackground

            if let battle = battleVM.battle {
                VStack(spacing: 4) {
                    battleField(battle: battle)
                    battleLog
                    controls(battle: battle)
                }
                .padding(.horizontal, 5)
                .padding(.bottom, 4)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                bgPulse = true
            }
        }
    }

    // MARK: - Background
    private var battleBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.02, blue: 0.02),
                    Color(red: 0.04, green: 0.01, blue: 0.08)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle radial danger glow from center
            RadialGradient(
                colors: [Color(red: 0.60, green: 0.00, blue: 0.00).opacity(bgPulse ? 0.20 : 0.08), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 110
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Battle Field
    private func battleField(battle: BattleState) -> some View {
        ZStack(alignment: .topLeading) {
            // Ground separator line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color(red: 1.00, green: 0.27, blue: 0.00).opacity(0.5), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .offset(y: 58)

            VStack(spacing: 0) {
                // Enemy row — top area
                HStack(alignment: .bottom) {
                    battleHPCard(
                        name:      battle.opponent.name,
                        hp:        battle.opponent.hp,
                        maxHP:     battle.opponent.maxHP,
                        isPlayer:  false
                    )
                    Spacer(minLength: 4)
                    // Enemy sprite with looming scale
                    VStack(spacing: 0) {
                        EnemySprite(pixelSize: 2)
                            .scaleEffect(x: 1.0, y: 1.05)  // slight looming tilt
                            .shadow(color: Color(red: 1.00, green: 0.27, blue: 0.00).opacity(0.5), radius: 4)
                        Spacer().frame(height: 4)
                    }
                }
                .frame(height: 38)

                // Player row — bottom area
                HStack(alignment: .top) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 4)
                        if let s = petVM.currentSpecies {
                            PixelSpriteView(
                                spritePrefix: s.spritePrefix,
                                frameCount:   s.frameCount,
                                fps:          4,
                                pixelSize:    2
                            )
                            .shadow(color: Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.5), radius: 4)
                        }
                    }
                    Spacer(minLength: 4)
                    battleHPCard(
                        name:      battle.player.name,
                        hp:        battle.player.hp,
                        maxHP:     battle.player.maxHP,
                        isPlayer:  true
                    )
                }
                .frame(height: 38)
            }
        }
        .frame(height: 76)
    }

    private func battleHPCard(name: String, hp: Int, maxHP: Int, isPlayer: Bool) -> some View {
        let frac      = Double(max(0, hp)) / Double(max(1, maxHP))
        let fillStart: Color = frac > 0.5 ? Color(red: 0.22, green: 1.00, blue: 0.08)
                             : frac > 0.25 ? Color(red: 1.00, green: 0.84, blue: 0.00)
                             : Color(red: 1.00, green: 0.27, blue: 0.00)
        let fillEnd   = fillStart.opacity(0.65)
        let alignment: HorizontalAlignment = isPlayer ? .trailing : .leading

        return VStack(alignment: alignment, spacing: 2) {
            Text(name)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: isPlayer ? .trailing : .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.10))
                    // Fill — chunky with one sharp edge
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(colors: [fillStart, fillEnd],
                                           startPoint: isPlayer ? .trailing : .leading,
                                           endPoint:   isPlayer ? .leading  : .trailing)
                        )
                        .frame(width: geo.size.width * CGFloat(frac))
                        .shadow(color: fillStart.opacity(0.5), radius: 2)
                }
            }
            .frame(height: 6)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: hp)

            Text("\(hp)/\(maxHP)")
                .font(.system(size: 7, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(width: 70)
        .padding(.horizontal, 5).padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.04, green: 0.00, blue: 0.10).opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
    }

    // MARK: - Battle Log (terminal style)
    private var battleLog: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(battleVM.recentLog) { entry in
                HStack(spacing: 3) {
                    Text(">")
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.7))
                    Text(entry.text)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 30, alignment: .topLeading)
        .padding(.horizontal, 6).padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.15), lineWidth: 1)
                )
        }
    }

    // MARK: - Controls
    @ViewBuilder
    private func controls(battle: BattleState) -> some View {
        if battleVM.showResult {
            resultView(won: battle.result == .playerWon)
        } else if battle.turn == .player && !battleVM.isProcessingAI {
            movesGrid(moves: battle.player.moves)
        } else {
            HStack(spacing: 6) {
                ProgressView().tint(Color(red: 0.00, green: 0.83, blue: 1.00))
                Text("Processing…")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }

    private func movesGrid(moves: [Move]) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 5), GridItem(.flexible(), spacing: 5)],
            spacing: 5
        ) {
            ForEach(moves) { move in
                MoveButton(move: move) {
                    battleVM.playerMove(move)
                }
            }
        }
    }

    private func resultView(won: Bool) -> some View {
        ZStack {
            // Particle circles effect
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(won ? Color(red: 0.22, green: 1.00, blue: 0.08).opacity(0.15)
                              : Color(red: 1.00, green: 0.27, blue: 0.00).opacity(0.15))
                    .frame(width: CGFloat(16 + i * 10), height: CGFloat(16 + i * 10))
                    .scaleEffect(bgPulse ? 1.0 : 0.5)
                    .opacity(bgPulse ? 0.0 : 0.3)
                    .animation(
                        .easeOut(duration: 1.4).repeatForever(autoreverses: false).delay(Double(i) * 0.2),
                        value: bgPulse
                    )
            }

            VStack(spacing: 5) {
                Text(won ? "VICTORY!" : "DEFEATED")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(
                        won
                        ? LinearGradient(colors: [Color(red: 0.22, green: 1.00, blue: 0.08), Color(red: 0.00, green: 0.83, blue: 1.00)],
                                         startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color(red: 1.00, green: 0.27, blue: 0.00), Color(red: 0.80, green: 0.00, blue: 0.40)],
                                         startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(color: won ? Color(red: 0.22, green: 1.00, blue: 0.08).opacity(0.8) : Color(red: 1.00, green: 0.27, blue: 0.00).opacity(0.8), radius: 6)

                if !won {
                    Text("Resting to 1 HP…")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Button("DONE") {
                    battleVM.dismissBattle()
                    dismiss()
                }
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14).padding(.vertical, 5)
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: won
                                ? [Color(red: 0.00, green: 0.83, blue: 1.00), Color(red: 0.55, green: 0.36, blue: 0.96)]
                                : [Color(red: 0.55, green: 0.36, blue: 0.96), Color(red: 1.00, green: 0.27, blue: 0.00)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                )
                .buttonStyle(.plain)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.85)))
    }
}

// MARK: - MoveButton
private struct MoveButton: View {
    let move:   Move
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(move.name)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("PWR \(move.basePower)")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background {
                RoundedRectangle(cornerRadius: 7)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.20, green: 0.05, blue: 0.35),
                                     Color(red: 0.10, green: 0.02, blue: 0.20)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .strokeBorder(
                                Color(red: 0.00, green: 0.83, blue: 1.00).opacity(isPressed ? 0.8 : 0.30),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color(red: 0.55, green: 0.36, blue: 0.96).opacity(isPressed ? 0.6 : 0.0), radius: 4)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.94 : 1.0)
        .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - EnemySprite
private struct EnemySprite: View {
    var pixelSize: CGFloat = 2

    // 0=transparent 1=red-orange body 2=yellow eyes 3=dark mouth 4=white teeth
    private static let frames: [[[Int]]] = [
        // Frame 0
        [
            [0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0],
            [0,0,1,1,0,0,0,0,0,0,0,0,1,1,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
            [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
            [0,1,1,2,2,2,1,1,1,1,2,2,2,1,1,0],
            [0,1,1,1,2,1,1,1,1,1,1,2,1,1,1,0],
            [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
            [0,1,1,1,3,3,3,3,3,3,3,3,3,1,1,0],
            [0,1,1,1,4,3,4,3,4,3,4,3,4,1,1,0],
            [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
            [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
            [0,0,0,0,1,1,0,0,0,0,1,1,0,0,0,0],
            [0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
        ],
        // Frame 1 — bounce down
        [
            [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
            [0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0],
            [0,0,1,1,0,0,0,0,0,0,0,0,1,1,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
            [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
            [0,1,1,2,2,2,1,1,1,1,2,2,2,1,1,0],
            [0,1,1,1,2,1,1,1,1,1,1,2,1,1,1,0],
            [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
            [0,1,1,1,3,3,3,3,3,3,3,3,3,1,1,0],
            [0,1,1,1,4,3,4,3,4,3,4,3,4,1,1,0],
            [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
            [0,0,0,0,1,1,0,0,0,0,1,1,0,0,0,0],
            [0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
        ],
    ]

    private static let palette: [Int: Color] = [
        1: Color(red: 0.88, green: 0.22, blue: 0.12),
        2: Color(red: 1.00, green: 0.85, blue: 0.10),
        3: Color(red: 0.12, green: 0.04, blue: 0.04),
        4: Color(red: 0.95, green: 0.95, blue: 0.95),
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.5)) { timeline in
            let frame = Int(timeline.date.timeIntervalSinceReferenceDate * 2) % 2
            Canvas { ctx, _ in
                let grid = Self.frames[frame]
                for row in 0..<grid.count {
                    for col in 0..<grid[row].count {
                        let idx = grid[row][col]
                        guard idx != 0, let color = Self.palette[idx] else { continue }
                        ctx.fill(
                            Path(CGRect(x: CGFloat(col) * pixelSize,
                                        y: CGFloat(row) * pixelSize,
                                        width: pixelSize, height: pixelSize)),
                            with: .color(color)
                        )
                    }
                }
            }
            .frame(width: 16 * pixelSize, height: 16 * pixelSize)
        }
    }
}

#Preview {
    let vm  = PetViewModel()
    let bvm = BattleViewModel(petVM: vm)
    return BattleView(battleVM: bvm).environmentObject(vm)
}
