import SwiftUI
import Combine

// MARK: - CosmeticTheme
struct CosmeticTheme {
    let id: String
    let name: String

    // Background gradient colors
    let bgTop: Color
    let bgBottom: Color

    // Primary accent (buttons, rings, highlights)
    let accent: Color
    // Secondary accent (badges, secondary elements)
    let accentSecondary: Color

    // Grid/decoration overlay color
    let gridColor: Color

    // Emoji used in store previews
    let icon: String
}

extension CosmeticTheme {
    // MARK: - Built-in themes

    static let cyberpunk = CosmeticTheme(
        id: "cyberpunk", name: "Cyberpunk",
        bgTop:           Color(red: 0.02, green: 0.04, blue: 0.10),
        bgBottom:        Color(red: 0.04, green: 0.02, blue: 0.12),
        accent:          Color(red: 0.00, green: 0.83, blue: 1.00),
        accentSecondary: Color(red: 0.55, green: 0.36, blue: 0.96),
        gridColor:       Color(red: 0.00, green: 0.83, blue: 1.00),
        icon: "🌆"
    )

    static let gameboy = CosmeticTheme(
        id: StoreManager.ProductID.themeGameboy, name: "Gameboy Green",
        bgTop:           Color(red: 0.06, green: 0.16, blue: 0.06),
        bgBottom:        Color(red: 0.03, green: 0.10, blue: 0.03),
        accent:          Color(red: 0.37, green: 0.86, blue: 0.37),
        accentSecondary: Color(red: 0.22, green: 0.58, blue: 0.22),
        gridColor:       Color(red: 0.37, green: 0.86, blue: 0.37),
        icon: "🎮"
    )

    static let virtualBoy = CosmeticTheme(
        id: StoreManager.ProductID.themeVirtualBoy, name: "Virtual Boy",
        bgTop:           Color(red: 0.12, green: 0.00, blue: 0.00),
        bgBottom:        Color(red: 0.06, green: 0.00, blue: 0.00),
        accent:          Color(red: 1.00, green: 0.15, blue: 0.15),
        accentSecondary: Color(red: 0.70, green: 0.05, blue: 0.05),
        gridColor:       Color(red: 1.00, green: 0.15, blue: 0.15),
        icon: "🔴"
    )

    static let oled = CosmeticTheme(
        id: StoreManager.ProductID.themeOLED, name: "OLED Dark",
        bgTop:           Color.black,
        bgBottom:        Color(red: 0.04, green: 0.04, blue: 0.04),
        accent:          Color.white,
        accentSecondary: Color(white: 0.60),
        gridColor:       Color(white: 0.20),
        icon: "⬛️"
    )

    static let sakura = CosmeticTheme(
        id: StoreManager.ProductID.themeSakura, name: "Sakura Pink",
        bgTop:           Color(red: 0.12, green: 0.04, blue: 0.10),
        bgBottom:        Color(red: 0.08, green: 0.02, blue: 0.08),
        accent:          Color(red: 1.00, green: 0.55, blue: 0.80),
        accentSecondary: Color(red: 0.80, green: 0.30, blue: 0.70),
        gridColor:       Color(red: 1.00, green: 0.55, blue: 0.80),
        icon: "🌸"
    )

    static let halloween = CosmeticTheme(
        id: StoreManager.ProductID.themeHalloween, name: "Spooky",
        bgTop:           Color(red: 0.08, green: 0.04, blue: 0.00),
        bgBottom:        Color(red: 0.04, green: 0.02, blue: 0.00),
        accent:          Color(red: 1.00, green: 0.45, blue: 0.00),
        accentSecondary: Color(red: 0.55, green: 0.10, blue: 0.80),
        gridColor:       Color(red: 1.00, green: 0.45, blue: 0.00),
        icon: "🎃"
    )

    static let winter = CosmeticTheme(
        id: StoreManager.ProductID.themeWinter, name: "Winter",
        bgTop:           Color(red: 0.04, green: 0.06, blue: 0.16),
        bgBottom:        Color(red: 0.02, green: 0.04, blue: 0.12),
        accent:          Color(red: 0.55, green: 0.85, blue: 1.00),
        accentSecondary: Color(red: 0.80, green: 0.92, blue: 1.00),
        gridColor:       Color(red: 0.55, green: 0.85, blue: 1.00),
        icon: "❄️"
    )

    static let all: [CosmeticTheme] = [
        .cyberpunk, .gameboy, .virtualBoy, .oled, .sakura, .halloween, .winter
    ]

    static func theme(for id: String) -> CosmeticTheme {
        all.first { $0.id == id } ?? .cyberpunk
    }
}

// MARK: - CosmeticsManager
@MainActor
final class CosmeticsManager: ObservableObject {

    static let shared = CosmeticsManager()

    @Published private(set) var activeTheme: CosmeticTheme = .cyberpunk

    private let defaults = UserDefaults(suiteName: "group.com.watchpet.app") ?? .standard
    private let themeKey = "activeThemeID"

    private init() {
        let saved = defaults.string(forKey: themeKey) ?? "cyberpunk"
        activeTheme = CosmeticTheme.theme(for: saved)
    }

    func applyTheme(_ id: String) {
        let theme = CosmeticTheme.theme(for: id)
        activeTheme = theme
        defaults.set(id, forKey: themeKey)
    }
}
