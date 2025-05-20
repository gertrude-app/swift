import ComposableArchitecture
import Dependencies
import LibApp
import ReplayKit
import SwiftUI

struct RunningView: View {
  @Environment(\.colorScheme) var cs
  @Environment(\.scenePhase) var scenePhase

  @State private var iconOffset = Vector(x: 0, y: 20)
  @State private var titleOffset = Vector(x: 0, y: 20)
  @State private var subtitleOffset = Vector(x: 0, y: 20)
  @State private var linkOffset = Vector(x: 0, y: 20)
  @State private var showBg = false
  @State private var isRecording = UIScreen.main.isCaptured

  private let broadcastPicker = RPSystemBroadcastPickerView()

  @Bindable var store: StoreOf<IOSReducer>

  let connected: Bool
  let onBtnTap: () -> Void
  let onAppForeground: () -> Void

  var body: some View {
    ZStack {
      FairiesView()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation {
            self.showBg = true
          }
        }

      VStack(spacing: 0) {
        Spacer()

        Image(systemName: "checkmark")
          .font(.system(size: 30, weight: .semibold))
          .foregroundStyle(Color(self.cs, light: .violet800, dark: .violet400))
          .padding(12)
          .background(Color(self.cs, light: .violet300.opacity(0.6), dark: .violet950))
          .cornerRadius(24)
          .swooshIn(tracking: self.$iconOffset, to: .zero, after: .seconds(0.2), for: .seconds(0.5))

        let status = self
          .isRecording ? "Gertrude is not blocking during screen recording." :
          "Gertrude is blocking unwanted content"
        Text(status)
          .font(.system(size: 24, weight: .medium))
          .padding(.bottom, 12)
          .padding(.top, 28)
          .swooshIn(
            tracking: self.$titleOffset,
            to: .zero,
            after: .seconds(0.3),
            for: .seconds(0.5)
          )

        let buttonTitle = self.isRecording ? "Stop Recording" : "Access Internet"
        if self.connected {
          BigButton(buttonTitle, type: .button {
            self.broadcastPicker.preferredExtension = .recorderExtensionBundleId
            self.broadcastPicker.showsMicrophoneButton = false
            // This workaround displays the prompt while minimizing encumbrance with UIKit.
            for subview in self.broadcastPicker.subviews where subview is UIButton {
              (subview as? UIButton)?.sendActions(for: .touchUpInside)
            }
          }).frame(maxWidth: 500)
        } else {
          BigButton(
            "Connect to parent account",
            type: .button(self.onBtnTap)
          ).padding(.bottom, 20)
        }

        Link(destination: URL(string: "https://gertrude.app")!) {
          HStack {
            Text("www.gertrude.app")
            Image(systemName: "arrow.up.right")
              .font(.system(size: 14, weight: .semibold))
              .offset(y: 1.5)
          }
        }
        .padding(.top, 25)
        .swooshIn(
          tracking: self.$linkOffset,
          to: .zero,
          after: .seconds(0.5),
          for: .seconds(0.5)
        )

        Spacer()
      }
      .frame(maxWidth: .infinity)
      .multilineTextAlignment(.center)
      .padding(30)
    }
    .sheet(item: self.$store.scope(
      state: \.destination?.connectAccount,
      action: \.destination.connectAccount
    )) {
      ConnectingView(store: $0)
    }
    .sheet(item: self.$store.scope(
      state: \.destination?.requestSuspension,
      action: \.destination.requestSuspension
    )) {
      RequestSuspensionView(store: $0)
    }
    .onChange(of: self.scenePhase) { oldPhase, newPhase in
      if oldPhase != .active, newPhase == .active {
        self.onAppForeground()
      }
    }
    .onReceive(
      NotificationCenter.default
        .publisher(for: UIScreen.capturedDidChangeNotification)
    ) { _ in
      self.isRecording = UIScreen.main.isCaptured
    }
  }
}

#Preview {
  RunningView(
    store: .init(initialState: .init()) { IOSReducer() },
    connected: false,
    onBtnTap: {},
    onAppForeground: {}
  )
}
