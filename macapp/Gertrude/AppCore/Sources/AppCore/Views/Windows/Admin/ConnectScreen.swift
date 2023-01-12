import SwiftUI

struct ConnectScreen: View, StoreView {
  @EnvironmentObject var store: AppStore

  var state: AdminWindowState.ConnectState {
    store.state.adminWindow.connectState
  }

  var fetchState: FetchState<String> {
    state.fetchState
  }

  var body: some View {
    VStack {
      switch fetchState {
      case .fetching:
        Submitting("Connecting...")
      case .success(let userName):
        HStack {
          Image(systemName: "checkmark.shield.fill")
            .resizable()
            .frame(width: 15, height: 18)
            .foregroundColor(.blue)
          Group {
            Text("Successfully connected to user ") + Text(userName).bold().underline()
              + Text(".")
          }
        }
        Button("More options", action: send(.moreOptionsClickedAfterConnectToUserSuccess))
          .padding()
      case .error(let msg):
        ErrorMessage(msg)
        Button("Try again", action: send(.tryAgainClickedAfterConnectToUserFailed))
          .padding()
      default:
          VStack(spacing: 18) {
            Text("Setup account connection...")
              .font(.system(size: 24))
              .offset(y: -5)
            Form {
              TextField("Enter code:", text: store.bind(
                { state.code },
                { .updateConnectionCode($0) }
              ))
              .font(.system(size: 17))
              HStack {
                Spacer()
                Button("Connect", action: send(.connectToUser))
                  .disabled(buttonDisabled)
              }
            }
            Markdown(
              "If you haven't already created one, you can get a **connection code** by logging in to your Gertrude admin web dashboard and clicking the _\"Add Device\"_ button for the user you'd like to protect on this computer."
            )
            .frame(maxWidth: .infinity)
            .opacity(0.8)
            .padding(0)

            Markdown(
              "Establishing this connection (which you only need to do once) allows you to manage the protection rules for this computer from _any device where you're logged into the Gertrude web admin._"
            )
            .frame(maxWidth: .infinity)
            .opacity(0.8)
            .offset(x: -6)

            HStack(spacing: 35) {

              Button("More info →") {
                _ = Current.os
                  .openWebUrl(.init(string: "https://gertrude.app/app-redir/connect/more-info")!)
              }.buttonStyle(.link)

              Button("Contact support →") {
                _ = Current.os
                  .openWebUrl(
                    .init(string: "https://gertrude.app/app-redir/connect/contact-support")!
                  )
              }.buttonStyle(.link)

              Button("Quit ×") {
                _ = Current.os.quitApp()
              }.buttonStyle(.link).foregroundColor(.darkModeRed)
            }
            .padding(top: 20)
          }
          .frame(width: 415)
      }
    }.infinite()
  }

  var buttonDisabled: Bool {
    let intCode = Int(state.code)
    guard let intCode = intCode else { return true }
    return intCode < 100000 || intCode > 999999 || fetchState.isFetching
  }
}

struct ConnectScreen_Previews: PreviewProvider, GertrudeProvider {
  static var initializeState: StateCustomizer? = { state in
    state.adminWindow = .connect(AdminWindowState.ConnectState())
  }

  static var cases: [StateCustomizer] = [
    { state in
      state.adminWindow.connectState.fetchState = .waiting
    },
    { state in
      state.adminWindow.connectState.fetchState = .success("Wilhite Kids")
    },
    { state in
      state.adminWindow.connectState.fetchState = .error("Failed to fetch")
    },
    { state in
      state.adminWindow.connectState.fetchState = .fetching
    },
  ]

  static var colorScheme: ColorScheme { .light }

  static var previews: some View {
    ForEach(allPreviews) {
      ConnectScreen().store($0).adminPreview()
    }
  }
}
