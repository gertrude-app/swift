import SwiftUI

struct AuthFailed: View {
  var reason: AuthFailureReason
  var onTryAgain: () -> Void

  var body: some View {
    VStack(spacing: 20) {
      Group {
        switch self.reason {
        case .networkError:
          Text(
            "You must be connected to the internet in order to complete the authorization step."
          )
        case .authorizationConflict:
          Text(
            "Failed to authorize due to conflict. You might already have another app managing parental controls. Disable that app to continue using Gertrude."
          )
        case .invalidAccountType:
          Text("Sorry, there was a problem with your **Apple Account.** Please ensure that:")
          HStack {
            VStack(alignment: .leading, spacing: 6) {
              Text("The \(self.deviceType) user is signed in to iCloud")
              Text("The \(self.deviceType) user is under 18")
              Text("The \(self.deviceType) user is in an Apple Family")
            }.font(.footnote)
            Spacer()
          }
          .padding(8)
          .background(.gray.opacity(0.1))
          .multilineTextAlignment(.leading)
          .cornerRadius(8)
        case .passcodeRequired:
          Text("Failed to authorize. A passcode is required in order to enable parental controls.")
        case .authorizationCanceled:
          Text("Failed to authorize. The parent or guardian canceled the authorization.")
        case .restricted:
          VStack(spacing: 16) {
            Text("A restriction is preventing Gertrude from using Family Controls.")
            Text(
              "Is this device is enrolled in **mobile device management (MDM)** by an organization or school? If so, try again on a device not managed by MDM."
            )
            .font(.footnote)
          }
        case .unexpected, .other:
          VStack(spacing: 16) {
            Text("An unexpected error occurred.")
            Text("Please try again, or contact us for more help at https://gertrude.app/contact.")
              .font(.footnote)
          }
        }
      }
      .multilineTextAlignment(.center)
      .foregroundStyle(.black)

      Button {
        self.onTryAgain()
      } label: {
        Spacer()
        switch self.reason {
        case .invalidAccountType, .restricted:
          HStack {
            Image(systemName: "arrow.left")
            Text("Review requirements")
              .padding(.trailing, 4)
          }

        default:
          Text("Try again")
        }
        Spacer()
      }
      .padding(.vertical, 12)
      .background(Color.violet100)
      .cornerRadius(8)
      .foregroundColor(.violet700)
      .font(.system(size: 16, weight: .semibold))
    }
    .padding(20)
    .padding(.top, 8)
    .background(.white)
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    .padding(.horizontal, 32)
    .frame(maxWidth: 600)
  }
}

struct AuthFailedPreview: View {
  var reason: AuthFailureReason

  var body: some View {
    ZStack {
      BgGradient().ignoresSafeArea()
      AuthFailed(reason: self.reason) {}
    }
  }
}

#Preview("No internet") {
  AuthFailedPreview(reason: .networkError)
}

#Preview("Conflict") {
  AuthFailedPreview(reason: .authorizationConflict)
}

#Preview("Invalid account") {
  AuthFailedPreview(reason: .invalidAccountType)
}

#Preview("Restricted/MDM") {
  AuthFailedPreview(reason: .restricted)
}

#Preview("Canceled") {
  AuthFailedPreview(reason: .authorizationCanceled)
}

#Preview("Need passcode") {
  AuthFailedPreview(reason: .passcodeRequired)
}

#Preview("Unexpected") {
  AuthFailedPreview(reason: .unexpected(.invalidArgument))
}
