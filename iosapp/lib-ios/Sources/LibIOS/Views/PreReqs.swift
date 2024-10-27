import ComposableArchitecture
import SwiftUI

struct PreReqs: View {
  var onTap: () -> Void

  var requirements: [String] {
    [
      "The \(self.deviceType) user must be **signed in to iCloud.**",
      "The \(self.deviceType) user must be **under 18.**",
      "The \(self.deviceType) user must be **part of an Apple Family.**",
      "The \(self.deviceType) must **not be controlled** by a school or organization with **MDM.**",
    ]
  }

  var body: some View {
    VStack(spacing: 32) {
      Text("In order to use Gertrude:")
        .font(.system(size: 26, weight: .semibold))
        .multilineTextAlignment(.center)
        .foregroundStyle(.black)

      VStack(alignment: .leading, spacing: 12) {
        ForEach(self.requirements, id: \.self) { requirement in
          HStack(alignment: .top) {
            Image(systemName: "checkmark.circle")
              .font(.system(size: 13, weight: .semibold))
              .foregroundColor(.violet500)
              .padding(.top, 1)
            Text(LocalizedStringKey(requirement))
              .font(.system(size: 16))
              .foregroundStyle(.black)
          }
        }
      }

      Spacer()

      PrimaryButton("Start authorization") {
        self.onTap()
      }
    }
    .padding(.top, 60)
    .padding(.bottom, 36)
    .padding(.horizontal, 24)
  }
}

#Preview {
  ZStack {
    BgGradient().ignoresSafeArea()
    PreReqs {}
  }
}
