import Dependencies
import LibClients
import SwiftUI

struct Running: View {
  @Dependency(\.device) var device

  var showVendorId: Bool
  var onShake: () -> Void

  var body: some View {
    VStack(spacing: 24) {
      Image("GertrudeIcon")
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.12), radius: 4)
        .padding(.bottom, 12)
        .foregroundStyle(.black)

      Text("Gertrude is blocking GIFs and image searches.")
        .font(.system(size: 24, weight: .semibold))
        .multilineTextAlignment(.center)
        .foregroundStyle(.black)

      Text("You can quit this app now—it will keep blocking even when not running.")
        .multilineTextAlignment(.center)
        .foregroundStyle(.black)

      Spacer()

      Text("ID: \(device.vendorId?.uuidString.lowercased() ?? "unknown")")
        .font(.system(size: 11, design: .monospaced))
        .foregroundStyle(.black)
        .opacity(self.showVendorId ? 1 : 0)

      Spacer()

      Text("Questions? Drop us a line at\nhttps://gertrude.app/contact")
        .font(.footnote)
        .foregroundStyle(.black)
    }
    .padding(.top, 60)
    .padding(.bottom, 36)
    .padding(.horizontal, 32)
    .onShake {
      self.onShake()
    }
  }
}

#Preview {
  ZStack {
    BgGradient().ignoresSafeArea()
    Running(showVendorId: false, onShake: {})
  }
}
