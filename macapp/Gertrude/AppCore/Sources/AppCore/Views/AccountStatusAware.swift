import SwiftUI

struct AccountStatusAware<Content>: View, StoreView where Content: View {
  enum Size {
    case regular
    case small
  }

  @EnvironmentObject var store: AppStore
  @ViewBuilder var content: () -> Content

  @State private var rechecking = false
  @State private var disconnecting = false

  var size: Size

  init(size: Size = .regular, content: @escaping () -> Content) {
    self.size = size
    self.content = content
  }

  var inactive: some View {
    VStack(alignment: .leading, spacing: size == .regular ? 13 : 9) {
      HStack {
        Spacer()
        Image(systemName: "hand.raised.fill")
          .font(size == .regular ? .title : .title2)
        Markdown("Your Gertrude account is **no longer active**.")
          .font(size == .regular ? .title : .title2)
        Spacer()
      }
      .padding(bottom: 5)
      Group {
        if store.state.filterState != .off {
          Markdown(
            "The internet filter will continue protecting this computer according to the rules set before the account went inactive, but no changes or suspensions can be made until the account is restored."
          )
        }
        Markdown(
          "To **restore the account,** log in to the Gertrude web admin dashboard, resolve the payment issue, and click the **Recheck** button below."
        )
        Markdown(
          "If you no longer wish to use Gertrude, click the **Disconnect** button below, then uninstall the app."
        )
        Markdown("Contact us at `support@gertrude.app` to get help.")
      }
      .opacity(0.85)
      HStack {
        Button("Recheck\(rechecking ? "ing..." : "")") {
          rechecking = true
          store.send(.requestCurrentAccountStatus)
          DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            rechecking = false
          }
        }
        .foregroundColor(.black)
        .disabled(rechecking)
        Button("Disconnect\(disconnecting ? "ing and quitting..." : "")") {
          Auth.challengeAdmin { isAdmin in
            DispatchQueue.main.async { disconnecting = true }
            if isAdmin { store.send(.disconnectInactiveAccount) }
          }
        }
        .foregroundColor(.darkModeRed)
        .disabled(disconnecting)
      }
      .padding(top: size == .regular ? 10 : 5)
    }
    .padding(size == .regular ? 40 : 18)
  }

  var body: some View {
    Group {
      switch store.state.accountStatus {
      case .needsAttention:
        VStack(spacing: 0) {
          HStack {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
            Markdown("Your Gertrude account payment **is past due**!")
              +
              Text(
                size == .regular ?
                  " Login to the web admin dashboard before app loses functionality." : ""
              )
            Spacer()
          }
          .foregroundColor(.white)
          .padding(y: 10)
          .background(Color.warningOrange)
          content()
        }
      case .inactive:
        inactive
          .centered()
          .background(Color.darkModeRed)
          .foregroundColor(.white)
      default:
        content()
      }
    }
  }
}

struct AccountStatusAware_Previews: PreviewProvider, GertrudeProvider {
  static var initializeState: StateCustomizer? = { _ in }

  static var cases: [(inout AppState) -> Void] = [
    { state in
      state.filterStatus = .installedAndRunning
      state.accountStatus = .inactive
    },
    { state in
      state.filterStatus = .installedAndRunning
      state.accountStatus = .inactive
    },
    { state in
      state.filterStatus = .installedAndRunning
      state.accountStatus = .inactive
    },
  ]

  static var previews: some View {
    var sizes = [AccountStatusAware<Text>.Size.regular, .small, .regular]
    var dims = [
      AdminWindow.MIN_WIDTH,
      AdminWindow.MIN_HEIGHT,
      FilterSuspensionRequest.MIN_WIDTH,
      FilterSuspensionRequest.MIN_HEIGHT,
      RequestsWindow.MIN_WIDTH,
      RequestsWindow.MIN_HEIGHT,
    ]
    return ForEach(allPreviews) {
      AccountStatusAware(size: sizes.removeFirst()) { Text("content here") }
        .store($0)
        .frame(
          width: dims.removeFirst(),
          height: dims.removeFirst()
        )
    }
  }
}
