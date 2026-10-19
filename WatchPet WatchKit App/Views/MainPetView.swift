import SwiftUI

// MARK: - Design Tokens
private extension Color {
    static let bgDeep      = Color(red: 0.02, green: 0.04, blue: 0.10)
    static let bgPanel     = Color(red: 0.04, green: 0.08, blue: 0.16)
    static let accentBlue  = Color(red: 0.00, green: 0.83, blue: 1.00)   // #00D4FF
    static let accentViolet = Color(red: 0.55, green: 0.36, blue: 0.96)  // #8B5CF6
    static let neonGreen   = Color(red: 0.22, green: 1.00, blue: 0.08)   // #39FF14
    static let neonOrange  = Color(red: 1.00, green: 0.27, blue: 0.00)   // #FF4500
    static let goldYellow  = Color(red: 1.00, green: 0.84, blue: 0.00)   // #FFD700
}

// MARK: - MainPetView
struct MainPetView: View {

    @EnvironmentObject var petVM: PetViewModel
    @ObservedObject private var cosmetics = CosmeticsManager.shared
    @State private var showCareMenu     = false
    @State private var showStats        = false
    @State private var navigateToBattle = false
    @State private var glowPulse        = false   // used only for egg card
    @State private var gridOpacity      = 0.04

    // Digital Crown petting
    @State private var crownValue: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Themed background
                LinearGradient(
                    colors: [cosmetics.activeTheme.bgTop, cosmetics.activeTheme.bgBottom],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                // Animated circuit grid overlay
                CircuitGridBackground(color: cosmetics.activeTheme.gridColor, opacity: gridOpacity)
                    .ignoresSafeArea()
                    .onAppear {
                        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                            gridOpacity = 0.09
                        }
                    }

