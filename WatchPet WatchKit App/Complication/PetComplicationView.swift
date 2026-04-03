import WidgetKit
import SwiftUI

// MARK: - PetEntry
struct PetEntry: TimelineEntry {
    let date:     Date
    let wellness: Int      // 0–100 overall wellness
    let hunger:   Int
    let petName:  String
    let spritePrefix: String
}

// MARK: - PetComplicationProvider
struct PetComplicationProvider: TimelineProvider {

    func placeholder(in context: Context) -> PetEntry {
        PetEntry(date: Date(), wellness: 80, hunger: 70, petName: "Blobby", spritePrefix: "baby_blob")
    }

    func getSnapshot(in context: Context, completion: @escaping (PetEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetEntry>) -> Void) {
        let current = entry()
        // Refresh every 20 minutes so stats stay reasonably current
        let nextUpdate = Date().addingTimeInterval(20 * 60)
        completion(Timeline(entries: [current], policy: .after(nextUpdate)))
    }

    private func entry() -> PetEntry {
        guard let pet = PersistenceManager.shared.load() else {
            return PetEntry(date: Date(), wellness: 100, hunger: 100, petName: "Blobby", spritePrefix: "baby_blob")
        }
        let tree = EvolutionTree.load()
        let species = tree.species(for: pet.speciesID)
        return PetEntry(
            date:         Date(),
            wellness:     pet.wellness,
            hunger:       pet.hunger,
            petName:      species?.name ?? "???",
            spritePrefix: species?.spritePrefix ?? "baby_blob"
        )
    }
}

// MARK: - PetComplicationEntryView
struct PetComplicationEntryView: View {

    @Environment(\.widgetFamily) var family
    let entry: PetEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryCorner:
            cornerView
        default:
            circularView
        }
    }

    // MARK: Circular: sprite + wellness ring
    private var circularView: some View {
        ZStack {
            Circle()
                .stroke(wellnessColor.opacity(0.3), lineWidth: 3)
            Circle()
                .trim(from: 0, to: CGFloat(entry.wellness) / 100)
                .stroke(wellnessColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Fallback glyph when no real sprite asset exists
            Image(systemName: "pawprint.fill")
                .font(.system(size: 16))
                .foregroundStyle(wellnessColor)
        }
        .padding(2)
    }

    // MARK: Rectangular: name + stat bars
    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(entry.petName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
            MiniBar(label: "🍖", value: entry.hunger,   color: .orange)
            MiniBar(label: "💪", value: entry.wellness, color: wellnessColor)
        }
        .padding(4)
    }

    // MARK: Corner: compact
    private var cornerView: some View {
        Image(systemName: "pawprint.fill")
            .font(.system(size: 14))
            .foregroundStyle(wellnessColor)
            .widgetLabel(entry.petName)
    }

    private var wellnessColor: Color {
        switch entry.wellness {
        case 70...: return .green
        case 40..<70: return .yellow
        default: return .red
        }
    }
}

// MARK: - MiniBar
private struct MiniBar: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text(label).font(.system(size: 8))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.15))
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
@main
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

#Preview(as: .accessoryCircular) {
    PetComplicationWidget()
} timeline: {
    PetEntry(date: .now, wellness: 75, hunger: 60, petName: "Knucklox", spritePrefix: "child_fighter")
}
