import SwiftUI

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var connectivity = PhoneConnectivityManager.shared

    var body: some View {
        TabView {
            CompendiumTabView()
                .tabItem { Label("Compendium", systemImage: "book.closed.fill") }

            StoreTabView()
                .tabItem { Label("Store", systemImage: "bag.fill") }

            SettingsTabView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environmentObject(connectivity)
        .tint(Color(red: 0.00, green: 0.83, blue: 1.00))
    }
}

// MARK: - Shared design tokens
private extension Color {
    static let bgDeep      = Color(red: 0.04, green: 0.06, blue: 0.14)
    static let accentBlue  = Color(red: 0.00, green: 0.83, blue: 1.00)
    static let accentViolet = Color(red: 0.55, green: 0.36, blue: 0.96)
    static let neonGreen   = Color(red: 0.22, green: 1.00, blue: 0.08)
    static let goldYellow  = Color(red: 1.00, green: 0.84, blue: 0.00)
}

// MARK: - Species data (mirrors EvolutionData.json)
// Hardcoded here so the phone app doesn't need to bundle the Watch's asset folder.
private struct PhoneSpecies: Identifiable {
    let id: String
    let name: String
    let stage: Int
    let description: String
    let moves: [(name: String, power: Int)]
}

private let allSpecies: [PhoneSpecies] = [
    .init(id: "baby_flame",   name: "Flameling",  stage: 0,
          description: "A feisty little flame lizard. Its tiny horn glows when excited.",
          moves: [("Tackle", 10), ("Ember", 14)]),
    .init(id: "baby_sprout",  name: "Sproutling", stage: 0,
          description: "A round green blob with a single leaf on its head. Loves sunlight.",
          moves: [("Tackle", 10), ("Leaf Slap", 12)]),
    .init(id: "baby_spark",   name: "Sparky",     stage: 0,
          description: "A tiny cube with a bouncy antenna. Buzzes with static electricity.",
          moves: [("Tackle", 10), ("Zap", 13)]),
    .init(id: "baby_shadow",  name: "Shady",      stage: 0,
          description: "A dark teardrop with glowing purple eyes. It watches everything silently.",
          moves: [("Tackle", 10), ("Glare", 12)]),
    .init(id: "child_dragon", name: "Drakeling",  stage: 1,
          description: "A growing dragon with wing nubs. Its roar can scorch the air.",
          moves: [("Scratch", 18), ("Ember", 20), ("Bite", 28)]),
    .init(id: "child_flora",  name: "Florakat",   stage: 1,
          description: "A cat-like creature adorned with leaves and vines. Stealthy and fast.",
          moves: [("Scratch", 18), ("Vine Whip", 22), ("Cute Eyes", 25)]),
    .init(id: "child_circuit",name: "Circuiton",  stage: 1,
          description: "A robotic owl with spinning gears and circuit-board wings.",
          moves: [("Scratch", 18), ("Shock Pulse", 21), ("Overclock", 26)]),
    .init(id: "child_phantom",name: "Phantomix",  stage: 1,
          description: "A ghostly cat wreathed in shadow flames. Phases through walls.",
          moves: [("Scratch", 18), ("Shadow Claw", 23), ("Terror Gaze", 24)]),
    .init(id: "adult_inferno",name: "Infernox",   stage: 2,
          description: "A towering fire dragon whose wings blot out the sun.",
          moves: [("Blazing Fist", 40), ("Inferno Breath", 45), ("Dragon Rage", 50)]),
    .init(id: "adult_gaia",   name: "Gaiathorn",  stage: 2,
          description: "An ancient tree-beast crowned with flowering horns.",
          moves: [("Root Slam", 38), ("Petal Storm", 42), ("Nature's Wrath", 48)]),
    .init(id: "adult_voltron",name: "Voltronix",  stage: 2,
          description: "A mechanical giant bristling with plasma cannons.",
          moves: [("Plasma Burst", 40), ("Circuit Storm", 44), ("Overcharge", 52)]),
    .init(id: "adult_eclipse",name: "Eclipsion",  stage: 2,
          description: "A void-born wraith that eclipses light wherever it drifts.",
          moves: [("Shadow Surge", 42), ("Void Pulse", 46), ("Eclipse Beam", 55)]),
]

