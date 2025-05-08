import ComposableArchitecture
import Dependencies
import LibApp
import SwiftUI

struct EnterCodeView: View {
  @FocusState private var isFocused: Bool
  @State private var input: String = ""

  let submit: (Int) -> Void

  var code: Int? {
    guard let code = Int(self.input) else { return nil }
    return code >= 100_000 && code <= 999_999 ? code : nil
  }

  var codeIsValid: Bool {
    self.code != nil
  }

  var body: some View {
    VStack {
      TextField("Enter code", text: self.$input)
        .keyboardType(.numberPad)
        .focused(self.$isFocused)
        .padding(20)
        .border(Color.gray)
      BigButton(
        "Submit",
        type: .button { self.submit(self.code ?? 111_111) },
        disabled: !self.codeIsValid
      )
    }
    .padding(20)
    .task { self.isFocused = true }
  }
}

struct ConnectingView: View {
  @Environment(\.openURL) var openURL
  @Environment(\.dismiss) var dismiss

  @Bindable var store: StoreOf<ConnectAccount>

  var body: some View {
    switch self.store.state.screen {
    case .enteringCode:
      EnterCodeView {
        self.store.send(.codeSubmitted($0))
      }
    case .connected(childName: let childName):
      Text("Connected to child: \(childName)")
    case .connecting:
      ProgressView()
    case .connectionFailed(error: let error):
      Text("Failed to connect, \(error)")
    case .pleaseDisableScreenTime:
      Text("Connect your Gertrude Account")
        .font(.title)
      Text("Tap the button below and disable Screen Time. Then come back here to continue.")
        .padding(20)
      BigButton(
        "Open Settings",
        type: .button { self.openAppSettings() }
      ).padding(20)
    }
  }

  func openAppSettings() {
    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
    self.openURL(settingsUrl)
    self.dismiss()
  }
}

#Preview("Enter code") {
  EnterCodeView(submit: { _ in })
}

#Preview("Error") {
  ConnectingView(store: .init(initialState: .init(screen: .connectionFailed(error: "Oh Noes!"))) {
    ConnectAccount()
  })
}
