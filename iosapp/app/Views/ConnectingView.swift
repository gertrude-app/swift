import ComposableArchitecture
import Dependencies
import LibApp
import SwiftUI

struct ConnectingView: View {
  @Bindable var store: StoreOf<ConnectAccount>
  let infoBlurb: String?

  var body: some View {
    switch self.store.state.screen {
    case .enteringCode:
      EnterCodeView(infoBlurb: self.infoBlurb) {
        self.store.send(.codeSubmitted($0))
      }
    case .connected(childName: let childName):
      ConnectedStateView(childName: childName)
    case .connecting:
      ConnectingStateView()
    case .connectionFailed(error: let error):
      ConnectionFailedView(error: error)
    }
  }
}

struct EnterCodeView: View {
  @Environment(\.colorScheme) var cs
  @FocusState private var isFocused: Bool
  @State private var input: String = ""
  @State private var showBg = false
  @State private var titleOffset = Vector(x: 0, y: 20)
  @State private var descriptionOffset = Vector(x: 0, y: 20)
  @State private var inputOffset = Vector(x: 0, y: 20)
  @State private var buttonOffset = Vector(x: 0, y: 20)
  @State private var helpButtonOffset = Vector(x: 0, y: 20)

  let infoBlurb: String?
  let submit: (Int) -> Void

  var code: Int? {
    guard let code = Int(self.input) else { return nil }
    return code >= 100_000 && code <= 999_999 ? code : nil
  }

  var codeIsValid: Bool {
    self.code != nil
  }

  var body: some View {
    ZStack {
      Color(self.cs, light: .violet100, dark: .violet950.opacity(0.4))
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation(.smooth(duration: 0.5)) {
            self.showBg = true
          }
        }

      VStack(spacing: 20) {
        Spacer()

        VStack(spacing: 16) {
          Text("Connect device")
            .font(.system(size: 28, weight: .bold))
            .multilineTextAlignment(.center)
            .swooshIn(
              tracking: self.$titleOffset,
              to: .zero,
              after: .zero,
              for: .seconds(0.6),
            )

          Text(
            self.infoBlurb ??
              "Enter a 6-digit connection code from the Gertrude parents website for the child you want to protect:",
          )
          .font(.system(size: 16, weight: .medium))
          .multilineTextAlignment(.center)
          .foregroundStyle(Color(self.cs, light: .black.opacity(0.8), dark: .white.opacity(0.8)))
          .swooshIn(
            tracking: self.$descriptionOffset,
            to: .zero,
            after: .seconds(0.1),
            for: .seconds(0.6),
          )
        }
        .padding(.horizontal, 30)

        VStack(spacing: 16) {
          TextField("Enter 6-digit code", text: self.$input)
            .keyboardType(.numberPad)
            .focused(self.$isFocused)
            .font(.system(size: 18, weight: .medium))
            .multilineTextAlignment(.center)
            .padding(16)
            .background(Color(self.cs, light: .white, dark: .white.opacity(0.1)))
            .cornerRadius(12)
            .overlay {
              RoundedRectangle(cornerRadius: 12)
                .stroke(
                  Color(self.cs, light: .violet300, dark: .violet700.opacity(0.5)),
                  lineWidth: 2,
                )
            }
            .swooshIn(
              tracking: self.$inputOffset,
              to: .zero,
              after: .seconds(0.2),
              for: .seconds(0.6),
            )

          BigButton(
            "Connect device",
            type: .button { self.submit(self.code ?? 111_111) },
            disabled: !self.codeIsValid,
          )
          .swooshIn(
            tracking: self.$buttonOffset,
            to: .zero,
            after: .seconds(0.3),
            for: .seconds(0.6),
          )

          BigButton(
            "Help me find the code...",
            type: .link(URL(string: "https://gertrude.app/iosapp-connect-help")!),
            variant: .secondary,
          )
          .swooshIn(
            tracking: self.$helpButtonOffset,
            to: .zero,
            after: .seconds(0.4),
            for: .seconds(0.6),
          )
        }
        .padding(.horizontal, 30)

        Spacer()
      }
      .frame(maxWidth: 500)
      .onAppear { self.isFocused = true }
    }
  }
}

struct ConnectingStateView: View {
  @Environment(\.colorScheme) var cs
  @State private var showBg = false

  var body: some View {
    ZStack {
      Color(self.cs, light: .violet100, dark: .violet950.opacity(0.4))
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation(.smooth(duration: 0.5)) {
            self.showBg = true
          }
        }

      VStack(spacing: 24) {
        ProgressView()
          .scaleEffect(1.5)
          .tint(Color(self.cs, light: .violet500, dark: .violet400))

        Text("Connecting...")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(Color(self.cs, light: .black.opacity(0.8), dark: .white.opacity(0.8)))
      }
    }
  }
}

