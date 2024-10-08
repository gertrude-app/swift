import SwiftUI

struct AuthFailed: View {
  var reason: AuthFailureReason
  var onTryAgain: () -> Void

  var body: some View {
    VStack(spacing: 20) {
      switch self.reason {
      case .networkError:
        Text(
          "You must be connected to the internet in order to complete the parent/guardian authorization step."
        )
      case .authorizationConflict:
        Text(
          "Failed to authorize due to conflict. You might already have another app managing parental controls. Disable that app to continue using Gertrude."
        )
      case .invalidAccountType:
        Text("Apple account error. Please confirm that:")
        VStack(alignment: .leading) {
          Text("The \(self.deviceType) user is logged into iCloud")
          Text("The \(self.deviceType) user is under 18")
          Text("The \(self.deviceType) user is enrolled in an Apple Family")
        }.font(.footnote)
      case .unexpected, .other:
        // TODO: log, contact support, etc.
        Text("An unexpected error occurred, please try again.")
      case .passcodeRequired:
        Text(
          "Failed to authorize. A passcode is required in order to enable parental controls."
        )
      case .authorizationCanceled:
        Text("Failed to authorize. The parent/guardian canceled the authorization.")
      }
      Button("OK") {
        self.onTryAgain()
      }
    }
  }
}

#Preview("No internet") {
  AuthFailed(reason: .networkError, onTryAgain: {})
}

#Preview("Conflict") {
  AuthFailed(reason: .authorizationConflict, onTryAgain: {})
}

#Preview("Invalid account") {
  AuthFailed(reason: .invalidAccountType, onTryAgain: {})
}

#Preview("Unexpected/other") {
  AuthFailed(reason: .unexpected(.restricted), onTryAgain: {})
}

#Preview("Canceled") {
  AuthFailed(reason: .authorizationCanceled, onTryAgain: {})
}

#Preview("Need passcode") {
  AuthFailed(reason: .passcodeRequired, onTryAgain: {})
}
