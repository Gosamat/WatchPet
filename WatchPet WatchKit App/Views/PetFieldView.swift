import SwiftUI

// MARK: - PetFieldView
/// Interactive pet habitat. The creature wanders, naps, eats food you drop,
/// and leaves the occasional surprise.
/// Responds to:
///   • Feed  → food appears at a random edge; pet walks over and eats it
///   • Clean → all poops vanish
///   • Crown scroll → floating hearts + happy bounce
struct PetFieldView: View {

    @EnvironmentObject var petVM: PetViewModel
    @ObservedObject private var cosmetics = CosmeticsManager.shared

    // ── Position ────────────────────────────────────────────────────────────
    @State private var petX: CGFloat    = 75
    @State private var petY: CGFloat    = 44
    @State private var goalX: CGFloat   = 75
    @State private var goalY: CGFloat   = 44
    @State private var facingRight      = true

    // ── Behaviour ───────────────────────────────────────────────────────────
    @State private var mode: FieldMode  = .idle
    @State private var modeTicks: Int   = 40

    // ── World items ─────────────────────────────────────────────────────────
    @State private var poops: [PoopDot]  = []
    @State private var foodPos: CGPoint? = nil
    @State private var poopClock: Int    = 0

    // ── Petting hearts ──────────────────────────────────────────────────────
    @State private var heartOpacity: Double  = 0
    @State private var heartOffset: CGFloat  = 0
    @State private var bouncing              = false

    // ── Field dimensions — read once via .background GeometryReader ─────────
    @State private var fw: CGFloat = 155
    @State private var fh: CGFloat = 82

    // ── Types ────────────────────────────────────────────────────────────────
    enum FieldMode: Equatable {
        case idle, walking, sleeping, eating, happy
    }
    struct PoopDot: Identifiable {
        let id = UUID(); let pos: CGPoint
    }

    // ── Layout constants ─────────────────────────────────────────────────────
    private var groundY: CGFloat  { fh * 0.72 }
    private var walkMinY: CGFloat { fh * 0.38 }
    private var walkMaxY: CGFloat { groundY - 8 }
    private let edgeMargin: CGFloat = 14
    private let petSpeed: CGFloat   = 1.1

