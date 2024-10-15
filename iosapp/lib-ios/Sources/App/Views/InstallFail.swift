import SwiftUI

struct InstallFail: View {
  var error: FilterInstallError
  var onTap: () -> Void

  var body: some View {
    VStack(spacing: 20) {
      Text("Filter setup failed with an error:").font(.system(size: 16, weight: .medium))

      Group {
        switch self.error {
        case .configurationInvalid:
          Text("Configuration is invalid.")
        case .configurationDisabled:
          Text("Configuration is disabled.")
        case .configurationStale:
          Text("Configuration is stale.")
        case .configurationCannotBeRemoved:
          Text("Configuration can not be removed.")
        case .configurationPermissionDenied:
          Text("Permission denied.")
        case .configurationInternalError:
          Text("Internal error.")
        case .unexpected(let underlying):
          Text("Unexpected error: \(underlying)")
        }
      }
      .font(.footnote)
      .foregroundColor(.red)
      .padding(.bottom, 20)
      .multilineTextAlignment(.center)

      Button {
        self.onTap()
      } label: {
        Spacer()
        Text("Try again")
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
    .frame(maxWidth: 600)
  }
}

struct InstallFailPreview: View {
  var error: FilterInstallError

  var body: some View {
    ZStack {
      BgGradient().ignoresSafeArea()
      InstallFail(error: self.error) {}
    }
  }
}

#Preview("Configuration cannot be removed") {
  InstallFailPreview(error: .configurationCannotBeRemoved)
}

#Preview("Configuration disabled") {
  InstallFailPreview(error: .configurationDisabled)
}

#Preview("Configuration internal error") {
  InstallFailPreview(error: .configurationInternalError)
}

#Preview("Configuration invalid") {
  InstallFailPreview(error: .configurationInvalid)
}

#Preview("Configuration permission denied") {
  InstallFailPreview(error: .configurationPermissionDenied)
}

#Preview("Configuration stale") {
  InstallFailPreview(error: .configurationStale)
}

#Preview("Unexpected error") {
  InstallFailPreview(
    error: .unexpected(
      "A kangaroo from kilimanjaro overheard a conversation between a lion and a tiger, which led to a data leak and a global pandemic."
    )
  )
}
