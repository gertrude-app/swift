import Foundation
import SwiftUI

struct Welcome: View {
  var onPrimaryButtonTap: () -> Void

  var body: some View {
    VStack(spacing: 15) {
      Text("Welcome!")
        .font(.system(size: 50, weight: .bold))

      Text("Gertrude fills in the gaps in Apple’s parental controls, including:")
        .multilineTextAlignment(.center)
        .opacity(0.7)

      VStack(alignment: .leading) {
        FeatureLI("Blocking GIFs in the #images iMessage texting app")
        FeatureLI("Blocking GIFs in WhatsApp, Skype, and other messaging apps")
        FeatureLI("Disabling internet image searching from Spotlight")
      }.padding(.horizontal, 16).padding(.top, 20)

      Spacer()

      PrimaryButton("Getting started") {
        self.onPrimaryButtonTap()
      }
    }
    .padding(.top, 120)
    .padding(.bottom, 60)
  }
}

#Preview {
  ZStack {
    BgGradient()
    Welcome {}
  }.ignoresSafeArea()
}