                VStack(spacing: 5) {

                    // MARK: Nameplate strip
                    nameplateRow

                    // MARK: Pet display — egg card while hatching, field otherwise
                    petDisplay

                    if !petVM.pet.isEgg && !petVM.pet.isEvolutionEgg {
                        // MARK: HP Bar — only explicit bar; other stats shown visually in the field
                        hpBar
                            .padding(.horizontal, 4)
                    } else {
                        // Show shake progress as text prompt while egg
                        Text("\(Int(petVM.shakeProgress * 100))% hatched")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.45))
                    }

                    // MARK: Action buttons — two rows to avoid bezel overflow
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            NeonButton(label: "Care",  gradient: careGradient)  { showCareMenu = true }
                                .disabled(petVM.pet.isEgg || petVM.pet.isEvolutionEgg)
                            NeonButton(label: "Fight", gradient: fightGradient) { navigateToBattle = true }
                                .disabled(petVM.pet.isEgg || petVM.pet.isEvolutionEgg)
                        }
                        NeonButton(label: "Stats", gradient: statsGradient) { showStats = true }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 2)
                }
                .padding(.horizontal, 2)
            }
            .navigationDestination(isPresented: $navigateToBattle) {
                BattleSetupView()
                    .environmentObject(petVM)
            }
            .sheet(isPresented: $showCareMenu) {
                CareMenuView().environmentObject(petVM)
            }
            .sheet(isPresented: $showStats) {
                StatsView().environmentObject(petVM)
            }
            .sheet(isPresented: Binding(
                get: { petVM.pendingEvolution != nil && !petVM.isEvolving },
                set: { _ in }
            )) {
                EvolutionView().environmentObject(petVM)
            }
            .sheet(isPresented: $petVM.showPaywall) {
                PaywallView().environmentObject(petVM)
            }
        }
        .onAppear { petVM.onAppear() }
        .onDisappear { petVM.onDisappear() }
        .onReceive(NotificationCenter.default.publisher(for: .fullGameUnlocked)) { _ in
            petVM.onFullGamePurchased()
        }
        // ── Digital Crown petting ─────────────────────────────────────────
        // Simple unbounded form — no range params that can crash watchOS
        .digitalCrownRotation($crownValue)
        .onChange(of: crownValue) { _ in
            guard !petVM.pet.isEgg, !petVM.pet.isEvolutionEgg else { return }
            petVM.handleCrownRotation(delta: 0.5)
        }
    }

    // MARK: - Gradients
    private var careGradient: LinearGradient {
        LinearGradient(colors: [Color(red: 1.00, green: 0.55, blue: 0.00), Color(red: 0.90, green: 0.25, blue: 0.50)],
                       startPoint: .leading, endPoint: .trailing)
    }
    private var fightGradient: LinearGradient {
        LinearGradient(colors: [Color(red: 1.00, green: 0.27, blue: 0.00), Color(red: 0.70, green: 0.00, blue: 0.60)],
                       startPoint: .leading, endPoint: .trailing)
    }
    private var statsGradient: LinearGradient {
        LinearGradient(colors: [Color.accentBlue, Color.accentViolet],
                       startPoint: .leading, endPoint: .trailing)
    }

    // MARK: - Nameplate Row
    private var nameplateRow: some View {
        HStack(spacing: 5) {
            stageBadge
            if petVM.pet.isEgg {
                Text("???")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            } else if petVM.pet.isEvolutionEgg {
                Text("Evolving…")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(Color.accentViolet)
                    .shadow(color: Color.accentViolet.opacity(0.6), radius: 4)
            } else {
                Text(petVM.currentSpecies?.name ?? "???")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: Color.accentBlue.opacity(0.6), radius: 4)
            }
            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.top, 2)
    }

    private var stageBadge: some View {
        let label: String
        if petVM.pet.isEgg || petVM.pet.isEvolutionEgg {
            label = "EGG"
        } else {
            let stages = ["BABY", "CHILD", "ADULT"]
            label = stages[min(petVM.pet.stage, 2)]
        }
        return Text(label)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(Color.accentBlue)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background {
                Capsule()
                    .fill(Color.accentBlue.opacity(0.12))
                    .overlay(Capsule().strokeBorder(Color.accentBlue.opacity(0.35), lineWidth: 1))
            }
    }

    // MARK: - Pet Display (field when alive, egg card when hatching)

    @ViewBuilder
    private var petDisplay: some View {
        if petVM.pet.isEgg || petVM.pet.isEvolutionEgg || petVM.isEvolving {
            eggCard
        } else {
            PetFieldView()
                .environmentObject(petVM)
                .padding(.horizontal, 4)
                .onTapGesture { showCareMenu = true }
        }
    }

    // MARK: - Egg Card (shown only during egg / evolution states)
    private var eggCard: some View {
        ZStack {
            // Outer glow halo
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.accentBlue.opacity(0.06))
                .frame(width: 100, height: 100)
                .shadow(color: Color.accentBlue.opacity(glowPulse ? 0.55 : 0.25), radius: glowPulse ? 12 : 6)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        glowPulse = true
                    }
                }

            // Card face
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Color.bgPanel, Color(red: 0.05, green: 0.12, blue: 0.22)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 96)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.accentBlue.opacity(0.25), lineWidth: 1)
                )

            // Content — only egg/evolution states reach here
            if petVM.isEvolving || petVM.pet.isEvolutionEgg {
                evolutionFlash
            } else {
                eggHatchView
            }
        }
        .onTapGesture { showCareMenu = true }
    }

    // MARK: - HP Bar
    private var hpBar: some View {
        let hp    = petVM.pet.effectiveHP
        let maxHP = petVM.pet.maxHP
        let frac  = CGFloat(hp) / CGFloat(max(1, maxHP))
        let fillColor: Color = frac > 0.5 ? .neonGreen : frac > 0.25 ? .goldYellow : .neonOrange
        let glowColor: Color = frac > 0.5 ? .neonGreen : frac > 0.25 ? .goldYellow : .neonOrange

        return HStack(spacing: 4) {
            Text("HP")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.accentBlue)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [fillColor, fillColor.opacity(0.7)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * frac)
                        .shadow(color: glowColor.opacity(0.6), radius: 3)
                }
            }
            .frame(height: 7)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: frac)

            Text("\(hp)/\(maxHP)")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(.white.opacity(0.65))
                .frame(width: 30, alignment: .trailing)
        }
    }

    // MARK: - Egg Hatch View
    private var eggHatchView: some View {
        let isEvolutionEgg = petVM.pet.isEvolutionEgg
        let progress = petVM.shakeProgress
        let ringColor: Color = isEvolutionEgg ? .accentViolet : .accentBlue

        return ZStack {
            // Progress ring around egg
            Circle()
                .strokeBorder(ringColor.opacity(0.15), lineWidth: 4)
                .frame(width: 72, height: 72)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(ringColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 72, height: 72)
                .shadow(color: ringColor.opacity(0.6), radius: 4)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: progress)

            PixelSpriteView(
                spritePrefix: isEvolutionEgg ? "egg_evolution" : "egg_normal",
                frameCount: 2,
                pixelSize: 4
            )

            // "SHAKE" prompt at bottom
            VStack {
                Spacer()
                Text("SHAKE")
                    .font(.system(size: 7, weight: .black, design: .monospaced))
                    .foregroundStyle(ringColor.opacity(0.8))
                    .offset(y: 40)
            }
            .frame(width: 80, height: 80)
        }
    }

    // MARK: - Evolution Flash
    private var evolutionFlash: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .strokeBorder(
                        LinearGradient(colors: [Color.accentBlue, Color.accentViolet],
                                       startPoint: .top, endPoint: .bottom),
                        lineWidth: 1.5
                    )
                    .scaleEffect(glowPulse ? 1.0 + CGFloat(i) * 0.3 : 0.7 + CGFloat(i) * 0.3)
                    .opacity(glowPulse ? 0.2 : 0.6)
                    .animation(
                        .easeInOut(duration: 0.7).repeatForever(autoreverses: true).delay(Double(i) * 0.2),
                        value: glowPulse
                    )
            }
            Image(systemName: "sparkles")
                .font(.system(size: 26))
                .foregroundStyle(
                    LinearGradient(colors: [Color.goldYellow, Color.accentBlue],
                                   startPoint: .top, endPoint: .bottom)
                )
                .scaleEffect(glowPulse ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: glowPulse)
        }
    }
}

