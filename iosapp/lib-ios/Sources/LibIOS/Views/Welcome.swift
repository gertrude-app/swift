import Foundation
import SwiftUI

struct Welcome: View {
  var onPrimaryButtonTap: () -> Void

  var body: some View {
    VStack(spacing: 15) {
      Text("Welcome!")
        .font(.system(size: 50, weight: .bold))
        .foregroundStyle(.black)

      Text("Gertrude fills in the gaps in Apple’s parental controls, including:")
        .multilineTextAlignment(.center)
        .foregroundStyle(.black)
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
    .padding(.top, 60)
    .padding(.bottom, 36)
  }
}

#Preview {
  ZStack {
    BgGradient().ignoresSafeArea()
    Welcome {}
  }
}
