import SwiftUI

#if os(iOS)
  extension UIDevice {
    static let deviceDidShakeNotification =
      Notification.Name(rawValue: "deviceDidShakeNotification")
  }

  extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
      if motion == .motionShake {
        NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
      }
    }
  }
#endif

struct DeviceShakeViewModifier: ViewModifier {
  let action: () -> Void

  func body(content: Content) -> some View {
    #if os(iOS)
      let notification = NotificationCenter.default
        .publisher(for: UIDevice.deviceDidShakeNotification)
    #else
      let notification = NotificationCenter.default
        .publisher(for: Notification.Name("unreachable"))
    #endif
    content
      .onAppear()
      .onReceive(notification) { _ in
        self.action()
      }
  }
}

extension View {
  func onShake(perform action: @escaping () -> Void) -> some View {
    self.modifier(DeviceShakeViewModifier(action: action))
  }
}
