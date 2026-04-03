import SwiftUI

// MARK: - CareMenuView
// Four care actions in a 2×2 grid. Each taps a PetViewModel method.
struct CareMenuView: View {

    @EnvironmentObject var petVM: PetViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var lastAction: String? = nil

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.20).ignoresSafeArea()

            VStack(spacing: 8) {
                Text("Care")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    CareButton(icon: "🍖", label: "Feed",  hint: "+Hunger") {
                        petVM.feed()
                        flash("Yum!")
                    }
                    CareButton(icon: "🎮", label: "Play",  hint: "+Happy") {
                        petVM.play()
                        flash("Wheee!")
                    }
                    CareButton(icon: "🛁", label: "Clean", hint: "+Clean") {
                        petVM.clean()
                        flash("Squeaky!")
                    }
                    CareButton(icon: "💤", label: "Sleep", hint: "+Health") {
                        petVM.sleep()
                        flash("Zzz…")
                    }
                }

                if let msg = lastAction {
                    Text(msg)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.yellow)
                        .transition(.opacity)
                }
            }
            .padding(10)
        }
    }

    private func flash(_ message: String) {
        withAnimation { lastAction = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { lastAction = nil }
        }
    }
}

// MARK: - CareButton
private struct CareButton: View {
    let icon:   String
    let label:  String
    let hint:   String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(icon).font(.system(size: 22))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                Text(hint)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CareMenuView().environmentObject(PetViewModel())
}
