import SwiftUI

// MARK: - iOS Companion ContentView
// The iPhone companion app is minimal — its main job is to relay battle data
// between two nearby iPhones and their paired Apple Watches.
struct ContentView: View {

    @StateObject private var battleManager = NearbyBattleManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                Image(systemName: "applewatch.side.right")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("WatchPet")
                    .font(.largeTitle.bold())

                Text("Your creature lives on your Apple Watch.\nOpen the app on your wrist to play!")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Divider().padding(.vertical)

                // Nearby battle status
                VStack(spacing: 8) {
                    Label("Nearby Battle", systemImage: "wave.3.right")
                        .font(.headline)

                    if let dist = battleManager.nearbyPeerDistance {
                        Text(String(format: "Opponent detected: %.1f m away", dist))
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text("No opponent nearby")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("Keep this app open to enable\nwatch-to-watch battles nearby.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("WatchPet")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview { ContentView() }
