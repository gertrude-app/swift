import SwiftUI

struct ClearingCacheView: View {
  @Environment(\.colorScheme) var cs

  @State private var spinnerOffset = Vector(x: 0, y: 20)
  @State private var titleOffset = Vector(x: 0, y: 20)
  @State private var subtitleOffset = Vector(x: 0, y: 20)
  @State private var amountClearedOffset = Vector(x: 0, y: 20)
  @State private var showBg = false

  var body: some View {
    ZStack {
      FairiesView()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation {
            self.showBg = true
          }
        }

      VStack(spacing: 0) {
        ProgressView()
          .swooshIn(
            tracking: self.$spinnerOffset,
            to: .zero,
            after: .seconds(0.2),
            for: .seconds(0.5)
          )

        Text("Clearing cache...")
          .font(.system(size: 24, weight: .medium))
          .padding(.top, 16)
          .swooshIn(
            tracking: self.$titleOffset,
            to: .zero,
            after: .seconds(0.3),
            for: .seconds(0.5)
          )

        Text("This may take a little while.")
          .padding(.top, 6)
          .font(.system(size: 18, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .black.opacity(0.7), dark: .white.opacity(0.7)))
          .swooshIn(
            tracking: self.$subtitleOffset,
            to: .zero,
            after: .seconds(0.4),
            for: .seconds(0.5)
          )

        Text("243.3 MB cleared") // TODO: this will change as cache is cleared
          .font(.system(size: 18, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .black.opacity(0.4), dark: .white.opacity(0.4)))
          .padding(.top, 20)
          .swooshIn(
            tracking: self.$amountClearedOffset,
            to: .zero,
            after: .seconds(0.5),
            for: .seconds(0.5)
          )
      }
    }
  }
}

#Preview {
  ClearingCacheView()
}