    // MARK: - Body
    var body: some View {
        ZStack {
            // ── Background ────────────────────────────────────────────────
            LinearGradient(
                colors: [cosmetics.activeTheme.bgTop,
                         cosmetics.activeTheme.bgBottom.opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )

            // Ground strip
            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: fh * 0.28)
            }

            // Horizon line
            Path { p in
                p.move(to:    CGPoint(x: 0,  y: groundY))
                p.addLine(to: CGPoint(x: fw, y: groundY))
            }
            .stroke(Color.white.opacity(0.13), lineWidth: 0.6)

            // ── Poops ─────────────────────────────────────────────────────
            ForEach(poops) { d in
                Text("💩")
                    .font(.system(size: 8))
                    .position(d.pos)
                    .transition(.opacity)
            }

            // ── Food ──────────────────────────────────────────────────────
            if let fp = foodPos {
                Text("🍖")
                    .font(.system(size: 12))
                    .position(fp)
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
            }

            // ── Pet ───────────────────────────────────────────────────────
            petSpriteView
                .scaleEffect(x: facingRight ? 1 : -1, y: 1)
                .offset(y: bouncing ? -3 : 0)
                .animation(
                    .interpolatingSpring(stiffness: 350, damping: 6)
                        .repeatCount(5, autoreverses: true),
                    value: bouncing
                )
                .position(x: petX, y: petY)
                .animation(.linear(duration: 0.1), value: petX)
                .animation(.linear(duration: 0.1), value: petY)

            // ── ZZZ ───────────────────────────────────────────────────────
            if mode == .sleeping {
                Text("z z z")
                    .font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                    .position(x: min(petX + 16, fw - 18), y: max(petY - 13, 8))
                    .transition(.opacity)
            }

            // ── Stat bubbles (replace bars — visual storytelling only) ────
            statBubble
                .position(x: min(max(petX, 16), fw - 16),
                          y: max(petY - 22, 10))
                .transition(.scale(scale: 0.5).combined(with: .opacity))

            // ── Hearts ────────────────────────────────────────────────────
            if heartOpacity > 0 {
                Text("♥  ♥")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.pink.opacity(0.9))
                    .opacity(heartOpacity)
                    .position(x: petX, y: petY + heartOffset)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: mode == .sleeping)
        .animation(.easeInOut(duration: 0.5), value: petVM.pet.hunger)
        .animation(.easeInOut(duration: 0.5), value: petVM.pet.happiness)
        .animation(.easeInOut(duration: 0.5), value: petVM.pet.isSick)
        .frame(maxWidth: .infinity, minHeight: 82, maxHeight: 82)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        // ── Read field size without causing layout loops ───────────────────
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        fw = geo.size.width
                        fh = geo.size.height
                        initPositions()
                    }
            }
        )
        // ── Game loop — .task auto-cancels when view disappears ────────────
        .task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)  // 10 fps
                gameTick()
            }
        }
        // ── React to game events ──────────────────────────────────────────
        .onChange(of: petVM.lastFedDate)     { _ in placeFood() }
        .onChange(of: petVM.lastCleanedDate) { _ in clearPoops() }
        .onChange(of: petVM.crownPetCount)   { _ in showHearts() }
    }

    // MARK: - Pet sprite
    @ViewBuilder
    private var petSpriteView: some View {
        if let s = petVM.currentSpecies {
            PixelSpriteView(
                spritePrefix: s.spritePrefix,
                frameCount:   s.frameCount,
                fps:          (mode == .idle || mode == .sleeping) ? 1 : 4,
                pixelSize:    3
            )
            .frame(width: 30, height: 30)
        } else {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 30, height: 30)
        }
    }

    // MARK: - Stat bubble
    /// One contextual emoji floats above the pet communicating the most urgent stat.
    /// Priority: sick > hungry > unhappy > (cleanliness shown via poops)
    @ViewBuilder
    private var statBubble: some View {
        let p = petVM.pet
        if p.isSick {
            bubble("🤒")
        } else if p.health < 25 {
            bubble("💔")
        } else if p.hunger < 30 {
            bubble("🍖")
        } else if p.happiness < 30 {
            bubble("😢")
        } else if p.cleanlinessScore < 25 && poops.count >= 2 {
            bubble("🛁")
        }
        // else: nothing — pet is doing fine
    }

    private func bubble(_ emoji: String) -> some View {
        Text(emoji)
            .font(.system(size: 10))
            .padding(3)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 5))
    }

    // MARK: - Init
    private func initPositions() {
        let cx = fw / 2
        let cy = fh * 0.54
        petX = cx; petY = cy
        goalX = cx; goalY = cy
        pickNewGoal()
    }

    // MARK: - Game tick (10 fps via .task)
    private func gameTick() {
        stepPosition()
        stepMode()
        stepPoopClock()
    }

    private func stepPosition() {
        let speed = mode == .eating ? 1.5 : petSpeed
        let dx = goalX - petX
        let dy = goalY - petY
        let dist = hypot(dx, dy)
        guard dist > speed else { return }
        petX += dx / dist * speed
        petY += dy / dist * speed
        if abs(dx) > 0.2 { facingRight = dx > 0 }
    }

    private func stepMode() {
        switch mode {
        case .idle:
            modeTicks -= 1
            if modeTicks <= 0 { decideNext() }

        case .walking:
            if distToGoal < 2 {
                mode = .idle
                modeTicks = Int.random(in: 20...55)
                maybeDropPoop()
            }

        case .sleeping:
            modeTicks -= 1
            if modeTicks <= 0 { mode = .idle; modeTicks = 30 }

        case .eating:
            guard let fp = foodPos else { mode = .idle; modeTicks = 20; return }
            goalX = fp.x; goalY = fp.y
            if distToPoint(fp) < 6 {
                withAnimation(.easeOut(duration: 0.3)) { foodPos = nil }
                mode = .idle; modeTicks = 30
                HapticManager.shared.playSuccess()
            }

        case .happy:
            modeTicks -= 1
            if modeTicks <= 0 { mode = .idle; modeTicks = 20 }
        }
    }

    private func decideNext() {
        let roll = Int.random(in: 0..<10)
        if      roll < 5 { pickNewGoal(); mode = .walking }
        else if roll < 7 { mode = .sleeping; modeTicks = Int.random(in: 50...130) }
        else             { mode = .idle;     modeTicks = Int.random(in: 25...60)  }
    }

    private func stepPoopClock() {
        poopClock += 1
        guard poopClock >= 120, poops.count < 3 else {
            if poopClock >= 120 { poopClock = 0 }; return
        }
        poopClock = 0
        let dirt = max(0, 100 - petVM.pet.cleanlinessScore)
        guard Int.random(in: 0..<30) < dirt / 7 else { return }
        let px = CGFloat.random(in: edgeMargin...(fw - edgeMargin))
        let py = CGFloat.random(in: walkMinY...walkMaxY)
        withAnimation(.easeIn(duration: 0.3)) {
            poops.append(PoopDot(pos: CGPoint(x: px, y: py)))
        }
    }

    private func maybeDropPoop() {
        guard poops.count < 3,
              petVM.pet.cleanlinessScore < 65,
              Int.random(in: 0..<8) == 0 else { return }
        withAnimation(.easeIn(duration: 0.25)) {
            poops.append(PoopDot(pos: CGPoint(x: petX, y: petY)))
        }
    }

    // MARK: - Helpers
    private var distToGoal: CGFloat       { distToPoint(CGPoint(x: goalX, y: goalY)) }
    private func distToPoint(_ p: CGPoint) -> CGFloat { hypot(p.x - petX, p.y - petY) }

    private func pickNewGoal() {
        goalX = CGFloat.random(in: edgeMargin...(fw - edgeMargin))
        goalY = CGFloat.random(in: walkMinY...walkMaxY)
    }

    // MARK: - Event responses
    private func placeFood() {
        let onLeft = Bool.random()
        let fx: CGFloat = onLeft ? edgeMargin + 2 : fw - edgeMargin - 2
        let fy = CGFloat.random(in: walkMinY...walkMaxY)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            foodPos = CGPoint(x: fx, y: fy)
        }
        mode = .eating
    }

    private func clearPoops() {
        withAnimation(.easeOut(duration: 0.45)) { poops.removeAll() }
    }

    private func showHearts() {
        heartOffset = 0
        heartOpacity = 1.0
        withAnimation(.easeOut(duration: 1.15)) {
            heartOffset = -28
            heartOpacity = 0
        }
        bouncing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { bouncing = false }
        mode = .happy; modeTicks = 22
    }
}
