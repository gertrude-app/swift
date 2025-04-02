import Dependencies
import SwiftUI
import ReplayKit
import Photos

struct RunningView: View {
  @Environment(\.colorScheme) var cs

  @State private var iconOffset = Vector(x: 0, y: 20)
  @State private var titleOffset = Vector(x: 0, y: 20)
  @State private var subtitleOffset = Vector(x: 0, y: 20)
  @State private var linkOffset = Vector(x: 0, y: 20)
  @State private var showBg = false
  
  private let broadcastPicker = RPSystemBroadcastPickerView()

  let showVendorId: Bool

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

        Text("Gertude is blocking unwanted content")
          .font(.system(size: 24, weight: .medium))
          .padding(.bottom, 12)
          .padding(.top, 28)
          .swooshIn(
            tracking: self.$titleOffset,
            to: .zero,
            after: .seconds(0.3),
            for: .seconds(0.5)
          )

        Text("You can pause filtering only when you choose to share your screen.")
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .black.opacity(0.6), dark: .white.opacity(0.6)))
          .swooshIn(
            tracking: self.$subtitleOffset,
            to: .zero,
            after: .seconds(0.4),
            for: .seconds(0.5)
          )
        
        BigButton("Pause Filter",type: .button { buttonTapped() }, variant: .primary)
          .frame(maxWidth: 500)
          .padding(30)

        Link(destination: URL(string: "https://gertrude.app")!) {
          HStack {
            Text("www.gertrude.app")
            Image(systemName: "arrow.up.right")
              .font(.system(size: 14, weight: .semibold))
              .offset(y: 1.5)
          }
        }
        .padding(.bottom, 25)
        .swooshIn(
          tracking: self.$linkOffset,
          to: .zero,
          after: .seconds(0.5),
          for: .seconds(0.5)
        )

        Text("\(UIDevice.current.identifierForVendor?.uuidString.lowercased() ?? "unknown")")
          .font(.system(size: 11, design: .monospaced))
          .opacity(self.showVendorId ? 1 : 0)
          .padding(.top, 25)

        Spacer()
      }
      .frame(maxWidth: .infinity)
      .multilineTextAlignment(.center)
      .padding(30)
    }
  }
  func buttonTapped() {
    // Assumes user will cooperate for the demo. Prompt here while we still have the UI thread.
    PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in }
    
    broadcastPicker.preferredExtension = "com.ftc.gertrude-ios.app.recorder"
    broadcastPicker.showsMicrophoneButton = false
    // This workaround displays the prompt while minimizing encumbrance with UIKit.
    for subview in broadcastPicker.subviews where subview is UIButton {
      (subview as? UIButton)?.sendActions(for: .touchUpInside)
    }
  }
}

#Preview {
  RunningView(showVendorId: false)
}

#Preview("with vendor id") {
  RunningView(showVendorId: true)
}