// MARK: - Compendium Tab
struct CompendiumTabView: View {
    @EnvironmentObject var connectivity: PhoneConnectivityManager
    @State private var selectedSpecies: PhoneSpecies? = nil

    private var seenIDs: Set<String> {
        Set(connectivity.petSnapshot?.seenSpeciesIDs ?? [])
    }

    private var discoveredCount: Int { allSpecies.filter { seenIDs.contains($0.id) }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Progress banner
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Creatures Discovered")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(discoveredCount) / \(allSpecies.count)")
                                .font(.title2.bold())
                        }
                        Spacer()
                        CircularProgress(value: Double(discoveredCount) / Double(allSpecies.count))
                            .frame(width: 52, height: 52)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)

                    // Grid by stage
                    ForEach(0..<3) { stage in
                        let stageSpecies = allSpecies.filter { $0.stage == stage }
                        if !stageSpecies.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(["Baby Forms", "Child Forms", "Adult Forms"][stage])
                                    .font(.headline)
                                    .padding(.horizontal)

                                LazyVGrid(
                                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                                    spacing: 12
                                ) {
                                    ForEach(stageSpecies) { sp in
                                        CompendiumCard(
                                            species: sp,
                                            isDiscovered: seenIDs.contains(sp.id)
                                        )
                                        .onTapGesture {
                                            if seenIDs.contains(sp.id) {
                                                selectedSpecies = sp
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    syncFooter
                }
                .padding(.top)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Compendium")
            .sheet(item: $selectedSpecies) { sp in
                SpeciesDetailSheet(species: sp)
            }
        }
    }

    private var syncFooter: some View {
        HStack(spacing: 6) {
            Image(systemName: connectivity.isWatchReachable ? "applewatch" : "applewatch.slash")
                .foregroundStyle(connectivity.isWatchReachable ? .green : .secondary)
                .font(.caption)
            if let date = connectivity.lastSyncDate {
                Text("Last sync: \(date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Open WatchPet on your watch to sync")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom)
    }
}

// MARK: - Compendium Card
private struct CompendiumCard: View {
    let species: PhoneSpecies
    let isDiscovered: Bool

    var stageColor: Color {
        [Color.neonGreen, Color.accentBlue, Color.accentViolet][species.stage]
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDiscovered
                          ? stageColor.opacity(0.10)
                          : Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isDiscovered ? stageColor.opacity(0.4) : Color.clear, lineWidth: 1.5)
                    )

                if isDiscovered {
                    // Large pixel art placeholder — real SpriteKit/image would go here
                    VStack(spacing: 2) {
                        Text(speciesEmoji)
                            .font(.system(size: 36))
                        Text(species.name)
                            .font(.caption2.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    .padding(8)
                } else {
                    VStack(spacing: 4) {
                        Text("?")
                            .font(.system(size: 36, weight: .black, design: .monospaced))
                            .foregroundStyle(.quaternary)
                        Text("???")
                            .font(.caption2.bold())
                            .foregroundStyle(.quaternary)
                    }
                    .padding(8)
                }
            }
            .frame(height: 90)
        }
    }

    // Quick emoji stand-in per species until full art assets are bundled
    private var speciesEmoji: String {
        switch species.id {
        case "baby_flame":    return "🔥"
        case "baby_sprout":   return "🌱"
        case "baby_spark":    return "⚡️"
        case "baby_shadow":   return "👁"
        case "child_dragon":  return "🐉"
        case "child_flora":   return "🌿"
        case "child_circuit": return "🤖"
        case "child_phantom": return "👻"
        case "adult_inferno": return "🌋"
        case "adult_gaia":    return "🌳"
        case "adult_voltron": return "⚙️"
        case "adult_eclipse": return "🌑"
        default:              return "❓"
        }
    }
}