// MARK: - CircuitGridBackground
private struct CircuitGridBackground: View {
    var color: Color = Color(red: 0.00, green: 0.83, blue: 1.00)
    var opacity: Double

    var body: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 22
            ctx.opacity = opacity

            var path = Path()
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            ctx.stroke(path, with: .color(color), lineWidth: 0.4)

            var dotPath = Path()
            var gx: CGFloat = 0
            while gx <= size.width {
                var gy: CGFloat = 0
                while gy <= size.height {
                    dotPath.addEllipse(in: CGRect(x: gx - 1, y: gy - 1, width: 2, height: 2))
                    gy += spacing
                }
                gx += spacing
            }
            ctx.fill(dotPath, with: .color(color))
        }
    }
}

// MARK: - NeonStatBar
private struct NeonStatBar: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(label).font(.system(size: 10))
                .frame(width: 16)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.07))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.6)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                        .shadow(color: color.opacity(0.4), radius: 2)
                }
            }
            .frame(height: 6)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)

            Text("\(value)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.60))
                .frame(width: 22, alignment: .trailing)
        }
    }
}

// MARK: - NeonButton
struct NeonButton: View {
    let label:    String
    let gradient: LinearGradient
    let action:   () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(gradient, in: RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - WatchButton (kept for BattleSetupView compatibility)
struct WatchButton: View {
    let label:  String
    let action: () -> Void

    var body: some View {
        NeonButton(
            label: label,
            gradient: LinearGradient(
                colors: [Color(red: 0.00, green: 0.83, blue: 1.00), Color(red: 0.55, green: 0.36, blue: 0.96)],
                startPoint: .leading, endPoint: .trailing
            ),
            action: action
        )
    }
}

#Preview {
    MainPetView()
        .environmentObject(PetViewModel())
}
