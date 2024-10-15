import SwiftUI

struct Authorized: View {
  var onInstallFilterTapped: () -> Void
  
  var body: some View {
    VStack(spacing: 20) {
      Text("Authorization granted! One more step: install the content filter.")
        .multilineTextAlignment(.center)
        .font(.system(size: 16, weight: .medium))
      
      Button{
        self.onInstallFilterTapped()
      } label: {
        Spacer()
        Text("Install filter")
        Spacer()
      }
      .padding(.vertical, 12)
      .background(violet100)
      .cornerRadius(8)
      .foregroundColor(violet700)
      .font(.system(size: 16, weight: .semibold))
    }
    .padding(20)
    .padding(.top, 8)
    .background(.white)
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    .padding(.horizontal, 32)
  }
}

#Preview {
  ZStack {
    BgGradient()
    Authorized {}
  }
  .ignoresSafeArea()
}
