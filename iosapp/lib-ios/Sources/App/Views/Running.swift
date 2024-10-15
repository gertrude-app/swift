import SwiftUI

struct Running: View {
  var body: some View {
    VStack(spacing: 20) {
      Text("Gertrude is blocking GIFs and image searches.")
        .font(.system(size: 20, weight: .semibold))
        .multilineTextAlignment(.center)

      Text("You can quit this app now—it will keep blocking even when not running.")
        .font(.footnote)
        .multilineTextAlignment(.center)

      Spacer()

      Text("Questions? Drop us a line at\nhttps://gertrude.app/contact")
        .font(.footnote)
    }
    .padding(.top, 60)
    .padding(.bottom, 36)
    .padding(.horizontal, 32)
  }
}

#Preview {
  ZStack {
    BgGradient().ignoresSafeArea()
    Running()
  }
}
