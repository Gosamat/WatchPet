import WidgetKit
import SwiftUI

// MARK: - PetMood
enum PetMood: String {
    case happy, neutral, sad, sick

    init(pet: VirtualPet) {
        if pet.isSick || pet.health < 25 {
            self = .sick
        } else if pet.happiness >= 60 && pet.health >= 50 {
            self = .happy
        } else if pet.happiness >= 30 {
            self = .neutral
        } else {
            self = .sad
        }
    }

    var emoji: String {
        switch self {
        case .happy:   return "😊"
        case .neutral: return "😐"
        case .sad:     return "😢"
        case .sick:    return "🤒"
        }
    }

    var label: String {
        switch self {
        case .happy:   return "HAPPY"
        case .neutral: return "OK"
        case .sad:     return "SAD"
        case .sick:    return "SICK"
        }
    }

    var ringColor: Color {
        switch self {
        case .happy:   return .green
        case .neutral: return .yellow
        case .sad:     return Color(red: 1, green: 0.4, blue: 0.2)
        case .sick:    return Color(red: 0.6, green: 0.9, blue: 0.3)
        }
    }
}

// MARK: - PetEntry
struct PetEntry: TimelineEntry {
    let date:         Date
    let wellness:     Int
    let hunger:       Int
    let happiness:    Int
    let health:       Int
    let petName:      String
    let spritePrefix: String
    let frameCount:   Int
    let mood:         PetMood
    let isSick:       Bool
}

// MARK: - PetComplicationProvider
struct PetComplicationProvider: TimelineProvider {

    func placeholder(in context: Context) -> PetEntry {
        PetEntry(date: Date(), wellness: 80, hunger: 70, happiness: 75,
                 health: 90, petName: "Flameling", spritePrefix: "baby_flame",
                 frameCount: 2, mood: .happy, isSick: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (PetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetEntry>) -> Void) {
        let entry = makeEntry()
        let next  = Date().addingTimeInterval(15 * 60)   // refresh every 15 min
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> PetEntry {
        guard let pet = PersistenceManager.shared.load() else {
            return PetEntry(date: Date(), wellness: 100, hunger: 100, happiness: 100,
                            health: 100, petName: "Flameling", spritePrefix: "baby_flame",
                            frameCount: 2, mood: .happy, isSick: false)
        }
        let tree    = EvolutionTree.load()
        let species = tree.species(for: pet.speciesID)
        return PetEntry(
            date:         Date(),
            wellness:     pet.wellness,
            hunger:       pet.hunger,
            happiness:    pet.happiness,
            health:       pet.health,
            petName:      species?.name ?? "???",
            spritePrefix: species?.spritePrefix ?? "baby_flame",
            frameCount:   species?.frameCount ?? 2,
            mood:         PetMood(pet: pet),
            isSick:       pet.isSick
        )
    }
}

// MARK: - PetComplicationEntryView
struct PetComplicationEntryView: View {

    @Environment(\.widgetFamily) var family
    let entry: PetEntry

    var body: some View {
        switch family {
        case .accessoryCircular:    circularView
        case .accessoryRectangular: rectangularView
        case .accessoryCorner:      cornerView
        default:                    circularView
        }
    }

    // MARK: - Circular
    // Mood-coloured ring + sprite + mood emoji badge
    private var circularView: some View {
        ZStack {
            // Background ring (dim)
            Circle()
                .stroke(entry.mood.ringColor.opacity(0.25), lineWidth: 3)

            // Filled wellness arc
            Circle()
                .trim(from: 0, to: CGFloat(entry.wellness) / 100)
                .stroke(
                    entry.mood.ringColor,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Sprite (static frame — no TimelineView in complications)
            PixelSpriteView(
                spritePrefix: entry.spritePrefix,
                frameCount:   entry.frameCount,
                pixelSize:    2,
                isStatic:     true
            )
            .frame(width: 28, height: 28)

            // Mood badge — bottom-right
            Text(entry.mood.emoji)
                .font(.system(size: 9))
                .offset(x: 11, y: 11)
        }
        .padding(2)
    }

    // MARK: - Rectangular
    // Sprite | Name + mood | HP bar
    private var rectangularView: some View {
        HStack(spacing: 6) {
            // Sprite
            PixelSpriteView(
                spritePrefix: entry.spritePrefix,
                frameCount:   entry.frameCount,
                pixelSize:    2,
                isStatic:     true
            )
            .frame(width: 28, height: 28)

            // Info column
            VStack(alignment: .leading, spacing: 3) {
                // Name + mood
                HStack(spacing: 3) {
                    Text(entry.petName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(entry.mood.emoji)
                        .font(.system(size: 10))
                }

                // Hunger bar
                ComplicationBar(value: entry.hunger,   color: .orange, label: "🍖")
                // HP bar
                ComplicationBar(value: entry.health,   color: moodColor, label: "❤️")
            }
        }
        .padding(.horizontal, 2)
    }

    // MARK: - Corner
    private var cornerView: some View {
        PixelSpriteView(
            spritePrefix: entry.spritePrefix,
            frameCount:   entry.frameCount,
            pixelSize:    2,
            isStatic:     true
        )
        .frame(width: 20, height: 20)
        .widgetLabel {
            Text("\(entry.petName) \(entry.mood.emoji)")
                .font(.system(size: 10, weight: .semibold))
        }
    }

    // MARK: - Helpers
    private var moodColor: Color {
        entry.mood.ringColor
    }
}

// MARK: - ComplicationBar
private struct ComplicationBar: View {
    let value: Int
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 3) {
            Text(label).font(.system(size: 8))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.15))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Widget declaration
// NOTE: Move this file to a dedicated Widget Extension target in Xcode
// (File > New > Target > Widget Extension) to enable it as a complication.
struct PetComplicationWidget: Widget {
    let kind = "PetComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetComplicationProvider()) { entry in
            PetComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("WatchPet")
        .description("Your creature at a glance.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryCorner])
    }
}

// MARK: - Previews
#Preview("Circular – Happy", as: .accessoryCircular) {
    PetComplicationWidget()
} timeline: {
    PetEntry(date: .now, wellness: 85, hunger: 80, happiness: 90,
             health: 95, petName: "Flameling", spritePrefix: "baby_flame",
             frameCount: 2, mood: .happy, isSick: false)
}

#Preview("Circular – Sad", as: .accessoryCircular) {
    PetComplicationWidget()
} timeline: {
    PetEntry(date: .now, wellness: 28, hunger: 15, happiness: 20,
             health: 40, petName: "Flameling", spritePrefix: "baby_flame",
             frameCount: 2, mood: .sad, isSick: false)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    PetComplicationWidget()
} timeline: {
    PetEntry(date: .now, wellness: 72, hunger: 60, happiness: 75,
             health: 80, petName: "Drakeling", spritePrefix: "child_dragon",
             frameCount: 2, mood: .happy, isSick: false)
}
