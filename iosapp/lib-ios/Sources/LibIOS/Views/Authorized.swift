import SwiftUI

struct Authorized: View {
  var onInstallFilterTapped: () -> Void

  var body: some View {
    VStack(spacing: 32) {
      Text("Half way there...")
        .font(.system(size: 30, weight: .semibold))
        .multilineTextAlignment(.center)
        .foregroundStyle(.black)

      Text("We’ve got authorization from Screen Time. Next we need to install the filter.")
        .font(.system(size: 18, weight: .regular))
        .padding(.top, 8)
        .padding(.horizontal, 16)
        .lineSpacing(5)
        .multilineTextAlignment(.center)
        .foregroundStyle(.black)

      Spacer()

      PrimaryButton("Install filter") {
        self.onInstallFilterTapped()
      }
    }
    .padding(.top, 60)
    .padding(.bottom, 36)
    .padding(.horizontal, 24)
  }
}

#Preview {
  ZStack {
    BgGradient()
      .ignoresSafeArea()
    Authorized {}
  }
}
