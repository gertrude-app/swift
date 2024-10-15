import ComposableArchitecture
import SwiftUI

struct PreReqs: View {
  var onTap: () -> Void

  var requirements: [String] {
    [
      "the \(self.deviceType) use must be logged into iCloud",
      "the \(self.deviceType) user must be under 18",
      "the \(self.deviceType) user must be part of an Apple Family",
      "the \(self.deviceType) user must be restricted from deleting apps",
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
              .foregroundColor(violet500)
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
    .padding(.top, 120)
    .padding(.bottom, 60)
  }
}

#Preview {
  ZStack {
    BgGradient()
    PreReqs {}
  }.ignoresSafeArea()
}
