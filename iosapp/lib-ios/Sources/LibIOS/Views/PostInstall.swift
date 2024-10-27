import SwiftUI

struct PostInstall: View {
  var onOkClicked: () -> Void

  var body: some View {
    VStack(spacing: 15) {
      Text("Filter installed successfully!")
        .font(.system(size: 40, weight: .bold))
        .multilineTextAlignment(.center)
        .foregroundStyle(.black)

      Text("Good to know:")
        .multilineTextAlignment(.center)
        .opacity(0.7)
        .foregroundStyle(.black)

      VStack(alignment: .leading) {
        FeatureLI(
          "Previously loaded GIFs will still be visible, so if you want to test that the filter is working, try searching for a new GIF."
        )
        FeatureLI("You can quit this app now—it will keep blocking even when not running.")
        FeatureLI(
          "Use Screen Time restrictions to make sure this \(self.deviceType) user can’t delete apps. Deleting the app removes the content filter."
        )
      }.padding(.horizontal, 16)

      Text("Questions? Drop us a line at\nhttps://gertrude.app/contact")
        .multilineTextAlignment(.center)
        .foregroundStyle(.black)
        .opacity(0.7)

      Spacer()

      PrimaryButton("OK") {
        self.onOkClicked()
      }
    }
    .padding(.top, 60)
    .padding(.bottom, 36)
  }
}

#Preview {
  ZStack {
    BgGradient().ignoresSafeArea()
    PostInstall {}
  }
}