struct ConnectedStateView: View {
  @Environment(\.colorScheme) var cs
  @State private var showBg = false
  @State private var iconOffset = Vector(x: 0, y: 20)
  @State private var textOffset = Vector(x: 0, y: 20)

  let childName: String

  var body: some View {
    ZStack {
      Color(self.cs, light: .violet100, dark: .violet950.opacity(0.4))
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation(.smooth(duration: 0.5)) {
            self.showBg = true
          }
        }

      VStack(spacing: 24) {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 60))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          .swooshIn(
            tracking: self.$iconOffset,
            to: .zero,
            after: .zero,
            for: .seconds(0.6),
          )

        VStack(spacing: 8) {
          Text("Successfully connected!")
            .font(.system(size: 24, weight: .bold))
            .multilineTextAlignment(.center)

          Text("This device is now connected to ***\(self.childName)***")
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(Color(self.cs, light: .black.opacity(0.8), dark: .white.opacity(0.8)))
            .multilineTextAlignment(.center)
        }
        .swooshIn(
          tracking: self.$textOffset,
          to: .zero,
          after: .seconds(0.1),
          for: .seconds(0.6),
        )
      }
      .padding(.horizontal, 30)
    }
  }
}

struct ConnectionFailedView: View {
  @Environment(\.colorScheme) var cs
  @State private var showBg = false
  @State private var iconOffset = Vector(x: 0, y: 20)
  @State private var textOffset = Vector(x: 0, y: 20)

  let error: String

  var body: some View {
    ZStack {
      Color(self.cs, light: .violet100, dark: .violet950.opacity(0.4))
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation(.smooth(duration: 0.5)) {
            self.showBg = true
          }
        }

      VStack(spacing: 24) {
        Image(systemName: "xmark.circle.fill")
          .font(.system(size: 60))
          .foregroundStyle(Color(self.cs, light: .red, dark: .red.opacity(0.8)))
          .swooshIn(
            tracking: self.$iconOffset,
            to: .zero,
            after: .zero,
            for: .seconds(0.6),
          )

        VStack(spacing: 8) {
          Text("Connection failed")
            .font(.system(size: 24, weight: .bold))
            .multilineTextAlignment(.center)

          Text(self.error)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .black.opacity(0.8), dark: .white.opacity(0.8)))
            .multilineTextAlignment(.center)
        }
        .swooshIn(
          tracking: self.$textOffset,
          to: .zero,
          after: .seconds(0.1),
          for: .seconds(0.6),
        )
      }
      .padding(.horizontal, 30)
    }
  }
}

#Preview("Enter code") {
  ConnectingView(
    store: .init(initialState: .init(screen: .enteringCode)) {
      ConnectAccount()
    },
    infoBlurb: nil,
  )
}

#Preview("Enter code (dark)") {
  ConnectingView(
    store: .init(initialState: .init(screen: .enteringCode)) {
      ConnectAccount()
    },
    infoBlurb: nil,
  )
  .preferredColorScheme(.dark)
}

#Preview("Connecting") {
  ConnectingView(
    store: .init(initialState: .init(screen: .connecting)) {
      ConnectAccount()
    },
    infoBlurb: nil,
  )
}

#Preview("Connecting (dark)") {
  ConnectingView(
    store: .init(initialState: .init(screen: .connecting)) {
      ConnectAccount()
    },
    infoBlurb: nil,
  )
  .preferredColorScheme(.dark)
}

#Preview("Connected") {
  ConnectingView(
    store: .init(initialState: .init(screen: .connected(childName: "Emma"))) {
      ConnectAccount()
    },
    infoBlurb: nil,
  )
}

#Preview("Connected (dark)") {
  ConnectingView(
    store: .init(initialState: .init(screen: .connected(childName: "Emma"))) {
      ConnectAccount()
    },
    infoBlurb: nil,
  )
  .preferredColorScheme(.dark)
}

#Preview("Connection failed") {
  ConnectingView(
    store: .init(initialState: .init(screen: .connectionFailed(
      error: "Invalid code. Please check the code and try again.",
    ))) {
      ConnectAccount()
    },
    infoBlurb: nil,
  )
}

#Preview("Connection failed (dark)") {
  ConnectingView(
    store: .init(initialState: .init(screen: .connectionFailed(
      error: "Invalid code. Please check the code and try again.",
    ))) {
      ConnectAccount()
    },
    infoBlurb: nil,
  )
  .preferredColorScheme(.dark)
}
