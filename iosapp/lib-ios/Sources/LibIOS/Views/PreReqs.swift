import ComposableArchitecture
import SwiftUI

struct PreReqs: View {
  var onTap: () -> Void

  var requirements: [String] {
    [
      "The \(self.deviceType) user must be logged into iCloud",
      "The \(self.deviceType) user must be under 18",
      "The \(self.deviceType) user must be part of an Apple Family",
      "The \(self.deviceType) user must be restricted from deleting apps",
    ]
  }

  var body: some View {
    VStack(spacing: 20) {
      Text("In order to safely use Gertrude:")
        .font(.system(size: 20, weight: .semibold))

      VStack(alignment: .leading) {
        ForEach(self.requirements, id: \.self) { requirement in
          HStack {
            Image(systemName: "checkmark.circle")
              .font(.system(size: 12, weight: .semibold))
              .foregroundColor(.violet500)
            Text(requirement)
              .font(.footnote)
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
  }
}

#Preview {
  ZStack {
    BgGradient().ignoresSafeArea()
    PreReqs {}
  }
}