// MARK: - Species Detail Sheet
private struct SpeciesDetailSheet: View {
    let species: PhoneSpecies
    @Environment(\.dismiss) private var dismiss

    var stageLabel: String { ["Baby", "Child", "Adult"][species.stage] }
    var stageColor: Color {
        [Color.neonGreen, Color.accentBlue, Color.accentViolet][species.stage]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero art area
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [stageColor.opacity(0.15), stageColor.opacity(0.05)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                        Text(speciesEmoji)
                            .font(.system(size: 80))
                            .padding(30)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 4) {
                        Text(species.name)
                            .font(.largeTitle.bold())
                        Text(stageLabel + " Form")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12).padding(.vertical, 4)
                            .background(stageColor.opacity(0.15), in: Capsule())
                    }

                    Text(species.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Moves
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Move Pool")
                            .font(.headline)
                        ForEach(species.moves, id: \.name) { move in
                            HStack {
                                Text(move.name)
                                    .font(.subheadline)
                                Spacer()
                                Text("PWR \(move.power)")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(stageColor)
                            }
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var speciesEmoji: String {
        switch species.id {
        case "baby_flame":    return "🔥"
        case "baby_sprout":   return "🌱"
        case "baby_spark":    return "⚡️"
        case "baby_shadow":   return "👁"
        case "child_dragon":  return "🐉"
        case "child_flora":   return "🌿"
        case "child_circuit": return "🤖"
        case "child_phantom": return "👻"
        case "adult_inferno": return "🌋"
        case "adult_gaia":    return "🌳"
        case "adult_voltron": return "⚙️"
        case "adult_eclipse": return "🌑"
        default:              return "❓"
        }
    }
}

// MARK: - Store Tab
struct StoreTabView: View {
    @EnvironmentObject var connectivity: PhoneConnectivityManager

    private let cosmetics: [(id: String, icon: String, name: String, subtitle: String, color: Color)] = [
        ("com.watchpet.theme.gameboy",    "🎮", "Gameboy Green",   "Classic monochrome LCD palette",     .green),
        ("com.watchpet.theme.virtualboy", "🔴", "Virtual Boy",     "Deep red stereoscopic palette",      .red),
        ("com.watchpet.theme.oled",       "⬛️", "OLED Dark",       "Pure black for OLED displays",       Color(white: 0.5)),
        ("com.watchpet.theme.sakura",     "🌸", "Sakura Pink",     "Soft cherry-blossom palette",        .pink),
        ("com.watchpet.theme.halloween",  "🎃", "Spooky 👻",       "Limited seasonal — Oct/Nov",         .orange),
        ("com.watchpet.theme.winter",     "❄️", "Winter",          "Limited seasonal — Dec/Jan",         .cyan),
    ]

    var body: some View {
        NavigationStack {
            List {
                // Pet status
                Section {
                    petStatusBanner
                } header: { Text("Your Pet") }

                // Full game unlock — the main revenue driver
                Section {
                    fullGameUnlockRow
                } header: {
                    Text("Full Game")
                } footer: {
                    Text("One-time purchase. Own it forever. No subscriptions, no pay-to-win mechanics.")
                        .font(.caption2)
                }

                // Cosmetics — purely visual
                Section {
                    ForEach(cosmetics, id: \.id) { item in
                        StoreRow(
                            icon: item.icon,
                            title: item.name,
                            subtitle: item.subtitle,
                            price: "$0.99",
                            gradient: LinearGradient(colors: [item.color.opacity(0.8), item.color], startPoint: .leading, endPoint: .trailing)
                        ) {
                            connectivity.sendAction("iap_theme", payload: ["themeID": item.id])
                        }
                    }
                } header: {
                    Text("Watch Themes")
                } footer: {
                    Text("Purely cosmetic. Changes your watch's color palette. Zero effect on gameplay.")
                        .font(.caption2)
                }

                Section {
                    Button {
                        connectivity.sendAction("restore_purchases")
                    } label: {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle("Store")
        }
    }

    private var fullGameUnlockRow: some View {
        HStack(spacing: 14) {
            Text("🐉")
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(colors: [Color(red: 0.00, green: 0.83, blue: 1.00),
                                            Color(red: 0.55, green: 0.36, blue: 0.96)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 10)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("Unlock Full Game")
                    .font(.headline)
                Text("All 12 creatures · Arena · No subscriptions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("$3.99") {
                connectivity.sendAction("iap_full_game")
            }
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(
                LinearGradient(colors: [Color(red: 0.00, green: 0.83, blue: 1.00),
                                        Color(red: 0.55, green: 0.36, blue: 0.96)],
                               startPoint: .leading, endPoint: .trailing),
                in: Capsule()
            )
        }
        .padding(.vertical, 4)
    }

    private var petStatusBanner: some View {
        HStack(spacing: 14) {
            if let pet = connectivity.petSnapshot {
                VStack(alignment: .leading, spacing: 2) {
                    Text(pet.isEgg ? "Your egg is waiting…" : "Pet is active")
                        .font(.headline)
                    Text("Wellness \(pet.wellness)% · Age \(pet.ageString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ProgressView(value: Double(pet.wellness) / 100)
                    .progressViewStyle(.circular)
                    .tint(pet.wellness > 60 ? .green : pet.wellness > 30 ? .orange : .red)
                    .frame(width: 36, height: 36)
            } else {
                Label("Open WatchPet on your watch", systemImage: "applewatch")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Store Row
private struct StoreRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let price: String
    let gradient: LinearGradient
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(icon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(gradient, in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Button(price) { action() }
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(.blue, in: Capsule())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settings Tab
struct SettingsTabView: View {
    @EnvironmentObject var connectivity: PhoneConnectivityManager
    @State private var careReminders = true
    @State private var discoveryAlerts = true
    @State private var evolutionAlerts = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Watch Status") {
                    HStack {
                        Label("Watch Reachable", systemImage: "applewatch")
                        Spacer()
                        Text(connectivity.isWatchReachable ? "Yes" : "No")
                            .foregroundStyle(connectivity.isWatchReachable ? .green : .secondary)
                    }
                    if let date = connectivity.lastSyncDate {
                        HStack {
                            Label("Last Sync", systemImage: "arrow.clockwise")
                            Spacer()
                            Text(date.formatted(date: .omitted, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Notifications") {
                    Toggle(isOn: $careReminders) {
                        Label("Care Reminders", systemImage: "bell.badge")
                    }
                    Toggle(isOn: $discoveryAlerts) {
                        Label("New Discovery Alerts", systemImage: "magnifyingglass")
                    }
                    Toggle(isOn: $evolutionAlerts) {
                        Label("Evolution Ready", systemImage: "sparkles")
                    }
                }
                .onChange(of: careReminders) { sendNotificationSettings() }
                .onChange(of: discoveryAlerts) { sendNotificationSettings() }
                .onChange(of: evolutionAlerts) { sendNotificationSettings() }

                Section("Cloud Backup") {
                    Label("Powered by iCloud (CloudKit)", systemImage: "icloud.fill")
                        .foregroundStyle(.secondary)
                    Text("Your pet's progress syncs automatically across your iPhone and Apple Watch when signed into the same iCloud account.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundStyle(.secondary)
                    }
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func sendNotificationSettings() {
        connectivity.sendAction("update_notification_settings", payload: [
            "careReminders": careReminders,
            "discoveryAlerts": discoveryAlerts,
            "evolutionAlerts": evolutionAlerts
        ])
    }
}

// MARK: - Circular Progress
private struct CircularProgress: View {
    let value: Double // 0–1

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color(.systemFill), lineWidth: 5)
            Circle()
                .trim(from: 0, to: value)
                .stroke(
                    AngularGradient(
                        colors: [Color.accentBlue, Color.accentViolet, Color.neonGreen],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(Int(value * 100))%")
                .font(.caption2.bold())
        }
    }
}

#Preview { ContentView() }
