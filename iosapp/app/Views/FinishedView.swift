import SwiftUI

struct FinishedView: View {
  @Environment(\.colorScheme) var cs

  @State private var showBg = false
  @State private var iconOffset = Vector(x: 0, y: 20)
  @State private var titleOffset = Vector(x: 0, y: 20)
  @State private var subtitleOffset = Vector(x: 0, y: 20)

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      Image(systemName: "party.popper")
        .font(.system(size: 30, weight: .semibold))
        .foregroundStyle(Color(self.cs, light: .violet800, dark: .violet400))
        .padding(12)
        .background(Color(self.cs, light: .violet300.opacity(0.6), dark: .violet950))
        .cornerRadius(24)
        .swooshIn(tracking: self.$iconOffset, to: .zero, after: .seconds(0.2), for: .seconds(0.5))

      Text("Quit the app, you’re done!")
        .font(.system(size: 24, weight: .bold))
        .padding(.bottom, 12)
        .padding(.top, 28)
        .swooshIn(tracking: self.$titleOffset, to: .zero, after: .seconds(0.3), for: .seconds(0.5))

      Text("Gertrude will keep blocking even when the app is not running.")
        .font(.system(size: 18, weight: .regular))
        .foregroundStyle(Color(self.cs, light: .black.opacity(0.7), dark: .white.opacity(0.7)))
        .multilineTextAlignment(.center)
        .swooshIn(
          tracking: self.$subtitleOffset,
          to: .zero,
          after: .seconds(0.4),
          for: .seconds(0.5)
        )

      Spacer()
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 30)
    .background(Gradient(colors: [.clear, Color(self.cs, light: .violet200, dark: .violet950)]))
    .opacity(self.showBg ? 1 : 0)
    .onAppear {
      withAnimation {
        self.showBg = true
      }
    }
  }
}

#Preview {
  FinishedView()
}
