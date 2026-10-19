import SwiftUI

// MARK: - ItemView
/// Watch-optimised inventory management screen.
/// Shows tabs for Food, Medicine, Stat Boosters, and Equipment.
/// Consumables can be used directly on the pet; equipment can be equipped/unequipped.
struct ItemView: View {

    @EnvironmentObject var petVM: PetViewModel
    @ObservedObject  private var itemManager = ItemManager.shared
    @Environment(\.dismiss) private var dismiss

    // Which category tab is selected
    @State private var selectedTab: ItemTab = .food
    @State private var confirmUseItem: Item?    // pending use confirmation
    @State private var showUsedBanner = false
    @State private var usedBannerText = ""

    enum ItemTab: String, CaseIterable {
        case food = "Food"
        case medicine = "Med"
        case boost = "Boost"
        case equipment = "Gear"
    }

    // MARK: Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                tabPicker
                    .padding(.horizontal, 4)
                    .padding(.top, 4)

                Divider().background(Color.white.opacity(0.1))

                // Item list
                itemList
            }
            .navigationTitle("Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            // Use confirmation
            .confirmationDialog(
                "Use \(confirmUseItem.flatMap { ItemCatalog.template(for: $0.templateID)?.name } ?? "item")?",
                isPresented: Binding(get: { confirmUseItem != nil }, set: { if !$0 { confirmUseItem = nil } }),
                titleVisibility: .visible
            ) {
                if let item = confirmUseItem {
                    Button("Use") { useItem(item) }
                    Button("Cancel", role: .cancel) { confirmUseItem = nil }
                }
            }
            // Feedback banner
            .overlay(alignment: .top) {
                if showUsedBanner {
                    Text(usedBannerText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.85), in: Capsule())
                        .padding(.top, 4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showUsedBanner)
        }
    }

    // MARK: - Tab picker
    private var tabPicker: some View {
        HStack(spacing: 4) {
            ForEach(ItemTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { selectedTab = tab }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 10, weight: selectedTab == tab ? .bold : .regular))
                        .foregroundStyle(selectedTab == tab ? .black : .white.opacity(0.7))
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedTab == tab ? Color.accentColor : Color.white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Item list
    @ViewBuilder
    private var itemList: some View {
        let items = currentTabItems
        if items.isEmpty {
            emptyState
        } else {
            List(items) { item in
                itemRow(item)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
            }
            .listStyle(.plain)
        }
    }

    private var currentTabItems: [Item] {
        switch selectedTab {
        case .food:      return itemManager.foodItems
        case .medicine:  return itemManager.medicineItems
        case .boost:     return itemManager.statBoostItems
        case .equipment: return itemManager.equipmentItems
        }
    }

    // MARK: - Item row
    private func itemRow(_ item: Item) -> some View {
        guard let template = ItemCatalog.template(for: item.templateID) else {
            return AnyView(EmptyView())
        }
        return AnyView(
            HStack(spacing: 8) {
                // Emoji + rarity dot
                ZStack(alignment: .bottomTrailing) {
                    Text(template.emoji)
                        .font(.system(size: 22))
                    Circle()
                        .fill(rarityColor(template.rarity))
                        .frame(width: 6, height: 6)
                        .offset(x: 2, y: 2)
                }
                .frame(width: 30)

                // Name + description
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(template.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                        if item.isEquipped {
                            Text("ON")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.green, in: Capsule())
                        }
                    }
                    Text(template.description)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                }
                Spacer()

                // Action button
                actionButton(for: item, template: template)
            }
        )
    }

    @ViewBuilder
    private func actionButton(for item: Item, template: ItemTemplate) -> some View {
        if template.isConsumable {
            Button("Use") { confirmUseItem = item }
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.8), in: Capsule())
                .buttonStyle(.plain)
        } else {
            Button(item.isEquipped ? "Remove" : "Equip") {
                if item.isEquipped {
                    itemManager.unequipItem(item)
                } else {
                    itemManager.equipItem(item)
                }
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(item.isEquipped ? Color.orange.opacity(0.8) : Color.purple.opacity(0.8),
                        in: Capsule())
            .buttonStyle(.plain)
        }
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("No items")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
            Text("Visit the Shop to get more!")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers
    private func useItem(_ item: Item) {
        confirmUseItem = nil
        let success = itemManager.useItem(item, on: &petVM.pet)
        if success {
            let name = ItemCatalog.template(for: item.templateID)?.name ?? "Item"
            usedBannerText = "\(name) used!"
            showUsedBanner = true
            petVM.save()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showUsedBanner = false
            }
        }
    }

    private func rarityColor(_ rarity: ItemRarity) -> Color {
        switch rarity {
        case .common:    return Color(hex: "#9E9E9E")
        case .uncommon:  return Color(hex: "#4CAF50")
        case .rare:      return Color(hex: "#2196F3")
        case .epic:      return Color(hex: "#9C27B0")
        case .legendary: return Color(hex: "#FFD700")
        }
    }
}

// MARK: - Color hex convenience (local to this file)
private extension Color {
    init(hex: String) {
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let val = UInt64((try? /^[0-9A-Fa-f]{6}$/.wholeMatch(in: h)) != nil
                        ? (Int(h, radix: 16) ?? 0) : 0)
        let r = Double((val >> 16) & 0xFF) / 255
        let g = Double((val >>  8) & 0xFF) / 255
        let b = Double( val        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    ItemView()
        .environmentObject(PetViewModel())
}
